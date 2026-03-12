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
  getPackageParticipants,
  getAllPackagesAdmin,
} = require('../controllers/packagesController');
const { protect, authorize } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

// ── Public Routes ──────────────────────────────────────────────────────────
router.get('/', getPackages);

// ── Protected: Must be before /:id to avoid being swallowed ──────────────
router.get('/my', protect, getMyPackages);                               // Guide: own packages
router.get('/bookings/mine', protect, getMyBookings);                   // User: own bookings
router.patch('/bookings/:id/cancel', protect, cancelBooking);           // User: cancel booking

// ── Admin-only management ──────────────────────────────────────────────────
router.get(
  '/admin/all',
  protect,
  authorize('admin', 'super-admin'),
  getAllPackagesAdmin,
);
router.patch(
  '/admin/:id/publish',
  protect,
  authorize('admin', 'super-admin'),
  publishPackage,
);

// ── Create (Guide / Admin) ─────────────────────────────────────────────────
router.post(
  '/',
  protect,
  authorize('guide', 'admin', 'super-admin'),
  upload.array('images', 5),
  createPackage,
);

// ── Parameterised Routes (/:id) — must come AFTER all static paths ────────
router.get('/:id', getPackageDetails);

router.put(
  '/:id',
  protect,
  authorize('guide', 'admin', 'super-admin'),
  upload.array('images', 5),
  updatePackage,
);

router.delete('/:id', protect, authorize('admin', 'super-admin'), deletePackage);

router.post('/:id/join', protect, joinPackage);                         // User: join a package
router.get('/:id/participants', protect, getPackageParticipants);       // Guide/Admin: participants

module.exports = router;
