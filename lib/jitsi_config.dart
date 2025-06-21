import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class JitsiConfig {
  /// Obtenir les options de configuration optimisées pour les formateurs
  static JitsiMeetingOptions getTrainerOptions(String roomName) {
    return JitsiMeetingOptions(
      roomNameOrUrl: roomName,
      serverUrl: "https://meet.jit.si",
      isAudioMuted: false,
      isVideoMuted: false,
      userDisplayName: "Formateur",
      userEmail: "formateur@skillbridge.com",
      featureFlags: _getTrainerFeatureFlags(),
    );
  }

  /// Obtenir les options de configuration pour les étudiants
  static JitsiMeetingOptions getStudentOptions(String roomName) {
    return JitsiMeetingOptions(
      roomNameOrUrl: roomName,
      serverUrl: "https://meet.jit.si",
      isAudioMuted: true, // Étudiant rejoint en mode muet
      isVideoMuted: true, // Étudiant rejoint avec caméra désactivée
      userDisplayName: "Étudiant",
      featureFlags: _getStudentFeatureFlags(),
    );
  }

  /// Obtenir les flags de fonctionnalités pour les formateurs
  static Map<String, dynamic> _getTrainerFeatureFlags() {
    // Configuration de base pour tous les environnements
    final Map<String, dynamic> flags = {
      "prejoinpage.enabled": false,
      "toolbox.enabled": true,
      "filmstrip.enabled": true,
      "welcomepage.enabled": false,
      "pip.enabled": false,
      "chat.enabled": true,
      "tile-view.enabled": true,
      "raise-hand.enabled": true,
      "meeting-password.enabled": false,
    };
    
    // Ajustements spécifiques pour le web
    if (kIsWeb) {
      flags["prejoinpage.enabled"] = false;
      flags["live-streaming.enabled"] = false;
      flags["recording.enabled"] = false;
      flags["calendar.enabled"] = false;
    } else {
      // Ajustements pour les plateformes mobiles
      flags["android.screensharing.enabled"] = true;
      flags["ios.screensharing.enabled"] = true;
    }
    
    return flags;
  }

  /// Obtenir les flags de fonctionnalités pour les étudiants
  static Map<String, dynamic> _getStudentFeatureFlags() {
    // Configuration de base pour tous les environnements
    final Map<String, dynamic> flags = {
      "prejoinpage.enabled": false,
      "toolbox.enabled": true,
      "filmstrip.enabled": true,
      "welcomepage.enabled": false,
      "pip.enabled": false,
      "chat.enabled": true,
      "tile-view.enabled": true,
      "raise-hand.enabled": true,
      "recording.enabled": false,
      "live-streaming.enabled": false,
      "meeting-password.enabled": false,
      "calendar.enabled": false,
    };
    
    return flags;
  }
  
  /// Configuration de l'écouteur d'événements Jitsi pour les formateurs
  static JitsiMeetingListener getTrainerListener({
    required Function() onConferenceTerminated,
    required Function() onConferenceJoined,
  }) {
    return JitsiMeetingListener(
      onConferenceWillJoin: (url) {
        print("Formateur - onConferenceWillJoin: url: $url");
      },
      onConferenceJoined: (url) {
        print("Formateur - onConferenceJoined: url: $url");
        onConferenceJoined();
      },
      onConferenceTerminated: (url, error) {
        print("Formateur - onConferenceTerminated: url: $url, error: $error");
        onConferenceTerminated();
      },
    );
  }
  
  /// Configuration de l'écouteur d'événements Jitsi pour les étudiants
  static JitsiMeetingListener getStudentListener({
    required Function() onConferenceTerminated,
    required Function() onConferenceJoined,
  }) {
    return JitsiMeetingListener(
      onConferenceWillJoin: (url) {
        print("Étudiant - onConferenceWillJoin: url: $url");
      },
      onConferenceJoined: (url) {
        print("Étudiant - onConferenceJoined: url: $url");
        onConferenceJoined();
      },
      onConferenceTerminated: (url, error) {
        print("Étudiant - onConferenceTerminated: url: $url, error: $error");
        onConferenceTerminated();
      },
    );
  }
} 