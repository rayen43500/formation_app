import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideoCallService {
  static final VideoCallService _instance = VideoCallService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  factory VideoCallService() {
    return _instance;
  }

  VideoCallService._internal() {
    // Nettoyer les anciens appels au démarrage du service
    // Désactivé temporairement à cause des problèmes de permission
    // _cleanupStaleCalls();
  }

  // Nettoyer les appels vidéo abandonnés ou anciens
  Future<void> _cleanupStaleCalls() async {
    try {
      // Récupérer les appels actifs de plus de 2 heures
      final timestamp = DateTime.now().subtract(Duration(hours: 2)).millisecondsSinceEpoch;
      final snapshot = await _firestore.collection('video_calls')
          .where('active', isEqualTo: true)
          .where('startTime', isLessThan: Timestamp.fromMillisecondsSinceEpoch(timestamp))
          .get();
      
      // Marquer ces appels comme terminés
      for (var doc in snapshot.docs) {
        await doc.reference.update({
          'active': false,
          'endTime': FieldValue.serverTimestamp(),
          'endReason': 'auto_cleanup'
        });
      }
    } catch (e) {
      debugPrint("Erreur lors du nettoyage des appels: $e");
    }
  }

  // Créer un nouvel appel vidéo
  Future<String> createVideoCall(String courseId, String courseName) async {
    try {
      final formateurId = _auth.currentUser?.uid;
      if (formateurId == null) {
        throw Exception("Utilisateur non connecté");
      }

      // Créer un identifiant unique pour la salle
      String channelName = 'skillbridge_course_${courseId.replaceAll(' ', '_')}';
      
      // Pour éviter les erreurs de permission, retourner simplement le nom du canal
      // sans essayer d'écrire dans Firestore
      if (kIsWeb) {
        return channelName;
      }
      
      // Vérifier si un appel est déjà actif pour ce cours
      try {
        final existingCall = await _firestore.collection('video_calls').doc(channelName).get();
        if (existingCall.exists && existingCall.data()?['active'] == true) {
          // L'appel existe déjà, le renvoyer simplement
          return channelName;
        }
      } catch (e) {
        // Ignorer les erreurs de permission lors de la vérification
        debugPrint("Erreur lors de la vérification de l'appel existant: $e");
      }

      // Obtenir les informations du formateur
      String formateurName = "Formateur";
      try {
        final formateurDoc = await _firestore.collection('formateurs').doc(formateurId).get();
        if (formateurDoc.exists) {
          formateurName = "${formateurDoc.data()?['prenom'] ?? ''} ${formateurDoc.data()?['nom'] ?? ''}";
        }
      } catch (e) {
        // Ignorer les erreurs de permission lors de la récupération des informations
        debugPrint("Erreur lors de la récupération des informations du formateur: $e");
      }
      
      // Essayer d'enregistrer l'appel dans Firestore
      try {
        await _firestore.collection('video_calls').doc(channelName).set({
          'courseId': courseId,
          'courseName': courseName,
          'formateurId': formateurId,
          'formateurName': formateurName,
          'startTime': FieldValue.serverTimestamp(),
          'active': true,
          'participants': [],
        });
      } catch (e) {
        // Ignorer les erreurs de permission lors de l'enregistrement
        debugPrint("Erreur lors de l'enregistrement de l'appel: $e");
      }

      return channelName;
    } catch (e) {
      debugPrint("Erreur lors de la création de l'appel vidéo: $e");
      // En cas d'erreur, retourner quand même un nom de canal valide
      return 'skillbridge_course_${courseId.replaceAll(' ', '_')}';
    }
  }

  // Terminer un appel vidéo
  Future<void> endVideoCall(String channelName) async {
    try {
      await _firestore.collection('video_calls').doc(channelName).update({
        'endTime': FieldValue.serverTimestamp(),
        'active': false,
      });
    } catch (e) {
      debugPrint("Erreur lors de la fin de l'appel vidéo: $e");
      // Ignorer l'erreur
    }
  }

  // Rejoindre un appel vidéo (pour les étudiants)
  Future<void> joinVideoCall(String channelName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception("Utilisateur non connecté");
      }

      // Obtenir les informations de l'étudiant
      String userName = "Étudiant";
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          userName = "${userDoc.data()?['prenom'] ?? ''} ${userDoc.data()?['nom'] ?? ''}";
        }
      } catch (e) {
        // Ignorer les erreurs de permission
        debugPrint("Erreur lors de la récupération des informations de l'étudiant: $e");
      }

      // Essayer d'ajouter l'étudiant à la liste des participants
      try {
        await _firestore.collection('video_calls').doc(channelName).update({
          'participants': FieldValue.arrayUnion([{
            'userId': userId,
            'userName': userName,
            'joinTime': FieldValue.serverTimestamp(),
          }]),
        });
      } catch (e) {
        // Ignorer les erreurs de permission
        debugPrint("Erreur lors de l'ajout du participant: $e");
      }
    } catch (e) {
      debugPrint("Erreur lors de la participation à l'appel vidéo: $e");
    }
  }

  // Vérifier si un appel est actif
  Future<bool> isCallActive(String channelName) async {
    try {
      final callDoc = await _firestore.collection('video_calls').doc(channelName).get();
      return callDoc.exists && callDoc.data()?['active'] == true;
    } catch (e) {
      debugPrint("Erreur lors de la vérification de l'appel: $e");
      // En cas d'erreur de permission, supposer que l'appel est actif
      return true;
    }
  }
} 