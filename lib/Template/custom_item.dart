import 'dart:io';
import 'package:flutter/material.dart';

class CustomItem extends StatelessWidget {
  final IconData icon;
  final String image;
  final String title;
  final String subtitle;
  final bool hasIcon1;
  final bool hasImage;
  final bool hassub;
  final bool hasIcon2;
  final bool hasBorder;
  final Color? colorImage;
  final Color? colorIcon;
  final Function? onTap;

  const CustomItem({
    Key? key,
    required this.icon,
    required this.image,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.hasIcon1 = false,
    this.hasImage = false,
    this.hassub = false,
    this.hasIcon2 = false,
    this.hasBorder = false,
    this.colorImage,
    this.colorIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap?.call();
      },
      child: Container(
        color: Colors.white,
        child: Row(
          children: [
            if (hasIcon1)
              Container(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    Icon(icon,
                        size: 30.0, color: colorIcon ?? Colors.blueAccent),
                  ],
                ),
              ),
            if (hasImage)
              Container(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          colorFilter: ColorFilter.mode(
                            colorImage ?? Colors.blueAccent,
                            BlendMode.srcIn,
                          ),
                          image: image.startsWith('http')
                              ? NetworkImage(image)
                              : image.startsWith('assets')
                                  ? AssetImage(image)
                                  : FileImage(File(image)) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(0.0, 13.0, 10.0, 10.0),
                decoration: BoxDecoration(
                  border: hasBorder
                      ? const Border(
                          bottom: BorderSide(
                            color: Color.fromARGB(255, 239, 239, 239),
                            width: 1.0,
                          ),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                fontSize: 18.0,
                                overflow: TextOverflow.ellipsis,
                              )),
                          SizedBox(height: 5.0),
                          if (hassub)
                            Text(subtitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w200,
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 13.0,
                                )),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.0),
                    if (hasIcon2)
                      IconButton(
                        icon: const Icon(Icons.navigate_next),
                        tooltip: 'Navigate Next Icon',
                        iconSize: 25.0,
                        color: const Color.fromARGB(255, 159, 159, 159),
                        onPressed: () {
                          onTap?.call();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
