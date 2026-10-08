import SwiftUI

struct ResourcesView: View {
    var body: some View {
        NavigationView {
            List {
                // Crisis Resources
                Section(header: Text("危机干预资源")) {
                    CrisisResourceRow(
                        name: "全国 24 小时心理援助热线",
                        number: "400-161-9995",
                        available: true
                    )
                    
                    CrisisResourceRow(
                        name: "北京心理危机研究与干预中心",
                        number: "010-82951332",
                        available: true
                    )
                    
                    CrisisResourceRow(
                        name: "生命热线（希望 24）",
                        number: "400-161-9995",
                        available: true
                    )
                }
                
                // Emergency Services
                Section(header: Text("紧急服务")) {
                    EmergencyServiceRow(
                        name: "急救",
                        number: "120",
                        color: .red
                    )
                    
                    EmergencyServiceRow(
                        name: "报警",
                        number: "110",
                        color: .blue
                    )
                }
                
                // International Resources
                Section(header: Text("国际资源")) {
                    InternationalResourceRow(
                        country: "美国",
                        name: "National Suicide Prevention Lifeline",
                        number: "988"
                    )
                    
                    InternationalResourceRow(
                        country: "美国",
                        name: "Crisis Text Line",
                        number: "Text HOME to 741741"
                    )
                    
                    InternationalResourceRow(
                        country: "英国",
                        name: "Samaritans",
                        number: "116 123"
                    )
                    
                    InternationalResourceRow(
                        country: "澳大利亚",
                        name: "Lifeline",
                        number: "13 11 14"
                    )
                }
                
                // Educational Resources
                Section(header: Text("教育资源")) {
                    EducationalResourceRow(
                        name: "心理健康知识",
                        description: "了解常见的心理健康状况和应对策略"
                    )
                    
                    EducationalResourceRow(
                        name: "自助技巧",
                        description: "CBT和正念冥想等自助方法"
                    )
                    
                    EducationalResourceRow(
                        name: "寻求专业帮助",
                        description: "如何找到合适的心理健康专业人士"
                    )
                }
            }
            .navigationTitle("资源")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Resource Row Components

struct CrisisResourceRow: View {
    let name: String
    let number: String
    let available: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(number)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if available {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Make phone call
            if let url = URL(string: "tel:\(number)") {
                UIApplication.shared.open(url)
            }
        }
    }
}

struct EmergencyServiceRow: View {
    let name: String
    let number: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(number)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "phone.fill")
                .foregroundColor(color)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Make phone call
            if let url = URL(string: "tel:\(number)") {
                UIApplication.shared.open(url)
            }
        }
    }
}

struct InternationalResourceRow: View {
    let country: String
    let name: String
    let number: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(country)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(number)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Copy number to clipboard
            UIPasteboard.general.string = number
        }
    }
}

struct EducationalResourceRow: View {
    let name: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Navigate to educational content
            // For now, just show placeholder
        }
    }
}

struct ResourcesView_Previews: PreviewProvider {
    static var previews: some View {
        ResourcesView()
    }
}