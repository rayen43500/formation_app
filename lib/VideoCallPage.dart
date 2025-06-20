import 'package:flutter/material.dart';
import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallPage extends StatefulWidget {
  final String channelName;
  final bool isTrainer;

  const VideoCallPage({
    Key? key,
    required this.channelName,
    required this.isTrainer,
  }) : super(key: key);

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool _isJoining = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndJoin();
  }

  Future<void> _requestPermissionsAndJoin() async {
    try {
      // Demander les permissions
      if (!await _checkAndRequestPermissions()) {
        setState(() {
          _errorMessage = "Les permissions caméra et microphone sont nécessaires pour l'appel vidéo";
          _isJoining = false;
        });
        return;
      }

      // Configurer les options de la réunion
      final options = JitsiMeetingOptions(
        roomNameOrUrl: widget.channelName,
        serverUrl: "https://meet.jit.si",
        isAudioMuted: !widget.isTrainer, // Étudiant rejoint en mode muet
        isVideoMuted: !widget.isTrainer, // Étudiant rejoint avec caméra désactivée
        userDisplayName: widget.isTrainer ? "Formateur" : "Étudiant",
        featureFlags: {
          "prejoinpage.enabled": false,
        },
      );

      // Rejoindre la réunion
      await JitsiMeetWrapper.joinMeeting(
        options: options,
        listener: JitsiMeetingListener(
          onConferenceWillJoin: (url) {
            debugPrint("onConferenceWillJoin: url: $url");
          },
          onConferenceJoined: (url) {
            debugPrint("onConferenceJoined: url: $url");
            setState(() {
              _isJoining = false;
            });
          },
          onConferenceTerminated: (url, error) {
            debugPrint("onConferenceTerminated: url: $url, error: $error");
            Navigator.pop(context);
          },
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur lors de la connexion à l'appel vidéo: $e";
        _isJoining = false;
      });
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.camera,
    ].request();
    
    return statuses[Permission.microphone]!.isGranted && 
           statuses[Permission.camera]!.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    if (_isJoining) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Appel Vidéo : ${widget.channelName}"),
          centerTitle: true,
          backgroundColor: Colors.blueGrey,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Connexion à l'appel vidéo en cours..."),
            ],
          ),
        ),
      );
    } else if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Erreur"),
          centerTitle: true,
          backgroundColor: Colors.blueGrey,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Retour"),
              )
            ],
          ),
        ),
      );
    } else {
      // Cette partie ne sera généralement pas affichée car Jitsi prend le contrôle
      return Scaffold(
        appBar: AppBar(
          title: Text("Appel Vidéo : ${widget.channelName}"),
          centerTitle: true,
          backgroundColor: Colors.blueGrey,
        ),
        body: Center(
          child: Text("Appel vidéo en cours..."),
        ),
      );
    }
  }
}