import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';

/// Global reusable cached image widget with loading and error states
class CachedImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Color? errorColor;
  final Widget? errorChild;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.errorColor,
    this.errorChild,
  });

  Widget _buildPlaceholder({Color? color, Widget? child}) => CachedImagePlaceholder(width: width, height: height, color: color, child: child);

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        placeholder: placeholder ?? (context, url) => _buildPlaceholder(child: MyLoader()),
        errorWidget: errorWidget ?? (context, url, error) => _buildPlaceholder(color: errorColor, child: errorChild),
      );
    } else {
      return errorWidget != null 
          ? errorWidget!(context, '', null)
          : _buildPlaceholder(color: errorColor, child: errorChild);
    }
  }
}

class CachedImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final Widget? child;

  const CachedImagePlaceholder({super.key, this.width, this.height, this.color, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color ?? Theme.of(context).colorScheme.outline,
      child: child ?? const Icon(
        Icons.image_not_supported,
        size: 50,
        color: Colors.grey,
      ),
    );
  }
}
