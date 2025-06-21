import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class JitsiConfig {
  /// Obtenir les options de configuration optimisées pour les formateurs
  static JitsiMeetingOptions getTrainerOptions(String roomName) {
    return JitsiMeetingOptions(
      roomNameOrUrl: roomName,
      serverUrl: "https://meet.jit.si",
      isAudioMuted: false,
      isAudioOnly: false,
      isVideoMuted: false,
      userDisplayName: "Formateur",
      userEmail: "",
      featureFlags: {
        "prejoinpage.enabled": false,     // Désactiver la page de prévisualisation
        "welcomepage.enabled": false,     // Désactiver la page d'accueil
        "calendar.enabled": false,        // Désactiver le calendrier
        "call-integration.enabled": false,// Désactiver l'intégration d'appel
        "pip.enabled": true,              // Activer le mode picture-in-picture
        "live-streaming.enabled": false,  // Désactiver le streaming en direct
        "recording.enabled": false,       // Désactiver l'enregistrement
        "chat.enabled": true,             // Activer le chat
        "invite.enabled": false,          // Désactiver les invitations
        "meeting-password.enabled": false,// Désactiver les mots de passe
        "tile-view.enabled": true,        // Activer la vue en tuiles
        "filmstrip.enabled": true,        // Activer la bande de film
        "help.enabled": false,            // Désactiver l'aide
        "ios.screensharing.enabled": true,// Activer le partage d'écran iOS
        "android.screensharing.enabled": true, // Activer le partage d'écran Android
        "speakerstats.enabled": false,    // Désactiver les statistiques des orateurs
        "kickout.enabled": true,          // Activer l'expulsion
        "lobby-mode.enabled": false,      // Désactiver le mode lobby
        "notifications.enabled": false,   // Désactiver les notifications
        "video-share.enabled": true,      // Activer le partage de vidéo
        "reactions.enabled": true,        // Activer les réactions
      },
    );
  }

  /// Obtenir les options de configuration pour les étudiants
  static JitsiMeetingOptions getStudentOptions(String roomName) {
    return JitsiMeetingOptions(
      roomNameOrUrl: roomName,
      serverUrl: "https://meet.jit.si",
      isAudioMuted: true,                // Étudiant rejoint en mode muet
      isAudioOnly: false,
      isVideoMuted: false,
      userDisplayName: "Étudiant",
      userEmail: "",
      featureFlags: {
        "prejoinpage.enabled": false,     // Désactiver la page de prévisualisation
        "welcomepage.enabled": false,     // Désactiver la page d'accueil
        "calendar.enabled": false,        // Désactiver le calendrier
        "call-integration.enabled": false,// Désactiver l'intégration d'appel
        "pip.enabled": true,              // Activer le mode picture-in-picture
        "live-streaming.enabled": false,  // Désactiver le streaming en direct
        "recording.enabled": false,       // Désactiver l'enregistrement
        "chat.enabled": true,             // Activer le chat
        "invite.enabled": false,          // Désactiver les invitations
        "meeting-password.enabled": false,// Désactiver les mots de passe
        "tile-view.enabled": true,        // Activer la vue en tuiles
        "filmstrip.enabled": true,        // Activer la bande de film
        "help.enabled": false,            // Désactiver l'aide
        "raise-hand.enabled": true,       // Activer la levée de main pour les étudiants
        "speakerstats.enabled": false,    // Désactiver les statistiques des orateurs
        "kickout.enabled": false,         // Désactiver l'expulsion pour les étudiants
        "lobby-mode.enabled": false,      // Désactiver le mode lobby
        "notifications.enabled": false,   // Désactiver les notifications
        "video-share.enabled": false,     // Désactiver le partage de vidéo pour les étudiants
        "reactions.enabled": true,        // Activer les réactions
      },
    );
  }

  /// Configuration de l'écouteur d'événements Jitsi pour les formateurs
  static JitsiMeetingListener getTrainerListener({
    required Function() onConferenceJoined,
    required Function() onConferenceTerminated,
  }) {
    return JitsiMeetingListener(
      onConferenceWillJoin: (url) {
        print("Le formateur va rejoindre la conférence: $url");
      },
      onConferenceJoined: (url) {
        print("Le formateur a rejoint la conférence: $url");
        onConferenceJoined();
      },
      onConferenceTerminated: (url, error) {
        print("Le formateur a quitté la conférence: $url, erreur: $error");
        onConferenceTerminated();
      },
    );
  }
  
  /// Configuration de l'écouteur d'événements Jitsi pour les étudiants
  static JitsiMeetingListener getStudentListener({
    required Function() onConferenceJoined,
    required Function() onConferenceTerminated,
  }) {
    return JitsiMeetingListener(
      onConferenceWillJoin: (url) {
        print("L'étudiant va rejoindre la conférence: $url");
      },
      onConferenceJoined: (url) {
        print("L'étudiant a rejoint la conférence: $url");
        onConferenceJoined();
      },
      onConferenceTerminated: (url, error) {
        print("L'étudiant a quitté la conférence: $url, erreur: $error");
        onConferenceTerminated();
      },
    );
  }
} 