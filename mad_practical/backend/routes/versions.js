const express = require('express');
const router = express.Router();
const versionController = require('../controllers/versionController');

router.get('/:fileId', versionController.getVersionsByFileId);
router.post('/', versionController.createVersion);

module.exports = router;
