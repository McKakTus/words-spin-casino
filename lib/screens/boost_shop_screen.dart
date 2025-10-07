import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/boost_catalog.dart';
import '../helpers/image_paths.dart';
import '../models/player_progress.dart';
import '../providers/player_progress_provider.dart';

class BoostShopScreen extends ConsumerStatefulWidget {
  const BoostShopScreen({super.key});

  static const routeName = '/boost-shop';

  @override
  ConsumerState<BoostShopScreen> createState() => _BoostShopScreenState();
}

class _BoostShopScreenState extends ConsumerState<BoostShopScreen> {
  final Set<BoostType> _pendingPurchases = <BoostType>{};

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(playerProgressProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(Images.background, fit: BoxFit.cover),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(color: Colors.black.withAlpha(54)),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Boost Shop',
              style: TextStyle(fontSize: 24),
            ),
          ),
          body: progressAsync.when(
            data: (progress) {
              return _buildContent(context, progress);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                error.toString(),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, PlayerProgress progress) {
    final boosts = BoostCatalog.all();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xCC1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_rounded, color: Color(0xFFFFAF28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chips Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress.chips.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFAF28),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _showPricingHelp(context),
                  child: const Text('Pricing Guide'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...boosts.map((info) {
            final price = BoostCatalog.price(info.type);
            final owned = progress.boostInventory[info.type] ?? 0;
            final bool canAfford = progress.chips >= price;
            final bool isPending = _pendingPurchases.contains(info.type);
            final bool enabled = canAfford && !isPending;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _BoostShopTile(
                info: info,
                price: price,
                owned: owned,
                enabled: enabled,
                busy: isPending,
                onTap: enabled ? () => _handlePurchase(info.type, price) : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(BoostType type, int price) async {
    setState(() => _pendingPurchases.add(type));
    final success = await ref.read(playerProgressProvider.notifier)
        .purchaseBoost(type, priceOverride: price);
    if (!mounted) return;
    setState(() => _pendingPurchases.remove(type));

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (success) {
      messenger.showSnackBar(
        SnackBar(content: Text('Purchased ${BoostCatalog.info(type).label}!')), 
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('Not enough chips for ${BoostCatalog.info(type).label}.')),
      );
    }
  }

  void _showPricingHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('How we price boosts'),
          content: const Text(
            'Boost prices scale with their impact. Utility boosts like Shuffle cost the least, '
            'while protection boosts such as Shield command the highest price. Time Freeze sits '
            'between them because it preserves both the timer and burning tiles.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}

class _BoostShopTile extends StatelessWidget {
  const _BoostShopTile({
    required this.info,
    required this.price,
    required this.owned,
    required this.enabled,
    required this.busy,
    this.onTap,
  });

  final BoostInfo info;
  final int price;
  final int owned;
  final bool enabled;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = info.accent;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: enabled ? accent : Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: accent.withValues(alpha: 0.2),
            child: Icon(info.icon, color: accent, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  info.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.savings_rounded,
                        size: 18, color: enabled ? accent : Colors.white38),
                    const SizedBox(width: 6),
                    Text(
                      price.toString(),
                      style: TextStyle(
                        color: enabled ? Colors.white : Colors.white38,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Owned: $owned',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: enabled ? onTap : null,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black),
                  )
                : const Text(
                    'Buy',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
          ),
        ],
      ),
    );
  }
}
