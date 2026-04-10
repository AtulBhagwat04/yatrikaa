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

  const jsonFields = [
    'destination',
    'duration',
    'itinerary',
    'inclusions',
    'exclusions',
    'images',
  ];
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
  if (typeof b.isComingSoon === 'string') {
    b.isComingSoon = b.isComingSoon === 'true';
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
      .populate('organizer', 'name profilePicture role tripsCount packagesCount isVerified guideRequestStatus')
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
      .populate('organizer', 'name profilePicture role tripsCount packagesCount isVerified guideRequestStatus');

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
    await pkg.populate('organizer', 'name profilePicture role tripsCount packagesCount isVerified guideRequestStatus');

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
    ).populate('organizer', 'name profilePicture role tripsCount packagesCount isVerified guideRequestStatus');

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
// @route GET /api/packages/my?page=1&limit=12
// @access Private (Guide, Admin)
const getMyPackages = async (req, res, next) => {
  try {
    const page  = Math.max(1, parseInt(req.query.page  || '1',  10));
    const limit = Math.max(0, parseInt(req.query.limit || '12', 10));

    const filter = { organizer: req.user._id };
    const baseQuery = TravelPackage.find(filter)
      .populate('organizer', 'name profilePicture role tripsCount packagesCount isVerified guideRequestStatus')
      .sort({ createdAt: -1 });

    let packages;
    let totalCount;

    if (limit === 0) {
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
      results: packages
    });
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
    const guide = await User.findById(pkg.organizer);

    // 1. Notify the User (Booking Pending)
    if (req.user.fcmToken) {
      const guideName = guide ? guide.name : 'the guide';
      notificationService.sendToToken(req.user.fcmToken, {
        title: 'Booking Request Sent! ⏳',
        body: `Your request to join "${pkg.title}" has been sent. Please wait for ${guideName} to approve your booking.`,
      }, { type: 'booking_pending', bookingId: booking._id.toString() }, req.user._id).catch(e => console.error(e));
    }

    // 2. Notify the Guide (New Booking Alert)
    if (guide && guide.fcmToken) {
      notificationService.sendToToken(guide.fcmToken, {
        title: 'New Booking Request Received! ⏳',
        body: `${req.user.name} joined "${pkg.title}". Please review and approve the request from your dashboard.`,
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
        populate: { path: 'organizer', select: 'name profilePicture role tripsCount packagesCount isVerified guideRequestStatus' },
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

    if (!isUser && !isPackageOwner && !isAdmin) {
      return res.status(403).json({ success: false, error: 'Not authorised' });
    }

    if (booking.status === 'Cancelled') {
      return res.status(400).json({ success: false, error: 'Booking is already cancelled' });
    }

    const oldStatus = booking.status;

    if (isUser && !isPackageOwner && !isAdmin) {
      if (booking.status === 'CancellationRequested') {
        return res.status(400).json({ success: false, error: 'Request already sent' });
      }
      booking.status = 'CancellationRequested';
      await booking.save();

      // Notify the Guide about the cancellation request
      const guide = await User.findById(pkg.organizer);
      if (guide && guide.fcmToken) {
        notificationService.sendToToken(guide.fcmToken, {
          title: 'Cancellation Requested! ⚠️',
          body: `${req.user.name} has requested to cancel their booking for "${pkg.title}". Please review it.`,
        }, { type: 'cancellation_request', bookingId: booking._id.toString() }, guide._id).catch(e => console.error(e));
      }

      return res.status(200).json({ success: true, result: booking, message: 'Cancellation requested' });
    }

    // Bulk Reject (Guide/Admin side): 
    // Only reject the travelers that are currently 'Pending'.
    // Preserve 'Confirmed' ones as per user request.
    let seatsToRelease = 0;
    booking.travelers.forEach(t => {
      if (t.status === 'Pending') {
        t.status = 'Cancelled';
        seatsToRelease++;
      }
    });

    // Update overall booking status: 
    // If someone is still confirmed, the booking stays Confirmed.
    // If everyone is now cancelled, it becomes Cancelled.
    const anyConfirmed = booking.travelers.some(t => t.status === 'Confirmed');
    booking.status = anyConfirmed ? 'Confirmed' : 'Cancelled';
    
    await booking.save();

    // Release seats for the travelers we just cancelled
    if (seatsToRelease > 0) {
      await TravelPackage.updateOne(
        { _id: pkg._id, currentParticipants: { $gte: seatsToRelease } },
        { $inc: { currentParticipants: -seatsToRelease } }
      );
    }

    // --- NOTIFICATION ---
    if (booking.user) {
      const dbUser = await User.findById(booking.user);
      if (dbUser && dbUser.fcmToken) {
        // Collect names of newly rejected travelers
        const newlyRejectedNames = booking.travelers.filter(t => t.status === 'Cancelled').map(t => t.name);
        let body = `Booking update for "${pkg.title}": ${booking.status}.`;
        if (newlyRejectedNames.length > 0) {
          body += ` Cancelled travelers: ${newlyRejectedNames.join(', ')}.`;
        }

        notificationService.sendToToken(dbUser.fcmToken, {
          title: 'Booking Status Update',
          body: body
        }, { type: 'booking_cancelled', bookingId: booking._id.toString() }, dbUser._id).catch(e => console.error(e));
      }
    }

    res.status(200).json({ success: true, result: booking });
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
    const isAdmin = req.user.role === 'admin';

    if (!isOrganiser && !isAdmin) {
      return res.status(403).json({ success: false, error: 'Not authorised' });
    }

    if (booking.status === 'Confirmed') {
      const allDone = booking.travelers.every(t => t.status !== 'Pending');
      if (allDone) return res.status(400).json({ success: false, error: 'Already fully processed' });
    }

    const { status: requestedStatus } = req.body;
    const finalStatus = (requestedStatus === 'Cancelled') ? 'Cancelled' : 'Confirmed';

    // Track newly updated names for notification
    const newlyUpdatedNames = [];
    booking.travelers.forEach(t => {
      if (t.status === 'Pending') {
        t.status = finalStatus;
        newlyUpdatedNames.push(t.name);
      }
    });

    // Update overall booking status
    const anyConfirmed = booking.travelers.some(t => t.status === 'Confirmed');
    booking.status = anyConfirmed ? 'Confirmed' : 'Cancelled';
    
    if (finalStatus === 'Cancelled' && newlyUpdatedNames.length > 0) {
      await TravelPackage.updateOne(
        { _id: pkg._id, currentParticipants: { $gte: newlyUpdatedNames.length } },
        { $inc: { currentParticipants: -newlyUpdatedNames.length } }
      );
    }
    
    await booking.save();

    const dbUser = await User.findById(booking.user);
    if (dbUser && dbUser.fcmToken) {
      let body = `Your booking for "${pkg.title}" update:`;
      if (finalStatus === 'Confirmed' && newlyUpdatedNames.length > 0) {
        body += ` Confirmed: ${newlyUpdatedNames.join(', ')}.`;
      } else if (finalStatus === 'Cancelled' && newlyUpdatedNames.length > 0) {
        body += ` Cancelled: ${newlyUpdatedNames.join(', ')}.`;
      }
      
      const cancelledNames = booking.travelers.filter(t => t.status === 'Cancelled' && !newlyUpdatedNames.includes(t.name)).map(t => t.name);
      if (cancelledNames.length > 0) {
        body += ` Previously Cancelled: ${cancelledNames.join(', ')}.`;
      }

      notificationService.sendToToken(dbUser.fcmToken, {
        title: 'Booking Confirmed! ✅',
        body: body,
      }, { type: 'booking_confirmed', bookingId: booking._id.toString() }, dbUser._id).catch(e => console.error(e));
    }

    res.status(200).json({ success: true, result: booking });
  } catch (err) {
    next(err);
  }
};

// @desc  Get participants list for a package
// @route GET /api/packages/:id/participants
// @access Private (Owner Guide, Admin)
const getPackageParticipants = async (req, res, next) => {
  try {
    const pkg = await TravelPackage.findById(req.params.id);
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    const isOwner = pkg.organizer.toString() === req.user._id.toString();
    const isAdmin = req.user.role === 'admin';
    if (!isOwner && !isAdmin) return res.status(403).json({ success: false, error: 'Not authorised' });

    const bookings = await Booking.find({ package: req.params.id })
      .populate('user', 'name email profilePicture contactNumber')
      .populate('package', 'title');

    res.status(200).json({ success: true, count: bookings.length, results: bookings });
  } catch (err) {
    next(err);
  }
};

// @desc  Admin: get all packages
const getAllPackagesAdmin = async (req, res, next) => {
  try {
    const { status } = req.query;
    const page  = Math.max(1, parseInt(req.query.page  || '1',  10));
    const limit = Math.max(0, parseInt(req.query.limit || '12', 10));

    const filter = status ? { status } : {};
    const baseQuery = TravelPackage.find(filter)
      .populate('organizer', 'name email profilePicture role tripsCount packagesCount isVerified guideRequestStatus')
      .sort({ createdAt: -1 });

    let packages;
    let totalCount;

    if (limit === 0) {
      packages   = await baseQuery;
      totalCount = packages.length;
    } else {
      totalCount = await TravelPackage.countDocuments(filter);
      packages   = await baseQuery.skip((page - 1) * limit).limit(limit);
    }

    const totalPages = limit > 0 ? Math.ceil(totalCount / limit) : 1;
    const hasMore    = limit > 0 && page < totalPages;

    res.status(200).json({ success: true, count: packages.length, totalCount, page, totalPages, hasMore, results: packages });
  } catch (err) {
    next(err);
  }
};

// @desc  Get all bookings for a guide's packages
const getGuideBookings = async (req, res, next) => {
  try {
    const packages = await TravelPackage.find({ organizer: req.user._id }).select('_id');
    const packageIds = packages.map(p => p._id);

    const bookings = await Booking.find({ package: { $in: packageIds } })
      .populate('user', 'name email profilePicture contactNumber')
      .populate('package', 'title images destination duration price')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, count: bookings.length, results: bookings });
  } catch (err) {
    next(err);
  }
};

// @desc  Handle individual traveler status
// @route PATCH /api/packages/bookings/:id/travelers/:travelerId
const handleTravelerStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    if (!['Confirmed', 'Cancelled'].includes(status)) return res.status(400).json({ success: false, error: 'Invalid status' });

    const booking = await Booking.findById(req.params.id).populate('package');
    if (!booking) return res.status(404).json({ success: false, error: 'Booking not found' });

    const pkg = booking.package;
    if (!pkg) return res.status(404).json({ success: false, error: 'Package broken' });

    const isOwner = pkg.organizer.toString() === req.user._id.toString();
    const isAdmin = req.user.role === 'admin';
    if (!isOwner && !isAdmin) return res.status(403).json({ success: false, error: 'Not authorised' });

    const travelerIndex = booking.travelers.findIndex(t => t._id.toString() === req.params.travelerId);
    if (travelerIndex === -1) return res.status(404).json({ success: false, error: 'Traveler not found' });

    // Track status change for seat count update
    const prevTravelerStatus = booking.travelers[travelerIndex].status;
    booking.travelers[travelerIndex].status = status;

    const allProcessed = booking.travelers.every(t => t.status !== 'Pending');
    if (allProcessed) {
      const anyConfirmed = booking.travelers.some(t => t.status === 'Confirmed');
      booking.status = anyConfirmed ? 'Confirmed' : 'Cancelled';
    }

    await booking.save();

    // Update seat count on the package if status changed
    if (prevTravelerStatus !== 'Cancelled' && status === 'Cancelled') {
      // Reverted/Rejected: decrement participant count but ensure it never goes below zero
      await TravelPackage.updateOne(
        { _id: pkg._id, currentParticipants: { $gt: 0 } },
        { $inc: { currentParticipants: -1 } }
      );
    } else if (prevTravelerStatus === 'Cancelled' && status === 'Confirmed') {
      // Re-confirmed: increment participant count back
      await TravelPackage.findByIdAndUpdate(pkg._id, { $inc: { currentParticipants: 1 } });
    }

    // --- NOTIFICATION ---
    let body;
    const pkgTitle = pkg.title;
    const travelerName = booking.travelers[travelerIndex].name;

    if (booking.travelers.length === 1) {
      body = `Your request to join "${pkgTitle}" has been ${status === 'Confirmed' ? 'confirmed' : 'rejected'}.`;
    } else {
      const statusText = status === 'Confirmed' ? 'confirmed' : 'cancelled';
      body = `${travelerName}'s spot for "${pkgTitle}" has been ${statusText}.`;

      const cancelledNames = booking.travelers.filter(t => t.status === 'Cancelled').map(t => t.name);
      if (cancelledNames.length > 0) {
        body += ` Cancelled: ${cancelledNames.join(', ')}.`;
      }
    }

    const dbUser = await User.findById(booking.user);
    if (dbUser && dbUser.fcmToken) {
      notificationService.sendToToken(dbUser.fcmToken, { title: `Trip Update: ${pkgTitle}`, body: body }, 
        { type: 'booking_confirmed', bookingId: booking._id.toString() }, dbUser._id).catch(e => console.error(e));
    }

    res.status(200).json({ success: true, result: booking });
  } catch (err) {
    next(err);
  }
};

// @desc  Add a review to a package
// @route POST /api/packages/:id/reviews
// @route POST /api/packages/:id/reviews
const addReview = async (req, res, next) => {
  const { id } = req.params;
  const { rating, text } = req.body;
  const userId = req.user._id;
  const authorName = req.user.name;
  const profilePhotoUrl = req.user.profilePicture;

  try {
    const pkg = await TravelPackage.findById(id);
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    const newReview = {
      user: userId,
      author_name: authorName,
      profile_photo_url: profilePhotoUrl,
      rating: parseFloat(rating),
      text: text,
      relative_time_description: "Just now",
      time: Math.floor(Date.now() / 1000)
    };

    // Update ratings
    const currentRating = pkg.ratings?.average || 0;
    const currentCount = pkg.ratings?.count || 0;
    const newCount = currentCount + 1;
    const newRating = (currentRating * currentCount + parseFloat(rating)) / newCount;

    if (!pkg.reviews) pkg.reviews = [];
    pkg.reviews.push(newReview);
    
    if (!pkg.ratings) pkg.ratings = { average: 0, count: 0 };
    pkg.ratings.average = parseFloat(newRating.toFixed(1));
    pkg.ratings.count = newCount;

    await pkg.save();

    // Update User review count
    await User.findByIdAndUpdate(req.user._id, { $inc: { reviewsCount: 1 } });

    res.status(201).json({ success: true, result: pkg });
  } catch (err) {
    next(err);
  }
};

// @route PUT /api/packages/:id/reviews/:reviewId
const updateReview = async (req, res, next) => {
  const { id, reviewId } = req.params;
  const { rating, text } = req.body;

  try {
    const pkg = await TravelPackage.findById(id);
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    const review = pkg.reviews.id(reviewId);
    if (!review) return res.status(404).json({ success: false, error: 'Review not found' });

    if (review.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, error: 'Unauthorized to update this review' });
    }

    const oldRating = review.rating;
    review.rating = parseFloat(rating);
    review.text = text;
    review.time = Math.floor(Date.now() / 1000);
    review.relative_time_description = "Edited just now";

    // Re-calculate average rating
    const totalRatingValue = (pkg.ratings.average * pkg.ratings.count) - oldRating + parseFloat(rating);
    pkg.ratings.average = parseFloat((totalRatingValue / pkg.ratings.count).toFixed(1));

    await pkg.save();
    res.status(200).json({ success: true, result: pkg });
  } catch (err) {
    next(err);
  }
};

// @route DELETE /api/packages/:id/reviews/:reviewId
const deleteReview = async (req, res, next) => {
  const { id, reviewId } = req.params;

  try {
    const pkg = await TravelPackage.findById(id);
    if (!pkg) return res.status(404).json({ success: false, error: 'Package not found' });

    const review = pkg.reviews.id(reviewId);
    if (!review) return res.status(404).json({ success: false, error: 'Review not found' });

    if (review.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, error: 'Unauthorized to delete this review' });
    }

    const reviewRating = review.rating;
    review.remove();

    // Re-calculate ratings
    const newCount = pkg.ratings.count - 1;
    if (newCount > 0) {
      const totalRatingValue = (pkg.ratings.average * pkg.ratings.count) - reviewRating;
      pkg.ratings.average = parseFloat((totalRatingValue / newCount).toFixed(1));
      pkg.ratings.count = newCount;
    } else {
      pkg.ratings.average = 0;
      pkg.ratings.count = 0;
    }

    await pkg.save();

    // Update User review count
    await User.findByIdAndUpdate(req.user._id, { $inc: { reviewsCount: -1 } });

    res.status(200).json({ success: true, result: pkg });
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
  handleTravelerStatus,
  addReview,
  updateReview,
  deleteReview,
};

