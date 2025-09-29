// import 'dart:async';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class AccountFilterPage extends StatefulWidget {
//   final String? kdtId;
//   final String? toanhaId;
//   final String? tangId;
//   final bool resident;
//   final String? khudothiName;
//   final String? toanhaName;
//   final String? tangName;

//   const AccountFilterPage({
//     super.key,
//     this.kdtId,
//     this.toanhaId,
//     this.tangId,
//     this.resident = true,
//     this.khudothiName,
//     this.toanhaName,
//     this.tangName,
//   });

//   @override
//   State<AccountFilterPage> createState() => _AccountFilterPageState();
// }

// class _AccountFilterPageState extends State<AccountFilterPage> {
//   String? kdtId;
//   String? toanhaId;
//   String? tangId;
//   bool resident = true;

//   List<Khudothi> khudothi = [];
//   List<List_Toanha> listToanha = [];
//   List<Tang_Result> listTang = [];

//   // Khu đô thị search variables
//   final _khudothiFieldKey = GlobalKey();
//   final _khudothiSearchController = TextEditingController();
//   final _khudothiFocusNode = FocusNode();
//   Timer? _debounceKhudothi;
//   bool isSearchingKhudothi = false;
//   List<Khudothi> _filteredKhudothiList = [];
//   bool _showKhudothiEmptyMessage = false;

//   // Tòa nhà search variables
//   final _toanhaFieldKey = GlobalKey();
//   final _toanhaSearchController = TextEditingController();
//   final _toanhaFocusNode = FocusNode();
//   Timer? _debounceToanha;
//   bool isSearchingToanha = false;
//   List<List_Toanha> _filteredToanhaList = [];
//   bool _showToanhaEmptyMessage = false;

//   // Tầng search variables
//   final _tangFieldKey = GlobalKey();
//   final _tangSearchController = TextEditingController();
//   final _tangFocusNode = FocusNode();
//   Timer? _debounceTang;
//   bool isSearchingTang = false;
//   List<Tang_Result> _filteredTangList = [];
//   bool _showTangEmptyMessage = false;

//   @override
//   void initState() {
//     super.initState();
//     // Initialize filter IDs
//     kdtId = widget.kdtId;
//     toanhaId = widget.toanhaId;
//     tangId = widget.tangId;
//     resident = widget.resident;

//     // Initialize text controllers
//     _khudothiSearchController.text = widget.khudothiName ?? '';
//     _toanhaSearchController.text = widget.toanhaName ?? '';
//     _tangSearchController.text = widget.tangName ?? '';

//     // Load initial data
//     loadKhudothi().then((_) {
//       loadToanha().then((_) {
//         loadTang();
//       });
//     });

//     // Add focus listeners
//     _khudothiFocusNode.addListener(_onKhudothiFocusChange);
//     _toanhaFocusNode.addListener(_onToanhaFocusChange);
//     _tangFocusNode.addListener(_onTangFocusChange);
//   }

//   Future loadKhudothi() async {
//     try {
//       final response = await API.Khudothi_GetList.call();
//       setState(() {
//         if (response != null) {
//           khudothi = response.toList();
//         } else {
//           khudothi = [];
//         }
//       });
//     } catch (e) {
//       if (mounted) {
//         print('Lỗi khi tải danh sách khu đô thị: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Không thể tải danh sách khu đô thị'),
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }
//     }
//   }

//   Future loadToanha() async {
//     try {
//       if (kdtId != null) {
//         final response = await API.ToaNha_GetList.call(
//           params: {"iKDT_Id": kdtId},
//         );
//         setState(() {
//           if (response != null) {
//             listToanha = response.toList();
//           } else {
//             listToanha = [];
//           }
//         });
//       } else {
//         if (khudothi.isNotEmpty) {
//           kdtId = khudothi[0].id;
//         }
//         final response = await API.ToaNha_GetList.call(
//           params: {"iKDT_Id": kdtId},
//         );
//         setState(() {
//           if (response != null) {
//             listToanha = response.toList();
//           } else {
//             listToanha = [];
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         print('Lỗi khi tải danh sách tòa nhà: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Không thể tải danh sách tòa nhà'),
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }
//     }
//   }

//   Future loadTang() async {
//     try {
//       if (kdtId != null && toanhaId != null) {
//         final response = await API.Tang_GetList.call(
//           params: {"KDT_id": kdtId, "Toanha_id": toanhaId},
//         );
//         setState(() {
//           if (response != null) {
//             listTang = response.toList();
//           } else {
//             listTang = [];
//           }
//         });
//       } else {
//         if (kdtId == null || kdtId == '') {
//           if (khudothi.isNotEmpty) {
//             kdtId = khudothi[0].id;
//           }
//         }
//         if (toanhaId == null || toanhaId == '') {
//           if (listToanha.isNotEmpty) {
//             toanhaId = listToanha[0].id;
//           }
//         }
//         final response = await API.Tang_GetList.call(
//           params: {"KDT_id": kdtId, "Toanha_id": toanhaId},
//         );
//         setState(() {
//           if (response != null) {
//             listTang = response.toList();
//           } else {
//             listTang = [];
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         print('Lỗi khi tải danh sách tầng: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Không thể tải danh sách tầng'),
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }
//     }
//   }

//   void _searchKhudothi(String query) {
//     if (_debounceKhudothi?.isActive ?? false) _debounceKhudothi?.cancel();

//     _debounceKhudothi = Timer(const Duration(milliseconds: 500), () {
//       setState(() {
//         isSearchingKhudothi = true;
//         if (query.isEmpty) {
//           _filteredKhudothiList = khudothi;
//         } else {
//           final queryWords = normalizeString(query.toLowerCase()).split(' ');
//           _filteredKhudothiList = khudothi.where((khudothi) {
//             final name = normalizeString((khudothi.name ?? '').toLowerCase());
//             final searchText = name;
//             return queryWords.every((word) => searchText.contains(word));
//           }).toList();
//         }
//         isSearchingKhudothi = false;
//         _showKhudothiEmptyMessage = _filteredKhudothiList.isEmpty;
//       });
//     });
//   }

//   void _selectKhudothi(Khudothi khudothi) {
//     setState(() {
//       kdtId = khudothi.id;
//       _khudothiSearchController.text = khudothi.name ?? '';
//       _filteredKhudothiList = [];
//     });
//     loadToanha().then((value) {
//       if (listToanha.isNotEmpty) {
//         toanhaId = null;
//         _toanhaSearchController.text = '';
//       } else {
//         toanhaId = null;
//         _toanhaSearchController.text = '';
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Khu đô thị này chưa có tòa nhà nào!'),
//             backgroundColor: Colors.orange,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//       setState(() {});
//     });
//     _khudothiFocusNode.unfocus();
//   }

//   void _onKhudothiFocusChange() {
//     if (_khudothiFocusNode.hasFocus) {
//       setState(() {
//         _filteredKhudothiList = khudothi;
//         _showKhudothiEmptyMessage = _filteredKhudothiList.isEmpty;
//       });

//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         final context = _khudothiFieldKey.currentContext;
//         if (context != null) {
//           Scrollable.ensureVisible(
//             context,
//             alignment: 0.1,
//             duration: Duration(milliseconds: 300),
//           );
//         }
//       });
//     } else {
//       if (_khudothiSearchController.text.isEmpty || kdtId != null) {
//         setState(() {
//           _filteredKhudothiList = [];
//           _showKhudothiEmptyMessage = false;
//         });
//       }
//     }
//   }

//   void _searchToanha(String query) {
//     if (_debounceToanha?.isActive ?? false) _debounceToanha?.cancel();

//     _debounceToanha = Timer(const Duration(milliseconds: 500), () {
//       setState(() {
//         isSearchingToanha = true;
//         if (query.isEmpty) {
//           _filteredToanhaList = listToanha;
//         } else {
//           final queryWords = normalizeString(query.toLowerCase()).split(' ');
//           _filteredToanhaList = listToanha.where((toanha) {
//             final name = normalizeString((toanha.name ?? '').toLowerCase());
//             final searchText = name;
//             return queryWords.every((word) => searchText.contains(word));
//           }).toList();
//         }
//         isSearchingToanha = false;
//         _showToanhaEmptyMessage = _filteredToanhaList.isEmpty;
//       });
//     });
//   }

//   void _selectToanha(List_Toanha toanha) {
//     setState(() {
//       toanhaId = toanha.id;
//       _toanhaSearchController.text = toanha.name ?? '';
//       _filteredToanhaList = [];
//     });
//     loadTang().then((value) {
//       if (listTang.isNotEmpty) {
//         tangId = null;
//         _tangSearchController.text = '';
//       } else {
//         tangId = null;
//         _tangSearchController.text = '';
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Tòa nhà này chưa có tầng nào!'),
//             backgroundColor: Colors.orange,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//       setState(() {});
//     });
//     _toanhaFocusNode.unfocus();
//   }

//   void _onToanhaFocusChange() {
//     if (_toanhaFocusNode.hasFocus) {
//       setState(() {
//         _filteredToanhaList = listToanha;
//         _showToanhaEmptyMessage = _filteredToanhaList.isEmpty;
//       });

//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         final context = _toanhaFieldKey.currentContext;
//         if (context != null) {
//           Scrollable.ensureVisible(
//             context,
//             alignment: 0.1,
//             duration: Duration(milliseconds: 300),
//           );
//         }
//       });
//     } else {
//       if (_toanhaSearchController.text.isEmpty || toanhaId != null) {
//         setState(() {
//           _filteredToanhaList = [];
//           _showToanhaEmptyMessage = false;
//         });
//       }
//     }
//   }

//   void _searchTang(String query) {
//     if (_debounceTang?.isActive ?? false) _debounceTang?.cancel();

//     _debounceTang = Timer(const Duration(milliseconds: 500), () {
//       setState(() {
//         isSearchingTang = true;
//         if (query.isEmpty) {
//           _filteredTangList = listTang;
//         } else {
//           final queryWords = normalizeString(query.toLowerCase()).split(' ');
//           _filteredTangList = listTang.where((tang) {
//             final name = normalizeString((tang.name ?? '').toLowerCase());
//             final searchText = name;
//             return queryWords.every((word) => searchText.contains(word));
//           }).toList();
//         }
//         isSearchingTang = false;
//         _showTangEmptyMessage = _filteredTangList.isEmpty;
//       });
//     });
//   }

//   void _selectTang(Tang_Result tang) {
//     setState(() {
//       tangId = tang.id;
//       _tangSearchController.text = tang.name ?? '';
//       _filteredTangList = [];
//     });
//     _tangFocusNode.unfocus();
//   }

//   void _onTangFocusChange() {
//     if (_tangFocusNode.hasFocus) {
//       setState(() {
//         _filteredTangList = listTang;
//         _showTangEmptyMessage = _filteredTangList.isEmpty;
//       });

//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         final context = _tangFieldKey.currentContext;
//         if (context != null) {
//           Scrollable.ensureVisible(
//             context,
//             alignment: 0.1,
//             duration: Duration(milliseconds: 300),
//           );
//         }
//       });
//     } else {
//       if (_tangSearchController.text.isEmpty || tangId != null) {
//         setState(() {
//           _filteredTangList = [];
//           _showTangEmptyMessage = false;
//         });
//       }
//     }
//   }

//   void _applyFilter() {
//     Navigator.of(context).pop({
//       'kdtId': kdtId,
//       'toanhaId': toanhaId,
//       'tangId': tangId,
//       'resident': resident,
//       'khudothiName': _khudothiSearchController.text,
//       'toanhaName': _toanhaSearchController.text,
//       'tangName': _tangSearchController.text,
//     });
//   }

//   void _clearFilter() {
//     setState(() {
//       _khudothiSearchController.clear();
//       _toanhaSearchController.clear();
//       _tangSearchController.clear();
//       kdtId = null;
//       toanhaId = null;
//       tangId = null;
//       resident = true;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         FocusScope.of(context).unfocus();
//       },
//       child: Scaffold(
//         resizeToAvoidBottomInset: true,
//         appBar: AppBar(
//           systemOverlayStyle: SystemUiOverlayStyle(
//             statusBarColor: Color(0xff84d9f3),
//             statusBarIconBrightness: Brightness.light,
//           ),
//           title: const Text(
//             'Bộ lọc tìm kiếm',
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Color(0xff84d9f3),
//           iconTheme: const IconThemeData(color: Colors.white),
//           actions: [
//             TextButton(
//               onPressed: _clearFilter,
//               child: Text('Xóa bộ lọc', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         ),
//         body: SafeArea(
//           child: SingleChildScrollView(
//             padding: EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Khu đô thị SearchField
//                 SearchField<Khudothi>(
//                   label: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [Text('Khu đô thị')],
//                   ),
//                   prefixIcon: Icon(
//                     CupertinoIcons.check_mark,
//                     color: Colors.green,
//                   ),
//                   controller: _khudothiSearchController,
//                   focusNode: _khudothiFocusNode,
//                   fieldKey: _khudothiFieldKey,
//                   items: _filteredKhudothiList,
//                   isLoading: isSearchingKhudothi,
//                   errorText: null,
//                   onSearch: _searchKhudothi,
//                   onSelect: _selectKhudothi,
//                   getLabel: (khudothi) {
//                     return khudothi.name ?? '';
//                   },
//                   decoration: InputDecoration(
//                     label: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [Text('Khu đô thị')],
//                     ),
//                     prefixIcon: const Icon(Icons.location_city),
//                     suffixIcon: const Icon(
//                       CupertinoIcons.chevron_down,
//                       size: 15,
//                     ),
//                     border: OutlineInputBorder(),
//                     enabledBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.grey.shade300),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.blue.shade300),
//                     ),
//                   ),
//                 ),
//                 if (_showKhudothiEmptyMessage) ...[
//                   SizedBox(height: 16),
//                   Center(
//                     child: Column(
//                       children: [
//                         Text(
//                           'Không có thông tin dữ liệu',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(color: Colors.red),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//                 const SizedBox(height: 16),

//                 // Tòa nhà SearchField
//                 SearchField<List_Toanha>(
//                   label: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [Text('Tòa nhà')],
//                   ),
//                   prefixIcon: Icon(
//                     CupertinoIcons.check_mark,
//                     color: Colors.green,
//                   ),
//                   controller: _toanhaSearchController,
//                   focusNode: _toanhaFocusNode,
//                   fieldKey: _toanhaFieldKey,
//                   items: _filteredToanhaList,
//                   isLoading: isSearchingToanha,
//                   errorText: null,
//                   onSearch: _searchToanha,
//                   onSelect: _selectToanha,
//                   getLabel: (toanha) {
//                     return toanha.name ?? '';
//                   },
//                   decoration: InputDecoration(
//                     label: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [Text('Tòa nhà')],
//                     ),
//                     prefixIcon: const Icon(Icons.apartment),
//                     suffixIcon: const Icon(
//                       CupertinoIcons.chevron_down,
//                       size: 15,
//                     ),
//                     border: OutlineInputBorder(),
//                     enabledBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.grey.shade300),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.blue.shade300),
//                     ),
//                   ),
//                 ),
//                 if (_showToanhaEmptyMessage) ...[
//                   SizedBox(height: 16),
//                   Center(
//                     child: Column(
//                       children: [
//                         Text(
//                           'Không có thông tin dữ liệu',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(color: Colors.red),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//                 const SizedBox(height: 16),

//                 // Tầng SearchField
//                 SearchField<Tang_Result>(
//                   label: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [Text('Tầng')],
//                   ),
//                   prefixIcon: Icon(
//                     CupertinoIcons.check_mark,
//                     color: Colors.green,
//                   ),
//                   controller: _tangSearchController,
//                   focusNode: _tangFocusNode,
//                   fieldKey: _tangFieldKey,
//                   items: _filteredTangList,
//                   isLoading: isSearchingTang,
//                   errorText: null,
//                   onSearch: _searchTang,
//                   onSelect: _selectTang,
//                   getLabel: (tang) {
//                     return tang.name ?? '';
//                   },
//                   decoration: InputDecoration(
//                     label: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [Text('Tầng')],
//                     ),
//                     prefixIcon: const Icon(Icons.layers),
//                     suffixIcon: const Icon(
//                       CupertinoIcons.chevron_down,
//                       size: 15,
//                     ),
//                     border: OutlineInputBorder(),
//                     enabledBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.grey.shade300),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.blue.shade300),
//                     ),
//                   ),
//                 ),
//                 if (_showTangEmptyMessage) ...[
//                   SizedBox(height: 16),
//                   Center(
//                     child: Column(
//                       children: [
//                         Text(
//                           'Không có thông tin dữ liệu',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(color: Colors.red),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//                 const SizedBox(height: 16),

//                 // Resident Switch
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Container(
//                         padding: EdgeInsets.symmetric(
//                           vertical: 8,
//                           horizontal: 16,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Color(0xff84d9f3).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(Icons.warehouse, color: Color(0xff559955)),
//                             SizedBox(width: 12),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Cư dân',
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                   Text(
//                                     'Bật để lấy danh sách tài khoản cư dân',
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.black54,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             Switch(
//                               value: resident,
//                               activeColor: Colors.blue,
//                               onChanged: (val) {
//                                 setState(() {
//                                   resident = val;
//                                 });
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 32),

//                 // Apply Filter Button
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     onPressed: _applyFilter,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue.shade600,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       'Áp dụng bộ lọc',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 16),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _khudothiSearchController.dispose();
//     _toanhaSearchController.dispose();
//     _tangSearchController.dispose();
//     _khudothiFocusNode.dispose();
//     _toanhaFocusNode.dispose();
//     _tangFocusNode.dispose();
//     _debounceKhudothi?.cancel();
//     _debounceToanha?.cancel();
//     _debounceTang?.cancel();
//     super.dispose();
//   }
// }
