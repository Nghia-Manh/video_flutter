import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:viettech_video/Objects/GroupPermission/groupPermission.dart';
import 'package:viettech_video/Objects/accounts_user/users.dart';
import 'package:viettech_video/Template/search_field.dart';
import 'package:viettech_video/apis/api.dart';

class AccountDetailPage extends StatefulWidget {
  final String? userId;
  final Users? accounts; // null nếu là thêm mới, có giá trị nếu là edit
  final Function? onEdit; // callback để refresh list
  const AccountDetailPage({
    super.key,
    this.userId,
    required this.accounts,
    required this.onEdit,
  });

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  late Users _accounts;
  final _formKey = GlobalKey<FormState>();
  File? _avatarImage; // Ảnh đại diện
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  String? groupPermissionId;
  List<GroupPermission> groupPermissionList = [];
  bool _autoValidate = false;
  bool get isEditing => widget.accounts != null;

  // khai báo biến tìm kiếm nhóm quyền
  final _groupPermissionFieldKey = GlobalKey();
  final _groupPermissionSearchController = TextEditingController();
  final _groupPermissionFocusNode = FocusNode();
  Timer? _debounceGroupPermission;
  bool isSearchingGroupPermission = false;
  List<GroupPermission> _filteredGroupPermissionList = [];
  bool _showGroupPermissionEmptyMessage = false;

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

  void _loadGroupPermissions() async {
    try {
      final response = await API.GroupPermission_GetList.call();
      if (!mounted) return;
      setState(() {
        if (response != null) {
          groupPermissionList = response.toList();
          // Nếu đang thêm mới và chưa có giá trị, chọn mặc định là item đầu
          if (groupPermissionList.isNotEmpty) {
            if (widget.accounts == null) {
              groupPermissionId = groupPermissionList.first.id;
            }
            setGroupPermissionValue();
          }
        } else {
          groupPermissionList = [];
        }
      });
    } catch (e) {
      print('Lỗi khi tải danh sách quyền nhóm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải danh sách quyền nhóm'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void setGroupPermissionValue() {
    final selectedGroupPermission = groupPermissionList.firstWhereOrNull(
      (g) => g.id == groupPermissionId,
    );
    if (selectedGroupPermission != null) {
      _groupPermissionSearchController.text =
          selectedGroupPermission.description ?? '';
    }
  }

  void _searchGroupPermission(String query) {
    if (_debounceGroupPermission?.isActive ?? false)
      _debounceGroupPermission?.cancel();

    _debounceGroupPermission = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        isSearchingGroupPermission = true;
        if (query.isEmpty) {
          _filteredGroupPermissionList = groupPermissionList;
        } else {
          final queryWords = normalizeString(query.toLowerCase()).split(' ');
          _filteredGroupPermissionList = groupPermissionList.where((
            groupPermission,
          ) {
            final name = normalizeString(
              (groupPermission.description ?? '').toLowerCase(),
            );
            final searchText = name;
            return queryWords.every((word) => searchText.contains(word));
          }).toList();
        }
        isSearchingGroupPermission = false;
        _showGroupPermissionEmptyMessage = _filteredGroupPermissionList.isEmpty;
      });
    });
  }

  void _selectGroupPermission(GroupPermission groupPermission) {
    setState(() {
      groupPermissionId = groupPermission.id;
      _groupPermissionSearchController.text = groupPermission.description ?? '';
      _filteredGroupPermissionList = [];
    });
    _groupPermissionFocusNode.unfocus();
  }

  void _onGroupPermissionFocusChange() {
    if (_groupPermissionFocusNode.hasFocus) {
      setState(() {
        _filteredGroupPermissionList = groupPermissionList;
        _showGroupPermissionEmptyMessage = _filteredGroupPermissionList.isEmpty;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _groupPermissionFieldKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.1,
            duration: Duration(milliseconds: 300),
          );
        }
      });
    } else {
      if (_groupPermissionSearchController.text.isEmpty ||
          groupPermissionId != null) {
        setState(() {
          _filteredGroupPermissionList = [];
          _showGroupPermissionEmptyMessage = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Lấy danh sách quyền nhóm
    _loadGroupPermissions();
    _groupPermissionFocusNode.addListener(_onGroupPermissionFocusChange);
    // Nếu là edit thì fill data vào form
    if (isEditing) {
      _usernameController.text = widget.accounts?.id ?? '';
      _nameController.text = widget.accounts?.fullName ?? '';
      _emailController.text = widget.accounts?.email ?? '';
      _phoneController.text = widget.accounts?.phone ?? '';
      _addressController.text = widget.accounts?.address ?? '';
      groupPermissionId = widget.accounts?.groupPermissionId;
      _birthdayController.text =
          (widget.accounts?.birthDay != null &&
              widget.accounts!.birthDay!.year > 1)
          ? _formatDatetime(widget.accounts!.birthDay!.toLocal().toString())
          : '';
      _accounts = Users.fromJson(widget.accounts?.toJson() ?? {});

      _originalData = _getCurrentFormData();
    } else {
      _accounts = Users();
      _originalData = _getCurrentFormData();
    }
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
        _accounts.id = _usernameController.text;
        _accounts.groupPermissionId = groupPermissionId;
        _accounts.fullName = _nameController.text;
        _accounts.address = _addressController.text;
        _accounts.phone = _phoneController.text;
        _accounts.email = _emailController.text;
        DateFormat format = DateFormat("dd/MM/yyyy");
        DateTime localBirthday = format.parse(_birthdayController.text);
        _accounts.birthDay = DateTime(
          localBirthday.year,
          localBirthday.month,
          localBirthday.day,
        );
        if (isEditing) {
          await API.Account_Edit.call(params: _accounts.toJson());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật tài khoản thành công')),
            );
          }
        } else {
          _accounts.password = _passwordController.text;
          // Thêm mới
          await API.Account_Add.call(params: _accounts.toJson());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thêm tài khoản thành công'),
                backgroundColor: Colors.green,
              ),
            );
          }
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
              statusBarColor: Color(0xFF768CEB),
              statusBarIconBrightness: Brightness.light, // Màu biểu tượng
            ),
            title: Text(
              isEditing ? 'Chi tiết tài khoản' : 'Thêm mới tài khoản',
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
                      _accounts.avatar != null && _accounts.avatar!.isNotEmpty
                          ? showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return SafeArea(
                                  child: Wrap(
                                    children: <Widget>[
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
                                                      image:
                                                          _getImageProvider(),
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // if (isEditing)
                                      //   ListTile(
                                      //     leading: const Icon(Icons.photo_library),
                                      //     title: const Text('Chọn ảnh đại diện'),
                                      //     onTap: () {
                                      //       Navigator.pop(context);
                                      //       _pickAvatarImage();
                                      //     },
                                      //   ),
                                      // if (_avatarImage != null ||
                                      //     (_accounts.avatar != null &&
                                      //         _accounts.avatar!.isNotEmpty))
                                      //   ListTile(
                                      //     leading: const Icon(Icons.delete),
                                      //     title: const Text('Xóa ảnh'),
                                      //     onTap: () {
                                      //       setState(() {
                                      //         _avatarImage = null;
                                      //         _accounts.avatar = null;
                                      //         _getImageProvider();
                                      //       });
                                      //       Navigator.pop(context);
                                      //     },
                                      //   ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : null;
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
                  const SizedBox(height: 30),
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
                      filled: isEditing ? true : false,
                      fillColor: isEditing
                          ? const Color(0xFFEEEEEE)
                          : Colors.transparent,
                      labelStyle: isEditing
                          ? const TextStyle(color: Colors.black87)
                          : null,
                    ),
                    style: isEditing
                        ? const TextStyle(color: Colors.black)
                        : null,
                    enabled: isEditing ? false : true,
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
                      filled: isEditing ? true : false,
                      fillColor: isEditing
                          ? const Color(0xFFEEEEEE)
                          : Colors.transparent,
                      labelStyle: isEditing
                          ? const TextStyle(color: Colors.black87)
                          : null,
                    ),
                    style: isEditing
                        ? const TextStyle(color: Colors.black)
                        : null,
                    enabled: isEditing ? false : true,
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
                      filled: isEditing ? true : false,
                      fillColor: isEditing
                          ? const Color(0xFFEEEEEE)
                          : Colors.transparent,
                      labelStyle: isEditing
                          ? const TextStyle(color: Colors.black87)
                          : null,
                    ),
                    style: isEditing
                        ? const TextStyle(color: Colors.black)
                        : null,
                    enabled: isEditing ? false : true,
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
                      filled: isEditing ? true : false,
                      fillColor: isEditing
                          ? const Color(0xFFEEEEEE)
                          : Colors.transparent,
                      labelStyle: isEditing
                          ? const TextStyle(color: Colors.black87)
                          : null,
                    ),
                    style: isEditing
                        ? const TextStyle(color: Colors.black)
                        : null,
                    enabled: isEditing ? false : true,
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
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Text('Địa chỉ')],
                      ),
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      filled: isEditing ? true : false,
                      fillColor: isEditing
                          ? const Color(0xFFEEEEEE)
                          : Colors.transparent,
                      labelStyle: isEditing
                          ? const TextStyle(color: Colors.black87)
                          : null,
                    ),
                    style: isEditing
                        ? const TextStyle(color: Colors.black)
                        : null,
                    enabled: isEditing ? false : true,
                  ),
                  const SizedBox(height: 16),
                  // TextFormField(
                  //   controller: _usernameController,
                  //   decoration: InputDecoration(
                  //     label: Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         Text('Tên đăng nhập'),
                  //         Text(' *', style: TextStyle(color: Colors.red)),
                  //       ],
                  //     ),
                  //     prefixIcon: Icon(Icons.person_outline),
                  //     border: OutlineInputBorder(),
                  //     enabledBorder: OutlineInputBorder(
                  //       borderSide: BorderSide(color: Colors.grey.shade300),
                  //     ),
                  //     focusedBorder: OutlineInputBorder(
                  //       borderSide: BorderSide(color: Colors.blue.shade300),
                  //     ),
                  //     filled: isEditing ? true : false,
                  //     fillColor: isEditing
                  //         ? const Color(0xFFEEEEEE)
                  //         : Colors.transparent,
                  //     labelStyle: isEditing
                  //         ? const TextStyle(color: Colors.black87)
                  //         : null,
                  //   ),
                  //   style: isEditing
                  //       ? const TextStyle(color: Colors.black)
                  //       : null,
                  //   enabled: isEditing ? false : true,
                  //   validator: (value) {
                  //     if (value == null || value.isEmpty) {
                  //       return 'Vui lòng nhập tên đăng nhập';
                  //     }
                  //     // Kiểm tra độ dài
                  //     if (value.length < 4) {
                  //       return 'Tên tài khoản phải có ít nhất 4 ký tự';
                  //     }
                  //     if (value.length > 30) {
                  //       return 'Tên tài khoản không được vượt quá 30 ký tự';
                  //     }
                  //     // Kiểm tra chỉ cho phép chữ cái thường, số và ký tự _
                  //     if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
                  //       return 'Tên tài khoản chỉ được chứa chữ cái thường, số và ký tự _';
                  //     }
                  //     return null;
                  //   },
                  // ),
                  // if (!isEditing) ...[
                  //   const SizedBox(height: 16),
                  //   TextFormField(
                  //     controller: _passwordController,
                  //     decoration: InputDecoration(
                  //       label: Row(
                  //         mainAxisSize: MainAxisSize.min,
                  //         children: [
                  //           Text('Mật khẩu'),
                  //           Text(' *', style: TextStyle(color: Colors.red)),
                  //         ],
                  //       ),
                  //       prefixIcon: Icon(Icons.person_outline),
                  //       border: OutlineInputBorder(),
                  //       enabledBorder: OutlineInputBorder(
                  //         borderSide: BorderSide(color: Colors.grey.shade300),
                  //       ),
                  //       focusedBorder: OutlineInputBorder(
                  //         borderSide: BorderSide(color: Colors.blue.shade300),
                  //       ),
                  //     ),
                  //     validator: (value) {
                  //       if (value == null || value.isEmpty) {
                  //         return 'Vui lòng nhập mật khẩu';
                  //       }
                  //       return null;
                  //     },
                  //   ),
                  // ],
                  // const SizedBox(height: 16),
                  // Dropdown nhóm quyền
                  SearchField<GroupPermission>(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Nhóm quyền',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(' *', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    prefixIcon: Icon(
                      CupertinoIcons.check_mark,
                      color: Colors.green,
                    ),
                    controller: _groupPermissionSearchController,
                    focusNode: _groupPermissionFocusNode,
                    fieldKey: _groupPermissionFieldKey,
                    items: _filteredGroupPermissionList,
                    isLoading: isSearchingGroupPermission,
                    errorText:
                        _autoValidate &&
                            _groupPermissionSearchController.text.isEmpty
                        ? 'Vui lòng chọn nhóm quyền'
                        : null,
                    onSearch: _searchGroupPermission,
                    onSelect: _selectGroupPermission,
                    getLabel: (groupPermission) {
                      return groupPermission.description ?? '';
                    },
                    decoration: InputDecoration(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Nhóm quyền',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(' *', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      prefixIcon: const Icon(Icons.security_outlined),
                      suffixIcon: const Icon(
                        CupertinoIcons.chevron_down,
                        size: 15,
                      ),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                  ),
                  if (_showGroupPermissionEmptyMessage) ...[
                    SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Không có thông tin dữ liệu',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                        isEditing ? 'CẬP NHẬT' : 'THÊM MỚI',
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
    _birthdayController.dispose();
    _nameController.removeListener(_checkForChanges);
    _addressController.removeListener(_checkForChanges);
    _phoneController.removeListener(_checkForChanges);
    _emailController.removeListener(_checkForChanges);
    _birthdayController.removeListener(_checkForChanges);
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
      'birthday': _birthdayController.text,
      'groupPermissionId': groupPermissionId,
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
