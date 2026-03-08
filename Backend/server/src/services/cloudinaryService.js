const cloudinary = require('cloudinary').v2;
const config = require('../config');

cloudinary.config({
  cloud_name: config.CLOUDINARY.CLOUD_NAME,
  api_key: config.CLOUDINARY.API_KEY,
  api_secret: config.CLOUDINARY.API_SECRET
});

const uploadImage = async (file, folder = 'Bhatkanti/General') => {
  return new Promise((resolve, reject) => {
    cloudinary.uploader.upload_stream({
      folder: folder
    }, (error, result) => {
      if (error) return reject(error);
      resolve(result);
    }).end(file.buffer);
  });
};

const deleteImage = async (publicId) => {
  try {
    const result = await cloudinary.uploader.destroy(publicId);
    return result;
  } catch (error) {
    throw error;
  }
};

module.exports = { uploadImage, deleteImage };
