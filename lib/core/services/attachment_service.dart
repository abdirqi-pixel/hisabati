import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AttachmentService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickInvoiceImageFromGallery() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return null;
    return _copyToAppFolder(File(image.path), 'images');
  }

  Future<File?> captureInvoiceImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image == null) return null;
    return _copyToAppFolder(File(image.path), 'images');
  }

  Future<File?> pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) return null;
    return _copyToAppFolder(File(result.files.single.path!), 'pdf');
  }

  Future<File> _copyToAppFolder(File source, String folder) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/attachments/$folder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final ext = p.extension(source.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final copied = await source.copy('${dir.path}/$fileName');
    return copied;
  }
}
