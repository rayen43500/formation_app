import 'package:flutter/material.dart';
import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'jitsi_config.dart';
import 'dart:html' as html;

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
  Timer? _connectionTimeoutTimer;
  int _connectionAttempts = 0;
  static const int _maxConnectionAttempts = 3;  // Augmenté à 3 tentatives
  bool _conferenceStarted = false;
  bool _useWebFallback = false;

  @override
  void initState() {
    super.initState();
    // Démarrage immédiat de l'appel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Si c'est un formateur, on utilise la méthode optimisée pour les formateurs
      if (widget.isTrainer) {
        _startTrainerVideoCall();
      } else {
        _requestPermissionsAndJoin();
      }
    });
  }
  
  @override
  void dispose() {
    _connectionTimeoutTimer?.cancel();
    super.dispose();
  }

  // Solution de secours pour le web - ouvrir Jitsi Meet directement dans le navigateur
  void _openJitsiInBrowser() {
    if (kIsWeb) {
      final url = 'https://meet.jit.si/${widget.channelName}';
      html.window.open(url, '_blank');
      
      // Fermer cette page après un court délai
      Timer(Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  // Méthode optimisée pour les formateurs avec moins d'attente
  Future<void> _startTrainerVideoCall() async {
    try {
      setState(() {
        _isJoining = true;
        _errorMessage = null;
        _conferenceStarted = true; // Marquer comme déjà démarré pour éviter les attentes
      });

      // Sur le web, utiliser la solution de secours si nécessaire
      if (kIsWeb && _useWebFallback) {
        _openJitsiInBrowser();
        return;
      }

      // Utiliser la configuration optimisée pour les formateurs
      final options = JitsiConfig.getTrainerOptions(widget.channelName);

      try {
        // Rejoindre la réunion directement sans attente
        await JitsiMeetWrapper.joinMeeting(
          options: options,
          listener: JitsiConfig.getTrainerListener(
            onConferenceJoined: () {
              if (mounted) {
                setState(() {
                  _isJoining = false;
                });
              }
            },
            onConferenceTerminated: () {
              if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
        );
      } catch (e) {
        print("Erreur lors de l'appel à JitsiMeetWrapper.joinMeeting: $e");
        // Si l'erreur est liée au plugin manquant, utiliser la solution de secours
        if (e.toString().contains('MissingPluginException') && kIsWeb) {
          setState(() {
            _useWebFallback = true;
          });
          _openJitsiInBrowser();
        } else {
          rethrow;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur lors de la connexion à l'appel vidéo: $e";
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _requestPermissionsAndJoin() async {
    try {
      // Reset connection state
      setState(() {
        _isJoining = true;
        _errorMessage = null;
      });
      
      // Sur le web, utiliser la solution de secours si nécessaire
      if (kIsWeb && _useWebFallback) {
        _openJitsiInBrowser();
        return;
      }
      
      // Start connection timeout timer
      _startConnectionTimeoutTimer();
      
      // Request permissions (not needed on web, but keep for other platforms)
      if (!kIsWeb && !await _checkAndRequestPermissions()) {
        setState(() {
          _errorMessage = "Les permissions caméra et microphone sont nécessaires pour l'appel vidéo";
          _isJoining = false;
        });
        _connectionTimeoutTimer?.cancel();
        return;
      }

      // Utiliser la configuration pour les étudiants
      final options = JitsiConfig.getStudentOptions(widget.channelName);

      try {
        // Join the meeting with improved error handling
        await JitsiMeetWrapper.joinMeeting(
          options: options,
          listener: JitsiConfig.getStudentListener(
            onConferenceJoined: () {
              _connectionTimeoutTimer?.cancel();
              if (mounted) {
                setState(() {
                  _isJoining = false;
                  _conferenceStarted = true;
                });
              }
            },
            onConferenceTerminated: () {
              _connectionTimeoutTimer?.cancel();
              if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
        );
      } catch (e) {
        print("Erreur lors de l'appel à JitsiMeetWrapper.joinMeeting: $e");
        // Si l'erreur est liée au plugin manquant, utiliser la solution de secours
        if (e.toString().contains('MissingPluginException') && kIsWeb) {
          setState(() {
            _useWebFallback = true;
          });
          _openJitsiInBrowser();
        } else if (kIsWeb) {
          // Sur le web, en cas d'erreur, proposer la solution de secours
          setState(() {
            _errorMessage = "Problème de connexion à l'appel vidéo. Essayez d'ouvrir directement dans le navigateur.";
            _isJoining = false;
            _useWebFallback = true;
          });
        } else {
          rethrow;
        }
      }
    } catch (e) {
      _connectionTimeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur lors de la connexion à l'appel vidéo: $e";
          _isJoining = false;
        });
      }
    }
  }

  void _startConnectionTimeoutTimer() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isJoining && !_conferenceStarted) {
        if (_connectionAttempts < _maxConnectionAttempts) {
          _connectionAttempts++;
          debugPrint("Connection timeout, retrying... Attempt: $_connectionAttempts");
          _requestPermissionsAndJoin();
        } else {
          setState(() {
            _errorMessage = "La connexion à l'appel vidéo a échoué après plusieurs tentatives. Veuillez vérifier votre connexion internet et réessayer.";
            _isJoining = false;
            // Sur le web, suggérer la solution de secours
            if (kIsWeb) {
              _useWebFallback = true;
            }
          });
        }
      }
    });
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
    // Pour les formateurs, afficher un écran de chargement minimal
    if (_isJoining && widget.isTrainer) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  color: Colors.green,
                  strokeWidth: 6,
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Connexion à l'appel vidéo...",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Bouton pour utiliser la solution de secours sur le web
              if (kIsWeb)
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _useWebFallback = true;
                      });
                      _openJitsiInBrowser();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      "Ouvrir dans le navigateur",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else if (_isJoining) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isTrainer ? "Démarrage de l'appel vidéo" : "Connexion à l'appel"),
          centerTitle: true,
          backgroundColor: widget.isTrainer ? Colors.green.shade700 : Colors.blueGrey,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                _connectionAttempts = 0;
                if (widget.isTrainer) {
                  _startTrainerVideoCall();
                } else {
                  _requestPermissionsAndJoin();
                }
              },
              tooltip: "Rafraîchir la connexion",
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isTrainer) 
                Icon(Icons.video_call, size: 80, color: Colors.green),
              if (!widget.isTrainer)
                CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                widget.isTrainer 
                    ? "Démarrage de votre session d'enseignement..." 
                    : "Connexion à l'appel vidéo en cours...",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                widget.isTrainer 
                    ? "Préparation de l'espace d'appel pour vos étudiants" 
                    : "Veuillez patienter pendant la connexion à la session",
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              if (_connectionAttempts > 0)
                Text(
                  "Tentative ${_connectionAttempts + 1}/$_maxConnectionAttempts",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Annuler"),
                  ),
                  // Bouton pour utiliser la solution de secours sur le web
                  if (kIsWeb)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _useWebFallback = true;
                          });
                          _openJitsiInBrowser();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: Text("Ouvrir dans le navigateur"),
                      ),
                    ),
                ],
              ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _connectionAttempts = 0;
                      if (widget.isTrainer) {
                        _startTrainerVideoCall();
                      } else {
                        _requestPermissionsAndJoin();
                      }
                    },
                    child: Text("Réessayer"),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Retour"),
                  ),
                  // Bouton pour utiliser la solution de secours sur le web
                  if (kIsWeb)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _useWebFallback = true;
                          });
                          _openJitsiInBrowser();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: Text("Ouvrir dans le navigateur"),
                      ),
                    ),
                ],
              ),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, size: 64, color: Colors.green),
              SizedBox(height: 20),
              Text(
                "Appel vidéo en cours",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                widget.isTrainer 
                    ? "Vous êtes le formateur de cette session" 
                    : "Vous êtes connecté en tant qu'étudiant",
                style: TextStyle(fontSize: 16),
              ),
              // Bouton pour utiliser la solution de secours sur le web
              if (kIsWeb)
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _useWebFallback = true;
                      });
                      _openJitsiInBrowser();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      "Ouvrir dans le navigateur",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
  }
}