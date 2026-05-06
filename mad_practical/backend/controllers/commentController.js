const Comment = require('../models/Comment');

// GET /api/comments/:fileId — get comments for a file
exports.getCommentsByFileId = async (req, res) => {
  try {
    const { fileId } = req.params;
    const comments = await Comment.find({ fileId }).sort({ timestamp: -1 });
    res.json(comments);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// POST /api/comments — add a comment
exports.createComment = async (req, res) => {
  try {
    const { fileId, text } = req.body;

    if (!fileId || !text || !text.trim()) {
      return res.status(400).json({ error: 'fileId and text are required' });
    }

    const comment = new Comment({
      fileId,
      text: text.trim(),
    });

    const saved = await comment.save();
    res.status(201).json(saved);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
