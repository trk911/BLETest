import SwiftUI

// نموذج الرسالة
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isMe: Bool
}

struct ContentView: View {
    @State private var messageToSend = ""
    @ObservedObject var bleManager = BLEManager()
    
    @State private var messages: [ChatMessage] = []
    
    var body: some View {
        VStack(spacing: 0) {
            
            // قائمة الرسائل
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(messages) { msg in
                        HStack {
                            
                            if msg.isMe {
                                Spacer()
                                
                                Text(msg.text)
                                    .padding(10)
                                    .background(Color.green.opacity(0.3))
                                    .cornerRadius(12)
                                    .frame(maxWidth: 250, alignment: .trailing)
                                
                            } else {
                                
                                Text(msg.text)
                                    .padding(10)
                                    .background(Color.blue.opacity(0.25))
                                    .cornerRadius(12)
                                    .frame(maxWidth: 250, alignment: .leading)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // حقل الكتابة + زر الإرسال
            HStack {
                TextField("اكتب رسالة...", text: $messageToSend)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 40)
                
                Button(action: sendMessage) {
                    Text("إرسال")
                        .bold()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.4))
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        
        // مراقبة الرسائل المستلمة من BLE
        .onReceive(bleManager.$receivedMessages) { newMessages in
            if let last = newMessages.last {
                messages.append(ChatMessage(text: last, isMe: false))
            }
        }
    }
    
    // إرسال الرسالة
    func sendMessage() {
        guard !messageToSend.isEmpty else { return }
        
        // أضفها محليًا كرسالة مرسلة
        messages.append(ChatMessage(text: messageToSend, isMe: true))
        
        // أرسل عبر البلوتوث
        bleManager.sendMessage(messageToSend)
        
        // تنظيف الحقل
        messageToSend = ""
    }
}
