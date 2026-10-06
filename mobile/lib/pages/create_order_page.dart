import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});
  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _senderName = TextEditingController();
  final _senderPhone = TextEditingController();
  final _pickup = TextEditingController();
  final _recipientName = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _delivery = TextEditingController();
  final _goods = TextEditingController();
  final _weight = TextEditingController(text: '1');
  final _length = TextEditingController(text: '20');
  final _width = TextEditingController(text: '15');
  final _height = TextEditingController(text: '10');
  final _declared = TextEditingController(text: '0');
  final _cod = TextEditingController(text: '0');
  final _notes = TextEditingController();
  String _service = 'standard';
  String _feePayer = 'shop_prepaid';
  bool _loading = false;
  Map<String, dynamic>? _quote;

  static final _phoneRegex = RegExp(r'^\+?[0-9 ()-]{8,20}$');

  @override
  void dispose() {
    for (final c in [_senderName,_senderPhone,_pickup,_recipientName,_recipientPhone,_delivery,_goods,_weight,_length,_width,_height,_declared,_cod,_notes]) { c.dispose(); }
    super.dispose();
  }

  void _invalidateQuote() { if (_quote != null) setState(() => _quote = null); }

  String? _required(String? value, String label, {int max = 300}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập $label.';
    if (v.length > max) return '$label không được vượt quá $max ký tự.';
    return null;
  }

  String? _phone(String? value, String label) {
    final required = _required(value, label, max: 20);
    if (required != null) return required;
    if (!_phoneRegex.hasMatch(value!.trim())) return '$label không hợp lệ (8–20 ký tự số).';
    return null;
  }

  String? _positiveDecimal(String? value, String label) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Vui lòng nhập $label.';
    final n = double.tryParse(raw);
    if (n == null) return '$label phải là số.';
    if (!n.isFinite || n <= 0) return '$label phải lớn hơn 0.';
    return null;
  }

  String? _nonNegativeInt(String? value, String label) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Vui lòng nhập $label.';
    final n = int.tryParse(raw);
    if (n == null) return '$label phải là số nguyên.';
    if (n < 0) return '$label không được âm.';
    return null;
  }

  Map<String, dynamic> _order() => {
    'senderName': _senderName.text.trim(), 'senderPhone': _senderPhone.text.trim(),
    'pickupAddress': _pickup.text.trim(), 'recipientName': _recipientName.text.trim(),
    'recipientPhone': _recipientPhone.text.trim(), 'deliveryAddress': _delivery.text.trim(),
    'goods': _goods.text.trim(), 'weightKg': double.parse(_weight.text.trim()),
    'lengthCm': double.parse(_length.text.trim()), 'widthCm': double.parse(_width.text.trim()),
    'heightCm': double.parse(_height.text.trim()), 'declaredValue': int.parse(_declared.text.trim()),
    'codAmount': int.parse(_cod.text.trim()), 'service': _service, 'feePayer': _feePayer,
    'notes': _notes.text.trim(),
  };

  Future<void> _quoteOrder() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) { _show('Vui lòng kiểm tra các trường đang báo lỗi.', true); return; }
    if (_notes.text.trim().length > 1000) { _show('Ghi chú không được vượt quá 1.000 ký tự.', true); return; }
    setState(() => _loading = true);
    try {
      final quote = await ApiService.createQuote(order: _order());
      if (!mounted) return;
      setState(() => _quote = quote);
      _show('Đã tính phí. Báo giá chỉ có hiệu lực trong thời gian ngắn.', false);
    } catch (e) { if (mounted) _show(e.toString().replaceFirst('Exception: ', ''), true); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _create() async {
    if (_quote == null || _loading) return;
    if (!_formKey.currentState!.validate()) { _show('Thông tin đã thay đổi. Vui lòng kiểm tra và tính phí lại.', true); return; }
    setState(() => _loading = true);
    try {
      final order = await ApiService.createOrder(order: _order(), quoteId: _quote!['id'].toString());
      if (!mounted) return;
      _show('Đã tạo đơn ${order['id']}.', false);
      Navigator.pop(context, true);
    } catch (e) { if (mounted) _show(e.toString().replaceFirst('Exception: ', ''), true); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _show(String text, bool error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700));

  Widget _field(String label, TextEditingController controller, {TextInputType? keyboardType, List<TextInputFormatter>? formatters, String? Function(String?)? validator, int maxLength = 300, int maxLines = 1}) {
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(
      controller: controller, keyboardType: keyboardType, inputFormatters: formatters,
      maxLength: maxLength, maxLines: maxLines, validator: validator ?? (v) => _required(v, label, max: maxLength),
      onChanged: (_) => _invalidateQuote(),
      decoration: _input(label).copyWith(counterText: maxLength <= 30 ? '' : null),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F4),
      appBar: AppBar(title: const Text('Tạo đơn giao hàng'), backgroundColor: const Color(0xFF123F31), foregroundColor: Colors.white),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(20), children: [
        const _SectionTitle('NGƯỜI GỬI'), const SizedBox(height: 12),
        _field('Tên người gửi', _senderName),
        _field('Điện thoại người gửi', _senderPhone, keyboardType: TextInputType.phone, maxLength: 20, validator: (v) => _phone(v, 'Số điện thoại người gửi')),
        _field('Địa chỉ lấy hàng', _pickup),
        const SizedBox(height: 8), const _SectionTitle('NGƯỜI NHẬN'), const SizedBox(height: 12),
        _field('Tên người nhận', _recipientName),
        _field('Điện thoại người nhận', _recipientPhone, keyboardType: TextInputType.phone, maxLength: 20, validator: (v) => _phone(v, 'Số điện thoại người nhận')),
        _field('Địa chỉ giao hàng', _delivery),
        const SizedBox(height: 8), const _SectionTitle('THÔNG TIN KIỆN HÀNG'), const SizedBox(height: 12),
        _field('Nội dung hàng hóa', _goods),
        _field('Khối lượng (kg)', _weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), maxLength: 10, validator: (v) => _positiveDecimal(v, 'Khối lượng')),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _field('Dài (cm)', _length, keyboardType: const TextInputType.numberWithOptions(decimal: true), maxLength: 10, validator: (v) => _positiveDecimal(v, 'Chiều dài'))), const SizedBox(width: 8),
          Expanded(child: _field('Rộng (cm)', _width, keyboardType: const TextInputType.numberWithOptions(decimal: true), maxLength: 10, validator: (v) => _positiveDecimal(v, 'Chiều rộng'))), const SizedBox(width: 8),
          Expanded(child: _field('Cao (cm)', _height, keyboardType: const TextInputType.numberWithOptions(decimal: true), maxLength: 10, validator: (v) => _positiveDecimal(v, 'Chiều cao'))),
        ]),
        _field('Giá trị hàng (đ)', _declared, keyboardType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly], maxLength: 12, validator: (v) => _nonNegativeInt(v, 'Giá trị hàng')),
        _field('Tiền thu hộ COD (đ)', _cod, keyboardType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly], maxLength: 12, validator: (v) => _nonNegativeInt(v, 'Tiền COD')),
        DropdownButtonFormField<String>(initialValue: _service, decoration: _input('Dịch vụ'), items: const [DropdownMenuItem(value:'standard',child:Text('Tiêu chuẩn')),DropdownMenuItem(value:'express',child:Text('Hỏa tốc'))], onChanged: _loading ? null : (v){setState(()=>_service=v!);_invalidateQuote();}),
        const SizedBox(height:14),
        DropdownButtonFormField<String>(initialValue: _feePayer, decoration: _input('Thanh toán phí vận chuyển'), items: const [DropdownMenuItem(value:'shop_prepaid',child:Text('Shop trả trước')),DropdownMenuItem(value:'recipient',child:Text('Người nhận trả')),DropdownMenuItem(value:'deduct_cod',child:Text('Khấu trừ COD'))], onChanged: _loading ? null : (v){setState(()=>_feePayer=v!);_invalidateQuote();}),
        const SizedBox(height:14),
        TextFormField(controller:_notes,maxLines:3,maxLength:1000,onChanged:(_)=>_invalidateQuote(),decoration:_input('Ghi chú giao hàng (không bắt buộc)')),
        if (_quote != null) Card(margin:const EdgeInsets.only(top:8), child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('BÁO GIÁ',style:TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:8),
          Text('${_quote!['fee']} đ',style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:Color(0xFF123F31))),
          if (_quote!['expiresAt'] != null) Text('Hết hạn: ${_formatDate(_quote!['expiresAt'])}',style:const TextStyle(color:Colors.black54)),
          const SizedBox(height:12),SizedBox(width:double.infinity,child:ElevatedButton(onPressed:_loading?null:_create,child:const Text('Xác nhận tạo đơn'))),
        ]))),
        const SizedBox(height:12),SizedBox(height:52,child:ElevatedButton(onPressed:_loading?null:_quoteOrder,child:Text(_loading?'Đang xử lý...':'Tính phí vận chuyển'))),
      ])),
    );
  }

  String _formatDate(dynamic value) { final d=DateTime.tryParse(value.toString())?.toLocal(); if(d==null)return value.toString(); String t(int n)=>n.toString().padLeft(2,'0'); return '${t(d.day)}/${t(d.month)}/${d.year} ${t(d.hour)}:${t(d.minute)}'; }
  InputDecoration _input(String label) => InputDecoration(labelText:label,filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(12)));
}

class _SectionTitle extends StatelessWidget { final String text; const _SectionTitle(this.text); @override Widget build(BuildContext context)=>Text(text,style:const TextStyle(fontWeight:FontWeight.bold,letterSpacing:1.2,color:Color(0xFF123F31))); }
