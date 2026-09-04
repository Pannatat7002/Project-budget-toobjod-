import Cocoa

let sourcePath = "assets/images/app_icon_fresh_scaled.png"

guard let sourceImage = NSImage(contentsOfFile: sourcePath) else {
    print("Failed to load source image from: \(sourcePath)")
    exit(1)
}

func resizeAndSave(image: NSImage, size: Int, destPath: String) {
    let newRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
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
        in: NSRect(x: 0, y: 0, width: size, height: size),
        from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
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
        print("Successfully generated \(size)x\(size) -> \(destPath)")
    } catch {
        print("Error writing to \(destPath): \(error)")
    }
}

// 1. Assets
resizeAndSave(image: sourceImage, size: 1024, destPath: "assets/images/app_icon.png")
resizeAndSave(image: sourceImage, size: 512, destPath: "assets/images/app_icon_512.png")
resizeAndSave(image: sourceImage, size: 1024, destPath: "assets/icon/app_icon.png")

// 2. Android Mipmap Icons (Pure Full Bleed Orange)
resizeAndSave(image: sourceImage, size: 48, destPath: "android/app/src/main/res/mipmap-mdpi/ic_launcher.png")
resizeAndSave(image: sourceImage, size: 72, destPath: "android/app/src/main/res/mipmap-hdpi/ic_launcher.png")
resizeAndSave(image: sourceImage, size: 96, destPath: "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png")
resizeAndSave(image: sourceImage, size: 144, destPath: "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png")
resizeAndSave(image: sourceImage, size: 192, destPath: "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png")

// 3. iOS AppIcon.appiconset (Pure Full Bleed Orange)
resizeAndSave(image: sourceImage, size: 1024, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png")
resizeAndSave(image: sourceImage, size: 20, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png")
resizeAndSave(image: sourceImage, size: 40, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png")
resizeAndSave(image: sourceImage, size: 60, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png")
resizeAndSave(image: sourceImage, size: 29, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png")
resizeAndSave(image: sourceImage, size: 58, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png")
resizeAndSave(image: sourceImage, size: 87, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png")
resizeAndSave(image: sourceImage, size: 40, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png")
resizeAndSave(image: sourceImage, size: 80, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png")
resizeAndSave(image: sourceImage, size: 120, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png")
resizeAndSave(image: sourceImage, size: 120, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png")
resizeAndSave(image: sourceImage, size: 180, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png")
resizeAndSave(image: sourceImage, size: 76, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png")
resizeAndSave(image: sourceImage, size: 152, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png")
resizeAndSave(image: sourceImage, size: 167, destPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png")

// 4. Web Icons
resizeAndSave(image: sourceImage, size: 192, destPath: "web/icons/Icon-192.png")
resizeAndSave(image: sourceImage, size: 512, destPath: "web/icons/Icon-512.png")
resizeAndSave(image: sourceImage, size: 192, destPath: "web/icons/Icon-maskable-192.png")
resizeAndSave(image: sourceImage, size: 512, destPath: "web/icons/Icon-maskable-512.png")
resizeAndSave(image: sourceImage, size: 64, destPath: "web/favicon.png")

print("All icons updated to pure seamless full-bleed version!")
