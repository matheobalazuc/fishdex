import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db   = FirebaseFirestore.instance;

  static User?   get currentUser     => _auth.currentUser;
  static bool    get isLoggedIn      => _auth.currentUser != null;
  static String  get currentUserId   => _auth.currentUser?.uid ?? '';
  static String  get currentUserName => _auth.currentUser?.displayName ?? 'Pêcheur';
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static Stream<User?> get userChanges      => _auth.userChanges();

  static String _email(String u) =>
      '${u.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}@fishdex.app';

  static Future<String?> register(
      String username, String displayName, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _email(username), password: password);
      await cred.user!.updateDisplayName(displayName.trim());
      await _db.collection('users').doc(cred.user!.uid).set({
        'username':    username.trim().toLowerCase(),
        'displayName': displayName.trim(),
        'catchCount':  0,
        'createdAt':   FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) { return _msg(e); }
    catch (e) { return e.toString(); }
  }

  static Future<String?> signIn(String username, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _email(username), password: password);
      return null;
    } on FirebaseAuthException catch (e) { return _msg(e); }
    catch (e) { return e.toString(); }
  }

  static Future<void> signOut() => _auth.signOut();

  static Future<String?> updateDisplayName(String newName) async {
    try {
      await _auth.currentUser!.updateDisplayName(newName.trim());
      await _db.collection('users').doc(currentUserId)
          .update({'displayName': newName.trim()});
      return null;
    } catch (e) { return e.toString(); }
  }

  static Future<String?> updateUsername(
      String newUsername, String password) async {
    try {
      final cred = EmailAuthProvider.credential(
          email: _auth.currentUser!.email!, password: password);
      await _auth.currentUser!.reauthenticateWithCredential(cred);
      await _auth.currentUser!.verifyBeforeUpdateEmail(_email(newUsername));
      await _db.collection('users').doc(currentUserId)
          .update({'username': newUsername.trim().toLowerCase()});
      return null;
    } on FirebaseAuthException catch (e) { return _msg(e); }
    catch (e) { return e.toString(); }
  }

  static Future<String?> changePassword(
      String currentPwd, String newPwd) async {
    try {
      final cred = EmailAuthProvider.credential(
          email: _auth.currentUser!.email!, password: currentPwd);
      await _auth.currentUser!.reauthenticateWithCredential(cred);
      await _auth.currentUser!.updatePassword(newPwd);
      return null;
    } on FirebaseAuthException catch (e) { return _msg(e); }
    catch (e) { return e.toString(); }
  }

  static Future<String?> deleteAccount(String password) async {
    try {
      final uid = currentUserId;
      final cred = EmailAuthProvider.credential(
          email: _auth.currentUser!.email!, password: password);
      await _auth.currentUser!.reauthenticateWithCredential(cred);
      final snap = await _db.collection('catches')
          .where('userId', isEqualTo: uid).get();
      if (snap.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in snap.docs) batch.delete(doc.reference);
        await batch.commit();
      }
      await _db.collection('users').doc(uid).delete();
      await _auth.currentUser!.delete();
      return null;
    } on FirebaseAuthException catch (e) { return _msg(e); }
    catch (e) { return e.toString(); }
  }

  static String _msg(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return 'Ce pseudo est déjà pris';
      case 'user-not-found':
      case 'invalid-credential':   return 'Pseudo ou mot de passe incorrect';
      case 'wrong-password':        return 'Mot de passe incorrect';
      case 'weak-password':         return 'Mot de passe trop faible (6 car. min.)';
      default: return e.message ?? 'Erreur de connexion';
    }
  }
}
