import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carros_mik_dundee/features/missions/domain/entities/mission.dart';
import 'package:carros_mik_dundee/shared/lib/format_request_for_whatsapp.dart';

class WhatsAppShareButton extends StatelessWidget {
  final Mission mission;

  const WhatsAppShareButton({super.key, required this.mission});

  Future<void> _share(BuildContext context) async {
    final text = formatRequestForWhatsApp(mission);
    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copiado! Cole no WhatsApp'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _share(context),
      icon: const _WhatsAppIcon(size: 18),
      label: const Text('Compartilhar no WhatsApp'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        foregroundColor: const Color(0xFF25D366),
        side: const BorderSide(color: Color(0xFF25D366), width: 1),
      ),
    );
  }
}

class _WhatsAppIcon extends StatelessWidget {
  final double size;
  const _WhatsAppIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _WhatsAppPainter()),
    );
  }
}

class _WhatsAppPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF25D366)
      ..style = PaintingStyle.fill;

    final path = Path();
    final s = size.width / 24.0;

    path.moveTo(17.472 * s, 14.382 * s);
    path.cubicTo(17.175 * s, 14.233 * s, 15.714 * s, 13.515 * s, 15.442 * s, 13.415 * s);
    path.cubicTo(15.169 * s, 13.316 * s, 14.971 * s, 13.267 * s, 14.772 * s, 13.565 * s);
    path.cubicTo(14.575 * s, 13.862 * s, 14.005 * s, 14.531 * s, 13.832 * s, 14.729 * s);
    path.cubicTo(13.659 * s, 14.928 * s, 13.485 * s, 14.952 * s, 13.188 * s, 14.804 * s);
    path.cubicTo(12.891 * s, 14.654 * s, 11.933 * s, 14.341 * s, 10.798 * s, 13.329 * s);
    path.cubicTo(9.915 * s, 12.541 * s, 9.318 * s, 11.568 * s, 9.145 * s, 11.27 * s);
    path.cubicTo(8.972 * s, 10.973 * s, 9.127 * s, 10.812 * s, 9.275 * s, 10.664 * s);
    path.cubicTo(9.409 * s, 10.531 * s, 9.573 * s, 10.317 * s, 9.721 * s, 10.144 * s);
    path.cubicTo(9.87 * s, 9.97 * s, 9.919 * s, 9.846 * s, 10.019 * s, 9.647 * s);
    path.cubicTo(10.118 * s, 9.449 * s, 10.069 * s, 9.276 * s, 9.994 * s, 9.127 * s);
    path.cubicTo(9.919 * s, 8.978 * s, 9.325 * s, 7.515 * s, 9.078 * s, 6.92 * s);
    path.cubicTo(8.836 * s, 6.341 * s, 8.591 * s, 6.42 * s, 8.409 * s, 6.41 * s);
    path.cubicTo(8.236 * s, 6.402 * s, 8.038 * s, 6.4 * s, 7.839 * s, 6.4 * s);
    path.cubicTo(7.641 * s, 6.4 * s, 7.319 * s, 6.474 * s, 7.047 * s, 6.772 * s);
    path.cubicTo(6.775 * s, 7.069 * s, 6.007 * s, 7.788 * s, 6.007 * s, 9.251 * s);
    path.cubicTo(6.007 * s, 10.713 * s, 7.072 * s, 12.126 * s, 7.22 * s, 12.325 * s);
    path.cubicTo(7.369 * s, 12.523 * s, 9.316 * s, 15.525 * s, 12.297 * s, 16.812 * s);
    path.cubicTo(13.006 * s, 17.118 * s, 13.559 * s, 17.301 * s, 13.991 * s, 17.437 * s);
    path.cubicTo(14.703 * s, 17.664 * s, 15.351 * s, 17.632 * s, 15.862 * s, 17.555 * s);
    path.cubicTo(16.433 * s, 17.47 * s, 17.62 * s, 16.836 * s, 17.868 * s, 16.142 * s);
    path.cubicTo(18.116 * s, 15.448 * s, 18.116 * s, 14.853 * s, 18.041 * s, 14.729 * s);
    path.cubicTo(17.967 * s, 14.605 * s, 17.769 * s, 14.531 * s, 17.472 * s, 14.382 * s);
    path.close();

    path.moveTo(12.051 * s, 21.785 * s);
    path.lineTo(12.047 * s, 21.785 * s);
    path.cubicTo(10.258 * s, 21.785 * s, 8.501 * s, 21.28 * s, 8.016 * s, 20.407 * s);
    path.lineTo(7.655 * s, 20.193 * s);
    path.lineTo(3.914 * s, 21.175 * s);
    path.lineTo(4.912 * s, 17.527 * s);
    path.lineTo(4.677 * s, 17.153 * s);
    path.cubicTo(3.671 * s, 15.394 * s, 3.167 * s, 13.391 * s, 3.168 * s, 11.893 * s);
    path.cubicTo(3.169 * s, 6.443 * s, 7.604 * s, 2.009 * s, 13.056 * s, 2.009 * s);
    path.cubicTo(15.696 * s, 2.009 * s, 18.178 * s, 3.039 * s, 20.044 * s, 4.907 * s);
    path.cubicTo(21.91 * s, 6.775 * s, 22.937 * s, 9.259 * s, 22.936 * s, 11.903 * s);
    path.cubicTo(22.933 * s, 17.353 * s, 18.499 * s, 21.785 * s, 13.051 * s, 21.785 * s);
    path.lineTo(12.051 * s, 21.785 * s);
    path.close();

    path.moveTo(20.464 * s, 3.488 * s);
    path.cubicTo(18.222 * s, 1.243 * s, 15.241 * s, 0 * s, 12.05 * s, 0 * s);
    path.cubicTo(5.495 * s, 0 * s, 0.16 * s, 5.335 * s, 0.157 * s, 11.892 * s);
    path.cubicTo(0.157 * s, 13.988 * s, 0.704 * s, 16.034 * s, 1.745 * s, 17.837 * s);
    path.lineTo(0.057 * s, 24 * s);
    path.lineTo(6.362 * s, 22.346 * s);
    path.cubicTo(8.098 * s, 23.293 * s, 10.055 * s, 23.794 * s, 12.045 * s, 23.794 * s);
    path.lineTo(12.05 * s, 23.794 * s);
    path.cubicTo(18.604 * s, 23.794 * s, 23.94 * s, 18.459 * s, 23.943 * s, 11.893 * s);
    path.cubicTo(23.943 * s, 8.699 * s, 22.706 * s, 5.733 * s, 20.464 * s, 3.488 * s);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
