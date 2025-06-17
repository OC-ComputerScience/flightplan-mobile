import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../services/api_session_storage.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _serviceLocator = ServiceLocator();
  bool _isLoading = false;
  String? _errorMessage;

  // Form fields
  DateTime? _selectedGradDate;
  String _profileDescription = '';
  List<int> _selectedMajors = [];
  List<int> _selectedStrengths = [];

  // Options for dropdowns
  List<Map<String, dynamic>> _semesterOptions = [];
  List<Map<String, dynamic>> _majorOptions = [];
  List<Map<String, dynamic>> _strengthOptions = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      // Load semesters
      final semestersResponse = await _serviceLocator.api.get('/semesters');
      if (semestersResponse['data'] != null) {
        setState(() {
          _semesterOptions =
              (semestersResponse['data'] as List).map((semester) {
            return {
              'id': semester['id'],
              'title':
                  '${semester['term'].toString().toUpperCase()} ${semester['year']}',
              'endDate': DateTime.parse(semester['endDate']),
            };
          }).toList();
        });
      }

      // Load majors
      final majorsResponse = await _serviceLocator.api.get('/majors');
      if (majorsResponse['data'] != null) {
        setState(() {
          _majorOptions = (majorsResponse['data'] as List).map((major) {
            return {
              'id': major['id'] as int,
              'title': major['name'] as String,
            };
          }).toList();
        });
      }

      // Load strengths
      final strengthsResponse = await _serviceLocator.api.get('/strengths');
      if (strengthsResponse['data'] != null) {
        setState(() {
          _strengthOptions =
              (strengthsResponse['data'] as List).map((strength) {
            return {
              'id': strength['id'] as int,
              'title': strength['name'] as String,
            };
          }).toList();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading options. Please try again.';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = (await ApiSessionStorage.getSession()).userId;

      // Create student
      final studentData = {
        'userId': userId,
        'graduationDate': _selectedGradDate?.toIso8601String(),
        'semestersFromGrad': _semesterOptions
                .indexWhere((s) => s['endDate'] == _selectedGradDate) +
            1,
        'pointsAwarded': 0,
        'pointsUsed': 0,
      };

      final studentResponse =
          await _serviceLocator.api.post('/students', studentData);

      if (studentResponse['id'] == null) {
        throw Exception(
            'Failed to create student: ${studentResponse['message'] ?? 'Unknown error'}');
      }

      final studentId = studentResponse['id'];

      // Update user profile
      final userUpdateData = {
        'id': userId,
        'profileDescription': _profileDescription,
      };

      await _serviceLocator.api.put('/user/$userId', userUpdateData);

      // Add majors
      for (final majorId in _selectedMajors) {
        final majorData = {
          'majorId': majorId,
        };
        await _serviceLocator.api.put('/students/$studentId/majors', majorData);
      }

      // Add strengths
      for (final strengthId in _selectedStrengths) {
        try {
          final strengthData = {
            'strengthId': strengthId,
          };
          await _serviceLocator.api.put('/students/$studentId/strengths', strengthData);
        } catch (e) {
          // Continue with other strengths even if one fails
          continue;
        }
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'An error occurred while saving your information: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMultiSelectChips(
      String label,
      List<Map<String, dynamic>> options,
      List<int> selectedIds,
      Function(List<int>) onSelectionChanged,
      {bool isRequired = true,
      int? maxSelections}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedIds.contains(option['id']);
            return FilterChip(
              label: Text(option['title']),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (maxSelections == null ||
                        selectedIds.length < maxSelections) {
                      onSelectionChanged([...selectedIds, option['id']]);
                    }
                  } else {
                    onSelectionChanged(
                        selectedIds.where((id) => id != option['id']).toList());
                  }
                });
              },
            );
          }).toList(),
        ),
        if (isRequired && selectedIds.isEmpty)
          Text(
            'Please select at least one option',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (maxSelections != null && selectedIds.length > maxSelections)
          Text(
            'You can only select up to $maxSelections options',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome!',
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please complete your profile to get started',
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Graduation Semester Dropdown
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(
                    labelText: 'Expected Graduation Semester',
                    border: OutlineInputBorder(),
                  ),
                  items: _semesterOptions.map((semester) {
                    return DropdownMenuItem(
                      value: semester,
                      child: Text(semester['title']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGradDate = value?['endDate'];
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your graduation semester';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Majors Multi-select
                _buildMultiSelectChips(
                  'Majors',
                  _majorOptions,
                  _selectedMajors,
                  (value) => setState(() => _selectedMajors = value),
                  isRequired: true,
                ),
                const SizedBox(height: 16),

                // Strengths Multi-select
                _buildMultiSelectChips(
                  'Clifton Strengths (Optional)',
                  _strengthOptions,
                  _selectedStrengths,
                  (value) => setState(() => _selectedStrengths = value),
                  isRequired: false,
                  maxSelections: 5,
                ),
                const SizedBox(height: 16),

                // Profile Description
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Profile Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    setState(() {
                      _profileDescription = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Error Message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
