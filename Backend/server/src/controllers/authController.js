const User = require('../models/User');
const jwt = require('jsonwebtoken');
const notificationService = require('../services/notificationService');
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

  async firebaseSync(req, res, next) {
    const { name, email, uid, profilePicture } = req.firebaseUser;
    const { role } = req.body;
    try {
      let user = await User.findOne({ 
        $or: [ { firebaseUid: uid }, { email: email.toLowerCase() } ] 
      });

      if (!user) {
        let finalRole = role || 'user';
        let guideStatus = 'None';

        if (finalRole === 'guide') {
          finalRole = 'user';
          guideStatus = 'Pending';
        }

        // Create new user if they don't exist
        user = await User.create({
          name: name || email.split('@')[0],
          email: email.toLowerCase(),
          firebaseUid: uid,
          profilePicture: profilePicture || '',
          role: finalRole,
          guideRequestStatus: guideStatus
        });
      } else if (!user.firebaseUid) {

        // Link firebase UID to existing email account
        user.firebaseUid = uid;
        if (profilePicture && !user.profilePicture) {
          user.profilePicture = profilePicture;
        }
        await user.save();
      }

      res.status(200).json({
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
        token: generateToken(user),
        isNewUser: user.createdAt === user.updatedAt
      });
    } catch (error) {
      console.error('[auth] firebaseSync error:', error.message);
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
          const folderName = `Yatrikaa/Users/${user._id}/Profile`;
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
      const user = await User.findById(req.params.id);
      if (!user) return res.status(404).json({ error: 'User not found' });

      // Helper to safely extract Cloudinary public_id
      const getPublicIdFromUrl = (url) => {
        if (!url || !url.includes('cloudinary.com')) return null;
        const urlParts = url.split('/');
        const uploadIndex = urlParts.indexOf('upload');
        if (uploadIndex !== -1) {
          const publicIdWithExt = urlParts.slice(uploadIndex + 2).join('/');
          return publicIdWithExt.split('.')[0];
        }
        return null;
      };

      // 1. Delete user profile picture from Cloudinary
      if (user.profilePicture) {
        const publicId = getPublicIdFromUrl(user.profilePicture);
        if (publicId) await deleteImage(publicId).catch(e => console.error('Cloudinary Profile Pic error:', e.message));
      }

      // 2. Delete all Travel Packages by this user & their Cloudinary images
      const TravelPackage = require('../models/TravelPackage');
      const packages = await TravelPackage.find({ organizer: user._id });
      for (const pkg of packages) {
        if (pkg.images && pkg.images.length > 0) {
          for (const imgUrl of pkg.images) {
            const publicId = getPublicIdFromUrl(imgUrl);
            if (publicId) await deleteImage(publicId).catch(e => console.error('Cloudinary Package Image error:', e.message));
          }
        }
      }
      await TravelPackage.deleteMany({ organizer: user._id });

      // 3. Delete all Posts by this user & their Cloudinary images
      const Post = require('../models/Post');
      const posts = await Post.find({ author: user._id });
      for (const post of posts) {
        if (post.images && post.images.length > 0) {
          for (const imgUrl of post.images) {
            const publicId = getPublicIdFromUrl(imgUrl);
            if (publicId) await deleteImage(publicId).catch(e => console.error('Cloudinary Post Image error:', e.message));
          }
        }
      }
      await Post.deleteMany({ author: user._id });

      // 4. Delete all Bookings made by this user
      const Booking = require('../models/Booking');
      await Booking.deleteMany({ user: user._id });

      // 5. Remove user from Post likes and comments globally
      await Post.updateMany(
        {},
        { $pull: { likes: user._id, comments: { user: user._id } } }
      );

      // 6. Delete reviews from Places (Assume Place match by author_name matching user.name)
      const Place = require('../models/Place');
      await Place.updateMany(
        { 'reviews.author_name': user.name },
        { $pull: { reviews: { author_name: user.name } } }
      );

      // Finally, delete the user document
      await User.findByIdAndDelete(user._id);

      res.json({ message: 'User and all associated data permanently deleted successfully' });
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

      // SEND NOTIFICATION TO THE USER
      if (user.fcmToken) {
        const notification = {
          title: `Guide Request Update`,
          body: `Your request to become a guide has been ${action}d!`,
        };
        const data = {
          type: 'guide_request',
          status: user.guideRequestStatus,
          timestamp: new Date().toISOString()
        };

        notificationService.sendToToken(user.fcmToken, notification, data)
          .catch(err => console.error('[auth] Failed to send guide request notification:', err.message));
      }

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

  async updateFcmToken(req, res, next) {
    const { fcmToken } = req.body;
    try {
      if (!fcmToken) {
        return res.status(400).json({ error: 'FCM token is required' });
      }

      const user = await User.findById(req.user._id);
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }

      user.fcmToken = fcmToken;
      await user.save();

      res.status(200).json({ success: true, message: 'FCM token updated successfully' });
    } catch (error) {
      console.error('[auth] updateFcmToken error:', error.message);
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
