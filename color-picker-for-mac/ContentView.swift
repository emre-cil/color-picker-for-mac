import SwiftUI
import AppKit

struct ContentView: View {
    @State private var x: CGFloat = 0
    @State private var y: CGFloat = 0
    @State private var color: NSColor = .clear

    var body: some View {
        VStack {
            Text("X: \(x)")
                .foregroundColor(.red)
            Text("Y: \(y)")
                .foregroundColor(.red)
            Text("Color: \(color.toHexString())")
                .foregroundColor(Color(color))
            Rectangle()
                .fill(Color(color))
                .frame(width: 50, height: 50)
                .border(Color.black, width: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .onAppear {
            GlobalMouseTracker.shared.startTracking { location in
                self.x = location.x
                self.y = location.y
                self.color = GlobalMouseTracker.shared.getColor(at: location)
            }
        }
        .onDisappear {
            GlobalMouseTracker.shared.stopTracking()
        }
    }
}

extension NSColor {
    func toHexString() -> String {
        guard let rgbColor = usingColorSpace(.deviceRGB) else { return "#000000" }
        let red = Int(rgbColor.redComponent * 255)
        let green = Int(rgbColor.greenComponent * 255)
        let blue = Int(rgbColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

class GlobalMouseTracker {
    static let shared = GlobalMouseTracker()
    private var monitor: Any?
    private var trackingHandler: ((CGPoint) -> Void)?

    private init() {}

    func startTracking(handler: @escaping (CGPoint) -> Void) {
        self.trackingHandler = handler
        self.monitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            let location = NSEvent.mouseLocation
            self.trackingHandler?(location)
        }
    }

    func stopTracking() {
        if let monitor = self.monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    func getColor(at location: CGPoint) -> NSColor {
        let screenHeight = NSScreen.main!.frame.height
        let captureRect = CGRect(x: location.x, y: screenHeight - location.y, width: 1, height: 1)
        guard let image = CGWindowListCreateImage(captureRect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else {
            return .clear
        }
        let bitmap = NSBitmapImageRep(cgImage: image)
        guard let color = bitmap.colorAt(x: 0, y: 0) else {
            return .clear
        }
        return color
    }
}

#Preview {
    ContentView()
}