const TravelPackage = require('../models/TravelPackage');
const Booking = require('../models/Booking');
const { uploadImage } = require('../services/cloudinaryService');
const User = require('../models/User');
const notificationService = require('../services/notificationService');

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
 * Upload all req.files to Cloudinary under Yatrikaa/Packages/<safeTitle>
 * Returns array of secure_url strings.
 */
const _uploadImages = async (files, title) => {
  if (!files || files.length === 0) return [];
  const safeTitle = String(title || 'package')
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '_');
  const folder = `Yatrikaa/Packages/${safeTitle}`;
  const results = await Promise.all(files.map(f => uploadImage(f, folder)));
  return results.map(r => r.secure_url);
};

// ─────────────────────────────────────────────────────────────────────────────
// PACKAGE CONTROLLERS
// ─────────────────────────────────────────────────────────────────────────────

// @desc  Get all published travel packages (with optional filters + pagination)
// @route GET /api/packages?page=1&limit=10&category=&search=
// @access Public
const getPackages = async (req, res, next) => {
  try {
    const { category, difficulty, search } = req.query;

    // Pagination params (default: page=1, limit=10; limit=0 → all)
    const page  = Math.max(1, parseInt(req.query.page  || '1',  10));
    const limit = Math.max(0, parseInt(req.query.limit || '10', 10));

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

    const baseQuery = TravelPackage.find(filter)
      .populate('organizer', 'name profileImage role tripsCount packagesCount isVerified guideRequestStatus')
      .sort({ isPopular: -1, createdAt: -1 });

    let packages;
    let totalCount;

    if (limit === 0) {
      // Legacy / admin: return all
      packages   = await baseQuery;
      totalCount = packages.length;
    } else {
      totalCount = await TravelPackage.countDocuments(filter);
      packages   = await baseQuery.skip((page - 1) * limit).limit(limit);
    }

    const totalPages = limit > 0 ? Math.ceil(totalCount / limit) : 1;
    const hasMore    = limit > 0 && page < totalPages;

    res.status(200).json({
      success: true,
      count: packages.length,
      totalCount,
      page,
      totalPages,
      hasMore,
      results: packages,
    });
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
      .populate('organizer', 'name profileImage role tripsCount packagesCount isVerified guideRequestStatus');

    if (!pkg) return res.status(404).json({ success: false, error: 'Travel package not found' });

    res.status(200).json({ success: true, result: pkg });
  } catch (err) {
    next(err);
  }
};

// @desc  Create a travel package
// @route POST /api/packages
// @access Private (Guide, Admin)
const createPackage = async (req, res, next) => {
  try {
    const body = _parsePackageBody(req.body);

    // Upload images to Cloudinary
    const imageUrls = await _uploadImages(req.files, body.title);
    if (imageUrls.length > 0) body.images = imageUrls;

    // Guides start as Draft pending admin review; admins publish immediately
    const userRole = req.user.role ? req.user.role.toLowerCase().replace(/[^a-z]/g, '') : '';
    const status = userRole === 'admin' ? 'Published' : 'Draft';

    const pkg = await TravelPackage.create({
      ...body,
      organizer: req.user._id,
      status,
    });

    // Populate organizer for response
    await pkg.populate('organizer', 'name profileImage role tripsCount packagesCount isVerified guideRequestStatus');

    // Increment organizer's packagesCount
    await User.findByIdAndUpdate(req.user._id, { $inc: { packagesCount: 1 } });

    console.log(`[packages] Created: "${pkg.title}" by ${req.user.name} (${status})`);
    res.status(201).json({ success: true, result: pkg });
  } catch (err) {
    console.error('[packages] createPackage error:', err.message);
    next(err);
  }
};

// @desc  Update a travel package
// @route PUT /api/packages/:id
// @access Private (Owner Guide, Admin)
const updatePackage = async (req, res, next) => {
  try {
    const pkg = await TravelPackage.findById(req.params.id);
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    const isOwner = pkg.organizer.toString() === req.user._id.toString();
    const userRole = req.user.role ? req.user.role.toLowerCase().replace(/[^a-z]/g, '') : '';
    const isAdmin = userRole === 'admin';
    if (!isOwner && !isAdmin) {
      return res.status(403).json({ success: false, error: 'Not authorised to edit this package' });
    }

    const body = _parsePackageBody(req.body);

    // Security: Only admins can change status (e.g. Publish/Draft)
    if (!isAdmin) {
      delete body.status;
    }

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
    ).populate('organizer', 'name profileImage role tripsCount packagesCount isVerified guideRequestStatus');

    res.status(200).json({ success: true, result: updated });
  } catch (err) {
    next(err);
  }
};

// @desc  Admin: publish / approve a Draft package
// @route PATCH /api/packages/:id/publish
// @access Private (Admin)
const publishPackage = async (req, res, next) => {
  try {
    const pkg = await TravelPackage.findByIdAndUpdate(
      req.params.id,
      { status: 'Published' },
      { new: true }
    );
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    // --- AUTOMATED NOTIFICATIONS ---
    // Notify the guide that their package is live!
    const guide = await User.findById(pkg.organizer);
    if (guide && guide.fcmToken) {
      notificationService.sendToToken(guide.fcmToken, {
        title: 'Package Published! 🌟',
        body: `Your package "${pkg.title}" is now live and visible to all travelers.`,
      }, { type: 'package_published', packageId: pkg._id.toString() }).catch(e => console.error(e));
    }

    res.status(200).json({ success: true, result: pkg, message: 'Package published successfully' });
  } catch (err) {
    next(err);
  }
};

// @desc  Delete / cancel a travel package
// @route DELETE /api/packages/:id
// @access Private (Admin only)
const deletePackage = async (req, res, next) => {
  try {
    const pkg = await TravelPackage.findByIdAndDelete(req.params.id);
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    // Cancel any pending bookings for this package
    await Booking.updateMany(
      { package: req.params.id, status: { $in: ['Pending', 'Confirmed'] } },
      { status: 'Cancelled' }
    );

    // Decrement organizer's packagesCount
    if (pkg.organizer) {
      await User.findByIdAndUpdate(pkg.organizer, { $inc: { packagesCount: -1 } });
    }

    res.status(200).json({ success: true, message: 'Package deleted successfully' });
  } catch (err) {
    next(err);
  }
};

// @desc  Get packages created by the logged-in guide
// @route GET /api/packages/my
// @access Private (Guide, Admin)
const getMyPackages = async (req, res, next) => {
  try {
    const packages = await TravelPackage.find({ organizer: req.user._id })
      .populate('organizer', 'name profileImage role tripsCount packagesCount isVerified guideRequestStatus')
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

    // Double booking prevention removed to allow multiple group bookings by same user

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

    // --- AUTOMATED NOTIFICATIONS ---
    // 1. Notify the User (Booking Success)
    if (req.user.fcmToken) {
      notificationService.sendToToken(req.user.fcmToken, {
        title: 'Booking Successful! ✈️',
        body: `You have successfully joined "${pkg.title}". Get ready for the adventure!`,
      }, { type: 'booking_success', bookingId: booking._id.toString() }, req.user._id).catch(e => console.error(e));
    }

    // 2. Notify the Guide (New Booking Alert)
    const guide = await User.findById(pkg.organizer);
    if (guide && guide.fcmToken) {
      notificationService.sendToToken(guide.fcmToken, {
        title: 'New Booking Received! 💰',
        body: `${req.user.name} and ${travelersCount - 1} others joined "${pkg.title}".`,
      }, { type: 'new_booking', bookingId: booking._id.toString() }, guide._id).catch(e => console.error(e));
    }

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
        populate: { path: 'organizer', select: 'name profileImage role tripsCount packagesCount isVerified guideRequestStatus' },
      })
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, count: bookings.length, results: bookings });
  } catch (err) {
    next(err);
  }
};

// @desc  Cancel or Reject a booking
// @route PATCH /api/packages/bookings/:id/cancel
// @access Private (User who booked, Organiser, or Admin)
const cancelBooking = async (req, res, next) => {
  try {
    const booking = await Booking.findById(req.params.id).populate('package');
    if (!booking) return res.status(404).json({ success: false, error: 'Booking not found' });

    const pkg = booking.package;
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    const isUser = booking.user && booking.user.toString() === req.user._id.toString();
    const isPackageOwner = pkg.organizer && pkg.organizer.toString() === req.user._id.toString();
    const userRole = req.user.role ? req.user.role.toLowerCase().trim() : 'user';
    const isAdmin = userRole === 'admin';

    console.log(`[CancelBooking] LOGS:
      BookingID: ${booking._id}
      CurrentStatus: ${booking.status}
      TravelerID: ${booking.user}
      RequestUserID: ${req.user._id}
      RequestUserRole: ${userRole}
      isUser: ${isUser}
      isPackageOwner: ${isPackageOwner}
      isAdmin: ${isAdmin}`);

    if (!isUser && !isPackageOwner && !isAdmin) {
      console.log(`[CancelBooking] Denied: User is neither traveler, owner, nor admin.`);
      return res.status(403).json({ success: false, error: 'Not authorised to cancel this booking' });
    }

    if (booking.status === 'Cancelled') {
      return res.status(400).json({ success: false, error: 'Booking is already cancelled' });
    }

    const oldStatus = booking.status;

    // Logic: If regular user tries to cancel, it becomes a "Request"
    // If Organiser or Admin tries to cancel, it becomes "Cancelled" (Approved)
    // IMPORTANT: Guide/Organiser role users are still treated as "User" if they book someone else's trip
    // Logic: If regular user tries to cancel someone else's package, it becomes a "Request"
    // If Package Owner or Admin tries to cancel, it becomes "Cancelled" immediately
    if (isUser && !isPackageOwner && !isAdmin) {
      if (booking.status === 'CancellationRequested') {
        return res.status(400).json({ success: false, error: 'Cancellation request already sent' });
      }
      booking.status = 'CancellationRequested';
      await booking.save();
      console.log(`[CancelBooking] Success: User ${req.user._id} requested cancellation.`);
      return res.status(200).json({ 
        success: true, 
        result: booking, 
        message: 'Cancellation request submitted to admin for approval' 
      });
    }

    // If we reach here, it's a privileged user cancelling or approving a request
    booking.status = 'Cancelled';
    await booking.save();
    console.log(`[CancelBooking] Success: Booking ${booking._id} set to Cancelled by privileged user ${req.user._id}.`);

    // Decrement participant count if it was Pending, Confirmed, or CancellationRequested
    if (oldStatus !== 'Cancelled') {
      const dec = booking.travelers?.length || 1;
      await TravelPackage.findByIdAndUpdate(pkg._id, {
        $inc: { currentParticipants: -dec },
      });
    }

    // --- AUTOMATED NOTIFICATIONS ---
    // Notify the user about the cancellation/rejection
    if (booking.user) {
      const dbUser = await User.findById(booking.user);
      if (dbUser && dbUser.fcmToken) {
        let title = 'Booking Cancelled';
        let body = `Your booking for "${pkg.title}" has been cancelled.`;
        
        if (booking.status === 'CancellationRequested') {
          title = 'Cancellation Requested';
          body = `Your request to cancel "${pkg.title}" has been submitted.`;
        }

        notificationService.sendToToken(dbUser.fcmToken, { title, body }, 
          { type: 'booking_cancelled', bookingId: booking._id.toString() }, dbUser._id).catch(e => console.error(e));
      }
    }

    res.status(200).json({ 
      success: true, 
      result: booking, 
      message: isPackageOwner || isAdmin ? 'Booking cancelled/approved' : 'Booking cancelled' 
    });
  } catch (err) {
    next(err);
  }
};

// @desc  Confirm / Approve a booking
// @route PATCH /api/packages/bookings/:id/confirm
// @access Private (Organiser or Admin only)
const confirmBooking = async (req, res, next) => {
  try {
    const booking = await Booking.findById(req.params.id).populate('package');
    if (!booking) return res.status(404).json({ success: false, error: 'Booking not found' });

    const pkg = booking.package;
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    const isOrganiser = pkg.organizer.toString() === req.user._id.toString();
    const userRole = req.user.role ? req.user.role.toLowerCase().replace(/[^a-z]/g, '') : '';
    const isAdmin = userRole === 'admin';

    if (!isOrganiser && !isAdmin) {
      return res.status(403).json({ success: false, error: 'Not authorised to confirm bookings for this package' });
    }

    if (booking.status === 'Confirmed') {
      return res.status(400).json({ success: false, error: 'Booking is already confirmed' });
    }

    booking.status = 'Confirmed';
    await booking.save();

    // --- AUTOMATED NOTIFICATIONS ---
    // Notify user that booking is confirmed
    const dbUser = await User.findById(booking.user);
    if (dbUser && dbUser.fcmToken) {
      notificationService.sendToToken(dbUser.fcmToken, {
        title: 'Booking Confirmed! ✅',
        body: `Pack your bags! Your booking for "${pkg.title}" is now confirmed.`,
      }, { type: 'booking_confirmed', bookingId: booking._id.toString() }, dbUser._id).catch(e => console.error(e));
    }

    res.status(200).json({ success: true, result: booking, message: 'Booking confirmed successfully' });
  } catch (err) {
    next(err);
  }
};

// @desc  Get participants list for a package (organiser/admin only)
// @route GET /api/packages/:id/participants
// @access Private (Owner Guide, Admin)
const getPackageParticipants = async (req, res, next) => {
  try {
    const pkg = await TravelPackage.findById(req.params.id);
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    const isOwner = pkg.organizer.toString() === req.user._id.toString();
    const userRole = req.user.role ? req.user.role.toLowerCase().replace(/[^a-z]/g, '') : '';
    const isAdmin = userRole === 'admin';
    if (!isOwner && !isAdmin) {
      return res.status(403).json({ success: false, error: 'Not authorised' });
    }

    const bookings = await Booking.find({ package: req.params.id })
      .populate('user', 'name email profileImage contactNumber')
      .populate('package', 'title');

    res.status(200).json({ success: true, count: bookings.length, results: bookings });
  } catch (err) {
    next(err);
  }
};

/**
 * @desc  Get all bookings for all packages organized by the logged-in guide
 * @route GET /api/packages/bookings/organizer
 * @access Private (Guide, Admin)
 */
const getGuideBookings = async (req, res, next) => {
  try {
    // 1. Find all packages by this guide
    const packages = await TravelPackage.find({ organizer: req.user._id }).select('_id');
    const packageIds = packages.map(p => p._id);

    // 2. Find all bookings for these packages
    const bookings = await Booking.find({ package: { $in: packageIds } })
      .populate('user', 'name email profileImage contactNumber')
      .populate('package', 'title images destination duration price')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, count: bookings.length, results: bookings });
  } catch (err) {
    next(err);
  }
};

// @desc  Admin: get all packages (including Draft)
// @route GET /api/packages/admin/all
// @access Private (Admin)
const getAllPackagesAdmin = async (req, res, next) => {
  try {
    const { status } = req.query;
    const filter = status ? { status } : {};
    const packages = await TravelPackage.find(filter)
      .populate('organizer', 'name email profileImage role tripsCount packagesCount isVerified guideRequestStatus')
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
  confirmBooking,
  getPackageParticipants,
  getAllPackagesAdmin,
  getGuideBookings,
};
