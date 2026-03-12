const TravelPackage = require('../models/TravelPackage');
const Booking = require('../models/Booking');
const { uploadImage } = require('../services/cloudinaryService');

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Parse multipart form-data body:
 * Flutter sends nested objects (destination, duration, itinerary, etc.)
 * as JSON-encoded strings. This function decodes them back to objects.
 */
const _parsePackageBody = (body) => {
  if (!body) return {};
  const b = { ...body };

  const jsonFields = ['destination', 'duration', 'itinerary', 'inclusions', 'exclusions'];
  for (const field of jsonFields) {
    if (b[field] && typeof b[field] === 'string') {
      try {
        b[field] = JSON.parse(b[field]);
      } catch (e) {
        console.warn(`[packages] Failed to parse field "${field}":`, e.message);
      }
    }
  }

  // Booleans
  if (typeof b.isPopular === 'string') {
    b.isPopular = b.isPopular === 'true';
  }

  // Numbers
  if (typeof b.price === 'string') b.price = parseFloat(b.price) || 0;
  if (typeof b.maxGroupSize === 'string') b.maxGroupSize = parseInt(b.maxGroupSize, 10) || 1;

  return b;
};

/**
 * Upload all req.files to Cloudinary under Bhatkanti/Packages/<safeTitle>
 * Returns array of secure_url strings.
 */
const _uploadImages = async (files, title) => {
  if (!files || files.length === 0) return [];
  const safeTitle = String(title || 'package')
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '_');
  const folder = `Bhatkanti/Packages/${safeTitle}`;
  const results = await Promise.all(files.map(f => uploadImage(f, folder)));
  return results.map(r => r.secure_url);
};

// ─────────────────────────────────────────────────────────────────────────────
// PACKAGE CONTROLLERS
// ─────────────────────────────────────────────────────────────────────────────

// @desc  Get all published travel packages (with optional filters)
// @route GET /api/packages
// @access Public
const getPackages = async (req, res, next) => {
  try {
    const { category, difficulty, search } = req.query;
    const filter = { status: 'Published' };

    if (category && category !== 'All') filter.category = category;
    if (difficulty) filter.difficulty = difficulty;
    if (search) {
      filter.$or = [
        { title: { $regex: search, $options: 'i' } },
        { 'destination.name': { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }

    const packages = await TravelPackage.find(filter)
      .populate('organizer', 'name profileImage role')
      .sort({ isPopular: -1, createdAt: -1 });

    res.status(200).json({ success: true, count: packages.length, results: packages });
  } catch (err) {
    next(err);
  }
};

// @desc  Get single package details
// @route GET /api/packages/:id
// @access Public
const getPackageDetails = async (req, res, next) => {
  try {
    const pkg = await TravelPackage.findById(req.params.id)
      .populate('organizer', 'name profileImage role');

    if (!pkg) return res.status(404).json({ success: false, error: 'Travel package not found' });

    res.status(200).json({ success: true, result: pkg });
  } catch (err) {
    next(err);
  }
};

// @desc  Create a travel package
// @route POST /api/packages
// @access Private (Guide, Admin, Super-Admin)
const createPackage = async (req, res, next) => {
  try {
    const body = _parsePackageBody(req.body);

    // Upload images to Cloudinary
    const imageUrls = await _uploadImages(req.files, body.title);
    if (imageUrls.length > 0) body.images = imageUrls;

    // Guides start as Draft pending admin review; admins publish immediately
    const status = ['admin', 'super-admin'].includes(req.user.role)
      ? 'Published'
      : 'Draft';

    const pkg = await TravelPackage.create({
      ...body,
      organizer: req.user._id,
      status,
    });

    // Populate organizer for response
    await pkg.populate('organizer', 'name profileImage role');

    console.log(`[packages] Created: "${pkg.title}" by ${req.user.name} (${status})`);
    res.status(201).json({ success: true, result: pkg });
  } catch (err) {
    console.error('[packages] createPackage error:', err.message);
    next(err);
  }
};

// @desc  Update a travel package
// @route PUT /api/packages/:id
// @access Private (Owner Guide, Admin, Super-Admin)
const updatePackage = async (req, res, next) => {
  try {
    const pkg = await TravelPackage.findById(req.params.id);
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    const isOwner = pkg.organizer.toString() === req.user._id.toString();
    const isAdmin = ['admin', 'super-admin'].includes(req.user.role);
    if (!isOwner && !isAdmin) {
      return res.status(403).json({ success: false, error: 'Not authorised to edit this package' });
    }

    const body = _parsePackageBody(req.body);

    // Upload any new images and merge with existing
    const newImageUrls = await _uploadImages(req.files, body.title || pkg.title);
    const existingImages = Array.isArray(body.images) ? body.images : pkg.images;
    if (newImageUrls.length > 0) {
      body.images = [...existingImages, ...newImageUrls];
    }

    const updated = await TravelPackage.findByIdAndUpdate(
      req.params.id,
      body,
      { new: true, runValidators: true }
    ).populate('organizer', 'name profileImage role');

    res.status(200).json({ success: true, result: updated });
  } catch (err) {
    next(err);
  }
};

// @desc  Admin: publish / approve a Draft package
// @route PATCH /api/packages/:id/publish
// @access Private (Admin, Super-Admin)
const publishPackage = async (req, res, next) => {
  try {
    const pkg = await TravelPackage.findByIdAndUpdate(
      req.params.id,
      { status: 'Published' },
      { new: true }
    );
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    res.status(200).json({ success: true, result: pkg, message: 'Package published successfully' });
  } catch (err) {
    next(err);
  }
};

// @desc  Delete / cancel a travel package
// @route DELETE /api/packages/:id
// @access Private (Admin, Super-Admin only)
const deletePackage = async (req, res, next) => {
  try {
    const pkg = await TravelPackage.findByIdAndDelete(req.params.id);
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    // Cancel any pending bookings for this package
    await Booking.updateMany(
      { package: req.params.id, status: { $in: ['Pending', 'Confirmed'] } },
      { status: 'Cancelled' }
    );

    res.status(200).json({ success: true, message: 'Package deleted successfully' });
  } catch (err) {
    next(err);
  }
};

// @desc  Get packages created by the logged-in guide
// @route GET /api/packages/my
// @access Private (Guide, Admin, Super-Admin)
const getMyPackages = async (req, res, next) => {
  try {
    const packages = await TravelPackage.find({ organizer: req.user._id })
      .populate('organizer', 'name profileImage role')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, count: packages.length, results: packages });
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING CONTROLLERS
// ─────────────────────────────────────────────────────────────────────────────

// @desc  Book / join a travel package
// @route POST /api/packages/:id/join
// @access Private (Any authenticated user)
const joinPackage = async (req, res, next) => {
  try {
    const pkg = await TravelPackage.findById(req.params.id);
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    if (pkg.status !== 'Published') {
      return res.status(400).json({ success: false, error: 'This package is not accepting bookings' });
    }

    // Seat check
    const remainingSlots = pkg.maxGroupSize - pkg.currentParticipants;
    const travelers = Array.isArray(req.body.travelers) ? req.body.travelers : [];
    const travelersCount = travelers.length || 1;

    if (travelersCount > remainingSlots) {
      return res.status(400).json({
        success: false,
        error: `Only ${remainingSlots} seat(s) remaining in this package`,
      });
    }

    // Prevent double booking
    const existing = await Booking.findOne({
      package: pkg._id,
      user: req.user._id,
      status: { $in: ['Pending', 'Confirmed'] },
    });
    if (existing) {
      return res.status(400).json({ success: false, error: 'You have already joined this package' });
    }

    const booking = await Booking.create({
      package: pkg._id,
      user: req.user._id,
      travelers,
      totalAmount: pkg.price * travelersCount,
      contactNumber: req.body.contactNumber,
      notes: req.body.notes,
    });

    // Increment participant count
    await TravelPackage.findByIdAndUpdate(pkg._id, {
      $inc: { currentParticipants: travelersCount },
    });

    // Populate package info in response for the Flutter model
    await booking.populate('package', 'title images destination duration price');

    console.log(`[packages] ${req.user.name} joined "${pkg.title}" (${travelersCount} travelers)`);
    res.status(201).json({ success: true, result: booking });
  } catch (err) {
    next(err);
  }
};

// @desc  Get all bookings of the logged-in user
// @route GET /api/packages/bookings/mine
// @access Private
const getMyBookings = async (req, res, next) => {
  try {
    const bookings = await Booking.find({ user: req.user._id })
      .populate('package', 'title images destination duration price organizer')
      .populate({
        path: 'package',
        populate: { path: 'organizer', select: 'name profileImage role' },
      })
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, count: bookings.length, results: bookings });
  } catch (err) {
    next(err);
  }
};

// @desc  Cancel a booking
// @route PATCH /api/packages/bookings/:id/cancel
// @access Private
const cancelBooking = async (req, res, next) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ success: false, error: 'Booking not found' });

    if (booking.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, error: 'Not authorised' });
    }
    if (booking.status === 'Cancelled') {
      return res.status(400).json({ success: false, error: 'Booking is already cancelled' });
    }

    booking.status = 'Cancelled';
    await booking.save();

    // Decrement participant count
    const dec = booking.travelers?.length || 1;
    await TravelPackage.findByIdAndUpdate(booking.package, {
      $inc: { currentParticipants: -dec },
    });

    res.status(200).json({ success: true, result: booking });
  } catch (err) {
    next(err);
  }
};

// @desc  Get participants list for a package (organiser/admin only)
// @route GET /api/packages/:id/participants
// @access Private (Owner Guide, Admin, Super-Admin)
const getPackageParticipants = async (req, res, next) => {
  try {
    const pkg = await TravelPackage.findById(req.params.id);
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    const isOwner = pkg.organizer.toString() === req.user._id.toString();
    const isAdmin = ['admin', 'super-admin'].includes(req.user.role);
    if (!isOwner && !isAdmin) {
      return res.status(403).json({ success: false, error: 'Not authorised' });
    }

    const bookings = await Booking.find({ package: req.params.id })
      .populate('user', 'name email profileImage contactNumber');

    res.status(200).json({ success: true, count: bookings.length, results: bookings });
  } catch (err) {
    next(err);
  }
};

// @desc  Admin: get all packages (including Draft)
// @route GET /api/packages/admin/all
// @access Private (Admin, Super-Admin)
const getAllPackagesAdmin = async (req, res, next) => {
  try {
    const { status } = req.query;
    const filter = status ? { status } : {};
    const packages = await TravelPackage.find(filter)
      .populate('organizer', 'name email profileImage role')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, count: packages.length, results: packages });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getPackages,
  getPackageDetails,
  createPackage,
  updatePackage,
  publishPackage,
  deletePackage,
  getMyPackages,
  joinPackage,
  getMyBookings,
  cancelBooking,
  getPackageParticipants,
  getAllPackagesAdmin,
};
