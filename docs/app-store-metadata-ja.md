# osmGenki？ App Store Connect 申請用文案（ベトナム語・v1.1.2）

最終更新：2026年11月15日

App Store Connect の各フィールドにそのまま貼り付けて使えます。文字数は提出前に再確認してください。
ストアの各欄（サブタイトル・プロモーション・概要・キーワード・最新情報）はベトナム語、審査員へのメモは日本語です。

---

## サブタイトル（30文字以内）

アプリ名の下に表示され、検索の対象にもなります。

```
Chỉ cần nói, nhật ký tự thành
```

（29文字）

---

## プロモーションテキスト（170文字以内）

審査通過後も、新バージョンを出さずに更新できます。

```
Chỉ cần nói về ngày hôm nay. AI viết thành nhật ký, chấm chỉ số Genki và khả năng hội thoại tiếng Nhật theo thang 10. Xem lại cảm xúc qua biểu đồ và lịch.
```

（154文字）

---

## 概要（説明・4,000文字以内）

```
osmGenki？ là ứng dụng nhật ký bằng giọng nói. Những ngày ngại viết, chỉ cần nói với micro về ngày hôm nay, đó sẽ trở thành nhật ký.

■ Nói để lưu lại
・Chọn thời lượng ghi âm rồi chạm micro (với “Tự do” ∞, chạm lần nữa để dừng)
・Chưa nói hết thì nói tiếp để thêm vào. Cũng có thể làm lại từ đầu
・Lắc iPhone để chuyển ngay đến màn hình “Nói”

■ AI sắp xếp thành nhật ký
・Gửi nội dung đã nói cho AI của Google, bạn sẽ nhận được nhật ký bằng chữ cùng đánh giá chỉ số Genki và khả năng hội thoại tiếng Nhật
・Dán câu trả lời để lưu thành nhật ký giọng nói của ngày hôm đó

■ Nhìn lại
・Bảng điều khiển hiển thị biểu đồ thay đổi của chỉ số Genki và khả năng hội thoại. Chụm để phóng to, kéo để di chuyển
・Chạm vào một ngày trên lịch để mở ghi chép của ngày đó
・Đọc lại nhật ký trong danh sách. Nhấn giữ điểm số để xem đánh giá chi tiết
・Nhờ AI chẩn đoán xu hướng nhật ký và xem lại sau

■ Xuất, nhập, đồng bộ
・Hỗ trợ xuất và nhập nhật ký (ghi chép trùng sẽ không bị nhân đôi)
・Đồng bộ giữa các iPhone cùng Apple ID qua iCloud (tùy chọn)

■ Hỗ trợ 3 ngôn ngữ
日本語・English・Tiếng Việt

■ Quyền riêng tư
・Không cần đăng ký tài khoản. Không quảng cáo, không phân tích truy cập, không theo dõi
・Nhật ký được lưu trên máy, không gửi về máy chủ của nhà phát triển
・Trước lần ghi âm đầu tiên, ứng dụng hỏi sự đồng ý rồi mới chuyển giọng nói thành văn bản bằng nhận dạng giọng nói của máy. Có thể rút lại đồng ý bất cứ lúc nào trong Cài đặt
・Mỗi lần gửi cho AI, bạn xác nhận nội dung trước, rồi văn bản được gửi qua trình duyệt bên ngoài đến Google Tìm kiếm (chế độ AI)

■ Thiết bị hỗ trợ
・iPhone (chỉ màn hình dọc)

Ngày vui hay ngày chưa vui, những điều bạn nói ra hôm nay sẽ tiếp thêm sức cho chính bạn sau này.
```

（1662文字）

---

## キーワード（100文字以内）

カンマ区切り。カンマの後ろにスペースは入れない（文字数節約のため）。アプリ名に含まれる語は入れない。

```
nhật ký,ghi âm,giọng nói,tâm trạng,tinh thần,tự chăm sóc,tiếng Nhật,hội thoại,luyện nói,nhìn lại
```

（96文字）

---

## このバージョンの最新情報（v1.1.2）

```
・Cải thiện cách đóng màn hình và cách sắp xếp các nút phía trên. Vuốt xuống từ đầu danh sách để đóng
・Cố định màn hình iPhone theo chiều dọc
・Phần giải thích về nhận dạng giọng nói được viết lại dễ hiểu hơn
・Sắp xếp lại bên trong ứng dụng để hoạt động ổn định hơn
```

（260文字）

---

## 審査員へのメモ（App Review Information > Notes）

```
2026/11/15
いつもアプリを審査頂きましてありがとうございます。
先にご審査いただいたVersion 1.1.1に対して、下記修正を行なっています。
・画面を閉じる操作と上部ツールバーの挙動を、同じ開発者の他アプリと揃えました（一覧の最上部から下へスワイプで閉じる）
・画面の向きを縦向きに固定しました
・音声認識の同意画面とプライバシーの説明文を見直しました（音声の処理内容・送信先に変更はありません）
・内部の共通化（動作の変更はありません）
新たな権限の要求、データの収集・送信先の変更はございません。
先に一度承認をいただいた内容から、上記修正以外の機能変更やビジネスモデルの変更はございません。
お手数をおかけして恐縮ですが、ご確認のほどよろしくお願いいたします。
```

---

## 提出前チェックリスト

- [ ] App Store Connect で新しいバージョンを 1.1.2 で作成し、`pubspec.yaml` のバージョン（1.1.2+1）と一致している（審査済みの 1.1.1 より大きいこと）
- [ ] App Privacy の回答は前バージョンから変更なし
- [ ] 音声認識の同意の説明が、プライバシーポリシー（docs/privacy-policy-ja.md）と食い違っていない
- [ ] 実機で試した（一覧の最上部から下スワイプで閉じる／縦向き固定／設定で言語を切り替えたとき、ホーム・日記一覧・ダッシュボード・ヘルプの文言がその場で替わる／録音→送信→貼り付けで保存）
