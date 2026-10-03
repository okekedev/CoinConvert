import Foundation
// Adds zh-Hant to each .xcstrings by converting the zh-Hans value (ICU Hans-Hant).
for path in CommandLine.arguments.dropFirst() {
    let url = URL(fileURLWithPath: path)
    var json = try! JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
    var strings = json["strings"] as! [String: Any]
    var added = 0
    for (key, value) in strings {
        guard var entry = value as? [String: Any], var locs = entry["localizations"] as? [String: Any],
              let hans = locs["zh-Hans"] as? [String: Any], let unit = hans["stringUnit"] as? [String: Any],
              let text = unit["value"] as? String else { continue }
        let hant = text.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? text
        locs["zh-Hant"] = ["stringUnit": ["state": "translated", "value": hant]]
        entry["localizations"] = locs
        strings[key] = entry
        added += 1
    }
    json["strings"] = strings
    let out = try! JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    try! out.write(to: url)
    print("\(url.lastPathComponent): zh-Hant x\(added)")
}
