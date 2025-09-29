import 'dart:io';
import 'package:flutter/material.dart';

class CustomAvatar extends StatelessWidget {
  final Color color;
  final String image;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool hassub;
  final bool hasIconColor;
  final Color coloricon;
  final bool hasIcon;
  final bool hasBorder;
  final bool hasimg;
  final Function? onTap;
  final Function? onTapIcon;

  const CustomAvatar({
    Key? key,
    required this.color,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.onTapIcon,
    this.hasIconColor = false,
    required this.coloricon,
    this.hassub = false,
    this.hasIcon = false,
    this.hasBorder = false,
    this.hasimg = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      color: color,
      child: InkWell(
        onTap: () {
          onTap?.call();
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              child: Column(
                children: [
                  if (hasimg)
                    (image != 'assets/images/user.png')
                        ? Container(
                            width: 45.0,
                            height: 45.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50.0),
                              image: DecorationImage(
                                image: image.startsWith('http')
                                    ? NetworkImage(image)
                                    : image.startsWith('assets')
                                    ? AssetImage(image)
                                    : FileImage(File(image)) as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 22.5,
                            backgroundColor: Color(0xFF768CEB).withOpacity(0.7),
                            child: Text(
                              title.isNotEmpty ? title[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Container(
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
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          if (hassub)
                            Text(
                              subtitle,
                              style: const TextStyle(
                                // fontWeight: FontWeight.w200,
                                fontSize: 15.0,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (hasIcon)
                      IconButton(
                        icon: Icon(icon),
                        tooltip: 'Navigate Next Icon',
                        iconSize: 30.0,
                        color: hasIconColor
                            ? coloricon
                            : const Color.fromARGB(255, 159, 159, 159),
                        onPressed: () {
                          onTapIcon?.call();
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
