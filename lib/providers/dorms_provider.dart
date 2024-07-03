import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_web/image_picker_web.dart';

class DormsNotifier extends ChangeNotifier {
  List<DocumentSnapshot> dormDocs = [];
  List<dynamic> existingDormImages = [];
  List<Uint8List> dormImages = [];

  Uint8List? ownershipSelectedFileBytes;
  String ownershipFileName = '';
  Uint8List? accreditationSelectedFileBytes;
  String accreditationFileName = '';

  void setDormDocs(List<DocumentSnapshot> dorms) {
    dormDocs = dorms;
    notifyListeners();
  }

  Future setDormNetworkImages(List<dynamic> networkImages) async {
    existingDormImages = networkImages;
    notifyListeners();
  }

  Future setDormImages() async {
    final selectedXFiles = await ImagePickerWeb.getMultiImagesAsBytes();
    if (selectedXFiles == null) {
      return;
    }
    dormImages = selectedXFiles;
    notifyListeners();
  }

  void removeDormFileImage(Uint8List file) {
    dormImages.remove(file);
    notifyListeners();
  }

  Future setProofOfOwnership() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) {
      return;
    }
    ownershipSelectedFileBytes = result.files.first.bytes;
    ownershipFileName = result.files.first.name;
    notifyListeners();
  }

  Future setAccreditation() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) {
      return;
    }
    accreditationSelectedFileBytes = result.files.first.bytes;
    accreditationFileName = result.files.first.name;
    notifyListeners();
  }

  void resetDorm() {
    existingDormImages.clear();
    dormImages.clear();
    ownershipSelectedFileBytes = null;
    ownershipFileName = '';
    accreditationSelectedFileBytes = null;
    accreditationFileName = '';
    notifyListeners();
  }
}

final dormsProvider =
    ChangeNotifierProvider<DormsNotifier>((ref) => DormsNotifier());
