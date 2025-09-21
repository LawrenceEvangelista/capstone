import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'package:translator/translator.dart'; // Add this package

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GoogleTranslator translator = GoogleTranslator();
  List<String> _recentSearches = ['happy', 'animal', 'school', 'friend', 'book'];
  List<Map<String, dynamic>> _wordDefinitions = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedLanguage = 'English'; // Default language

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

  Future<List<Map<String, dynamic>>> _searchEnglishWord(String word) async {
    final response = await http.get(
      Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Word not found');
    }
  }

  Future<List<Map<String, dynamic>>> _searchTagalogWord(String word) async {
    try {
      // First, get English definition if the word is in English
      List<Map<String, dynamic>> englishDefinitions = [];
      String translatedWord = word;

      // Try to detect if it's an English word and get its definition
      try {
        englishDefinitions = await _searchEnglishWord(word);
      } catch (e) {
        // If not found in English dictionary, assume it's a Tagalog word
        // Translate Tagalog word to English to get context
        var translation = await translator.translate(word, from: 'tl', to: 'en');
        translatedWord = translation.text;

        // Try to get English definition of the translated word
        try {
          englishDefinitions = await _searchEnglishWord(translatedWord);
        } catch (e) {
          // If still no definition found, create a simple translation entry
        }
      }

      // Create Tagalog dictionary entry with translations
      Map<String, dynamic> tagalogEntry = await _createTagalogEntry(word, englishDefinitions);

      return [tagalogEntry];
    } catch (e) {
      throw Exception('Translation failed');
    }
  }

  // Missing method implementation
  Future<Map<String, dynamic>> _createTagalogEntry(String originalWord, List<Map<String, dynamic>> englishDefinitions) async {
    try {
      String englishTranslation = '';
      String tagalogTranslation = '';
      List<Map<String, dynamic>> meanings = [];

      // If we have English definitions, it means the original word was in English
      if (englishDefinitions.isNotEmpty) {
        englishTranslation = originalWord;
        // Translate English word to Tagalog
        var translation = await translator.translate(originalWord, from: 'en', to: 'tl');
        tagalogTranslation = translation.text;

        // Convert English definitions to bilingual format
        for (var englishEntry in englishDefinitions) {
          if (englishEntry['meanings'] != null) {
            for (var meaning in englishEntry['meanings']) {
              List<Map<String, dynamic>> bilingualDefinitions = [];

              if (meaning['definitions'] != null) {
                for (var def in meaning['definitions']) {
                  // Translate English definition to Tagalog
                  var translatedDef = await translator.translate(def['definition'], from: 'en', to: 'tl');
                  String? translatedExample;

                  if (def['example'] != null) {
                    var exampleTranslation = await translator.translate(def['example'], from: 'en', to: 'tl');
                    translatedExample = exampleTranslation.text;
                  }

                  bilingualDefinitions.add({
                    'definition': translatedDef.text,
                    'englishDefinition': def['definition'],
                    'example': translatedExample,
                    'englishExample': def['example'],
                  });
                }
              }

              meanings.add({
                'partOfSpeech': _translatePartOfSpeech(meaning['partOfSpeech'] ?? ''),
                'englishPartOfSpeech': meaning['partOfSpeech'],
                'definitions': bilingualDefinitions,
              });
            }
          }
        }
      } else {
        // Original word is likely in Tagalog
        tagalogTranslation = originalWord;
        // Translate Tagalog word to English
        var translation = await translator.translate(originalWord, from: 'tl', to: 'en');
        englishTranslation = translation.text;

        // Create basic definition entry for Tagalog word
        meanings.add({
          'partOfSpeech': 'salita', // Generic term for "word" in Tagalog
          'englishPartOfSpeech': 'word',
          'definitions': [
            {
              'definition': 'Tagalog na salita na nangangahulugang "$englishTranslation"',
              'englishDefinition': 'Tagalog word meaning "$englishTranslation"',
              'example': null,
              'englishExample': null,
            }
          ],
        });
      }

      return {
        'word': tagalogTranslation,
        'englishTranslation': englishTranslation,
        'phonetic': '',
        'meanings': meanings,
      };
    } catch (e) {
      // Fallback simple entry if translation fails
      return {
        'word': originalWord,
        'englishTranslation': null,
        'phonetic': '',
        'meanings': [
          {
            'partOfSpeech': 'salita',
            'englishPartOfSpeech': 'word',
            'definitions': [
              {
                'definition': 'Hindi mahanap ang kahulugan ng salitang ito.',
                'englishDefinition': 'Definition not found for this word.',
                'example': null,
                'englishExample': null,
              }
            ],
          }
        ],
      };
    }
  }

  String _translatePartOfSpeech(String pos) {
    Map<String, String> posTranslations = {
      'noun': 'pangngalan',
      'verb': 'pandiwa',
      'adjective': 'pang-uri',
      'adverb': 'pang-abay',
      'pronoun': 'panghalip',
      'preposition': 'pang-ukol',
      'conjunction': 'pangatnig',
      'interjection': 'pandamdam',
    };

    return posTranslations[pos.toLowerCase()] ?? pos;
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
            // Language indicator and search bar
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
                    // Language indicator with translation info
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
                          Icon(Icons.translate, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            _selectedLanguage == 'English'
                                ? 'English Dictionary'
                                : 'Tagalog Dictionary (may salin)',
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: _primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedLanguage == 'English'
                          ? 'Searching and translating...'
                          : 'Naghahanap at nagsasalin...',
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
                        Icons.translate_outlined,
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
            Icon(
              Icons.translate,
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
                  : 'Subukan: tubig, dilig, mahal, pag-ibig',
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
          final englishTranslation = wordData['englishTranslation'] as String?;
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
                              : Icons.translate,
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
                            if (englishTranslation != null && _selectedLanguage == 'Tagalog')
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'English: $englishTranslation',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 14,
                                    color: _primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
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
    final englishPartOfSpeech = meaning['englishPartOfSpeech'] as String?;
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                partOfSpeech,
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: _accentColor,
                  fontSize: 18,
                ),
              ),
              if (englishPartOfSpeech != null && _selectedLanguage == 'Tagalog') ...[
                Text(
                  ' ($englishPartOfSpeech)',
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.normal,
                    color: _accentColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ],
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
    final englishDefinition = definition['englishDefinition'] as String?;
    final example = definition['example'] as String?;
    final englishExample = definition['englishExample'] as String?;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    definitionText,
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  if (englishDefinition != null && _selectedLanguage == 'Tagalog') ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        'English: $englishDefinition',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (example != null) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                if (englishExample != null && _selectedLanguage == 'Tagalog') ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.translate,
                          color: Colors.green.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'English: $englishExample',
                            style: GoogleFonts.fredoka(
                              fontSize: 13,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}