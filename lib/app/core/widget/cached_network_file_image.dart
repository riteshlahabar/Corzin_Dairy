import 'dart:io';

import 'package:flutter/material.dart';

import '../services/cached_image_file_service.dart';

class CachedNetworkFileImage extends StatefulWidget {
  const CachedNetworkFileImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.height,
    this.width,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit? fit;
  final double? height;
  final double? width;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  State<CachedNetworkFileImage> createState() => _CachedNetworkFileImageState();
}

class _CachedNetworkFileImageState extends State<CachedNetworkFileImage> {
  File? _file;
  bool _failed = false;
  String _loadedUrl = '';

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant CachedNetworkFileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _file = null;
      _failed = false;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final url = widget.imageUrl.trim();
    _loadedUrl = url;
    if (url.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    final file = await CachedImageFileService.instance.getImageFile(url);
    if (!mounted || _loadedUrl != url) return;
    setState(() {
      _file = file;
      _failed = file == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    if (file != null) {
      return Image.file(
        file,
        height: widget.height,
        width: widget.width,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    return _failed ? _fallback() : _placeholder();
  }

  Widget _placeholder() {
    return widget.placeholder ??
        SizedBox(
          height: widget.height,
          width: widget.width,
        );
  }

  Widget _fallback() {
    return widget.errorWidget ?? _placeholder();
  }
}
