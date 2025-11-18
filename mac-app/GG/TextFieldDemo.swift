//
//  TextFieldDemo.swift
//  GG
//
//  Created by TypeWise AI
//  Demo view for testing text field reader functionality
//

import SwiftUI

struct TextFieldDemo: View {
    @State private var textField1: String = ""
    @State private var textField2: String = ""
    @State private var textArea: String = ""
    @State private var searchField: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Text Field Reader Demo")
                .font(.title)
                .fontWeight(.bold)

            Text("Use these fields to test the text field reader functionality. The main app window should show the content of whichever field is focused.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Divider()

            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading) {
                    Text("Standard Text Field:")
                        .font(.headline)
                    TextField("Enter some text here...", text: $textField1)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading) {
                    Text("Another Text Field:")
                        .font(.headline)
                    TextField("Type anything...", text: $textField2)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading) {
                    Text("Search Field:")
                        .font(.headline)
                    TextField("Search...", text: $searchField)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading) {
                    Text("Text Area (Multi-line):")
                        .font(.headline)
                    TextEditor(text: $textArea)
                        .frame(height: 100)
                        .border(Color.gray, width: 1)
                }
            }

            Spacer()

            Text("Instructions:")
                .font(.headline)

            VStack(alignment: .leading, spacing: 5) {
                Text("1. Click in any text field above")
                Text("2. Start typing")
                Text("3. Check the main app window to see if the text is being captured")
                Text("4. Try switching between different fields")
                Text("5. The focused app should show as 'GG' and the text content should update in real-time")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}

struct TextFieldDemo_Previews: PreviewProvider {
    static var previews: some View {
        TextFieldDemo()
    }
}
