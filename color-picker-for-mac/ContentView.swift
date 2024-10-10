import SwiftUI
import AppKit

struct ContentView: View {
    @State private var colorHex: String = "Press Command + Option + P"
    @State private var color: Color = .white
    @State private var isPickingColor: Bool = false
    @State private var hexWindow: NSWindow? // Using @State to allow mutation

    var body: some View {
        VStack {
            Text(colorHex)
                .padding()
            Rectangle()
                .fill(color)
                .frame(width: 100, height: 100)
            Button("Pick Color") {
                startColorPicking()
            }
            .keyboardShortcut("P", modifiers: [.command, .option])
            .hidden() // Hide the button as we don't need it visible
        }
        .onChange(of: isPickingColor) { newValue in
            if newValue {
                NSCursor.crosshair.set()
                createHexWindow()
            } else {
                NSCursor.arrow.set()
                hexWindow?.close()
                hexWindow = nil
            }
        }
    }

    func startColorPicking() {
        isPickingColor = true
        NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { _ in
            let mouseLocation = NSEvent.mouseLocation
            if let color = getColor(at: mouseLocation) {
                self.color = Color(nsColor: color)
                self.colorHex = color.hexString
                updateHexWindow(with: color.hexString, at: mouseLocation)
            }
        }
    }

    func stopColorPicking() {
        isPickingColor = false
        NSEvent.removeMonitor(self)
    }

    func getColor(at location: NSPoint) -> NSColor? {
        guard let screen = NSScreen.main else { return nil }
        let screenHeight = screen.frame.height
        let adjustedLocation = NSPoint(x: location.x, y: screenHeight - location.y)
        let image = CGWindowListCreateImage(CGRect(origin: adjustedLocation, size: CGSize(width: 1, height: 1)), .optionOnScreenOnly, kCGNullWindowID, .bestResolution)
        guard let cgImage = image else { return nil }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        let color = bitmap.colorAt(x: 0, y: 0)
        return color
    }

    func createHexWindow() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 50),
                              styleMask: [.borderless],
                              backing: .buffered,
                              defer: false)
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear

        let textField = NSTextField(labelWithString: "")
        textField.frame = window.contentView!.bounds
        textField.alignment = .center
        textField.textColor = .white
        textField.backgroundColor = .black
        textField.isBezeled = false
        textField.drawsBackground = true

        window.contentView?.addSubview(textField)
        window.makeKeyAndOrderFront(nil)
        hexWindow = window // This should work now
    }

    func updateHexWindow(with hex: String, at location: NSPoint) {
        guard let window = hexWindow, let textField = window.contentView?.subviews.first as? NSTextField else { return }
        textField.stringValue = hex
        let screenHeight = NSScreen.main?.frame.height ?? 0
        // Position the window just above the cursor
        window.setFrameTopLeftPoint(NSPoint(x: location.x + 10, y: screenHeight - location.y - 10))
    }
}

extension NSColor {
    var hexString: String {
        let red = Int(round(self.redComponent * 0xFF))
        let green = Int(round(self.greenComponent * 0xFF))
        let blue = Int(round(self.blueComponent * 0xFF))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

#Preview {
    ContentView()
}
