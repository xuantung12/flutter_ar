import 'package:flutter/material.dart';
import 'story_data.dart';
import 'story_detail_page.dart';

class StoryListPage extends StatefulWidget {
  const StoryListPage({Key? key}) : super(key: key);

  @override
  State<StoryListPage> createState() => _StoryListPageState();
}

class _StoryListPageState extends State<StoryListPage> {
  String selectedCategory = 'Tất Cả';
  List<Story> stories = StoryData.getAllStories();

  List<Story> getFilteredStories() {
    if (selectedCategory == 'Tất Cả') {
      return stories;
    }
    return stories.where((story) => story.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredStories = getFilteredStories();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade300,
              Colors.pink.shade200,
              Colors.purple.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Kho Truyện',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.menu_book, color: Colors.white, size: 32),
                  ],
                ),
              ),

              // Category Filter
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: StoryData.getCategories().length,
                  itemBuilder: (context, index) {
                    final category = StoryData.getCategories()[index];
                    final isSelected = category == selectedCategory;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: FilterChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.orange : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        backgroundColor: Colors.white.withOpacity(0.2),
                        selectedColor: Colors.white,
                        elevation: 5,
                      ),
                    );
                  },
                ),
              ),

              // Story List
              Expanded(
                child: filteredStories.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có truyện nào',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredStories.length,
                        itemBuilder: (context, index) {
                          final story = filteredStories[index];
                          return _buildStoryCard(story);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCard(Story story) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryDetailPage(story: story),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.book,
                  size: 40,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      story.author,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      story.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            story.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.child_care, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${story.ageRange}+ tuổi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}