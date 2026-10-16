import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_themes.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/fancy.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final name = state.user?.displayName ?? '';
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return GradientScaffold(
      useGradient: false,
      title: const Text('Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          DepthCard(
            entranceIndex: 0,
            gradient: [palette.blueLight, palette.blue, palette.purple],
            child: Row(
              children: [
                UserAvatar(name: name, radius: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '@${state.user?.username ?? ''}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Preferences',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          DepthCard(
            entranceIndex: 1,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String>(
              initialValue: state.themeId,
              decoration: const InputDecoration(
                labelText: 'App theme',
                border: InputBorder.none,
              ),
              items: [
                for (final option in AppThemes.all)
                  DropdownMenuItem(
                    value: option.id,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: option.palette.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(option.name),
                        Icon(
                          option.brightness == Brightness.dark
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) context.read<AppState>().setTheme(value);
              },
            ),
          ),
          const SizedBox(height: 20),
          DepthCard(
            entranceIndex: 2,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                _Row(
                  icon: Icons.logout_rounded,
                  color: palette.cyan,
                  title: 'Log out',
                  subtitle: 'Sign out of this account',
                  onTap: () => context.read<AppState>().logout(),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _Row(
                  icon: Icons.delete_forever_rounded,
                  color: palette.pink,
                  title: 'Delete account',
                  subtitle: 'Permanently removes your account, decks and cards',
                  onTap: () async {
                    final ok = await confirmDialog(
                      context,
                      title: 'Delete account?',
                      message:
                          'This permanently deletes your account and all of your decks and cards.',
                      action: 'Delete account',
                    );
                    if (ok && context.mounted) {
                      context.read<AppState>().deleteAccount();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return ListTile(
      leading: IconChip(icon: icon, color: color, size: 42),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: palette.muted, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: palette.muted),
      onTap: onTap,
    );
  }
}
