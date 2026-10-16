import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/fancy.dart';
import 'deck_list_page.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

/// Hosts the four pages and the floating bottom bar:
/// [Profile] [Add] [Home] [Decks] [Settings]
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Page indexes: 0 = profile, 1 = home, 2 = decks, 3 = settings
  int _page = 1;

  Future<void> _createDeck() async {
    final r = await showItemDialog(
      context,
      title: 'New deck',
      label1: 'Deck title',
      label2: 'Description',
    );
    if (r == null || !mounted) return;
    context.read<AppState>().addDeck(r.title, r.body, image: r.image);
    setState(() => _page = 2); // jump to the deck list to see it
  }

  Widget _buildPage() {
    switch (_page) {
      case 0:
        return const ProfilePage();
      case 2:
        return const DeckListPage();
      case 3:
        return const SettingsPage();
      default:
        return HomePage(
          onSeeAllDecks: () => setState(() => _page = 2),
          onNewDeck: _createDeck,
          onOpenProfile: () => setState(() => _page = 0),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      // Pages fade and slide in when you switch tabs.
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_page), child: _buildPage()),
      ),
      bottomNavigationBar: _BottomBar(
        page: _page,
        onSelect: (i) => setState(() => _page = i),
        onAdd: _createDeck,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int page;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  const _BottomBar({
    required this.page,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SizedBox(
          height: 88,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // the bar itself
              Container(
                height: 66,
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(33),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withAlpha(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 110 : 24),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(
                      Icons.person_rounded,
                      page == 0,
                      () => onSelect(0),
                      'Profile',
                    ),
                    _NavItem(
                      Icons.add_circle_rounded,
                      false,
                      onAdd,
                      'New deck',
                    ),
                    const SizedBox(
                      width: 60,
                    ), // room for the raised home button
                    _NavItem(
                      Icons.view_list_rounded,
                      page == 2,
                      () => onSelect(2),
                      'Decks',
                    ),
                    _NavItem(
                      Icons.settings_rounded,
                      page == 3,
                      () => onSelect(3),
                      'Settings',
                    ),
                  ],
                ),
              ),
              // raised centre home button
              Align(
                alignment: Alignment.topCenter,
                child: Bounce(
                  scale: 0.88,
                  child: GestureDetector(
                    onTap: () => onSelect(1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      width: page == 1 ? 64 : 58,
                      height: page == 1 ? 64 : 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [palette.blueLight, palette.blue],
                        ),
                        border: Border.all(color: palette.bgBottom, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: palette.blue.withAlpha(page == 1 ? 170 : 90),
                            blurRadius: page == 1 ? 22 : 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String tooltip;
  const _NavItem(this.icon, this.selected, this.onTap, this.tooltip);

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Tooltip(
      message: tooltip,
      child: Bounce(
        scale: 0.8,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: selected ? 1.2 : 1,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    icon,
                    size: 26,
                    color: selected ? palette.blueLight : palette.muted,
                  ),
                ),
                const SizedBox(height: 4),
                // small dot under the selected icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: selected ? 6 : 0,
                  height: selected ? 6 : 0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.cyan,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
