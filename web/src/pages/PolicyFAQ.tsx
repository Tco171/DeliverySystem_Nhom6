import { useState, useId } from "react";
import "./pages.css";

interface FAQItem {
  id: string;
  question: string;
  category: "chung" | "donhang" | "cod" | "khieunai";
  answer: string;
}

const FAQ_LIST: FAQItem[] = [
  {
    id: "faq-1",
    question: "Thời gian giao hàng của Express mất bao lâu?",
    category: "chung",
    answer:
      "Tùy theo gói dịch vụ bạn lựa chọn: Gói Hỏa tốc giao ngay trong 30 – 60 phút; Gói Nhanh giao trong 4 – 6 giờ cùng ngày; Gói Tiêu chuẩn giao từ 24 – 48 giờ đối với khu vực nội tỉnh / thành phố và 2 – 3 ngày đối với các tuyến liên tỉnh.",
  },
  {
    id: "faq-2",
    question: "Làm thế nào để tra cứu hành trình vận đơn bưu kiện?",
    category: "donhang",
    answer:
      "Bạn có thể nhập Mã vận đơn (ví dụ: EXP-DEMO-001) vào ô 'Tra cứu vận đơn' tại trang Tổng quan hoặc mục Quản lý đơn hàng. Hệ thống sẽ hiển thị toàn bộ lịch sử trạng thái: Chờ lấy, Đang trung chuyển, Đang giao và thời gian dự kiến phát hàng.",
  },
  {
    id: "faq-3",
    question: "Tiền thu hộ COD được đối soát và thanh toán khi nào?",
    category: "cod",
    answer:
      "Express cung cấp lịch đối soát COD linh hoạt: Đối soát định kỳ vào thứ 2 – thứ 4 – thứ 6 hàng tuần hoặc đối soát tự động theo chu kỳ ngày hôm sau (T+1) đối với khách hàng thân thiết. Tiền COD sẽ được chuyển khoản trực tiếp vào tài khoản ngân hàng của quý shop đã đăng ký.",
  },
  {
    id: "faq-4",
    question: "Nếu người nhận không nghe máy hoặc vắng nhà thì bưu tá xử lý thế nào?",
    category: "donhang",
    answer:
      "Bưu tá sẽ liên hệ tối thiểu 03 cuộc gọi ở các thời điểm khác nhau. Nếu vẫn không liên lạc được, đơn hàng sẽ được lưu kho tại bưu cục gần nhất và phát lại hoàn toàn miễn phí tối đa 03 lần vào các ngày tiếp theo trước khi thực hiện chuyển hoàn hàng về cho shop.",
  },
  {
    id: "faq-5",
    question: "Tôi có thể chọn người thanh toán cước vận chuyển (Shop hay Khách nhận) không?",
    category: "donhang",
    answer:
      "Có. Khi tạo đơn giao hàng, bạn có 3 tùy chọn thanh toán cước phí: 'Shop trả trước' (trừ vào tài khoản shop), 'Người nhận trả' (shipper thu thêm tiền cước khi giao hàng), hoặc 'Khấu trừ COD' (tự động trừ cước vào số tiền COD thu hộ trước khi chuyển khoản cho shop).",
  },
  {
    id: "faq-6",
    question: "Làm thế nào để hủy đơn hàng hoặc thay đổi địa chỉ nhận sau khi đã tạo đơn?",
    category: "donhang",
    answer:
      "Nếu đơn hàng ở trạng thái 'Chờ lấy hàng', bạn có thể chỉnh sửa địa chỉ hoặc hủy đơn trực tiếp trên hệ thống quản lý. Khi đơn đã bàn giao cho bưu tá hoặc đang trung chuyển, vui lòng tạo yêu cầu hỗ trợ hoặc liên hệ bộ phận Điều phối để được cập nhật lộ trình kịp thời.",
  },
  {
    id: "faq-7",
    question: "Hàng hóa bị vỡ hỏng hoặc móp méo khi giao đến, tôi cần làm gì để được bồi thường?",
    category: "khieunai",
    answer:
      "Vui lòng giữ nguyên hiện trạng gói hàng, chụp ảnh/quay video bao bì và sản phẩm bị hỏng, sau đó gửi yêu cầu tại mục 'Xử lý sự cố' trong vòng 48 giờ kể từ lúc nhận hàng. Đơn hàng có khai giá sẽ được bồi thường tối đa 100% giá trị trong 3 – 5 ngày làm việc.",
  },
  {
    id: "faq-8",
    question: "Làm sao để lưu các điểm lấy hàng cố định giúp tiết kiệm thời gian tạo đơn?",
    category: "chung",
    answer:
      "Tại màn hình 'Tạo đơn mới', bạn điền thông tin kho/cửa hàng (Tên điểm, Người liên hệ, Số điện thoại, Địa chỉ), sau đó nhập tên gợi nhớ vào ô 'Tên điểm lấy hàng mới' và bấm nút 'Lưu điểm lấy hàng'. Các lần tạo đơn sau bạn chỉ cần chọn điểm từ danh sách thả xuống.",
  },
  {
    id: "faq-9",
    question: "Quy định về kích thước và khối lượng tối đa cho mỗi bưu gửi là gì?",
    category: "chung",
    answer:
      "Đối với phương tiện Xe máy, kiện hàng không vượt quá 30 kg và kích thước các chiều không vượt quá 50 x 40 x 40 cm. Đối với Ô tô tải, nhận bưu kiện và hàng cồng kềnh lên đến 1.500 kg (1.5 tấn) với thể tích tối đa phù hợp khoang xe tải.",
  },
  {
    id: "faq-10",
    question: "Express có cung cấp dịch vụ đóng gói hàng hóa hoặc thùng carton không?",
    category: "chung",
    answer:
      "Tại các bưu cục và kho trung chuyển, Express cung cấp đầy đủ bao bì chuẩn gồm thùng carton đa kích cỡ, màng bọc chống sốc bubble wrap, màng co và băng dính chuyên dụng. Bạn cũng có thể yêu cầu shipper mang theo bao bì đóng gói khi đặt dịch vụ.",
  },
];

interface PolicyFAQProps {
  currentTab?: "policy" | "faq";
  onTabChange?: (tab: "policy" | "faq") => void;
}

export default function PolicyFAQ({ currentTab, onTabChange }: PolicyFAQProps = {}) {
  const [internalTab, setInternalTab] = useState<"policy" | "faq">("policy");

  const activeTab = currentTab ?? internalTab;
  const setActiveTab = (tab: "policy" | "faq") => {
    setInternalTab(tab);
    onTabChange?.(tab);
  };

  const [openFaqId, setOpenFaqId] = useState<string | null>("faq-1");
  const [faqSearch, setFaqSearch] = useState<string>("");
  const faqSearchInputId = useId();

  const toggleFaq = (id: string) => {
    setOpenFaqId((prev) => (prev === id ? null : id));
  };

  const filteredFaq = FAQ_LIST.filter(
    (item) =>
      item.question.toLowerCase().includes(faqSearch.trim().toLowerCase()) ||
      item.answer.toLowerCase().includes(faqSearch.trim().toLowerCase())
  );

  return (
    <div className="policy-container">
      {/* Tab Điều hướng trên cùng */}
      <div className="policy-tabs-bar" role="tablist">
        <button
          type="button"
          role="tab"
          aria-selected={activeTab === "policy"}
          className={`policy-tab-btn ${activeTab === "policy" ? "active" : ""}`}
          onClick={() => setActiveTab("policy")}
        >
          Chính sách giao hàng
        </button>
        <button
          type="button"
          role="tab"
          aria-selected={activeTab === "faq"}
          className={`policy-tab-btn ${activeTab === "faq" ? "active" : ""}`}
          onClick={() => setActiveTab("faq")}
        >
          Câu hỏi thường gặp (FAQ)
        </button>
      </div>

      {/* ========================================================
          TAB 1: CHÍNH SÁCH GIAO HÀNG
          ======================================================== */}
      {activeTab === "policy" && (
        <div className="policy-sections">
          {/* Mục 1: Quy chuẩn đóng gói bưu kiện */}
          <section className="policy-card">
            <h3 className="policy-card-title">
              1. Quy chuẩn đóng gói bưu kiện
            </h3>
            <p className="muted" style={{ marginBottom: "18px" }}>
              Đóng gói đúng tiêu chuẩn giúp bảo vệ hàng hóa tối đa trong quá trình vận chuyển và là căn cứ giải quyết bảo hiểm bồi thường.
            </p>

            <div className="policy-items-grid">
              <div className="policy-subitem">
                <h5>Hàng hóa thông thường</h5>
                <p>
                  Sử dụng thùng carton cứng cáp (3 – 5 lớp), chèn xốp hoặc giấy bọt khí kín 6 mặt để sản phẩm không xê dịch.
                  Dán băng dính niêm phong theo hình chữ H kín các mép đáy và nắp thùng.
                </p>
              </div>

              <div className="policy-subitem">
                <h5>Hàng dễ vỡ (Thủy tinh, Gốm sứ, Đồ lưu niệm)</h5>
                <p>
                  Bọc từng sản phẩm bằng bọt khí chống sốc (bubble wrap) tối thiểu 3 – 4 lớp. Đóng trong thùng carton đôi hoặc thùng xốp.
                  Bắt buộc dán nhãn cảnh báo <strong>&quot;HÀNG DỄ VỠ - XIN NHẸ TAY&quot;</strong> ở vị trí dễ quan sát.
                </p>
              </div>

              <div className="policy-subitem">
                <h5>Hóa mỹ phẩm &amp; Chất lỏng</h5>
                <p>
                  Nắp chai lọ phải được bịt kín bằng băng dính hoặc màng co nhiệt. Đựng trong túi zip nhựa kín chống rò rỉ trước khi đặt vào thùng.
                  Chèn vật liệu hút ẩm/hút nước xung quanh để phòng ngừa sự cố tràn chất lỏng.
                </p>
              </div>

              <div className="policy-subitem">
                <h5>Thiết bị điện tử &amp; Hàng giá trị cao</h5>
                <p>
                  Đặt trong túi nilon chống tĩnh điện, lót mút xốp định hình dày từ 3 – 5 cm bao quanh. Ưu tiên giữ nguyên đai kiện
                  hộp nguyên seal của nhà sản xuất hoặc đóng thùng gỗ đối với thiết bị kích thước lớn.
                </p>
              </div>

              <div className="policy-subitem">
                <h5>Quần áo, Vải sợi &amp; Hàng mềm</h5>
                <p>
                  Sử dụng túi niêm phong PE chuyên dụng chống thấm nước, miết chặt dải keo dán miệng túi hoặc đóng túi nilon kín trước khi cho vào thùng carton.
                </p>
              </div>

              <div className="policy-subitem">
                <h5>Yêu cầu in &amp; Dán phiếu gửi (Bill vận đơn)</h5>
                <p>
                  Dán phiếu gửi vận đơn trên mặt phẳng lớn nhất của kiện hàng. Đảm bảo mã vạch (Barcode/QR code) rõ nét, không bị nếp gấp hay che khuất thông tin.
                </p>
              </div>
            </div>
          </section>

          {/* Mục 2: Danh mục hàng cấm gửi */}
          <section className="policy-card">
            <h3 className="policy-card-title">
              2. Danh mục hàng cấm vận chuyển
            </h3>
            <p className="muted" style={{ marginBottom: "18px" }}>
              Express tuân thủ nghiêm ngặt quy định pháp luật Việt Nam. Chúng tôi từ chối tiếp nhận và sẽ bàn giao cơ quan chức năng các bưu gửi thuộc danh mục cấm:
            </p>

            <div className="prohibited-grid">
              <div className="prohibited-item">
                <div>
                  <h5>Vũ khí, Vật liệu nổ &amp; Chất cháy nổ</h5>
                  <p>
                    Vũ khí quân dụng, súng đạn, lựu đạn, dao găm, kiếm; pháo hoa, pháo nổ; xăng dầu, cồn nồng độ cao, gas, bật lửa ga và các chất dễ bắt lửa.
                  </p>
                </div>
              </div>

              <div className="prohibited-item">
                <div>
                  <h5>Chất ma túy &amp; Độc chất nguy hiểm</h5>
                  <p>
                    Chất ma túy, tiền chất ma túy, thuốc hướng thần, thuốc độc hại, hóa chất ăn mòn (axit, bazơ mạnh), chất thải y tế, chất gây phóng xạ.
                  </p>
                </div>
              </div>

              <div className="prohibited-item">
                <div>
                  <h5>Tiền tệ &amp; Kim khí quý, Đá quý</h5>
                  <p>
                    Tiền mặt Việt Nam Đồng, ngoại tệ các nước, séc, chứng từ có giá trị thanh toán, vàng miếng, bạch kim, kim cương, đá quý tự nhiên chưa kiểm định.
                  </p>
                </div>
              </div>

              <div className="prohibited-item">
                <div>
                  <h5>Động vật sống &amp; Thực phẩm tươi sống có mùi</h5>
                  <p>
                    Động vật hoang dã, thú cưng sống, thi hài, tro cốt; thực phẩm tươi sống dễ ươn hỏng, mắm tôm, sầu riêng hoặc thực phẩm phát sinh mùi nồng nặc không bọc kín.
                  </p>
                </div>
              </div>

              <div className="prohibited-item">
                <div>
                  <h5>Tài liệu phản động &amp; Văn hóa phẩm đồi trụy</h5>
                  <p>
                    Tài liệu, ấn phẩm nhằm phá hoại trật tự an ninh quốc gia; văn hóa phẩm khiêu dâm, đồi trụy, mê tín dị đoan hoặc các ấn phẩm xâm phạm quyền tác giả.
                  </p>
                </div>
              </div>

              <div className="prohibited-item">
                <div>
                  <h5>Hàng lậu &amp; Hàng không rõ nguồn gốc</h5>
                  <p>
                    Hàng hóa nhập lậu trốn thuế, hàng giả, hàng nhái nhãn hiệu không có hóa đơn chứng từ hợp pháp kèm theo khi cơ quan chức năng kiểm tra liên ngành.
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* Mục 3: Chính sách bồi thường sự cố */}
          <section className="policy-card">
            <h3 className="policy-card-title">
              3. Chính sách bảo hiểm &amp; Bồi thường sự cố
            </h3>
            <p className="muted" style={{ marginBottom: "18px" }}>
              Express cam kết trách nhiệm cao nhất với tài sản của quý khách. Mức bồi thường được quy định rõ ràng và minh bạch theo phân loại hàng hóa:
            </p>

            <div className="compensation-box">
              <div className="compensation-tier">
                <h5>Đơn hàng CÓ khai giá</h5>
                <div className="comp-rate">100% Giá trị</div>
                <p>
                  Bồi thường tối đa 100% giá trị khai báo khi xảy ra mất mát, hư hỏng hoàn toàn (Căn cứ theo hóa đơn GTGT hoặc chứng từ thanh toán hợp lệ của sản phẩm).
                </p>
              </div>

              <div className="compensation-tier">
                <h5>Đơn hàng KHÔNG khai giá</h5>
                <div className="comp-rate">Gấp 4 lần Cước</div>
                <p>
                  Bồi thường bằng 04 lần cước phí vận chuyển thực tế đã thu của bưu kiện nếu phát sinh sự cố thất lạc hoặc hư hỏng toàn bộ do lỗi của đơn vị vận chuyển.
                </p>
              </div>

              <div className="compensation-tier">
                <h5>Hư hỏng một phần</h5>
                <div className="comp-rate">Theo Tỷ lệ thiệt hại</div>
                <p>
                  Bồi thường theo tỷ lệ hư hại thực tế xác định tại biên bản đồng kiểm giữa bưu tá và người nhận, tối đa không vượt quá mức bồi thường mất mát toàn bộ.
                </p>
              </div>
            </div>

            <div style={{ marginTop: "20px", padding: "16px", background: "#f8fafc", borderRadius: "10px", border: "1px solid #e2e8f0" }}>
              <h5 style={{ margin: "0 0 10px", color: "var(--express-primary)", fontSize: "14px" }}>
                Quy trình tiếp nhận &amp; Thời hạn xử lý khiếu nại
              </h5>
              <ul style={{ margin: 0, paddingLeft: "20px", fontSize: "13px", lineHeight: "1.7", color: "var(--express-text-main)" }}>
                <li>
                  <strong>Thời hạn khiếu nại:</strong> Trong vòng <strong>48 giờ</strong> kể từ thời điểm nhận hàng (đối với hư hỏng) và <strong>07 ngày</strong> (đối với đơn hàng chậm giao/mất tích).
                </li>
                <li>
                  <strong>Thời hạn giải quyết:</strong> Bộ phận CSKH tiếp nhận và phản hồi trong <strong>24 giờ</strong>; hoàn tất chi trả bồi thường trong vòng <strong>03 – 05 ngày làm việc</strong> sau khi thống nhất biên bản sự cố.
                </li>
                <li>
                  <strong>Miễn trừ trách nhiệm:</strong> Các trường hợp bất khả kháng theo quy định pháp luật (thiên tai, bão lũ, lệnh trưng dụng của nhà nước); hư hại do người gửi đóng gói không đúng quy chuẩn; người nhận đã ký nhận đầy đủ và không khiếu nại trong thời hạn quy định.
                </li>
              </ul>
            </div>
          </section>
        </div>
      )}

      {/* ========================================================
          TAB 2: CÂU HỎI THƯỜNG GẶP (FAQ) - ACCORDION
          ======================================================== */}
      {activeTab === "faq" && (
        <section className="panel">
          <div className="panel-heading">
            <div>
              <h2>Câu hỏi thường gặp (FAQ)</h2>
              <p className="muted">
                Tìm kiếm nhanh câu trả lời cho các thắc mắc phổ biến về quy trình giao nhận, thanh toán COD và bồi thường.
              </p>
            </div>
          </div>

          <div className="faq-search-box">
            <input
              id={faqSearchInputId}
              type="text"
              aria-label="Tìm kiếm câu hỏi"
              className="faq-search-input"
              placeholder="Nhập từ khóa tìm kiếm (Ví dụ: COD, thời gian giao, tra cứu, hủy đơn...)"
              value={faqSearch}
              onChange={(e) => setFaqSearch(e.target.value)}
            />
          </div>

          <div className="faq-list">
            {filteredFaq.length === 0 ? (
              <div className="empty">
                <h3>Không tìm thấy câu hỏi phù hợp</h3>
                <p>Thử tìm kiếm với từ khóa khác hoặc liên hệ bộ phận hỗ trợ khách hàng của Express.</p>
              </div>
            ) : (
              filteredFaq.map((item) => {
                const isOpen = openFaqId === item.id;
                return (
                  <article key={item.id} className={`faq-item ${isOpen ? "open" : ""}`}>
                    <button
                      type="button"
                      className="faq-question-btn"
                      onClick={() => toggleFaq(item.id)}
                      aria-expanded={isOpen}
                    >
                      <div className="faq-question-text">
                        <span className="faq-q-badge">?</span>
                        <span>{item.question}</span>
                      </div>
                      <span className={`faq-chevron ${isOpen ? "open" : ""}`}>▼</span>
                    </button>

                    {isOpen && (
                      <div className="faq-answer">
                        <p>{item.answer}</p>
                      </div>
                    )}
                  </article>
                );
              })
            )}
          </div>
        </section>
      )}
    </div>
  );
}

