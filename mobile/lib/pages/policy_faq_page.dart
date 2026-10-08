import 'package:flutter/material.dart';

class PolicyFaqPage extends StatefulWidget {
  const PolicyFaqPage({super.key});

  @override
  State<PolicyFaqPage> createState() =>
      _PolicyFaqPageState();
}

class _PolicyFaqPageState
    extends State<PolicyFaqPage> {
  int _tab = 0;

  static const Color forest =
      Color(0xFF123F31);

  static const Color muted =
      Color(0xFF668177);

  // static const Color orange =
  //     Color(0xFFE65520);

  static const Color background =
      Color(0xFFF7F8F4);

  static const List<
      (String, String)> _faq = [
    (
      'Thời gian giao hàng của Express mất bao lâu?',
      'Thời gian giao phụ thuộc vào dịch vụ đã chọn. '
          'Giao Tiêu chuẩn khoảng 24-48 giờ, '
          'Giao Nhanh khoảng 4-6 giờ và '
          'Giao Hỏa tốc khoảng 30-60 phút.',
    ),
    (
      'Làm thế nào để tra cứu hành trình vận đơn?',
      'Bạn có thể nhập mã vận đơn tại màn hình Tổng quan '
          'hoặc mở mục Đơn hàng và chọn đơn cần theo dõi.',
    ),
    (
      'Tiền thu hộ COD được đối soát khi nào?',
      'Tiền COD được ghi nhận sau khi đơn giao thành công '
          'và được đối soát theo kỳ thanh toán của hệ thống.',
    ),
    (
      'Nếu người nhận vắng nhà thì xử lý thế nào?',
      'Nhân viên giao nhận sẽ liên hệ lại và thực hiện '
          'giao lại theo chính sách giao hàng của Express.',
    ),
    (
      'Có thể chọn người thanh toán phí vận chuyển không?',
      'Có. Khi tạo đơn, bạn có thể chọn người gửi trả trước, '
          'người nhận trả hoặc khấu trừ phí từ COD '
          'nếu hệ thống hỗ trợ.',
    ),
    (
      'Có thể hủy đơn hoặc đổi địa chỉ sau khi tạo không?',
      'Khả năng hủy hoặc thay đổi thông tin phụ thuộc '
          'vào trạng thái hiện tại của đơn hàng.',
    ),
    (
      'Hàng bị hư hỏng thì khiếu nại như thế nào?',
      'Bạn nên giữ hình ảnh, chứng từ và gửi yêu cầu '
          'khiếu nại trong thời hạn quy định để Express '
          'kiểm tra và xử lý.',
    ),
    (
      'Khối lượng tối đa của đơn hàng là bao nhiêu?',
      'Giới hạn khối lượng phụ thuộc vào loại phương tiện '
          'và dịch vụ. Vui lòng xem mục Bảng giá & Dịch vụ '
          'để biết chi tiết.',
    ),
  ];

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title:
            const Text('Chính sách & FAQ'),
        backgroundColor: forest,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(18),
        children: [
          _introCard(),

          const SizedBox(height: 18),

          SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(
                value: 0,
                icon:
                    Icon(Icons.policy_outlined),
                label:
                    Text('Chính sách'),
              ),
              ButtonSegment<int>(
                value: 1,
                icon:
                    Icon(Icons.help_outline),
                label: Text('FAQ'),
              ),
            ],
            selected: {_tab},
            onSelectionChanged:
                (value) {
              setState(() {
                _tab = value.first;
              });
            },
          ),

          const SizedBox(height: 20),

          if (_tab == 0)
            ..._policyWidgets()
          else
            ..._faqWidgets(),
        ],
      ),
    );
  }

  Widget _introCard() {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: forest,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Hỗ trợ khách hàng',
            style: TextStyle(
              color:
                  Color(0xFFEAF6A6),
              fontSize: 12,
              letterSpacing: 1.4,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Mọi điều bạn cần biết '
            'trước và sau khi gửi hàng.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight:
                  FontWeight.w800,
              height: 1.25,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Xem quy định vận chuyển, '
            'chính sách COD, hoàn hàng '
            'và các câu hỏi thường gặp.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _policyWidgets() {
    return [
      _policyCard(
        icon: Icons.inventory_2_outlined,
        title:
            '1. Quy chuẩn đóng gói',
        items: const [
          'Hàng dễ vỡ phải được bọc chống sốc '
              'và chèn kín khoảng trống.',
          'Chất lỏng phải đóng kín nắp, chống rò rỉ '
              'và đặt trong túi chống thấm.',
          'Thiết bị điện tử nên được bọc chống tĩnh điện '
              'và chống va đập.',
          'Phiếu gửi phải được dán ở vị trí dễ quan sát '
              'và không che mã vận đơn.',
        ],
      ),

      const SizedBox(height: 14),

      _policyCard(
        icon:
            Icons.block_outlined,
        title:
            '2. Hàng hóa cấm vận chuyển',
        items: const [
          'Vũ khí, vật liệu nổ và chất dễ cháy.',
          'Ma túy, chất độc và hóa chất nguy hiểm.',
          'Tiền mặt, ngoại tệ, vàng và đá quý '
              'chưa đủ điều kiện vận chuyển.',
          'Động vật sống và hàng hóa dễ gây mất vệ sinh '
              'hoặc phát sinh mùi mạnh.',
          'Hàng lậu, hàng giả hoặc hàng không có '
              'nguồn gốc hợp pháp.',
        ],
      ),

      const SizedBox(height: 14),

      _policyCard(
        icon:
            Icons.verified_user_outlined,
        title:
            '3. Bảo hiểm & bồi thường',
        items: const [
          'Đơn có khai giá có thể được bồi thường '
              'theo giá trị chứng minh hợp lệ.',
          'Đơn không khai giá áp dụng mức bồi thường '
              'theo quy định cước vận chuyển.',
          'Hư hỏng một phần được xác định theo '
              'tỷ lệ thiệt hại thực tế.',
          'Khiếu nại cần được gửi trong thời hạn '
              'quy định sau khi nhận hàng.',
        ],
      ),

      const SizedBox(height: 14),

      _policyCard(
        icon:
            Icons.payments_outlined,
        title:
            '4. Chính sách COD',
        items: const [
          'COD là khoản tiền Express thu hộ từ người nhận.',
          'COD chỉ được ghi nhận sau khi đơn giao thành công.',
          'Phí vận chuyển có thể được khấu trừ từ COD '
              'nếu người gửi chọn hình thức này.',
          'Tiền COD được đối soát theo kỳ thanh toán '
              'của hệ thống.',
        ],
      ),

      const SizedBox(height: 14),

      _policyCard(
        icon:
            Icons.cancel_outlined,
        title:
            '5. Hủy đơn',
        items: const [
          'Đơn có thể được hủy khi chưa bắt đầu quá trình giao nhận.',
          'Một số trạng thái đang xử lý có thể không cho phép hủy.',
          'Phí phát sinh sau khi đơn đã được xử lý '
              'có thể được tính theo quy định.',
        ],
      ),

      const SizedBox(height: 14),

      _policyCard(
        icon:
            Icons.assignment_return_outlined,
        title:
            '6. Giao lại & hoàn hàng',
        items: const [
          'Đơn giao thất bại có thể được thực hiện giao lại.',
          'Nếu không thể giao thành công sau số lần quy định, '
              'đơn có thể được hoàn về người gửi.',
          'Phí giao lại hoặc hoàn hàng có thể phát sinh '
              'tùy theo tình trạng đơn.',
        ],
      ),

      const SizedBox(height: 14),

      _policyCard(
        icon:
            Icons.lock_outline,
        title:
            '7. Chính sách bảo mật',
        items: const [
          'Thông tin khách hàng chỉ được sử dụng '
              'cho mục đích cung cấp dịch vụ.',
          'Thông tin đơn hàng và tài khoản được '
              'bảo vệ theo quy định của hệ thống.',
          'Khách hàng có trách nhiệm bảo mật '
              'thông tin đăng nhập của mình.',
        ],
      ),
    ];
  }

  List<Widget> _faqWidgets() {
    return _faq
        .map(
          (item) => Card(
            color: Colors.white,
            margin:
                const EdgeInsets.only(
              bottom: 10,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: ExpansionTile(
              shape:
                  const Border(),
              collapsedShape:
                  const Border(),
              leading:
                  const CircleAvatar(
                backgroundColor:
                    Color(0xFFEAF6A6),
                foregroundColor:
                    forest,
                child: Text(
                  '?',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                item.$1,
                style:
                    const TextStyle(
                  color: forest,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              children: [
                Padding(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    18,
                    0,
                    18,
                    18,
                  ),
                  child: Text(
                    item.$2,
                    style:
                        const TextStyle(
                      color: muted,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _policyCard({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
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
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFEAF6A6,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  color: forest,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  title,
                  style:
                      const TextStyle(
                    color: forest,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          ...items.map(
            (item) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Padding(
                    padding:
                        EdgeInsets.only(
                      top: 3,
                    ),
                    child: Icon(
                      Icons
                          .check_circle_outline,
                      size: 18,
                      color: forest,
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      item,
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF43554E,
                        ),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}