const User = require('../models/User');
const config = require('../config');

const seedAdmins = async () => {
  try {
    // Check if Admin exists
    const adminExists = await User.findOne({ email: config.ADMIN_EMAIL });
    if (!adminExists) {
      await User.create({
        name: 'System Admin',
        email: config.ADMIN_EMAIL,
        password: config.ADMIN_PASSWORD,
        role: 'admin'
      });
      console.log('✅ Default Admin created');
    } else {
      console.log('ℹ️ Admin account already present');
    }

  } catch (error) {
    console.error('❌ Error seeding admins:', error.message);
  }
};

module.exports = seedAdmins;
