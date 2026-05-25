import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

import '../utils/theme_colors.dart';



class RoundedCard extends StatelessWidget {

  final Widget child;

  final EdgeInsetsGeometry? padding;

  final Color? color;

  final VoidCallback? onTap;



  const RoundedCard({

    super.key,

    required this.child,

    this.padding,

    this.color,

    this.onTap,

  });



  @override

  Widget build(BuildContext context) {

    final tc = context.tc;

    final card = Container(

      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingMd),

      decoration: BoxDecoration(

        color: color ?? tc.surface,

        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),

        border: Border.all(color: tc.border),

        boxShadow: tc.softShadow,

      ),

      child: child,

    );



    if (onTap != null) {

      return Material(

        color: Colors.transparent,

        child: InkWell(

          onTap: onTap,

          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),

          child: card,

        ),

      );

    }

    return card;

  }

}


