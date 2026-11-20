import BoardKit
@preconcurrency import CoreBluetooth
import Foundation

/// Bluetooth Low Energy to the board, used whenever it's in range. Messages are split to fit the connection's write size
/// (`Framing`) and put back together on arrival.
@MainActor
final class BluetoothTransport: NSObject, BoardTransport, @preconcurrency CBCentralManagerDelegate, @preconcurrency CBPeripheralDelegate {
	let kind = LinkKind.bluetooth
	var onReceive: (([UInt8]) -> Void)?
	var onConnectionChange: (() -> Void)?
	private(set) var isConnected = false {
		didSet { if oldValue != isConnected { onConnectionChange?() } }
	}
	/// For the Device screen: "Scanning…", "Bluetooth is off", …
	private(set) var statusText = "Off"

	private let serviceID = CBUUID(string: BoardBLE.service)
	private let writeID = CBUUID(string: BoardBLE.write)
	private let notifyID = CBUUID(string: BoardBLE.notify)

	private var central: CBCentralManager?
	private var peripheral: CBPeripheral?
	private var writeCharacteristic: CBCharacteristic?
	private var queue: [Data] = []
	private var reassembler = Framing.Reassembler()
	private var enabled = false

	func configure(enabled: Bool) {
		guard enabled != self.enabled else { return }
		self.enabled = enabled
		if enabled {
			// Creating the manager is what asks for permission, so it waits until Bluetooth is switched on.
			central = central ?? CBCentralManager(delegate: self, queue: .main)
			startScanning()
		} else {
			if let peripheral { central?.cancelPeripheralConnection(peripheral) }
			central?.stopScan()
			drop()
			statusText = "Off"
		}
	}

	func send(_ bytes: [UInt8]) {
		guard isConnected, let peripheral, writeCharacteristic != nil else { return }
		let payload = max(peripheral.maximumWriteValueLength(for: .withoutResponse) - 1, 19)
		queue.append(contentsOf: Framing.split(bytes, payload: payload).map { Data($0) })
		drain()
	}

	private func drain() {
		guard let peripheral, let characteristic = writeCharacteristic else { return }
		while let next = queue.first, peripheral.canSendWriteWithoutResponse {
			peripheral.writeValue(next, for: characteristic, type: .withoutResponse)
			queue.removeFirst()
		}
	}

	private func startScanning() {
		guard enabled, let central, central.state == .poweredOn, peripheral == nil else { return }
		statusText = "Searching…"
		central.scanForPeripherals(withServices: [serviceID])
	}

	private func drop() {
		peripheral = nil
		writeCharacteristic = nil
		queue = []
		reassembler = Framing.Reassembler()
		isConnected = false
	}

	// MARK: CBCentralManagerDelegate

	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		switch central.state {
			case .poweredOn: startScanning()
			case .poweredOff: statusText = "Bluetooth is off"; drop()
			case .unauthorized: statusText = "Bluetooth access is turned off for Board"; drop()
			case .unsupported: statusText = "Bluetooth isn't available on this device"; drop()
			default: statusText = "Waiting for Bluetooth…"
		}
	}

	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
		guard self.peripheral == nil else { return }
		central.stopScan()
		self.peripheral = peripheral
		peripheral.delegate = self
		statusText = "Connecting…"
		central.connect(peripheral)
	}

	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		statusText = "Setting up…"
		peripheral.discoverServices([serviceID])
	}

	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		drop()
		retrySoon()
	}

	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		drop()
		statusText = enabled ? "Searching…" : "Off"
		retrySoon()
	}

	private func retrySoon() {
		Task { [weak self] in
			try? await Task.sleep(for: .seconds(1))
			self?.startScanning()
		}
	}

	// MARK: CBPeripheralDelegate

	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let service = peripheral.services?.first(where: { $0.uuid == serviceID }) else { return }
		peripheral.discoverCharacteristics([writeID, notifyID], for: service)
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		for characteristic in service.characteristics ?? [] {
			if characteristic.uuid == writeID { writeCharacteristic = characteristic }
			if characteristic.uuid == notifyID { peripheral.setNotifyValue(true, for: characteristic) }
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
		guard characteristic.uuid == notifyID, characteristic.isNotifying, writeCharacteristic != nil else { return }
		statusText = "Connected"
		isConnected = true
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		guard characteristic.uuid == notifyID, let data = characteristic.value else { return }
		if let whole = reassembler.add([UInt8](data)) { onReceive?(whole) }
	}

	func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) { drain() }
}
