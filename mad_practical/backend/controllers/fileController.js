const path = require('path');
const fs = require('fs');
const multer = require('multer');
const File = require('../models/File');
const Version = require('../models/Version');
const Comment = require('../models/Comment');

// ─── Multer storage ───────────────────────────────────────
const uploadDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => {
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, unique + path.extname(file.originalname));
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 50 * 1024 * 1024 }, // 50 MB
});

// Export multer middleware so the router can use it
exports.uploadMiddleware = upload.single('file');

// ─── Helper: detect fileType from mime / extension ────────
function detectFileType(mimetype = '', originalname = '') {
  const ext = path.extname(originalname).toLowerCase();
  if (mimetype.startsWith('image/') || ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'].includes(ext))
    return 'image';
  if (mimetype === 'application/pdf' || ext === '.pdf') return 'pdf';
  if (['.doc', '.docx', '.txt', '.odt', '.rtf'].includes(ext) || mimetype.includes('word'))
    return 'doc';
  if (mimetype.startsWith('video/') || ['.mp4', '.mov', '.avi', '.mkv'].includes(ext))
    return 'video';
  return 'other';
}

// ─── GET /api/files ───────────────────────────────────────
exports.getAllFiles = async (req, res) => {
  try {
    const files = await File.find().sort({ createdAt: -1 });
    res.json(files);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ─── POST /api/files ──────────────────────────────────────
// Handles both:
//   • multipart/form-data  (local file upload)
//   • application/json     (manual entry with no file)
exports.createFile = async (req, res) => {
  try {
    // Fields come from either req.body (JSON) or req.body (form-data text fields)
    let { fileName, fileType, description } = req.body;
    const uploadedFile = req.file; // set by multer if a file was attached

    // If a real file was uploaded, derive metadata from it
    if (uploadedFile) {
      fileName = fileName || path.parse(uploadedFile.originalname).name;
      fileType = fileType || detectFileType(uploadedFile.mimetype, uploadedFile.originalname);
    }

    if (!fileName || !String(fileName).trim()) {
      // Clean up orphaned upload
      if (uploadedFile) fs.unlinkSync(uploadedFile.path);
      return res.status(400).json({ error: 'File name is required' });
    }

    fileName = String(fileName).trim();

    // Duplicate check
    const existing = await File.findOne({ fileName });
    if (existing) {
      if (uploadedFile) fs.unlinkSync(uploadedFile.path);
      return res.status(409).json({ error: 'A file with this name already exists' });
    }

    const file = new File({
      fileName,
      fileType: fileType || 'other',
      description: description || '',
      ...(uploadedFile && {
        originalName: uploadedFile.originalname,
        filePath: `/uploads/${uploadedFile.filename}`,
        fileSize: uploadedFile.size,
      }),
    });

    const saved = await file.save();

    // Create initial version (v1)
    await new Version({
      fileId: saved._id,
      versionNumber: 1,
      note: uploadedFile ? `Uploaded: ${uploadedFile.originalname}` : 'Initial version',
    }).save();

    res.status(201).json(saved);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ─── PUT /api/files/:id ───────────────────────────────────
exports.updateFile = async (req, res) => {
  try {
    const { id } = req.params;
    const file = await File.findByIdAndUpdate(id, req.body, { new: true });
    if (!file) return res.status(404).json({ error: 'File not found' });
    res.json(file);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ─── DELETE /api/files/:id ────────────────────────────────
exports.deleteFile = async (req, res) => {
  try {
    const { id } = req.params;
    const file = await File.findByIdAndDelete(id);
    if (!file) return res.status(404).json({ error: 'File not found' });

    // Delete physical file if it exists
    if (file.filePath) {
      const abs = path.join(__dirname, '..', file.filePath);
      if (fs.existsSync(abs)) fs.unlinkSync(abs);
    }

    await Version.deleteMany({ fileId: id });
    await Comment.deleteMany({ fileId: id });

    res.json({ message: 'File deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
