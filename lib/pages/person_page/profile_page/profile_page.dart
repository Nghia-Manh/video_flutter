import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:viettech_video/Objects/accounts_user/users.dart';
import 'package:viettech_video/apis/api.dart';

class ProfilePage extends StatefulWidget {
  final Users? accounts; // null nếu là thêm mới, có giá trị nếu là edit
  final Function? onEdit; // callback để refresh list
  const ProfilePage({super.key, required this.accounts, required this.onEdit});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Users _accounts;
  final _formKey = GlobalKey<FormState>();
  File? _avatarImage; // Ảnh đại diện
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  bool _autoValidate = false;

  bool _hasChanges = false; // Thêm biến theo dõi thay đổi
  late Map<String, dynamic> _originalData;

  // Hàm chọn ảnh đại diện
  Future<void> _pickAvatarImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        // Cập nhật UI trước
        setState(() {
          _avatarImage = File(pickedFile.path);
        });

        // Sau đó gọi API
        try {
          await API.Account_ChangeAvatar.call(file: _avatarImage);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thay đổi ảnh đại diện thành công'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (apiError) {
          print('Lỗi API: $apiError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi khi cập nhật ảnh: ${apiError.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Lỗi khi chọn ảnh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDatetime(String rawDate) {
    try {
      rawDate = rawDate.replaceAll("Z", "").replaceAll("+0000", "");
      DateTime parsedDate = DateTime.parse(rawDate);
      if (parsedDate.year <= 1) {
        return 'Chưa xác định';
      }
      return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
    } catch (e) {
      print("Lỗi khi chuyển đổi ngày: $e");
      return 'N/A';
    }
  }

  Future<void> _selectBirthday(BuildContext context) async {
    DateTime? _selectedDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdayController.text =
            '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Nếu là edit thì fill data vào form
    _nameController.text = widget.accounts?.fullName ?? '';
    _emailController.text = widget.accounts?.email ?? '';
    _phoneController.text = widget.accounts?.phone ?? '';
    _addressController.text = widget.accounts?.address ?? '';
    _birthdayController.text =
        (widget.accounts?.birthDay != null &&
            widget.accounts!.birthDay!.year > 1)
        ? _formatDatetime(widget.accounts!.birthDay!.toLocal().toString())
        : '';

    _accounts = Users.fromJson(widget.accounts?.toJson() ?? {});

    _originalData = _getCurrentFormData();

    _nameController.addListener(_checkForChanges);
    _addressController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
  }

  void _saveAccount() async {
    setState(() {
      _autoValidate = true;
    });

    if (_formKey.currentState!.validate()) {
      try {
        _accounts.fullName = _nameController.text;
        _accounts.phone = _phoneController.text;
        _accounts.email = _emailController.text;
        DateFormat format = DateFormat("dd/MM/yyyy");
        DateTime localBirthday = format.parse(_birthdayController.text);
        _accounts.birthDay = DateTime(
          localBirthday.year,
          localBirthday.month,
          localBirthday.day,
        );
        await API.Account_Edit.call(params: _accounts.toJson());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật tài khoản thành công')),
          );
        }

        widget.onEdit?.call();
        Get.back();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception:', '')),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  ImageProvider _getImageProvider() {
    try {
      if (_avatarImage != null) {
        return FileImage(_avatarImage!);
      }
      if (_accounts.avatar != null && _accounts.avatar!.isNotEmpty) {
        if (_accounts.avatar!.startsWith('assets')) {
          return AssetImage(_accounts.avatar!);
        }
        if (_accounts.avatar!.startsWith('http')) {
          return NetworkImage(_accounts.avatar!);
        }
        String imageUrl = _accounts.avatar!;
        imageUrl = 'http://demo.quanlynoibo.com:8123/Avatars/$imageUrl';
        return NetworkImage(imageUrl);
      }
      return AssetImage('assets/images/user.png');
    } catch (e) {
      print('Lỗi load ảnh: $e');
      return const AssetImage('assets/images/user.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Color(
                0xFF768CEB,
              ), // Đặt màu nền cho thanh trạng thái
              statusBarIconBrightness:
                  Brightness.light, // Màu biểu tượng: trắng
            ),
            title: Text(
              'Thông tin cá nhân',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF768CEB),
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: _handleBack,
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              autovalidateMode: _autoValidate
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Ảnh đại diện
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return SafeArea(
                            child: Wrap(
                              children: <Widget>[
                                if (_avatarImage != null ||
                                    (_accounts.avatar != null &&
                                        _accounts.avatar!.isNotEmpty))
                                  ListTile(
                                    leading: const Icon(Icons.image),
                                    title: const Text('Xem ảnh'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Scaffold(
                                            appBar: AppBar(
                                              backgroundColor: Colors.black,
                                              leading: IconButton(
                                                icon: Icon(
                                                  Icons.arrow_back,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                            ),
                                            backgroundColor: Colors.black,
                                            body: Center(
                                              child: InteractiveViewer(
                                                minScale: 0.5,
                                                maxScale: 4.0,
                                                child: Image(
                                                  image: _getImageProvider(),
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Chọn ảnh đại diện'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickAvatarImage();
                                  },
                                ),
                                if (_avatarImage != null ||
                                    (_accounts.avatar != null &&
                                        _accounts.avatar!.isNotEmpty))
                                  ListTile(
                                    leading: const Icon(Icons.delete),
                                    title: const Text('Xóa ảnh'),
                                    onTap: () {
                                      setState(() {
                                        _avatarImage = null;
                                        _accounts.avatar = null;
                                        _getImageProvider();
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(
                              0,
                              3,
                            ), // changes position of shadow
                          ),
                        ],
                      ),
                      child: (_avatarImage != null || _accounts.avatar != null)
                          ? CircleAvatar(
                              radius: 60,
                              backgroundImage: _getImageProvider(),
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.camera_alt,
                                size: 30,
                                color: Colors.grey,
                              ),
                            )
                          : CircleAvatar(
                              radius: 60,
                              backgroundColor: const Color(
                                0xFF768CEB,
                              ).withOpacity(0.7),
                              child: Text(
                                (_accounts.fullName != null &&
                                        _accounts.fullName!.isNotEmpty)
                                    ? _accounts.fullName![0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Họ tên'),
                          Text(' *', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập họ tên';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _birthdayController,
                    decoration: InputDecoration(
                      labelText: 'Ngày sinh',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_month_outlined),
                        onPressed: () => _selectBirthday(context),
                      ),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng chọn ngày sinh';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Số điện thoại'),
                          Text(' *', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      prefixIcon: Icon(Icons.phone_rounded),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }
                      if (!RegExp(r"^0[1-9]\d{8}$").hasMatch(value)) {
                        return 'Số điện thoại không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Text('Email')],
                      ),
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return null;
                      }
                      final RegExp emailRegex = RegExp(
                        r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
                      );
                      if (!emailRegex.hasMatch((value ?? '').trim())) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff559955),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'CẬP NHẬT',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _nameController.removeListener(_checkForChanges);
    _addressController.removeListener(_checkForChanges);
    _phoneController.removeListener(_checkForChanges);
    _emailController.removeListener(_checkForChanges);
    super.dispose();
  }

  void _checkForChanges() {
    final currentData = _getCurrentFormData();
    if (!_hasChanges && !_mapEquals(currentData, _originalData)) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Map<String, dynamic> _getCurrentFormData() {
    return {
      'name': _nameController.text,
      'address': _addressController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
    };
  }

  bool _mapEquals(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final v1 = a[key];
      final v2 = b[key];
      if (v1 is List && v2 is List) {
        if (!_listEquals(v1, v2)) return false;
      } else if (v1 != v2) {
        return false;
      }
    }
    return true;
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] is Map && b[i] is Map) {
        if (!_mapEquals(a[i], b[i])) return false;
      } else if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Xác nhận'),
          content: Text(
            'Bạn có chắc chắn muốn quay lại? Các thay đổi sẽ không được lưu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('HỦY'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('ĐỒNG Ý', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  void _handleBack() async {
    if (_hasChanges) {
      final shouldPop = await _onWillPop();
      if (shouldPop) {
        Get.back();
      }
    } else {
      Get.back();
    }
  }
}
