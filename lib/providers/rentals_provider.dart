import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RentalsNotifier extends ChangeNotifier {
  List<DocumentSnapshot> rentalDocs = [];

  void setRentalDocs(List<DocumentSnapshot> rentals) {
    rentalDocs = rentals;
    notifyListeners();
  }
}

final rentalsProvider =
    ChangeNotifierProvider<RentalsNotifier>((ref) => RentalsNotifier());
