import Foundation
import Observation
import Security

/// Where to find the board: the server's address and shared password, and which links to use.
@Observable
final class ConnectionSettings {
	var serverURL: String { didSet { UserDefaults.standard.set(serverURL, forKey: "serverURL") } }
	var useServer: Bool { didSet { UserDefaults.standard.set(useServer, forKey: "useServer") } }
	var useBluetooth: Bool { didSet { UserDefaults.standard.set(useBluetooth, forKey: "useBluetooth") } }
	var token: String { didSet { Keychain.set(token, account: "boardToken") } }

	init() {
		let d = UserDefaults.standard
		serverURL = d.string(forKey: "serverURL") ?? ""
		useServer = d.object(forKey: "useServer") as? Bool ?? true
		useBluetooth = d.object(forKey: "useBluetooth") as? Bool ?? true
		token = Keychain.get(account: "boardToken") ?? ""
	}

	/// The WebSocket address for the server, or nil until it's filled in.
	var socketURL: URL? {
		var text = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !text.isEmpty else { return nil }
		if !text.contains("://") { text = "https://" + text }
		guard var parts = URLComponents(string: text), parts.host != nil else { return nil }
		parts.scheme = parts.scheme == "http" || parts.scheme == "ws" ? "ws" : "wss"
		parts.path = "/v1/board/socket"
		parts.queryItems = [URLQueryItem(name: "tz", value: TimeZone.current.identifier)]
		return parts.url
	}
}

/// The shared password lives in the keychain, not in UserDefaults.
enum Keychain {
	private static func query(_ account: String) -> [String: Any] {
		[kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "board", kSecAttrAccount as String: account]
	}

	static func get(account: String) -> String? {
		var q = query(account)
		q[kSecReturnData as String] = true
		q[kSecMatchLimit as String] = kSecMatchLimitOne
		var out: CFTypeRef?
		guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let data = out as? Data else { return nil }
		return String(data: data, encoding: .utf8)
	}

	static func set(_ value: String, account: String) {
		SecItemDelete(query(account) as CFDictionary)
		guard !value.isEmpty else { return }
		var q = query(account)
		q[kSecValueData as String] = Data(value.utf8)
		SecItemAdd(q as CFDictionary, nil)
	}
}
