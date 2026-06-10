# Requirements Document

## Introduction

Voice Expense Manager là ứng dụng quản lý chi tiêu cá nhân lấy giao diện giọng nói làm trung tâm. Người dùng có thể ghi lại khoản chi tiêu, theo dõi ngân sách, xem báo cáo, và quản lý danh mục — tất cả thông qua lệnh thoại (voice command). Ứng dụng hỗ trợ tiếng Việt và tiếng Anh, xử lý ngôn ngữ tự nhiên để trích xuất thông tin chi tiêu từ câu nói, và phản hồi lại bằng giọng nói tổng hợp.

## Glossary

- **Voice_Input_Module**: Thành phần tiếp nhận và xử lý giọng nói đầu vào từ microphone của người dùng.
- **Speech_Recognition_Engine**: Thành phần chuyển đổi giọng nói thành văn bản (Speech-to-Text).
- **NLP_Processor**: Thành phần xử lý ngôn ngữ tự nhiên, trích xuất thực thể (số tiền, danh mục, ngày) từ văn bản.
- **TTS_Engine**: Thành phần chuyển đổi văn bản phản hồi thành giọng nói (Text-to-Speech).
- **Expense_Manager**: Thành phần lõi xử lý logic tạo, đọc, cập nhật, xóa khoản chi tiêu.
- **Budget_Manager**: Thành phần quản lý ngân sách theo danh mục và theo kỳ (tháng/tuần).
- **Report_Generator**: Thành phần tổng hợp và tạo báo cáo chi tiêu.
- **Category_Manager**: Thành phần quản lý danh mục chi tiêu.
- **Data_Store**: Cơ sở dữ liệu lưu trữ các khoản chi tiêu, danh mục, và ngân sách.
- **Expense**: Một khoản chi tiêu gồm số tiền, danh mục, ghi chú tùy chọn, và thời gian.
- **Category**: Nhãn phân loại chi tiêu (ví dụ: Ăn uống, Đi lại, Giải trí).
- **Budget**: Hạn mức chi tiêu cho một danh mục trong một kỳ thời gian nhất định.
- **Voice_Command**: Câu nói của người dùng thể hiện ý định thực hiện một thao tác trong ứng dụng.
- **Intent**: Ý định được trích xuất từ Voice_Command (ví dụ: add_expense, view_report, set_budget).
- **Confirmation_Flow**: Luồng xác nhận yêu cầu người dùng nói "có/yes" hoặc "không/no" trước khi thực thi.

---

## Requirements

### Requirement 1: Nhận diện giọng nói và chuyển đổi văn bản

**User Story:** Là người dùng, tôi muốn nói vào microphone và được ứng dụng hiểu lệnh của tôi, để tôi có thể điều khiển ứng dụng hoàn toàn bằng giọng nói mà không cần gõ phím.

#### Acceptance Criteria

1. WHEN người dùng nhấn nút kích hoạt giọng nói, THE Voice_Input_Module SHALL bắt đầu thu âm trong vòng 500ms.
2. WHEN Voice_Input_Module đang thu âm và phát hiện 2 giây im lặng liên tục hoặc đạt tối đa 10 giây, tùy điều kiện nào xảy ra trước, THE Voice_Input_Module SHALL dừng thu âm.
3. WHEN Voice_Input_Module dừng thu âm do phát hiện im lặng hoặc đạt giới hạn thời gian, THE Speech_Recognition_Engine SHALL chuyển đổi âm thanh thu được thành văn bản trong vòng 3 giây.
4. IF Voice_Input_Module dừng thu âm vì lý do khác (không phải im lặng hoặc hết thời gian), THEN THE Speech_Recognition_Engine SHALL không xử lý âm thanh đó.
5. IF Voice_Input_Module không phát hiện bất kỳ âm thanh giọng nói nào trong suốt phiên thu âm, THEN THE Voice_Input_Module SHALL dừng thu âm và THE TTS_Engine SHALL thông báo không nhận được giọng nói.
6. IF Speech_Recognition_Engine nhận diện văn bản với độ tin cậy dưới 70%, THEN THE TTS_Engine SHALL yêu cầu người dùng nói lại; sau 3 lần thử không thành công, THE Voice_Input_Module SHALL kết thúc phiên và thông báo người dùng thử lại sau.
7. THE Speech_Recognition_Engine SHALL sử dụng ngôn ngữ tương ứng với cài đặt ngôn ngữ hiện tại của ứng dụng (tiếng Việt hoặc tiếng Anh) để nhận diện giọng nói.
8. WHEN Speech_Recognition_Engine trả về văn bản với độ tin cậy từ 70% trở lên, THE NLP_Processor SHALL phân tích văn bản và trích xuất Intent trong vòng 1 giây, bất kể trạng thái tổng thể của kết quả nhận diện.
9. IF NLP_Processor không tìm thấy Intent nào khớp với văn bản được nhận diện, THEN THE TTS_Engine SHALL thông báo không hiểu yêu cầu và gợi ý người dùng nói lại rõ hơn.

---

### Requirement 2: Ghi nhận khoản chi tiêu bằng giọng nói

**User Story:** Là người dùng, tôi muốn nói một câu tự nhiên như "tôi vừa chi 50 nghìn tiền cà phê" để ghi lại chi tiêu, để tôi không cần điền form thủ công.

#### Acceptance Criteria

1. WHEN NLP_Processor nhận diện Intent là `add_expense`, THE NLP_Processor SHALL trích xuất số tiền, danh mục, và ghi chú tùy chọn từ Voice_Command.
2. WHEN NLP_Processor trích xuất thành công đầy đủ thông tin bắt buộc (số tiền và danh mục), THE TTS_Engine SHALL đọc tóm tắt thông tin (số tiền, danh mục, thời gian) và chuyển sang Confirmation_Flow.
3. WHEN người dùng xác nhận trong Confirmation_Flow, THE Expense_Manager SHALL lưu Expense vào Data_Store và THE TTS_Engine SHALL phản hồi xác nhận thành công kèm thông tin khoản vừa lưu.
4. IF NLP_Processor không trích xuất được số tiền từ Voice_Command, THEN THE TTS_Engine SHALL hỏi "Bạn chi bao nhiêu tiền?" và chờ Voice_Command tiếp theo cung cấp số tiền.
5. IF NLP_Processor không xác định được danh mục từ Voice_Command, THEN THE NLP_Processor SHALL chọn tối đa 3 danh mục phù hợp nhất (hoặc đọc danh sách rỗng nếu không có gợi ý nào) và THE TTS_Engine SHALL đọc danh sách gợi ý và yêu cầu người dùng chọn bằng giọng nói.
6. WHEN người dùng chỉ định thời gian trong Voice_Command (ví dụ: "hôm qua", "sáng nay"), THE Expense_Manager SHALL ghi nhận thời gian đó cho Expense; WHEN người dùng không chỉ định thời gian, THE Expense_Manager SHALL ghi nhận thời gian xác nhận trong Confirmation_Flow.
7. WHEN người dùng nói thời gian tương đối trong Voice_Command (ví dụ: "hôm qua", "sáng nay", "thứ hai tuần trước"), THE NLP_Processor SHALL chuyển đổi thành timestamp tuyệt đối dựa trên thời gian hiện tại của thiết bị trước khi lưu.

---

### Requirement 3: Truy vấn và xem lịch sử chi tiêu bằng giọng nói

**User Story:** Là người dùng, tôi muốn hỏi "tuần này tôi tiêu bao nhiêu tiền ăn uống" và nhận câu trả lời bằng giọng nói, để tôi nắm được tình hình chi tiêu của mình nhanh chóng.

#### Acceptance Criteria

1. WHEN NLP_Processor nhận diện Intent là `query_expense`, THE Expense_Manager SHALL truy vấn Data_Store theo các bộ lọc được trích xuất (khoảng thời gian, danh mục, khoảng số tiền).
2. WHEN truy vấn trả về từ 1 đến 5 khoản chi tiêu, THE TTS_Engine SHALL đọc tên và số tiền từng khoản theo thứ tự thời gian giảm dần, kết thúc bằng tổng số khoản và tổng số tiền.
3. IF truy vấn không tìm thấy khoản chi tiêu nào, THEN THE TTS_Engine SHALL thông báo không có dữ liệu khớp với điều kiện tìm kiếm.
4. IF kết quả truy vấn có trên 5 khoản, THEN THE TTS_Engine SHALL đọc tóm tắt tổng hợp gồm tổng số khoản, tổng số tiền, và danh mục chiếm tỷ lệ cao nhất.
5. THE Expense_Manager SHALL hỗ trợ truy vấn theo khoảng thời gian với định nghĩa: "hôm nay" (00:00–23:59 ngày hiện tại), "hôm qua" (00:00–23:59 ngày hôm trước), "tuần này" (thứ Hai đến ngày hiện tại của tuần hiện tại), "tháng này" (ngày 1 đến ngày hiện tại của tháng hiện tại), và khoảng ngày tùy chỉnh tối đa 365 ngày.
6. IF NLP_Processor không trích xuất được bộ lọc thời gian hợp lệ từ Voice_Command, THEN THE TTS_Engine SHALL hỏi người dùng muốn xem chi tiêu trong khoảng thời gian nào.

---

### Requirement 4: Quản lý ngân sách bằng giọng nói

**User Story:** Là người dùng, tôi muốn đặt hạn mức chi tiêu cho từng danh mục bằng giọng nói và nhận cảnh báo khi sắp vượt ngân sách, để tôi kiểm soát tài chính có kế hoạch hơn.

#### Acceptance Criteria

1. WHEN NLP_Processor nhận diện Intent là `set_budget`, THE Budget_Manager SHALL tạo hoặc cập nhật Budget với số tiền hợp lệ (từ 0.01 đến 999,999,999.99) cho danh mục và kỳ thời gian (ngày/tuần/tháng/năm) được chỉ định.
2. WHEN Budget_Manager tạo hoặc cập nhật Budget thành công, THE TTS_Engine SHALL xác nhận bằng cách đọc tên danh mục, số tiền ngân sách, và kỳ thời gian vừa được thiết lập.
3. IF NLP_Processor không trích xuất được đủ thông tin (danh mục hoặc kỳ thời gian) từ Voice_Command `set_budget`, THEN THE TTS_Engine SHALL hỏi lại người dùng về thông tin còn thiếu.
4. WHEN Expense_Manager lưu một Expense mới và tổng chi tiêu của danh mục trong kỳ đạt từ 80% đến dưới 100% Budget lần đầu tiên, THE Budget_Manager SHALL thông báo cảnh báo qua TTS_Engine kèm phần trăm đã sử dụng và số tiền còn lại.
5. WHEN Expense_Manager lưu một Expense mới và tổng chi tiêu của danh mục trong kỳ vượt 100% Budget lần đầu tiên, THE Budget_Manager SHALL thông báo đã vượt ngân sách, số tiền vượt, và tổng chi tiêu hiện tại qua TTS_Engine.
6. WHEN Expense_Manager lưu một Expense mới và danh mục đã ở trạng thái vượt ngân sách từ trước, THE Budget_Manager SHALL không phát lại cảnh báo vượt ngân sách.
7. WHEN NLP_Processor nhận diện Intent là `query_budget`, THE Budget_Manager SHALL đọc số tiền đã dùng, số tiền còn lại, và phần trăm đã sử dụng của Budget được chỉ định qua TTS_Engine.
8. IF NLP_Processor nhận diện Intent là `query_budget` nhưng không có Budget nào tồn tại cho danh mục được chỉ định, THEN THE TTS_Engine SHALL thông báo chưa có ngân sách cho danh mục đó và gợi ý người dùng thiết lập.
9. IF người dùng đặt Budget với số tiền bằng 0, âm, hoặc vượt quá 999,999,999.99, THEN THE Budget_Manager SHALL từ chối yêu cầu và THE TTS_Engine SHALL thông báo số tiền không hợp lệ và yêu cầu nhập lại.

---

### Requirement 5: Xem báo cáo chi tiêu bằng giọng nói

**User Story:** Là người dùng, tôi muốn nghe tóm tắt chi tiêu theo tháng hoặc theo danh mục, để tôi hiểu được thói quen chi tiêu của mình mà không cần nhìn vào màn hình.

#### Acceptance Criteria

1. WHEN NLP_Processor nhận diện Intent là `view_report`, THE Report_Generator SHALL tổng hợp dữ liệu Expense từ Data_Store theo kỳ được chỉ định.
2. WHEN Report_Generator tổng hợp xong, THE TTS_Engine SHALL đọc báo cáo bao gồm: tổng chi tiêu của kỳ, danh mục chiếm tỷ lệ cao nhất (tên và phần trăm), và so sánh tổng chi tiêu với kỳ trước nếu có dữ liệu (tăng/giảm bao nhiêu phần trăm).
3. WHEN người dùng yêu cầu báo cáo theo danh mục cụ thể, THE Report_Generator SHALL tổng hợp dữ liệu theo danh mục và THE TTS_Engine SHALL đọc tối đa 5 danh mục theo thứ tự chi tiêu từ cao xuống thấp, kèm số tiền và phần trăm của mỗi danh mục; giới hạn 5 danh mục và thứ tự này chỉ áp dụng cho loại báo cáo theo danh mục.
4. IF Data_Store không có dữ liệu Expense nào cho kỳ được yêu cầu, THEN THE Report_Generator SHALL không tổng hợp và THE TTS_Engine SHALL thông báo không có dữ liệu chi tiêu cho kỳ đó.
5. WHERE ứng dụng có giao diện màn hình, THE Report_Generator SHALL hiển thị biểu đồ tròn hoặc cột trực quan theo danh mục đồng thời với khi TTS_Engine đang đọc báo cáo giọng nói.

---

### Requirement 6: Quản lý danh mục chi tiêu bằng giọng nói

**User Story:** Là người dùng, tôi muốn tạo, đổi tên, và xóa danh mục chi tiêu bằng giọng nói, để tôi tùy chỉnh ứng dụng phù hợp với thói quen chi tiêu của mình.

#### Acceptance Criteria

1. WHEN NLP_Processor nhận diện Intent là `create_category`, THE Category_Manager SHALL kiểm tra tên danh mục có hợp lệ (1–50 ký tự, không rỗng) trước khi tạo.
2. WHEN tên danh mục hợp lệ và chưa tồn tại trong Data_Store, THE Category_Manager SHALL tạo danh mục mới và THE TTS_Engine SHALL xác nhận tên danh mục vừa tạo.
3. IF tên danh mục đã tồn tại trong Data_Store (so sánh không phân biệt hoa thường), THEN THE Category_Manager SHALL không tạo danh mục trùng và THE TTS_Engine SHALL thông báo tên đã được sử dụng và yêu cầu người dùng chọn tên khác.
4. WHEN NLP_Processor nhận diện Intent là `delete_category`, THE Category_Manager SHALL kiểm tra danh mục có tồn tại và THE TTS_Engine SHALL yêu cầu xác nhận qua Confirmation_Flow trước khi xóa.
5. WHEN người dùng xác nhận xóa danh mục, THE Category_Manager SHALL xóa danh mục khỏi Data_Store và tự động chuyển tất cả Expense thuộc danh mục đó sang danh mục "Không phân loại", sau đó THE TTS_Engine SHALL xác nhận đã xóa.
6. THE Category_Manager SHALL ngăn xóa hoặc đổi tên 8 danh mục mặc định: Ăn uống, Đi lại, Mua sắm, Giải trí, Sức khỏe, Hóa đơn, Giáo dục, Khác; THE TTS_Engine SHALL thông báo khi người dùng cố xóa/đổi tên danh mục mặc định.
7. WHEN NLP_Processor nhận diện Intent là `rename_category`, THE Category_Manager SHALL yêu cầu xác nhận tên mới qua Confirmation_Flow; tên mới phải hợp lệ (1–50 ký tự) và chưa tồn tại trong Data_Store.
8. IF tên mới trong `rename_category` đã tồn tại trong Data_Store (so sánh không phân biệt hoa thường), THEN THE Category_Manager SHALL không thực hiện đổi tên và THE TTS_Engine SHALL thông báo tên đã được sử dụng.
9. IF danh mục không tồn tại trong Data_Store khi xử lý Intent `delete_category` hoặc `rename_category`, THEN THE TTS_Engine SHALL thông báo không tìm thấy danh mục và yêu cầu người dùng kiểm tra lại tên.
10. WHEN người dùng từ chối xác nhận trong Confirmation_Flow cho `delete_category` hoặc `rename_category`, THE Category_Manager SHALL hủy thao tác và THE TTS_Engine SHALL thông báo đã hủy.

---

### Requirement 7: Phân tích ngôn ngữ tự nhiên và ánh xạ Intent

**User Story:** Là người dùng, tôi muốn nói theo cách tự nhiên của tôi và ứng dụng hiểu đúng ý định, để tôi không phải học thuộc lòng các lệnh cố định.

#### Acceptance Criteria

1. WHEN NLP_Processor nhận được văn bản từ Speech_Recognition_Engine, THE NLP_Processor SHALL ánh xạ các biến thể ngôn ngữ tự nhiên của cùng một Intent về cùng một nhãn Intent chuẩn (ví dụ: "chi tiêu", "mua", "trả tiền", "thanh toán" đều ánh xạ đến `add_expense`).
2. WHEN NLP_Processor nhận diện được Intent với độ tin cậy từ 60% trở lên, THE NLP_Processor SHALL trả về Intent đó để tiếp tục xử lý.
3. WHEN NLP_Processor nhận diện Intent với độ tin cậy dưới 60%, THE TTS_Engine SHALL liệt kê tối đa 3 Intent có xác suất cao nhất và yêu cầu người dùng xác nhận; IF người dùng không xác nhận trong 10 giây, THEN THE Voice_Input_Module SHALL kết thúc phiên xác nhận.
4. WHEN NLP_Processor phân tích số tiền trong Voice_Command, THE NLP_Processor SHALL chuẩn hóa số tiền sang giá trị số nguyên hoặc thập phân (ví dụ: "50k" → 50000, "2 triệu" → 2000000, "1.5tr" → 1500000, "năm mươi nghìn" → 50000); IF NLP_Processor không thể phân tích cụm số tiền thành giá trị số, THEN THE NLP_Processor SHALL bỏ qua trường số tiền và tiếp tục xử lý mà không báo lỗi.
5. WHEN NLP_Processor phát hiện đơn vị tiền tệ trong Voice_Command, THE NLP_Processor SHALL chuẩn hóa về một trong hai đơn vị VND hoặc USD và lưu cùng với giá trị số tiền.
6. THE NLP_Processor SHALL luôn xử lý Intent theo chế độ tuần tự; IF Voice_Command chứa nhiều hơn một Intent, THEN THE NLP_Processor SHALL tách thành danh sách tối đa 3 Intent theo thứ tự xuất hiện và xử lý từng Intent một, xác nhận với người dùng trước khi chuyển sang Intent tiếp theo.

---

### Requirement 8: Phản hồi giọng nói và trải nghiệm người dùng

**User Story:** Là người dùng, tôi muốn nhận phản hồi bằng giọng nói rõ ràng, ngắn gọn, và tự nhiên, để tôi có thể sử dụng ứng dụng mà không cần nhìn màn hình.

#### Acceptance Criteria

1. WHEN hệ thống hoàn tất xử lý một yêu cầu, THE TTS_Engine SHALL bắt đầu phát phản hồi bằng giọng nói trong vòng 2 giây kể từ khi xử lý xong.
2. WHEN TTS_Engine phát phản hồi, THE TTS_Engine SHALL sử dụng cùng ngôn ngữ với Voice_Command của người dùng (tiếng Việt hoặc tiếng Anh) để đọc phản hồi.
3. WHEN TTS_Engine bắt đầu phát âm, THE Voice_Input_Module SHALL tạm dừng thu âm mới và chỉ kích hoạt lại sau khi TTS_Engine kết thúc phát âm hoàn toàn; IF TTS_Engine bị dừng giữa chừng bởi lệnh dừng của người dùng, THEN THE Voice_Input_Module SHALL không tự động kích hoạt lại thu âm.
4. THE TTS_Engine SHALL hỗ trợ người dùng điều chỉnh tốc độ đọc từ 0.5x đến 2.0x tốc độ chuẩn; WHERE ứng dụng có màn hình cài đặt, thay đổi tốc độ có hiệu lực ngay cho lần phát tiếp theo; WHERE ứng dụng không có màn hình cài đặt, thay đổi tốc độ được chấp nhận nhưng chỉ có hiệu lực khi màn hình cài đặt khả dụng.
5. WHEN người dùng nói từ khoá dừng ("dừng lại", "thôi", "stop", "cancel") trong khi TTS_Engine đang phát âm, THE TTS_Engine SHALL dừng phát âm ngay lập tức trong vòng 200ms.
6. IF hệ thống cần hơn 2 giây để xử lý một yêu cầu, THEN THE TTS_Engine SHALL phát thông báo chờ (ví dụ: "Đang xử lý, vui lòng chờ...") trong vòng 2 giây kể từ khi nhận yêu cầu và không lặp lại thông báo chờ cho cùng một yêu cầu.

---

### Requirement 9: Lưu trữ và đồng bộ dữ liệu

**User Story:** Là người dùng, tôi muốn dữ liệu chi tiêu của mình được lưu trữ an toàn và không bị mất khi đóng ứng dụng, để tôi có thể truy cập lịch sử chi tiêu bất cứ lúc nào.

#### Acceptance Criteria

1. THE Data_Store SHALL lưu trữ tất cả Expense, Category, và Budget trên thiết bị cục bộ để đảm bảo ứng dụng đọc và ghi dữ liệu hoạt động khi không có kết nối internet.
2. WHEN người dùng tạo, cập nhật, hoặc xóa một Expense, THE Data_Store SHALL hoàn tất ghi dữ liệu vào bộ nhớ cục bộ trong vòng 500ms kể từ khi người dùng xác nhận thao tác.
3. WHERE ứng dụng có kết nối internet, THE Data_Store SHALL đồng bộ dữ liệu với cloud storage trong nền với mức sử dụng CPU không vượt quá 10% trong suốt quá trình đồng bộ.
4. IF quá trình đồng bộ thất bại, THEN THE Data_Store SHALL lưu các thay đổi vào hàng đợi đồng bộ (tối đa 1.000 mục) và thử lại theo cơ chế exponential backoff (1s, 2s, 4s, 8s, 16s) tối đa 5 lần; hàng đợi được duy trì khi khởi động lại ứng dụng.
5. WHEN người dùng yêu cầu xuất dữ liệu qua Voice_Command, THE Data_Store SHALL xuất dữ liệu Expense ra file CSV hoặc JSON bao gồm các trường: id, số tiền (2 chữ số thập phân), đơn vị tiền tệ, danh mục, ghi chú, và timestamp (chính xác đến giây).
6. IF hàng đợi đồng bộ đạt đến giới hạn 1.000 mục, THEN THE Data_Store SHALL từ chối thêm mục mới vào hàng đợi và THE TTS_Engine SHALL thông báo người dùng về tình trạng đồng bộ bị tắc nghẽn.
7. WHEN người dùng xuất dữ liệu ra CSV và sau đó nhập lại file đó vào ứng dụng, THE Data_Store SHALL tạo ra bản ghi Expense với số tiền giống nhau (chính xác đến 2 chữ số thập phân), cùng tên danh mục, và cùng timestamp chính xác đến giây.

---

### Requirement 10: Bảo mật và quyền riêng tư

**User Story:** Là người dùng, tôi muốn dữ liệu tài chính của mình được bảo vệ, để thông tin chi tiêu cá nhân không bị lộ ra ngoài.

#### Acceptance Criteria

1. WHEN người dùng nhấn nút hoặc chạm vào biểu tượng microphone, THE Voice_Input_Module SHALL bắt đầu ghi âm; không có cơ chế nào khác (kích hoạt bằng giọng nói, tự động tiếp tục phiên) được phép bắt đầu ghi âm; WHEN người dùng nhấn lại hoặc Voice_Input_Module phát hiện kết thúc phiên, THE Voice_Input_Module SHALL dừng ghi âm ngay lập tức; ứng dụng không được ghi âm nền ngoài hai trạng thái này.
2. WHERE ứng dụng sử dụng Speech_Recognition_Engine bên thứ ba, THE Voice_Input_Module SHALL chỉ gửi văn bản đã được chuyển đổi tới các dịch vụ xử lý nội bộ; không gửi dữ liệu âm thanh thô lên bất kỳ server bên ngoài nào.
3. THE Data_Store SHALL mã hóa tất cả dữ liệu tài chính (giao dịch, danh mục, ghi chú) lưu trữ cục bộ bằng thuật toán mã hóa đối xứng với khóa có độ dài tối thiểu 256-bit.
4. WHEN người dùng xóa tài khoản hoặc yêu cầu xóa toàn bộ dữ liệu, THE Data_Store SHALL xóa toàn bộ dữ liệu cục bộ và gửi yêu cầu xóa cloud trong vòng 24 giờ; THE TTS_Engine SHALL xác nhận đã xóa sau khi hoàn tất.
5. IF ứng dụng không nhận được tương tác nào trong 5 phút liên tục, THEN THE Voice_Input_Module SHALL vẫn giữ tính năng giọng nói ở trạng thái kỹ thuật hoạt động nhưng yêu cầu người dùng xác thực lại bằng PIN hoặc sinh trắc học đã đăng ký trước khi xử lý bất kỳ Voice_Command nào tiếp theo.
6. IF người dùng thất bại xác thực lại 3 lần liên tiếp, THEN THE Voice_Input_Module SHALL vô hiệu hóa hoàn toàn tính năng giọng nói và yêu cầu người dùng đăng nhập lại qua màn hình chính của ứng dụng.
