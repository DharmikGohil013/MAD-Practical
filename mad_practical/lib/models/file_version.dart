import 'package:hive/hive.dart';

class FileVersionAdapter extends TypeAdapter<FileVersion> {
  @override
  final int typeId = 1;

  @override
  FileVersion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return FileVersion(
      id: fields[0] as String,
      fileId: fields[1] as String,
      versionNumber: fields[2] as int,
      timestamp: fields[3] as DateTime,
      note: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FileVersion obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.fileId);
    writer.writeByte(2);
    writer.write(obj.versionNumber);
    writer.writeByte(3);
    writer.write(obj.timestamp);
    writer.writeByte(4);
    writer.write(obj.note);
  }
}

class FileVersion {
  String id;
  String fileId;
  int versionNumber;
  DateTime timestamp;
  String note;

  FileVersion({
    required this.id,
    required this.fileId,
    required this.versionNumber,
    required this.timestamp,
    this.note = '',
  });

  factory FileVersion.fromJson(Map<String, dynamic> json) {
    return FileVersion(
      id: json['_id'] ?? '',
      fileId: json['fileId'] ?? '',
      versionNumber: json['versionNumber'] ?? 1,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fileId': fileId,
      'versionNumber': versionNumber,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }
}
