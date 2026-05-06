import 'package:hive/hive.dart';

class FileModelAdapter extends TypeAdapter<FileModel> {
  @override
  final int typeId = 0;

  @override
  FileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return FileModel(
      id: fields[0] as String,
      fileName: fields[1] as String,
      fileType: fields[2] as String,
      description: fields[3] as String,
      createdAt: fields[4] as DateTime,
      isShared: fields[5] as bool,
      hasConflict: fields[6] as bool,
      conflictResolution: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FileModel obj) {
    writer.writeByte(8);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.fileName);
    writer.writeByte(2);
    writer.write(obj.fileType);
    writer.writeByte(3);
    writer.write(obj.description);
    writer.writeByte(4);
    writer.write(obj.createdAt);
    writer.writeByte(5);
    writer.write(obj.isShared);
    writer.writeByte(6);
    writer.write(obj.hasConflict);
    writer.writeByte(7);
    writer.write(obj.conflictResolution);
  }
}

class FileModel {
  String id;
  String fileName;
  String fileType;
  String description;
  DateTime createdAt;
  bool isShared;
  bool hasConflict;
  String conflictResolution;

  FileModel({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.description,
    required this.createdAt,
    this.isShared = false,
    this.hasConflict = false,
    this.conflictResolution = 'none',
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['_id'] ?? '',
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? 'other',
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isShared: json['isShared'] ?? false,
      hasConflict: json['hasConflict'] ?? false,
      conflictResolution: json['conflictResolution'] ?? 'none',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fileName': fileName,
      'fileType': fileType,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isShared': isShared,
      'hasConflict': hasConflict,
      'conflictResolution': conflictResolution,
    };
  }
}
