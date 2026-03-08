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

class AuthController {
  async register(req, res, next) {
    const { name, email, password, role } = req.body;
    try {
      const userExists = await User.findOne({ email });
      if (userExists) {
        return res.status(400).json({ error: 'User already exists' });
      }

      const user = await User.create({
        name,
        email,
        password,
        role: role || 'user'
      });

      res.status(201).json({
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        tripsCount: user.tripsCount,
        savedCount: user.savedCount,
        reviewsCount: user.reviewsCount,
        postsCount: user.postsCount,
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
          tripsCount: user.tripsCount,
          savedCount: user.savedCount,
          reviewsCount: user.reviewsCount,
          postsCount: user.postsCount,
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
}

module.exports = new AuthController();
