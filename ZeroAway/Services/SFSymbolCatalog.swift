import AppKit

enum SFSymbolCatalog {
    static let allNames: [String] = [
        "computermouse.fill", "computermouse", "cursorarrow", "cursorarrow.click",
        "cursorarrow.click.2", "cursorarrow.motionlines", "hand.tap.fill", "hand.point.up.left.fill",
        "keyboard.fill", "keyboard", "laptopcomputer", "desktopcomputer", "display",
        "iphone", "ipad", "applewatch", "airpodspro", "headphones",
        "bolt.fill", "bolt", "sparkles", "star.fill", "star", "heart.fill", "heart",
        "moon.fill", "moon.zzz.fill", "sun.max.fill", "sun.min.fill", "cloud.fill",
        "clock.fill", "clock", "timer", "alarm.fill", "hourglass",
        "pause.fill", "pause.circle.fill", "play.fill", "play.circle.fill", "stop.fill",
        "power", "power.circle.fill", "battery.100", "battery.25",
        "figure.walk", "figure.run", "figure.stand", "person.fill", "person.2.fill",
        "eye.fill", "eye", "eye.slash.fill", "bell.fill", "bell.slash.fill",
        "exclamationmark.triangle.fill", "exclamationmark.circle.fill", "checkmark.circle.fill",
        "xmark.circle.fill", "questionmark.circle.fill", "info.circle.fill",
        "waveform.path.ecg", "waveform", "chart.line.uptrend.xyaxis",
        "cup.and.saucer.fill", "mug.fill", "fork.knife", "carrot.fill",
        "leaf.fill", "flame.fill", "drop.fill", "snowflake",
        "globe", "network", "wifi", "antenna.radiowaves.left.and.right",
        "lock.fill", "lock.open.fill", "key.fill", "shield.fill", "shield.checkered",
        "paperplane.fill", "envelope.fill", "message.fill", "bubble.left.fill",
        "phone.fill", "video.fill", "camera.fill", "photo.fill",
        "music.note", "guitars.fill", "gamecontroller.fill", "dice.fill",
        "book.fill", "graduationcap.fill", "briefcase.fill", "building.2.fill",
        "house.fill", "bed.double.fill", "sofa.fill", "lamp.desk.fill",
        "wrench.fill", "hammer.fill", "screwdriver.fill", "gearshape.fill",
        "paintbrush.fill", "pencil", "highlighter", "scissors",
        "cart.fill", "bag.fill", "creditcard.fill", "dollarsign.circle.fill",
        "airplane", "car.fill", "bicycle", "bus.fill", "tram.fill",
        "pawprint.fill", "hare.fill", "tortoise.fill", "ant.fill",
        "circle.fill", "square.fill", "triangle.fill", "diamond.fill",
        "seal.fill", "rosette", "crown.fill", "trophy.fill",
        "flag.fill", "mappin.circle.fill", "location.fill", "compass.drawing",
        "binoculars.fill", "telescope.fill", "mountain.2.fill", "beach.umbrella.fill",
        "thermometer.medium", "humidity.fill", "wind", "tornado",
        "brain.head.profile", "lungs.fill", "pills.fill", "cross.case.fill",
        "stethoscope", "bandage.fill", "allergens", "medical.thermometer.fill",
        "command", "option", "shift.fill", "space",
        "return", "delete.left.fill", "escape", "tab.fill",
    ]

    static let extendedNames: [String] = [
        "arrow.up", "arrow.down", "arrow.left", "arrow.right", "arrow.clockwise",
        "arrow.counterclockwise", "arrow.triangle.2.circlepath", "chevron.up", "chevron.down",
        "chevron.left", "chevron.right", "plus", "minus", "multiply", "divide",
        "equal", "sum", "function", "number", "textformat", "text.alignleft",
        "doc.fill", "doc.text.fill", "folder.fill", "folder.badge.plus", "tray.fill",
        "archivebox.fill", "externaldrive.fill", "internaldrive.fill", "opticaldiscdrive.fill",
        "memorychip", "cpu", "server.rack", "cable.connector", "plugs.fill",
        "lightbulb.fill", "lightbulb.max.fill", "fanblades.fill", "thermometer.sun.fill",
        "umbrella.fill", "cloud.sun.fill", "cloud.rain.fill", "cloud.snow.fill",
        "cloud.bolt.fill", "moon.stars.fill", "sunrise.fill", "sunset.fill",
        "calendar", "calendar.badge.clock", "calendar.badge.plus", "clock.badge.checkmark", "clock.circle.fill",
        "stopwatch.fill", "deskclock.fill", "metronome.fill",
        "play.circle.fill", "pause.circle", "record.circle", "forward.fill", "backward.fill",
        "speaker.fill", "speaker.wave.3.fill", "mic.fill", "mic.slash.fill",
        "video.circle.fill", "dot.radiowaves.left.and.right", "antenna.radiowaves.left.and.right",
        "person.crop.circle.fill", "person.badge.plus", "person.3.fill", "shared.with.you",
        "hand.wave.fill", "hand.thumbsup.fill", "hand.raised.fill", "hands.clap.fill",
        "face.smiling.fill", "theatermasks.fill", "party.popper.fill",
        "pawprint.circle.fill", "fish.fill", "bird.fill", "ladybug.fill",
        "tree.fill", "camera.macro", "flower.fill", "laurel.leading",
        "fork.knife.circle.fill", "wineglass.fill", "birthday.cake.fill", "popcorn.fill",
        "sportscourt.fill", "basketball.fill", "football.fill", "tennisball.fill",
        "dumbbell.fill", "figure.yoga", "figure.mind.and.body", "figure.pool.swim",
        "car.circle.fill", "fuelpump.fill", "ev.charger.fill", "sailboat.fill",
        "airplane.circle.fill", "tram.circle.fill", "scooter",
        "map.fill", "location.circle.fill", "location.north.fill", "safari.fill",
        "binoculars", "map.circle.fill", "signpost.right.fill",
        "building.fill", "building.columns.fill", "storefront.fill", "parkingsign.circle.fill",
        "banknote.fill", "yensign.circle.fill", "eurosign.circle.fill", "sterlingsign.circle.fill",
        "chart.bar.fill", "chart.pie.fill", "chart.xyaxis.line", "gauge.with.dots.needle.67percent",
        "percent", "number.circle.fill", "sum", "x.squareroot",
        "lock.shield.fill", "key.horizontal.fill", "faceid", "touchid",
        "wifi.circle.fill", "personalhotspot", "bolt.horizontal.circle.fill",
        "link", "link.circle.fill", "paperclip", "doc.on.doc.fill",
        "square.and.arrow.up", "square.and.arrow.down", "trash.fill", "archivebox.fill",
        "pencil.circle.fill", "eraser.fill", "paintbrush.pointed.fill", "ruler.fill",
        "wrench.and.screwdriver.fill", "hammer.circle.fill", "scissors.circle.fill",
        "puzzlepiece.fill", "cube.fill", "shippingbox.fill", "gift.fill",
        "tag.fill", "bookmark.fill", "pin.fill", "paperclip.circle.fill",
        "bell.badge.fill", "bell.and.waves.left.and.right.fill",
        "exclamationmark.octagon.fill", "exclamationmark.shield.fill",
        "checkmark.shield.fill", "xmark.shield.fill", "questionmark.diamond.fill",
        "info.square.fill", "light.beacon.max.fill", "rays",
        "sparkle", "wand.and.stars", "fireworks", "moonphase.full.moon",
        "circle.hexagongrid.fill", "square.grid.3x3.fill", "circle.grid.3x3.fill",
        "rectangle.grid.1x2.fill", "list.bullet", "line.3.horizontal",
        "slider.horizontal.below.rectangle", "switch.2", "togglepower",
        "poweroutlet.type.b.fill", "button.programmable", "capsule.fill",
    ]

    static var available: [String] {
        var seen = Set<String>()
        return (allNames + extendedNames)
            .filter { name in
                guard !seen.contains(name) else { return false }
                seen.insert(name)
                return NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
            }
            .sorted()
    }

    static func resolved(_ name: String, fallback: String) -> String {
        if NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil { return name }
        if NSImage(systemSymbolName: fallback, accessibilityDescription: nil) != nil { return fallback }
        return "circle.fill"
    }
}
