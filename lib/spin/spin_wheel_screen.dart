import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/equb_service.dart';

class SpinWheelScreen extends StatefulWidget {
  final String equbId;
  const SpinWheelScreen({super.key, required this.equbId});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late final EqubService _equbService;
  late final AnimationController _controller;
  Animation<double>? _animation;

  double _currentAngle = 0.0;
  bool _isSpinning = false;
  int? _winnerIndex;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _memberDocs = const [];
  Set<String> _winnerUids = const {};
  bool _isOwner = false;
  String? _winnerName;

  @override
  void initState() {
    super.initState();
    _equbService = EqubService();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _checkOwnership();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkOwnership() async {
    final isOwner = await _equbService.isOwner(widget.equbId);
    setState(() {
      _isOwner = isOwner;
    });
  }

  Future<void> _spin() async {
    // Restrict spinning to owner only
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the group owner can spin the wheel'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_isSpinning || _memberDocs.isEmpty) return;
    setState(() {
      _isSpinning = true;
      _winnerIndex = null;
    });

    final segments = _memberDocs.length;
    final random = math.Random();
    final winnerIndex = random.nextInt(segments);
    // Calculate end angle so the selected segment lands at the top indicator
    final segmentAngle = 2 * math.pi / segments;
    // Center of the winning segment relative to 12 o'clock indicator
    final targetSegmentCenterFromTop = (segments - winnerIndex - 0.5) * segmentAngle;
    final extraSpins = 6 + random.nextInt(4); // 6-9 full spins
    final targetAngle = _currentAngle + extraSpins * 2 * math.pi + targetSegmentCenterFromTop;

    _animation = Tween<double>(begin: _currentAngle, end: targetAngle)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart))
      ..addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          _currentAngle = targetAngle % (2 * math.pi);
          final winnerDoc = _memberDocs[winnerIndex];
          final winnerData = winnerDoc.data();
          final name = winnerData['name'] ?? winnerData['email'] ?? winnerDoc.id;
          setState(() {
            _isSpinning = false;
            _winnerIndex = winnerIndex;
            _winnerName = name;
          });
          // Persist result
          await _equbService.saveSpinResult(
            equbId: widget.equbId,
            winnerUid: winnerDoc.id,
            winnerData: winnerData,
          );
        }
      })
      ..addListener(() {
        setState(() {});
      });

    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spin Wheel'),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _equbService.streamMembers(widget.equbId),
            builder: (context, membersSnap) {
              final allMembers = membersSnap.data?.docs ?? [];
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _equbService.streamSpins(widget.equbId),
                builder: (context, spinsSnap) {
                  final spins = spinsSnap.data?.docs ?? [];
                  _winnerUids = spins
                      .map((s) => (s.data()['winnerUid'] as String?) ?? '')
                      .where((id) => id.isNotEmpty)
                      .toSet();

                  final eligible = allMembers.where((m) => !_winnerUids.contains(m.id)).toList(growable: false);
                  _memberDocs = eligible;
                  final names = eligible
                      .map((d) => (d.data()['name'] ?? d.data()['email'] ?? d.id).toString())
                      .toList(growable: false);

                  return Column(
                    children: [
                      const SizedBox(height: 24),
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Wheel
                            Transform.rotate(
                              angle: _animation?.value ?? _currentAngle,
                              child: CustomPaint(
                                size: const Size(320, 320),
                                painter: _WheelPainter(segmentCount: names.length),
                              ),
                            ),
                            // Center hub
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: _isSpinning
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.casino_outlined),
                            ),
                            // Top indicator
                            Positioned(
                              top: 0,
                              child: CustomPaint(
                                size: const Size(24, 24),
                                painter: _IndicatorPainter(color: theme.colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
              const SizedBox(height: 24),
              if (_isOwner)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: names.isEmpty || _isSpinning ? null : _spin,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Spin'),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: theme.colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Only the group owner can spin the wheel',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (names.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'All members have already won. No eligible members left.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: names.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final isWinner = index == _winnerIndex;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(names[index]),
                      trailing: isWinner ? const Icon(Icons.emoji_events, color: Colors.amber) : null,
                    );
                  },
                ),
              ),
            ],
          );
            },
          );
        },
      ),
          // Winner announcement overlay
          if (_isSpinning)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.casino,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Spinning...',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else if (_winnerName != null)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Card(
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 64,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Winner!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _winnerName!,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _winnerName = null;
                          });
                        },
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final int segmentCount;
  _WheelPainter({required this.segmentCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final anglePerSegment = 2 * math.pi / (segmentCount == 0 ? 1 : segmentCount);
    final colors = <Color>[
      const Color(0xFFEF5350),
      const Color(0xFFAB47BC),
      const Color(0xFF5C6BC0),
      const Color(0xFF29B6F6),
      const Color(0xFF66BB6A),
      const Color(0xFFFFCA28),
      const Color(0xFFFF7043),
    ];

    for (int i = 0; i < (segmentCount == 0 ? 1 : segmentCount); i++) {
      paint.color = colors[i % colors.length];
      final startAngle = i * anglePerSegment;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, startAngle, anglePerSegment, true, paint);
    }

    // Outer ring
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.white;
    canvas.drawCircle(center, radius, ring);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => oldDelegate.segmentCount != segmentCount;
}

class _IndicatorPainter extends CustomPainter {
  final Color color;
  _IndicatorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _IndicatorPainter oldDelegate) => oldDelegate.color != color;
}


