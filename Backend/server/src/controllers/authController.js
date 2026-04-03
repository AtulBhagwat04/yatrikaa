const User = require('../models/User');
const jwt = require('jsonwebtoken');
const config = require('../config');

const generateToken = (user) => {
  return jwt.sign(
    { id: user._id, role: user.role },
    config.JWT_SECRET,
    { expiresIn: '30d' }
  );
};

const { uploadImage, deleteImage } = require('../services/cloudinaryService');

class AuthController {
  async register(req, res, next) {
    const { name, email, password, role } = req.body;
    try {
      const userExists = await User.findOne({ email });
      if (userExists) {
        return res.status(400).json({ error: 'User already exists' });
      }

      let finalRole = role || 'user';
      let guideStatus = 'None';

      // If registering as guide, set role to user and request status to Pending
      if (finalRole === 'guide') {
        finalRole = 'user';
        guideStatus = 'Pending';
      }

      const user = await User.create({
        name,
        email,
        password,
        role: finalRole,
        guideRequestStatus: guideStatus
      });

      res.status(201).json({
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        guideRequestStatus: user.guideRequestStatus,
        tripsCount: user.tripsCount,
        savedCount: user.savedCount,
        reviewsCount: user.reviewsCount,
        postsCount: user.postsCount,
        phoneNumber: user.phoneNumber,
        gender: user.gender,
        profilePicture: user.profilePicture,
        token: generateToken(user)
      });
    } catch (error) {
      next(error);
    }
  }

  async login(req, res, next) {
    const { email, password } = req.body;
    try {
      const user = await User.findOne({ email });
      if (user && (await user.comparePassword(password))) {
        res.json({
          id: user._id,
          name: user.name,
          email: user.email,
          role: user.role,
          guideRequestStatus: user.guideRequestStatus,
          tripsCount: user.tripsCount,
          savedCount: user.savedCount,
          reviewsCount: user.reviewsCount,
          postsCount: user.postsCount,
          phoneNumber: user.phoneNumber,
          gender: user.gender,
          profilePicture: user.profilePicture,
          token: generateToken(user)
        });
      } else {
        res.status(401).json({ error: 'Invalid email or password' });
      }
    } catch (error) {
      next(error);
    }
  }

  async updateProfile(req, res, next) {
    try {
      const user = await User.findById(req.user._id);

      if (user) {
        user.name = req.body.name || user.name;
        user.email = req.body.email || user.email;
        user.phoneNumber = req.body.phoneNumber !== undefined ? req.body.phoneNumber : user.phoneNumber;
        user.gender = req.body.gender !== undefined ? req.body.gender : user.gender;

        if (req.file) {
          // Delete old profile picture if it exists on Cloudinary
          if (user.profilePicture && user.profilePicture.includes('cloudinary.com')) {
            try {
              const urlParts = user.profilePicture.split('/');
              const uploadIndex = urlParts.indexOf('upload');
              if (uploadIndex !== -1) {
                const publicIdWithExt = urlParts.slice(uploadIndex + 2).join('/');
                const publicId = publicIdWithExt.split('.')[0];
                await deleteImage(publicId);
              }
            } catch (e) {
              console.error('Error deleting old profile picture:', e.message);
            }
          }

          // Upload new profile picture to a folder unique to this user
          const folderName = `Bhatkanti/Users/${user._id}/Profile`;
          const result = await uploadImage(req.file, folderName);
          user.profilePicture = result.secure_url;
        }

        const updatedUser = await user.save();

        res.json({
          id: updatedUser._id,
          name: updatedUser.name,
          email: updatedUser.email,
          role: updatedUser.role,
          tripsCount: updatedUser.tripsCount,
          savedCount: updatedUser.savedCount,
          reviewsCount: updatedUser.reviewsCount,
          postsCount: updatedUser.postsCount,
          phoneNumber: updatedUser.phoneNumber,
          gender: updatedUser.gender,
          profilePicture: updatedUser.profilePicture,
          token: generateToken(updatedUser)
        });
      } else {
        res.status(404).json({ error: 'User not found' });
      }
    } catch (error) {
      next(error);
    }
  }

  async changePassword(req, res, next) {
    const { currentPassword, newPassword } = req.body;
    try {
      const user = await User.findById(req.user._id);

      if (user && (await user.comparePassword(currentPassword))) {
        user.password = newPassword;
        await user.save();
        res.json({ message: 'Password updated successfully' });
      } else {
        res.status(401).json({ error: 'Invalid current password' });
      }
    } catch (error) {
      next(error);
    }
  }

  async getAllUsers(req, res, next) {
    try {
      const users = await User.find({}).select('-password');
      res.json(users);
    } catch (error) {
      next(error);
    }
  }

  async deleteUser(req, res, next) {
    try {
      const user = await User.findByIdAndDelete(req.params.id);
      if (!user) return res.status(404).json({ error: 'User not found' });
      res.json({ message: 'User deleted successfully' });
    } catch (error) {
      next(error);
    }
  }

  async getGuideRequests(req, res, next) {
    try {
      console.log(`[auth] Fetching guide requests for admin: ${req.user.email}`);
      const requests = await User.find({ guideRequestStatus: 'Pending' }).select('-password');
      console.log(`[auth] Found ${requests.length} pending requests`);
      res.json({ success: true, count: requests.length, results: requests });
    } catch (error) {
      console.error('[auth] getGuideRequests error:', error.message);
      next(error);
    }
  }

  async handleGuideRequest(req, res, next) {
    const { userId, action } = req.body; // action: 'approve' or 'reject'
    try {
      const user = await User.findById(userId);
      if (!user) return res.status(404).json({ error: 'User not found' });

      if (action === 'approve') {
        user.role = 'guide';
        user.guideRequestStatus = 'Approved';
      } else {
        user.guideRequestStatus = 'Rejected';
      }

      await user.save();
      console.log(`[auth] Guide Request ${action}d for ${user.email}`);

      res.json({ 
        success: true, 
        message: `Guide request ${action}d successfully`,
        result: {
          id: user._id,
          role: user.role,
          guideRequestStatus: user.guideRequestStatus
        }
      });
    } catch (error) {
      next(error);
    }
  }

  async requestGuideRole(req, res, next) {
    try {
      const user = await User.findById(req.user._id);
      if (!user) return res.status(404).json({ error: 'User not found' });

      if (user.role === 'guide') {
        return res.status(400).json({ error: 'User is already a guide' });
      }

      user.guideRequestStatus = 'Pending';
      await user.save();

      res.json({ success: true, message: 'Guide request submitted successfully' });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AuthController();
