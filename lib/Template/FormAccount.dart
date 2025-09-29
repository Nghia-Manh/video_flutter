import 'dart:io';
import 'package:flutter/material.dart';

class FormAccount extends StatefulWidget {
  final String? title;
  final String? hintText;
  final Widget? entry;
  final Function()? ontab;

  const FormAccount({
    super.key,
    this.title,
    this.hintText,
    this.entry,
    this.ontab,
  });

  @override
  _FormAccountState createState() => _FormAccountState();
}

class _FormAccountState extends State<FormAccount> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 5, right: 5),
      margin: EdgeInsets.only(top: 5),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFebeced), width: 1.0),
          ),
        ),
        child: GestureDetector(
          onTap: () {
            if (widget.ontab != null) widget.ontab!();
          },
          child: Row(
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(top: 15, bottom: 15),
                child: Text(
                  widget.title ?? "",
                  style: TextStyle(
                    color: Color.fromARGB(255, 93, 116, 215),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child:
                    widget.entry ??
                    Container(
                      child: Text(
                        widget.hintText ?? "",
                        style: TextStyle(
                          color: Color.fromARGB(255, 136, 155, 240),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
              ),
              SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class FormAvatar extends StatefulWidget {
  final String image;
  final String title;
  final Function? onTap;

  const FormAvatar({
    super.key,
    required this.image,
    required this.title,
    this.onTap,
  });

  @override
  _FormAvatarState createState() => _FormAvatarState();
}

class _FormAvatarState extends State<FormAvatar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 5, right: 5),
      margin: EdgeInsets.only(top: 5),
      child: Container(
        padding: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFebeced), width: 1.0),
          ),
        ),
        child: InkWell(
          onTap: () {
            if (widget.onTap != null) widget.onTap!();
          },
          child: GestureDetector(
            child: Row(
              children: <Widget>[
                (widget.image != 'assets/images/user.png')
                    ? Container(
                        width: 45.0,
                        height: 45.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50.0),
                          image: DecorationImage(
                            image: widget.image.startsWith('http')
                                ? NetworkImage(widget.image)
                                : widget.image.startsWith('assets')
                                ? AssetImage(widget.image)
                                : FileImage(File(widget.image))
                                      as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 22.5,
                        backgroundColor: Color(0xFF768CEB).withOpacity(0.7),
                        child: Text(
                          widget.title.isNotEmpty
                              ? widget.title[0].toUpperCase()
                              : '',
                          style: TextStyle(fontSize: 22, color: Colors.white),
                        ),
                      ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.only(top: 15, bottom: 15),
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: Color.fromARGB(255, 93, 116, 215),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color.fromARGB(255, 93, 116, 215),
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
