import 'package:flutter/material.dart';

class PhotoViewer extends StatelessWidget {
  final String url;
  final String heroTag;
  const PhotoViewer({super.key, required this.url, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
