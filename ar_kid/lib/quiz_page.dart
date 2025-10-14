import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({Key? key}) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // Dữ liệu câu hỏi
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Động vật nào sau đây sống ở biển?',
      'options': ['Chó', 'Mèo', 'Cá', 'Gà'],
      'correctAnswer': 2,
    },
    {
      'question': '2 + 2 bằng bao nhiêu?',
      'options': ['3', '4', '5', '6'],
      'correctAnswer': 1,
    },
    {
      'question': 'Trái đất có bao nhiêu mặt trăng?',
      'options': ['0', '1', '2', '3'],
      'correctAnswer': 1,
    },
    {
      'question': 'Màu gì là màu của lá cây?',
      'options': ['Đỏ', 'Xanh', 'Vàng', 'Tím'],
      'correctAnswer': 1,
    },
    {
      'question': 'Con vật nào có thể bay?',
      'options': ['Chim', 'Cá', 'Rùa', 'Chuột'],
      'correctAnswer': 0,
    },
    {
      'question': 'Một tuần có bao nhiêu ngày?',
      'options': ['5', '6', '7', '8'],
      'correctAnswer': 2,
    },
    {
      'question': 'Hình tròn có bao nhiêu góc?',
      'options': ['0', '1', '3', '4'],
      'correctAnswer': 0,
    },
    {
      'question': 'Mặt trời mọc ở hướng nào?',
      'options': ['Tây', 'Đông', 'Nam', 'Bắc'],
      'correctAnswer': 1,
    },
    {
      'question': 'Con gì kêu gâu gâu?',
      'options': ['Mèo', 'Chó', 'Gà', 'Vịt'],
      'correctAnswer': 1,
    },
    {
      'question': '5 x 2 bằng bao nhiêu?',
      'options': ['8', '10', '12', '15'],
      'correctAnswer': 1,
    },
  ];

  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _hasAnswered = false;
  bool _isQuizCompleted = false;

  // Hàm chọn đáp án
  void _selectAnswer(int index) {
    if (_hasAnswered) return;
    
    setState(() {
      _selectedAnswerIndex = index;
      _hasAnswered = true;
      
      // Kiểm tra đáp án đúng
      if (index == _questions[_currentQuestionIndex]['correctAnswer']) {
        _score += 10;
      }
    });

    // Chờ 1.5 giây rồi chuyển câu tiếp theo
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  // Chuyển sang câu hỏi tiếp theo
  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _hasAnswered = false;
      } else {
        _isQuizCompleted = true;
      }
    });
  }

  // Làm lại quiz
  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _selectedAnswerIndex = null;
      _hasAnswered = false;
      _isQuizCompleted = false;
    });
  }

  // Lấy màu cho nút đáp án
  Color _getButtonColor(int index) {
    if (!_hasAnswered) {
      return Colors.white;
    }
    
    if (index == _questions[_currentQuestionIndex]['correctAnswer']) {
      return Colors.green;
    }
    
    if (index == _selectedAnswerIndex) {
      return Colors.red;
    }
    
    return Colors.white;
  }

  // Lấy icon cho nút đáp án
  IconData? _getButtonIcon(int index) {
    if (!_hasAnswered) {
      return null;
    }
    
    if (index == _questions[_currentQuestionIndex]['correctAnswer']) {
      return Icons.check_circle;
    }
    
    if (index == _selectedAnswerIndex) {
      return Icons.cancel;
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isQuizCompleted) {
      return _buildResultScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Vui Nhộn'),
        backgroundColor: Colors.purple,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple,
              Colors.purple.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Tiến trình
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Câu ${_currentQuestionIndex + 1}/${_questions.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${((_currentQuestionIndex + 1) / _questions.length * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Thanh tiến trình
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / _questions.length,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Câu hỏi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    _questions[_currentQuestionIndex]['question'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Các đáp án
                Expanded(
                  child: ListView.builder(
                    itemCount: _questions[_currentQuestionIndex]['options'].length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: InkWell(
                          onTap: () => _selectAnswer(index),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _getButtonColor(index),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _hasAnswered
                                        ? _getButtonColor(index).withOpacity(0.3)
                                        : Colors.purple.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _hasAnswered
                                            ? (_getButtonColor(index) == Colors.white
                                                ? Colors.purple
                                                : Colors.white)
                                            : Colors.purple,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _questions[_currentQuestionIndex]['options'][index],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _hasAnswered
                                          ? (_getButtonColor(index) == Colors.white
                                              ? Colors.purple
                                              : Colors.white)
                                          : Colors.purple,
                                    ),
                                  ),
                                ),
                                if (_getButtonIcon(index) != null)
                                  Icon(
                                    _getButtonIcon(index),
                                    color: Colors.white,
                                    size: 30,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Màn hình kết quả
  Widget _buildResultScreen() {
    final percentage = (_score / (_questions.length * 10) * 100).toInt();
    String message;
    IconData icon;
    Color color;

    if (percentage >= 80) {
      message = 'Xuất sắc!';
      icon = Icons.emoji_events;
      color = Colors.amber;
    } else if (percentage >= 60) {
      message = 'Tốt lắm!';
      icon = Icons.sentiment_very_satisfied;
      color = Colors.green;
    } else if (percentage >= 40) {
      message = 'Khá tốt!';
      icon = Icons.sentiment_satisfied;
      color = Colors.blue;
    } else {
      message = 'Cố gắng lên nhé!';
      icon = Icons.sentiment_neutral;
      color = Colors.orange;
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade300,
              Colors.blue.shade300,
              Colors.pink.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 120,
                    color: color,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Điểm số của bạn',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.purple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$_score',
                              style: const TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            Text(
                              '/${_questions.length * 10}',
                              style: const TextStyle(
                                fontSize: 30,
                                color: Colors.purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 24,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton.icon(
                    onPressed: _restartQuiz,
                    icon: const Icon(Icons.refresh, size: 28),
                    label: const Text(
                      'Làm Lại',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.home, size: 28),
                    label: const Text(
                      'Về Trang Chủ',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}