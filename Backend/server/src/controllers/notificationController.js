const Notification = require('../models/Notification');

exports.getNotifications = async (req, res, next) => {
  try {
    const notifications = await Notification.find({ user: req.user._id })
      .sort({ timestamp: -1 })
      .limit(50);
    
    res.status(200).json(notifications);
  } catch (err) {
    next(err);
  }
};

exports.markAsRead = async (req, res, next) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({ error: 'Notification not found' });
    }

    res.status(200).json(notification);
  } catch (err) {
    next(err);
  }
};

exports.markAllAsRead = async (req, res, next) => {
  try {
    await Notification.updateMany(
      { user: req.user._id, isRead: false },
      { isRead: true }
    );

    res.status(200).json({ status: 'success', message: 'All notifications marked as read' });
  } catch (err) {
    next(err);
  }
};

exports.clearAll = async (req, res, next) => {
  try {
    await Notification.deleteMany({ user: req.user._id });
    res.status(200).json({ status: 'success', message: 'All notifications cleared' });
  } catch (err) {
    next(err);
  }
};
