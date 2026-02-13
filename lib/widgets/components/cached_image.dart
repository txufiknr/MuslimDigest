import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Global reusable cached image widget with loading and error states
class CachedImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        placeholder: placeholder ?? (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
        ),
        errorWidget: errorWidget ?? (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.grey,
          ),
        ),
      );
    } else {
      return errorWidget != null 
          ? errorWidget!(context, '', null)
          : Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Icon(
                Icons.article,
                size: 50,
                color: Colors.grey,
              ),
            );
    }
  }
}
