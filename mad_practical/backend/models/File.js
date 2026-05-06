const mongoose = require('mongoose');

const fileSchema = new mongoose.Schema({
  fileName: {
    type: String,
    required: true,
    trim: true,
  },
  fileType: {
    type: String,
    required: true,
    enum: ['pdf', 'doc', 'image', 'video', 'other'],
    default: 'other',
  },
  originalName: {
    type: String,
    default: '',
  },
  filePath: {
    type: String,
    default: '',
  },
  fileSize: {
    type: Number,
    default: 0,
  },
  description: {
    type: String,
    default: '',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  isShared: {
    type: Boolean,
    default: false,
  },
  hasConflict: {
    type: Boolean,
    default: false,
  },
  conflictResolution: {
    type: String,
    enum: ['none', 'keep_latest', 'keep_all'],
    default: 'none',
  },
});

module.exports = mongoose.model('File', fileSchema);
