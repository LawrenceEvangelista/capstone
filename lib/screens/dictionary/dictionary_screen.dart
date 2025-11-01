import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = ['happy', 'animal', 'school', 'friend', 'book'];
  List<Map<String, dynamic>> _wordDefinitions = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Cartoonish colors matching login screen style
  final Color _backgroundColor = const Color(0xFFFFF176); // Light yellow
  final Color _primaryColor = const Color(0xFFFF6D00); // Orange
  final Color _accentColor = const Color(0xFF8E24AA); // Purple

  @override
  void initState() {
    super.initState();
    // Load a default word on start
    _searchWord('hello');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchWord(String word) async {
    if (word.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Using the Free Dictionary API
      final response = await http.get(
        Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word'),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _wordDefinitions = List<Map<String, dynamic>>.from(data);

          // Add to recent searches if not already there
          if (!_recentSearches.contains(word.toLowerCase())) {
            _recentSearches.insert(0, word.toLowerCase());
            if (_recentSearches.length > 10) {
              _recentSearches.removeLast();
            }
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Sorry, we couldn\'t find that word. Try another one!';
          _wordDefinitions = [];
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Dictionary',
          style: GoogleFonts.fredoka(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          // Optional cartoon background pattern
          image: const DecorationImage(
            image: AssetImage('assets/cartoon_background.png'),
            opacity: 0.1,
            fit: BoxFit.cover,
          ),
          color: _backgroundColor,
        ),
        child: Column(
          children: [
            // Search bar with a fun design
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Type a word...',
                                hintStyle: GoogleFonts.fredoka(
                                  color: Colors.grey,
                                ),
                                prefixIcon: Icon(Icons.search, color: _primaryColor),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onSubmitted: (value) => _searchWord(value),
                              textInputAction: TextInputAction.search,
                              style: GoogleFonts.fredoka(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_accentColor, _primaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => _searchWord(_searchController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                            child: Text(
                              'Search',
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap on a word to see its meaning:',
                      style: GoogleFonts.fredoka(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recentSearches.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              backgroundColor: Colors.white,
                              shadowColor: _accentColor.withOpacity(0.2),
                              elevation: 3,
                              label: Text(
                                _recentSearches[index],
                                style: GoogleFonts.fredoka(
                                  color: _accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onPressed: () {
                                _searchController.text = _recentSearches[index];
                                _searchWord(_recentSearches[index]);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content area
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: _primaryColor,
                ),
              )
                  : _errorMessage.isNotEmpty
                  ? FadeIn(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: _accentColor.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          color: _accentColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
                  : _buildWordDefinitions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordDefinitions() {
    if (_wordDefinitions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/cartoon_dictionary.png', // Replace with your asset
              height: 120,
              width: 120,
            ),
            const SizedBox(height: 20),
            Text(
              'Search for a word to see its definition!',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                color: _primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _wordDefinitions.length,
        itemBuilder: (context, index) {
          final wordData = _wordDefinitions[index];
          final word = wordData['word'] as String;
          final phonetic = wordData['phonetic'] ?? '';
          final meanings = wordData['meanings'] as List<dynamic>;

          return Card(
            elevation: 8,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            color: Colors.white,
            shadowColor: _primaryColor.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.menu_book,
                          color: _accentColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word,
                              style: GoogleFonts.fredoka(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                            if (phonetic.isNotEmpty)
                              Text(
                                phonetic,
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1.5),
                  for (var meaning in meanings) ...[
                    _buildMeaning(meaning),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeaning(Map<String, dynamic> meaning) {
    final partOfSpeech = meaning['partOfSpeech'] as String;
    final definitions = meaning['definitions'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _accentColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            partOfSpeech,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
              color: _accentColor,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < definitions.length; i++) ...[
          _buildDefinition(i + 1, definitions[i]),
          if (i < definitions.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildDefinition(int index, Map<String, dynamic> definition) {
    final definitionText = definition['definition'] as String;
    final example = definition['example'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                definitionText,
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        if (example != null) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    color: _accentColor.withOpacity(0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      example,
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}