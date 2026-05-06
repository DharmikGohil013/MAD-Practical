const express = require('express');
const router = express.Router();
const commentController = require('../controllers/commentController');

router.get('/:fileId', commentController.getCommentsByFileId);
router.post('/', commentController.createComment);

module.exports = router;
