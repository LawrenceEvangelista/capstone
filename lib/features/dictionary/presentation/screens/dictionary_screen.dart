import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

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
  String _selectedLanguage = 'English'; // Default language
  Set<String> _profanitySet = {}; // Loaded from JSON

  // API Configuration
  // For emulator, use: 'http://10.0.2.2:3000/api'
  // For real device, use your computer's IP: 'http://192.168.x.x:3000/api'
  // For localhost testing: 'http://localhost:3000/api'
  static const String TAGALOG_API_BASE = 'http://192.168.1.8:3000/api';
  static const String ENGLISH_API_BASE = 'https://api.dictionaryapi.dev/api/v2/entries/en';

  // Cartoonish colors matching login screen style
  final Color _backgroundColor = const Color(0xFFFFF176); // Light yellow
  final Color _primaryColor = const Color(0xFFFF6D00); // Orange
  final Color _accentColor = const Color(0xFF8E24AA); // Purple

  @override
  void initState() {
    super.initState();
    _loadProfanityBlocklist();
  }

  /// Load profanity blocklist from assets JSON file
  Future<void> _loadProfanityBlocklist() async {
    try {
      final jsonString = await rootBundle.loadString('assets/config/profanity_blocklist.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final blocklist = List<String>.from(jsonData['blocklist'] ?? []);
      
      setState(() {
        _profanitySet = blocklist.map((w) => w.toLowerCase()).toSet();
      });
      
      // Load default word after blocklist is ready
      _searchWord('hello');
    } catch (e) {
      print('Error loading profanity blocklist: $e');
      // Continue anyway with empty blocklist
      _searchWord('hello');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Check if a single word contains profanities
  bool _containsProfanity(String word) {
    if (word.isEmpty || _profanitySet.isEmpty) return false;
    String lowerWord = word.toLowerCase().trim();
    
    // Check exact matches in blocklist (O(1) lookup)
    if (_profanitySet.contains(lowerWord)) {
      return true;
    }
    
    // Check for censored variations (f*ck, b*tch, etc.)
    String cleanedWord = lowerWord.replaceAll(RegExp(r'[\*\-_]'), '');
    for (String blocked in _profanitySet) {
      String cleanedBlocked = blocked.replaceAll(RegExp(r'[\*\-_]'), '');
      if (cleanedWord == cleanedBlocked) {
        return true;
      }
    }
    
    return false;
  }

  /// Filter out profanities from API results
  List<Map<String, dynamic>> _filterProfanities(
    List<Map<String, dynamic>> results
  ) {
    return results.where((wordData) {
      final word = wordData['word'] as String? ?? '';
      
      // Check if word is profane
      if (_containsProfanity(word)) {
        print('🚫 Blocked profanity: $word');
        return false;
      }
      
      // Check if any definitions contain profane language
      final meanings = wordData['meanings'] as List<dynamic>? ?? [];
      for (var meaning in meanings) {
        if (meaning is Map<String, dynamic>) {
          final definitions = meaning['definitions'] as List<dynamic>? ?? [];
          for (var def in definitions) {
            if (def is Map<String, dynamic>) {
              final definition = def['definition'] as String? ?? '';
              final example = def['example'] as String? ?? '';
              
              if (_containsProfanity(definition) || _containsProfanity(example)) {
                print('🚫 Blocked definition with profanity: $word');
                return false;
              }
            }
          }
        }
      }
      
      return true;
    }).toList();
  }

  Future<void> _searchWord(String word) async {
    if (word.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _wordDefinitions = [];
    });

    try {
      List<Map<String, dynamic>> results = [];

      if (_selectedLanguage == 'English') {
        results = await _searchEnglishWord(word);
      } else if (_selectedLanguage == 'Tagalog') {
        results = await _searchTagalogWord(word);
      }

      setState(() {
        _isLoading = false;
        _wordDefinitions = results;

        // Add to recent searches if not already there
        if (!_recentSearches.contains(word.toLowerCase())) {
          _recentSearches.insert(0, word.toLowerCase());
          if (_recentSearches.length > 10) {
            _recentSearches.removeLast();
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _selectedLanguage == 'English'
            ? 'Something went wrong. Please try again.'
            : 'May problema. Subukan ulit.';
      });
    }
  }

  // English Dictionary - Uses free API
  Future<List<Map<String, dynamic>>> _searchEnglishWord(String word) async {
    // First check: block search if word itself is profane
    if (_containsProfanity(word)) {
      throw Exception(
        _selectedLanguage == 'English'
            ? 'This word is not appropriate for this dictionary.'
            : 'Ang salitang ito ay hindi angkop para sa diksyunaryo.'
      );
    }

    final response = await http.get(
      Uri.parse('$ENGLISH_API_BASE/$word'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final results = List<Map<String, dynamic>>.from(data);
      
      // Filter out profanities from API results
      final filtered = _filterProfanities(results);
      
      if (filtered.isEmpty) {
        throw Exception(
          _selectedLanguage == 'English'
              ? 'This word or its definitions contain inappropriate content.'
              : 'Ang salita o ang mga kahulugan ay naglalaman ng hindi angkop na nilalaman.'
        );
      }
      
      return filtered;
    } else {
      throw Exception('Word not found');
    }
  }

  // Tagalog Dictionary - Uses YOUR custom API
  Future<List<Map<String, dynamic>>> _searchTagalogWord(String word) async {
    // First check: block search if word itself is profane
    if (_containsProfanity(word)) {
      throw Exception(
        _selectedLanguage == 'English'
            ? 'This word is not appropriate for this dictionary.'
            : 'Ang salitang ito ay hindi angkop para sa diksyunaryo.'
      );
    }

    try {
      print('Attempting to connect to: $TAGALOG_API_BASE/words/$word'); // Debug log

      final response = await http.get(
        Uri.parse('$TAGALOG_API_BASE/words/${Uri.encodeComponent(word)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10)); // Add timeout

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final converted = _convertTagalogApiResponse(data);
        
        // Filter out profanities from API results
        final filtered = _filterProfanities([converted]);
        
        if (filtered.isEmpty) {
          throw Exception(
            _selectedLanguage == 'English'
                ? 'This word or its definitions contain inappropriate content.'
                : 'Ang salita o ang mga kahulugan ay naglalaman ng hindi angkop na nilalaman.'
          );
        }
        
        return filtered;
      } else if (response.statusCode == 404) {
        throw Exception('Hindi nahanap ang salita sa diksyunaryo');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw Exception('Timeout: Hindi makonekta sa server. Siguraduhing tumatakbo ang API.');
    } on SocketException catch (e) {
      print('Connection error: $e');
      throw Exception('Hindi makonekta sa server. Tingnan ang IP address at firewall.');
    } catch (e) {
      print('Error fetching Tagalog word: $e');
      throw Exception('Error: $e');
    }
  }

  // Convert your API response format to match the UI expectations
  Map<String, dynamic> _convertTagalogApiResponse(Map<String, dynamic> apiData) {
    List<Map<String, dynamic>> meanings = [];

    if (apiData['meanings'] != null) {
      for (var meaning in apiData['meanings']) {
        if (meaning['definitions'] != null && meaning['definitions'] is List) {
          List<Map<String, dynamic>> definitions = [];

          for (var def in meaning['definitions']) {
            definitions.add({
              'definition': def['definition'] ?? '',
              'example': (def['examples'] != null && def['examples'].isNotEmpty)
                  ? def['examples'][0]
                  : null,
            });
          }

          meanings.add({
            'partOfSpeech': meaning['partOfSpeech'] ?? 'salita',
            'definitions': definitions,
          });
        }
      }
    }

    return {
      'word': apiData['word'] ?? '',
      'phonetic': apiData['pronunciation'] ?? '',
      'meanings': meanings,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedLanguage == 'English' ? 'My Dictionary' : 'Aking Diksyunaryo',
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
        actions: [
          // Language selector
          PopupMenuButton<String>(
            icon: Icon(Icons.language, color: Colors.white),
            onSelected: (String language) {
              setState(() {
                _selectedLanguage = language;
                _recentSearches = language == 'English'
                    ? ['happy', 'animal', 'school', 'friend', 'book']
                    : ['mahal', 'kumain', 'bahay', 'tubig', 'maganda'];
                _wordDefinitions = [];
                _errorMessage = '';
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'English',
                child: Row(
                  children: [
                    Text('🇺🇸', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text('English', style: GoogleFonts.fredoka()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Tagalog',
                child: Row(
                  children: [
                    Text('🇵🇭', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text('Tagalog', style: GoogleFonts.fredoka()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
        ),
        child: Column(
          children: [
            // Search bar section
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
                    // Language indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_accentColor, _primaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedLanguage == 'English' ? Icons.book : Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            _selectedLanguage == 'English'
                                ? 'English Dictionary'
                                : 'Tunay na Tagalog Dictionary',
                            style: GoogleFonts.fredoka(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search bar
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
                                hintText: _selectedLanguage == 'English'
                                    ? 'Type an English word...'
                                    : 'Mag-type ng Tagalog na salita...',
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
                              _selectedLanguage == 'English' ? 'Search' : 'Hanap',
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
                      _selectedLanguage == 'English'
                          ? 'Tap on a word to see its meaning:'
                          : 'I-tap ang salita para sa kahulugan:',
                      style: GoogleFonts.fredoka(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Recent searches with clear button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SizedBox(
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
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _recentSearches.clear();
                            });
                          },
                          tooltip: _selectedLanguage == 'English'
                              ? 'Clear recent searches'
                              : 'Burahin ang recent',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Content area
            Expanded(
              child: _isLoading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: _primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedLanguage == 'English'
                          ? 'Searching...'
                          : 'Naghahanap...',
                      style: GoogleFonts.fredoka(
                        color: _primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage,
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            color: _accentColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
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
            Icon(
              Icons.menu_book,
              size: 120,
              color: _primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedLanguage == 'English'
                  ? 'Search for a word to see its definition!'
                  : 'Maghanap ng salita para sa kahulugan!',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                color: _primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _selectedLanguage == 'English'
                  ? 'Try: happy, love, book, water'
                  : 'Subukan: mahal, kumain, bahay, tubig',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
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
                          _selectedLanguage == 'English'
                              ? Icons.menu_book
                              : Icons.auto_stories,
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
        if (example != null && example.isNotEmpty) ...[
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