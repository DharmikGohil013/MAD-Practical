const File = require('../models/File');
const Version = require('../models/Version');
const Comment = require('../models/Comment');

// GET /api/files — get all files
exports.getAllFiles = async (req, res) => {
  try {
    const files = await File.find().sort({ createdAt: -1 });
    res.json(files);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// POST /api/files — create a new file
exports.createFile = async (req, res) => {
  try {
    const { fileName, fileType, description } = req.body;

    if (!fileName || !fileName.trim()) {
      return res.status(400).json({ error: 'File name is required' });
    }

    // Check for duplicate file name
    const existing = await File.findOne({ fileName: fileName.trim() });
    if (existing) {
      return res.status(409).json({ error: 'A file with this name already exists' });
    }

    const file = new File({
      fileName: fileName.trim(),
      fileType: fileType || 'other',
      description: description || '',
    });

    const saved = await file.save();

    // Create initial version (v1)
    const version = new Version({
      fileId: saved._id,
      versionNumber: 1,
      note: 'Initial version',
    });
    await version.save();

    res.status(201).json(saved);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// PUT /api/files/:id — update file
exports.updateFile = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    const file = await File.findByIdAndUpdate(id, updates, { new: true });
    if (!file) {
      return res.status(404).json({ error: 'File not found' });
    }

    res.json(file);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// DELETE /api/files/:id — delete file + its versions + comments
exports.deleteFile = async (req, res) => {
  try {
    const { id } = req.params;

    const file = await File.findByIdAndDelete(id);
    if (!file) {
      return res.status(404).json({ error: 'File not found' });
    }

    // Cascade delete versions and comments
    await Version.deleteMany({ fileId: id });
    await Comment.deleteMany({ fileId: id });

    res.json({ message: 'File deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
