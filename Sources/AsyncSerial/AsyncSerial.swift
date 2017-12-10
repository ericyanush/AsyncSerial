import Foundation

public enum PortError: Error {
    case failedToOpen(String)
    case invalidPath
    case portNotOpen
}

public protocol SerialPortReceiveDelegate: class {
    func serialPort(_ serialPort: SerialPort, didReceive data: Data)
}

public class SerialPort {
    
    public weak var delegate: SerialPortReceiveDelegate?
    
    public fileprivate(set) var path: String
    
    fileprivate var fileDescriptor: Int32?
    fileprivate var eventQueue = DispatchQueue(label: "SwiftSerial Event Queue")
    fileprivate var readSource: DispatchSourceRead?
    fileprivate var writeSource: DispatchSourceWrite?
    
    fileprivate var writeBuffer = Data()
    fileprivate var bufferLock = NSLock()
    
    public var isOpen: Bool { return fileDescriptor != nil }
    
    public var hasPendingTransmitData: Bool {
        let dataCount: Int
        bufferLock.lock()
        dataCount = writeBuffer.count
        bufferLock.unlock()
        return dataCount != 0
    }
    
    public init(path: String) {
        self.path = path
    }

    public enum OpenType {
        case readOnly, writeOnly, readWrite
    }
    
    public func openPort(_ openType: OpenType) throws {
        guard !path.isEmpty else {
            throw PortError.invalidPath
        }
        
        let openFlags: Int32
        #if os(Linux)
            openFlags = openType.flag | O_NOCTTY | O_NOCTTY
        #elseif os(OSX)
            openFlags = openType.flag | O_NOCTTY | O_NONBLOCK | O_EXLOCK
        #endif
        let descriptor = open(path, openFlags)
        
        // Throw error if open() failed
        guard descriptor != -1 else {
            throw PortError.failedToOpen(String(cString: strerror(errno)))
        }
        fileDescriptor = descriptor
        
        readSource = DispatchSource.makeReadSource(fileDescriptor: descriptor, queue: eventQueue)
        writeSource = DispatchSource.makeWriteSource(fileDescriptor: descriptor, queue: eventQueue)
        readSource!.setEventHandler { [weak self] in self?.readData() }
        readSource!.resume()
        writeSource!.setEventHandler { [weak self] in self?.processOutgoingData() }
    }
    
    public func set(baudRate: BaudRate,
                    parity: ParityType = .none,
                    stopBits: StopBits = .one,
                    dataBits: DataBits = .eight) {
        
        guard let fileDescriptor = fileDescriptor else {
            return
        }
        
        var termSettings = termios()
        
        tcgetattr(fileDescriptor, &termSettings)
        
        cfsetispeed(&termSettings, baudRate.value)
        cfsetospeed(&termSettings, baudRate.value)
        
        termSettings.c_cflag |= parity.value
        
        if case .two = stopBits {
            termSettings.c_cflag |= tcflag_t(CSTOPB)
        } else {
            termSettings.c_cflag &= ~tcflag_t(CSTOPB)
        }
        
        termSettings.c_cflag &= ~tcflag_t(CSIZE)
        termSettings.c_cflag |= dataBits.value
        
        termSettings.c_lflag &= ~tcflag_t(ICANON | ECHO | ECHOE | ISIG)
        
        termSettings.c_cflag |= tcflag_t(CREAD | CLOCAL)
        
        tcsetattr(fileDescriptor, TCSANOW, &termSettings)
    }
    
    public func closePort() {
        if let fileDescriptor = fileDescriptor {
            readSource?.cancel()
            writeSource?.cancel()
            close(fileDescriptor)
        }
        fileDescriptor = nil
    }
    
    public func send(_ data: Data) throws {
        guard fileDescriptor != nil else { throw PortError.portNotOpen }
        eventQueue.async {
            self.bufferLock.lock()
            defer { self.bufferLock.unlock() }
            let resumeRequired = self.writeBuffer.count == 0
            self.writeBuffer.append(data)
            if resumeRequired { self.writeSource?.resume() }
        }
    }
    
    public enum BaudRate {
        case b0
        case b50
        case b75
        case b110
        case b134
        case b150
        case b200
        case b300
        case b600
        case b1200
        case b1800
        case b2400
        case b4800
        case b9600
        case b19200
        case b38400
        case b57600
        case b115200
        case b230400
    }
    
    public enum DataBits {
        case five, six, seven, eight
    }
    
    public enum StopBits {
        case one, two
    }
    
    public enum ParityType {
        case none, even, odd
    }
}

extension SerialPort {
    
    private func readData() {
        guard let fileDescriptor = fileDescriptor else { return }
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate(capacity: bufferSize) }
        
        let bytesRead = read(fileDescriptor, buffer, bufferSize)
        let data = Data(bytes: buffer, count: bytesRead)
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self, let delegate = strongSelf.delegate else { return }
            delegate.serialPort(strongSelf, didReceive: data)
        }
    }
    
    private func processOutgoingData() {
        guard let fileDescriptor = fileDescriptor else { return }
        bufferLock.lock()
        defer { bufferLock.unlock() }
        guard writeBuffer.count > 0 else {
            writeSource?.suspend()
            return
        }
        
        var bytesWritten = 0
        writeBuffer.withUnsafeBytes {
            bytesWritten = write(fileDescriptor, $0, writeBuffer.count)
        }
        writeBuffer.removeFirst(bytesWritten)
        
        if writeBuffer.count == 0 {
            writeSource?.suspend()
        }
    }
}


