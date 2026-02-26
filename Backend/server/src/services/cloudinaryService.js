const cloudinary = require('cloudinary').v2;
const config = require('../config');

cloudinary.config({
  cloud_name: config.CLOUDINARY.CLOUD_NAME,
  api_key: config.CLOUDINARY.API_KEY,
  api_secret: config.CLOUDINARY.API_SECRET
});

const uploadImage = async (file) => {
  return new Promise((resolve, reject) => {
    cloudinary.uploader.upload_stream({
      folder: 'bhatkanti_posts'
    }, (error, result) => {
      if (error) return reject(error);
      resolve(result);
    }).end(file.buffer);
  });
};

module.exports = { uploadImage };
