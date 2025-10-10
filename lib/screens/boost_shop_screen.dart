import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/boost_catalog.dart';
import '../helpers/image_paths.dart';

import '../widgets/stroke_text.dart';
import '../widgets/header.dart';
import '../widgets/primary_button.dart';

import '../models/player_progress.dart';

import '../providers/player_progress_provider.dart';
import '../providers/storage_providers.dart';

import 'stats_screen.dart';

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
    final profileAsync = ref.watch(activeProfileProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(Images.background, fit: BoxFit.cover),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return progressAsync.when(
                data: (progress) => Column(
                  children: [
                    ProfileHeader(
                      userName: profile.name,
                      avatarIndex: profile.avatarIndex,
                      progress: progress,
                      onStatsTap: () =>
                          Navigator.of(context).pushNamed(StatsScreen.routeName),
                    ),
                    Expanded(child: _buildContent(context, progress)),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              );
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
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const StrokeText(
            text: 'BOOST SHOP',
            fontSize: 44,
            strokeColor: Color(0xFFD8D5EA),
            fillColor: Colors.white,
            shadowColor: Color(0xFF46557B),
            shadowBlurRadius: 2,
            height: 1.1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          const Text(
            'Spend chips on power-ups that tilt the odds in your favor.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 15,
              decoration: TextDecoration.none,
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

    final bool showBusy = busy && enabled;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Color(0xAA1F1039),
        borderRadius: BorderRadius.all(Radius.circular(24)),
        border: Border.fromBorderSide(BorderSide(color: Color(0x33FFFFFF))),
        boxShadow: [
          BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [accent.withOpacity(0.35), accent.withOpacity(0.14)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(info.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            info.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontFamily: 'Cookies',
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.24),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            'Owned: $owned',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      info.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(Images.coin, width: 28),
                              const SizedBox(width: 8),
                              Text(
                                price.toString(),
                                style: TextStyle(
                                  color: enabled ? Colors.white : Colors.white38,
                                  fontSize: 20,
                                  fontFamily: 'Cookies',
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 260,
              child: PrimaryButton(
                label: 'BUY',
                uppercase: false,
                onPressed: enabled ? onTap : null,
                busy: showBusy,
                enabled: enabled,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                backgroundColor: enabled ? Colors.transparent : Colors.white.withOpacity(0.25),
                backgroundGradient: enabled
                    ? const LinearGradient(
                        colors: [Color(0xFFAF7EE7), Color(0xFF383169), Color(0xFF272052)],
                        stops: [0.05, 0.65, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                borderColor: Colors.white54,
                shadowColor: Color(0xFFFFFFFF),
                disabledBorderColor: Colors.transparent,
                textStyle: TextStyle(
                  fontSize: 26,
                  color: enabled ? Color(0xFF383169) : Colors.white70,
                  fontFamily: 'Cookies',
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
