import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'create_order_page.dart';

// =========================================================
// MODEL DỮ LIỆU
// =========================================================

class _PriceRow {
  final String vehicle;
  final String service;
  final int fee;

  const _PriceRow(
    this.vehicle,
    this.service,
    this.fee,
  );
}

class _WeightTier {
  final String label;
  final String fee;

  const _WeightTier(
    this.label,
    this.fee,
  );
}

class _ServiceInfo {
  final String name;
  final String description;
  final String time;
  final String fromPrice;
  final IconData icon;

  const _ServiceInfo({
    required this.name,
    required this.description,
    required this.time,
    required this.fromPrice,
    required this.icon,
  });
}

// =========================================================
// DỮ LIỆU DỊCH VỤ
// =========================================================

const List<_ServiceInfo> _services = [
  _ServiceInfo(
    name: 'Giao Tiêu chuẩn',
    description:
        'Giải pháp tiết kiệm cho những đơn hàng không yêu cầu giao quá gấp.',
    time: '24 - 48 giờ',
    fromPrice: 'Từ 20.000đ',
    icon: Icons.inventory_2_outlined,
  ),
  _ServiceInfo(
    name: 'Giao Nhanh',
    description:
        'Ưu tiên xử lý và giao hàng nhanh hơn dịch vụ tiêu chuẩn.',
    time: '4 - 6 giờ',
    fromPrice: 'Từ 30.000đ',
    icon: Icons.local_shipping_outlined,
  ),
  _ServiceInfo(
    name: 'Giao Hỏa tốc',
    description:
        'Phù hợp với đơn hàng cần được giao trong thời gian ngắn nhất.',
    time: '30 - 60 phút',
    fromPrice: 'Từ 40.000đ',
    icon: Icons.bolt_outlined,
  ),
];

// =========================================================
// DỮ LIỆU BẢNG GIÁ
// =========================================================

const List<_PriceRow> _basePrices = [
  _PriceRow(
    'Xe máy',
    'Tiêu chuẩn',
    20000,
  ),
  _PriceRow(
    'Xe máy',
    'Nhanh',
    30000,
  ),
  _PriceRow(
    'Xe máy',
    'Hỏa tốc',
    40000,
  ),
  _PriceRow(
    'Ô tô',
    'Tiêu chuẩn',
    50000,
  ),
  _PriceRow(
    'Ô tô',
    'Nhanh',
    70000,
  ),
];

const List<String> _vehicles = [
  'Xe máy',
  'Ô tô',
];

const int _tier5to10Fee = 10000;
const int _perKgFeeOver10 = 2000;

const List<_WeightTier> _weightTiers = [
  _WeightTier(
    '0 - 5 kg',
    'Miễn phí',
  ),
  _WeightTier(
    '5 - 10 kg',
    '+10.000đ',
  ),
  _WeightTier(
    'Trên 10 kg',
    '+10.000đ, mỗi kg vượt 10kg cộng 2.000đ',
  ),
];

// =========================================================
// HÀM XỬ LÝ
// =========================================================

int _weightSurcharge(double kg) {
  if (kg <= 5) {
    return 0;
  }

  if (kg <= 10) {
    return _tier5to10Fee;
  }

  return _tier5to10Fee +
      (kg - 10).ceil() * _perKgFeeOver10;
}

List<String> _servicesOf(String vehicle) {
  return _basePrices
      .where(
        (row) => row.vehicle == vehicle,
      )
      .map(
        (row) => row.service,
      )
      .toList();
}

String _vnd(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (
        i > 0 &&
        (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }

    buffer.write(digits[i]);
  }

  return '$bufferđ';
}

String _surchargeText(int surcharge) {
  if (surcharge == 0) {
    return 'Miễn phí';
  }

  return '+${_vnd(surcharge)}';
}

// =========================================================
// PAGE
// =========================================================

class PriceListPage extends StatefulWidget {
  const PriceListPage({super.key});

  @override
  State<PriceListPage> createState() =>
      _PriceListPageState();
}

class _PriceListPageState
    extends State<PriceListPage> {
  static const Color _green =
      Color(0xFF123F31);

  static const Color _ink =
      Color(0xFF173E32);

  static const Color _muted =
      Color(0xFF69786E);

  static const Color _orange =
      Color(0xFFE65520);

  final TextEditingController
      _weightController =
      TextEditingController(
    text: '1',
  );

  String _vehicle = 'Xe máy';
  String _service = 'Tiêu chuẩn';
  double _weight = 1;

  int get _baseFee {
    for (final row in _basePrices) {
      if (
          row.vehicle == _vehicle &&
          row.service == _service) {
        return row.fee;
      }
    }

    return 0;
  }

  void _changeVehicle(
    String vehicle,
  ) {
    setState(() {
      _vehicle = vehicle;

      final available =
          _servicesOf(vehicle);

      if (!available.contains(_service)) {
        _service = available.first;
      }
    });
  }

  void _openCreateOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CreateOrderPage(),
      ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final surcharge =
        _weightSurcharge(_weight);

    final extraKg =
        _weight > 10
            ? (_weight - 10).ceil()
            : 0;

    final total =
        _baseFee + surcharge;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8F4),

      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text(
          'Bảng giá & Dịch vụ',
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            // =============================================
            // DỊCH VỤ
            // =============================================

            const Text(
              'Dịch vụ vận chuyển',
              style: TextStyle(
                color: _ink,
                fontSize: 24,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Chọn dịch vụ phù hợp với nhu cầu và thời gian giao hàng của bạn.',
              style: TextStyle(
                color: _muted,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            for (final service in _services)
              _serviceCard(service),

            const SizedBox(height: 12),

            // =============================================
            // BẢNG GIÁ
            // =============================================

            _SectionCard(
              title:
                  'Bảng giá dịch vụ Express',
              subtitle:
                  'Phí cơ bản theo loại xe và dịch vụ giao hàng.',
              child: _SimpleTable(
                headers: const [
                  'Loại xe',
                  'Dịch vụ',
                  'Phí cơ bản',
                ],
                flex: const [
                  3,
                  3,
                  3,
                ],
                rows: [
                  for (final row
                      in _basePrices)
                    [
                      row.vehicle,
                      row.service,
                      _vnd(row.fee),
                    ],
                ],
              ),
            ),

            // =============================================
            // PHỤ PHÍ KHỐI LƯỢNG
            // =============================================

            _SectionCard(
              title:
                  'Phụ phí khối lượng',
              subtitle:
                  'Cộng thêm vào phí cơ bản tùy theo khối lượng kiện hàng.',
              child: _SimpleTable(
                headers: const [
                  'Khối lượng',
                  'Phụ phí',
                ],
                flex: const [
                  3,
                  4,
                ],
                rows: [
                  for (final tier
                      in _weightTiers)
                    [
                      tier.label,
                      tier.fee,
                    ],
                ],
              ),
            ),

            // =============================================
            // TÍNH THỬ PHÍ
            // =============================================

            _SectionCard(
              title:
                  'Tính thử phí vận chuyển',
              subtitle:
                  'Chỉ mang tính tham khảo. Phí chính thức được hệ thống báo khi bạn tạo đơn.',
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loại xe',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child:
                        SegmentedButton<
                            String>(
                      segments:
                          _vehicles.map(
                        (vehicle) {
                          return ButtonSegment<
                              String>(
                            value: vehicle,
                            label:
                                Text(
                              vehicle,
                            ),
                            icon: Icon(
                              vehicle ==
                                      'Xe máy'
                                  ? Icons
                                      .two_wheeler
                                  : Icons
                                      .directions_car,
                            ),
                          );
                        },
                      ).toList(),

                      selected: {
                        _vehicle,
                      },

                      onSelectionChanged:
                          (selection) {
                        _changeVehicle(
                          selection.first,
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  const Text(
                    'Dịch vụ',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final service
                          in _servicesOf(
                            _vehicle,
                          ))
                        ChoiceChip(
                          label:
                              Text(service),
                          selected:
                              _service ==
                                  service,
                          onSelected: (_) {
                            setState(() {
                              _service =
                                  service;
                            });
                          },
                        ),
                    ],
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  TextField(
                    controller:
                        _weightController,

                    keyboardType:
                        TextInputType.number,

                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly,
                    ],

                    maxLength: 4,

                    decoration:
                        const InputDecoration(
                      labelText:
                          'Khối lượng (kg)',
                      hintText:
                          'Nhập số kg',
                      counterText: '',
                      border:
                          OutlineInputBorder(),
                    ),

                    onChanged: (text) {
                      setState(() {
                        _weight =
                            (int.tryParse(
                                      text,
                                    ) ??
                                    0)
                                .toDouble();
                      });
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets
                            .all(16),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFF1F5F2,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                                14,
                              ),
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        _feeLine(
                          'Phí cơ bản',
                          _vnd(
                            _baseFee,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        _feeLine(
                          'Phụ phí khối lượng',
                          _surchargeText(
                            surcharge,
                          ),
                        ),

                        if (extraKg > 0)
                          Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              top: 6,
                            ),
                            child: Text(
                              '$extraKg kg vượt mức 10kg x ${_vnd(_perKgFeeOver10)}/kg',
                              style:
                                  const TextStyle(
                                color:
                                    _muted,
                                fontSize:
                                    12,
                              ),
                            ),
                          ),

                        const Divider(
                          height: 24,
                        ),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text(
                              'Tổng cộng',
                              style:
                                  TextStyle(
                                color:
                                    _ink,
                                fontSize:
                                    17,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            Text(
                              _vnd(total),
                              style:
                                  const TextStyle(
                                color:
                                    _orange,
                                fontSize:
                                    22,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        FilledButton.icon(
                      style:
                          FilledButton
                              .styleFrom(
                        backgroundColor:
                            _orange,
                        foregroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 14,
                        ),
                      ),
                      onPressed:
                          _openCreateOrder,
                      icon: const Icon(
                        Icons.add,
                      ),
                      label:
                          const Text(
                        'Tạo đơn với dịch vụ này',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =======================================================
  // CARD DỊCH VỤ
  // =======================================================

  Widget _serviceCard(
    _ServiceInfo service,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(
            0xFFE2E8E4,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFEAF6A6,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                            14,
                          ),
                ),
                child: Icon(
                  service.icon,
                  color: _green,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      service.name,
                      style:
                          const TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      service
                          .description,
                      style:
                          const TextStyle(
                        color: _muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _serviceInfoBox(
                  icon:
                      Icons
                          .schedule_outlined,
                  label:
                      'Thời gian',
                  value:
                      service.time,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    _serviceInfoBox(
                  icon:
                      Icons
                          .payments_outlined,
                  label: 'Giá',
                  value: service
                      .fromPrice,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          SizedBox(
            width:
                double.infinity,
            child:
                FilledButton.icon(
              style:
                  FilledButton
                      .styleFrom(
                backgroundColor:
                    _orange,
                foregroundColor:
                    Colors.white,
              ),
              onPressed:
                  _openCreateOrder,
              icon:
                  const Icon(
                Icons.add,
              ),
              label:
                  const Text(
                'Tạo đơn',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceInfoBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color:
            const Color(
          0xFFF5F7F3,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _green,
            size: 19,
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            label,
            style:
                const TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),

          const SizedBox(
            height: 2,
          ),

          Text(
            value,
            style:
                const TextStyle(
              color: _ink,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeLine(
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style:
                const TextStyle(
              color: _muted,
            ),
          ),
        ),
        Text(
          value,
          style:
              const TextStyle(
            color: _ink,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// =========================================================
// SECTION CARD
// =========================================================

class _SectionCard
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(
            0xFFE2E8E4,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(
                0xFF173E32,
              ),
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            subtitle,
            style:
                const TextStyle(
              fontSize: 13,
              color:
                  Color(
                0xFF69786E,
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          child,
        ],
      ),
    );
  }
}

// =========================================================
// SIMPLE TABLE
// =========================================================

class _SimpleTable
    extends StatelessWidget {
  final List<String> headers;
  final List<int> flex;
  final List<List<String>> rows;

  const _SimpleTable({
    required this.headers,
    required this.flex,
    required this.rows,
  });

  Widget _buildRow(
    List<String> cells, {
    required bool isHeader,
    required bool isLast,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 10,
      ),

      decoration: BoxDecoration(
        color: isHeader
            ? const Color(
                0xFFF5F7F3,
              )
            : null,

        border: isLast
            ? null
            : const Border(
                bottom:
                    BorderSide(
                  color:
                      Color(
                    0xFFEDF0EB,
                  ),
                ),
              ),
      ),

      child: Row(
        children: [
          for (var i = 0;
              i < cells.length;
              i++)
            Expanded(
              flex: flex[i],
              child: Text(
                cells[i],
                style: TextStyle(
                  fontSize:
                      isHeader
                          ? 12
                          : 14,

                  fontWeight:
                      isHeader ||
                              i ==
                                  cells.length -
                                      1
                          ? FontWeight
                              .w600
                          : FontWeight
                              .normal,

                  color:
                      isHeader
                          ? const Color(
                              0xFF748174,
                            )
                          : const Color(
                              0xFF173E32,
                            ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(10),

      child: Column(
        children: [
          _buildRow(
            headers,
            isHeader: true,
            isLast: false,
          ),

          for (var i = 0;
              i < rows.length;
              i++)
            _buildRow(
              rows[i],
              isHeader: false,
              isLast:
                  i ==
                      rows.length -
                          1,
            ),
        ],
      ),
    );
  }
}