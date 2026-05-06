const express = require('express');
const path = require('path');
const router = express.Router();
const fileController = require('../controllers/fileController');

// Serve uploaded files statically
router.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

router.get('/', fileController.getAllFiles);
// uploadMiddleware runs multer, then createFile handles both JSON and multipart
router.post('/', fileController.uploadMiddleware, fileController.createFile);
router.put('/:id', fileController.updateFile);
router.delete('/:id', fileController.deleteFile);

module.exports = router;
