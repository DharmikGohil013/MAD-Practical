import 'package:hive/hive.dart';

class FileCommentAdapter extends TypeAdapter<FileComment> {
  @override
  final int typeId = 2;

  @override
  FileComment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return FileComment(
      id: fields[0] as String,
      fileId: fields[1] as String,
      text: fields[2] as String,
      timestamp: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FileComment obj) {
    writer.writeByte(4);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.fileId);
    writer.writeByte(2);
    writer.write(obj.text);
    writer.writeByte(3);
    writer.write(obj.timestamp);
  }
}

class FileComment {
  String id;
  String fileId;
  String text;
  DateTime timestamp;

  FileComment({
    required this.id,
    required this.fileId,
    required this.text,
    required this.timestamp,
  });

  factory FileComment.fromJson(Map<String, dynamic> json) {
    return FileComment(
      id: json['_id'] ?? '',
      fileId: json['fileId'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fileId': fileId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
