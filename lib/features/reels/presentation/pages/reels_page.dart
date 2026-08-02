import 'package:flutter/material.dart';

class ReelsPage extends StatelessWidget {
  const ReelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: 10,
        itemBuilder: (context, index) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Mock Video (Image)
              Image.network(
                'https://picsum.photos/id/${index + 100}/800/1200',
                fit: BoxFit.cover,
              ),
              // Gradient for text readability
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.6, 1.0],
                  ),
                ),
              ),
              // Content (User Info, Caption, Audio)
              Positioned(
                bottom: 20,
                left: 16,
                right: 80, // leave space for actions
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=${index + 5}'),
                        ),
                        const SizedBox(width: 10),
                        Text('user_${index + 5}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            minimumSize: const Size(60, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('Follow', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('This is a mock reel for Vistagram! Check it out #reel $index', maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.music_note, size: 16),
                        const SizedBox(width: 5),
                        Text('Original Audio - user_${index + 5}'),
                      ],
                    )
                  ],
                ),
              ),
              // Right Action Column
              Positioned(
                bottom: 20,
                right: 16,
                child: Column(
                  children: [
                    _buildActionItem(Icons.favorite_border, '12K'),
                    _buildActionItem(Icons.chat_bubble_outline, '400'),
                    _buildActionItem(Icons.send_outlined, 'Share'),
                    _buildActionItem(Icons.more_vert, ''),
                    const SizedBox(height: 10),
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage('https://i.pravatar.cc/150?img=${index + 5}'),
                          fit: BoxFit.cover,
                        )
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        children: [
          Icon(icon, size: 32),
          if (label.isNotEmpty) const SizedBox(height: 5),
          if (label.isNotEmpty) Text(label),
        ],
      ),
    );
  }
}
