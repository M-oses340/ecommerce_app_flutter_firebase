import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  /// 🔹 Stream for live wallet balance updates
  Stream<DocumentSnapshot<Map<String, dynamic>>> get walletStream {
    if (uid == null) {
      // Return an empty stream if user not logged in
      return const Stream.empty();
    }
    return _db.collection('wallets').doc(uid).snapshots();
  }

  /// 🔹 Stream for user transactions (ordered by latest first)
  Stream<QuerySnapshot<Map<String, dynamic>>> get transactionsStream {
    if (uid == null) {
      return const Stream.empty();
    }
    return _db
        .collection('wallets')
        .doc(uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// 🔹 Add funds to wallet
  Future<void> addFunds(double amount, {String source = "Top-up"}) async {
    if (uid == null) return;
    final walletRef = _db.collection('wallets').doc(uid);
    final walletDoc = await walletRef.get();

    if (walletDoc.exists) {
      await walletRef.update({
        'wallet_balance': FieldValue.increment(amount),
      });
    } else {
      await walletRef.set({
        'wallet_balance': amount,
      });
    }

    await walletRef.collection('transactions').add({
      'type': 'credit',
      'amount': amount,
      'source': source,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// 🔹 Deduct funds (e.g., for orders)
  Future<void> deductFunds(double amount, {String reason = "Purchase"}) async {
    if (uid == null) return;
    final walletRef = _db.collection('wallets').doc(uid);

    await walletRef.update({
      'wallet_balance': FieldValue.increment(-amount),
    });

    await walletRef.collection('transactions').add({
      'type': 'debit',
      'amount': amount,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
