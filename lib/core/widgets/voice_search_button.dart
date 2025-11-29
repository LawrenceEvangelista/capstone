import 'package:flutter/material.dart';
import 'package:testapp/core/services/voice_search_service.dart';

class VoiceButton extends StatefulWidget {
  final Function(String) onResult;

  const VoiceButton({super.key, required this.onResult});

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton> {
  final voice = VoiceService();
  bool listening = false;

  Future<void> toggle() async {
    if (!listening) {
      setState(() => listening = true);
      await voice.start((text) {
        widget.onResult(text);
        voice.stop();
        setState(() => listening = false);
      });
    } else {
      await voice.stop();
      setState(() => listening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        listening ? Icons.mic : Icons.mic_none,
        color: Colors.redAccent,
      ),
      onPressed: toggle,
    );
  }
}

/*How to use inside your search bar

Row(
  children: [
    Expanded(
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(hintText: "Search stories..."),
      ),
    ),
    VoiceButton(
      onResult: (text) {
        searchController.text = text;
        performSearch(text);
      },
    ),
  ],
)
*/
