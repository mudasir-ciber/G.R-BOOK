import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Reusable top bar for internal screens matching Screens 4, 5, 6, 7, 8, 9, 10.
class GrBookTopBar extends StatelessWidget implements PreferredSizeWidget {
  const GrBookTopBar({
    super.key,
    this.showBack = true,
    this.onBack,
    this.leadingIcon,
    this.onLeadingPressed,
    this.trailing,
  });

  final bool showBack;
  final VoidCallback? onBack;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingPressed;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Left circular button
            if (leadingIcon != null)
              _CircleButton(
                icon: leadingIcon!,
                onPressed: onLeadingPressed,
              )
            else if (showBack)
              _CircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            else
              const SizedBox(width: 40),

            // Center branding: Book logo + "G.R. Book"
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/book_logo.png',
                      height: 24,
                      width: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.menu_book_rounded,
                        color: GrBookTheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'G.R. Book',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: GrBookTheme.primaryDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Right trailing action or spacer
            if (trailing != null) trailing! else const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: GrBookTheme.borderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: GrBookTheme.primary, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}

/// Screen title and subtitle matching reference designs.
class GrBookPageHeader extends StatelessWidget {
  const GrBookPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: crossAxisAlignment,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: GrBookTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: GrBookTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Gradient primary pill button matching reference designs ("Login →", "Save & Continue →", etc.)
class GrBookGradientButton extends StatelessWidget {
  const GrBookGradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon = Icons.arrow_forward_rounded,
    this.height = 52,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final IconData? trailingIcon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? null
            : GrBookTheme.primaryButtonGradient,
        color: onPressed == null ? Colors.grey.shade400 : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed == null
            ? null
            : const [
                BoxShadow(
                  color: Color(0x330F7A42),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 8),
                        Icon(trailingIcon, color: Colors.white, size: 18),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Outlined button matching reference designs ("Create New Account", "← Back to Login", "Promote")
class GrBookOutlinedButton extends StatelessWidget {
  const GrBookOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.height = 50,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: GrBookTheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: GrBookTheme.primary, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: GrBookTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular green icon badge for list tiles (Class item, Pass Out cap, Settings items)
class GrBookIconBadge extends StatelessWidget {
  const GrBookIconBadge({
    super.key,
    required this.icon,
    this.size = 46,
    this.iconSize = 24,
    this.backgroundColor,
    this.iconColor,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? GrBookTheme.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor ?? GrBookTheme.primary,
        ),
      ),
    );
  }
}
