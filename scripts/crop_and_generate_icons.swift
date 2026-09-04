import Cocoa

let sourcePath = "/Users/palm/.gemini/antigravity-ide/brain/f7e570ad-f418-465d-a907-d7cfe31b4e85/app_icon_toobjod_1788160774150.jpg"

guard let sourceImage = NSImage(contentsOfFile: sourcePath) else {
    print("Failed to load source image from: \(sourcePath)")
    exit(1)
}

// Crop region: The inner card without the outer border (fits edge-to-edge)
// Note: In Cocoa coordinates, (0,0) is bottom-left.
// The inner card is centered around (x: 130, y: 130) with width 764 and height 764
let cropRect = NSRect(x: 130, y: 130, width: 764, height: 764)

func cropResizeAndSave(image: NSImage, srcRect: NSRect, destSize: Int, destPath: String) {
    let newRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: destSize,
        pixelsHigh: destSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: newRep)
    NSGraphicsContext.current?.imageInterpolation = .high

    image.draw(
        in: NSRect(x: 0, y: 0, width: destSize, height: destSize),
        from: srcRect,
        operation: .copy,
        fraction: 1.0
    )

    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = newRep.representation(using: .png, properties: [:]) else {
        print("Failed to generate PNG data for \(destPath)")
        return
    }

    let url = URL(fileURLWithPath: destPath)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    do {
        try pngData.write(to: url)
        print("Successfully generated \(destSize)x\(destSize) -> \(destPath)")
    } catch {
        print("Error writing to \(destPath): \(error)")
    }
}

// 1. Assets
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 1024, destPath: "assets/images/app_icon.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 512, destPath: "assets/images/app_icon_512.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 1024, destPath: "assets/icon/app_icon.png")

// 2. Android Mipmap Icons (Full Bleed Edge-to-Edge)
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 48, destPath: "android/app/src/main/res/mipmap-mdpi/ic_launcher.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 72, destPath: "android/app/src/main/res/mipmap-hdpi/ic_launcher.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 96, destPath: "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 144, destPath: "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 192, destPath: "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png")

// 3. iOS AppIcon.appiconset (Full Bleed Edge-to-Edge)
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 1024, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 20, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 40, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 60, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 29, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 58, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 87, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 40, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 80, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 120, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 120, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 180, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 76, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 152, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 167, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png")

// 4. Web Icons
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 192, destPath: "web/icons/Icon-192.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 512, destPath: "web/icons/Icon-512.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 192, destPath: "web/icons/Icon-maskable-192.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 512, destPath: "web/icons/Icon-maskable-512.png")
cropResizeAndSave(image: sourceImage, srcRect: cropRect, destSize: 64, destPath: "web/favicon.png")

print("All full-bleed edge-to-edge icons generated successfully!")
