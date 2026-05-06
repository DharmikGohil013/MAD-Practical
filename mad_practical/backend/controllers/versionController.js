const Version = require('../models/Version');
const File = require('../models/File');

// GET /api/versions/:fileId — get all versions for a file
exports.getVersionsByFileId = async (req, res) => {
  try {
    const { fileId } = req.params;
    const versions = await Version.find({ fileId }).sort({ versionNumber: -1 });
    res.json(versions);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// POST /api/versions — add a new version
exports.createVersion = async (req, res) => {
  try {
    const { fileId, note } = req.body;

    if (!fileId) {
      return res.status(400).json({ error: 'fileId is required' });
    }

    // Get latest version number
    const latestVersion = await Version.findOne({ fileId }).sort({ versionNumber: -1 });
    const newVersionNumber = latestVersion ? latestVersion.versionNumber + 1 : 1;

    const version = new Version({
      fileId,
      versionNumber: newVersionNumber,
      note: note || '',
    });

    const saved = await version.save();

    // Conflict detection: check if 2+ versions were created within 5 minutes
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    const recentVersions = await Version.countDocuments({
      fileId,
      timestamp: { $gte: fiveMinutesAgo },
    });

    if (recentVersions >= 2) {
      await File.findByIdAndUpdate(fileId, { hasConflict: true });
    }

    res.status(201).json(saved);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
