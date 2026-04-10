const express = require('express');
const router = express.Router();
const {
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
  deleteReview } = require('../controllers/packagesController');
const { protect, authorize } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

// ── Public Routes ──────────────────────────────────────────────────────────
router.get('/', getPackages);

// ── Protected: Must be before /:id to avoid being swallowed ──────────────
router.get('/my', protect, getMyPackages);                               // Guide: own packages
router.get('/bookings/mine', protect, getMyBookings);                   // User: own bookings
router.get('/bookings/organizer', protect, getGuideBookings);             // Guide: all bookings for their packages
router.patch('/bookings/:id/cancel', protect, cancelBooking);           // User/Guide: cancel booking
router.patch('/bookings/:id/confirm', protect, confirmBooking);          // Guide/Admin: confirm booking
router.patch('/bookings/:id/travelers/:travelerId', protect, handleTravelerStatus); // Guide/Admin: confirm/reject individual traveler

// ── Admin-only management ──────────────────────────────────────────────────
router.get(
  '/admin/all',
  protect,
  authorize('admin'),
  getAllPackagesAdmin,
);
router.patch(
  '/admin/:id/publish',
  protect,
  authorize('admin'),
  publishPackage,
);

// ── Create (Guide / Admin) ─────────────────────────────────────────────────
router.post(
  '/',
  protect,
  authorize('guide', 'admin'),
  upload.array('images', 5),
  createPackage,
);

// ── Parameterised Routes (/:id) — must come AFTER all static paths ────────
router.get('/:id', getPackageDetails);

router.patch(
  '/:id',
  protect,
  authorize('guide', 'admin'),
  upload.array('images', 5),
  updatePackage,
);

router.delete('/:id', protect, authorize('admin'), deletePackage);

router.post('/:id/join', protect, joinPackage);                         // User: join a package
router.post('/:id/reviews', protect, addReview);                        // User: add a review
router.put('/:id/reviews/:reviewId', protect, updateReview);           // User: update own review
router.delete('/:id/reviews/:reviewId', protect, deleteReview);        // User: delete own review
router.get('/:id/participants', protect, getPackageParticipants);       // Guide/Admin: participants

module.exports = router;
