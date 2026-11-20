/// The Bluetooth Low Energy layout of the board, shared so the apps and the firmware can't disagree.
/// One service, two characteristics; messages are `BoardMessage` bytes split with `Framing`.
public enum BoardBLE {
	public static let deviceName = "Dither Board"
	public static let service = "6F5A0000-B0A4-4C3E-9A52-7D1F3E8B2C10"
	/// Apps write here (write without response).
	public static let write = "6F5A0001-B0A4-4C3E-9A52-7D1F3E8B2C10"
	/// The board notifies here.
	public static let notify = "6F5A0002-B0A4-4C3E-9A52-7D1F3E8B2C10"
	/// Where the apps and the board find the server's socket.
	public static let socketPath = "/v1/board/socket"
}
