//
//  SerialExtensions.swift
//  AsyncSerialPackageDescription
//
//  Created by Eric Yanush on 2017-12-07.
//

import Foundation

internal extension SerialPort.ParityType {
    var value: tcflag_t {
        switch self {
        case .none: return 0
        case .even: return tcflag_t(PARENB)
        case .odd:  return tcflag_t(PARENB | PARODD)
        }
    }
}

internal extension SerialPort.DataBits {
    var value: tcflag_t {
        switch self {
        case .five:  return tcflag_t(CS5)
        case .six:   return tcflag_t(CS6)
        case .seven: return tcflag_t(CS7)
        case .eight: return tcflag_t(CS8)
        }
    }
}

internal extension SerialPort.BaudRate {
    var value: speed_t {
        switch self {
        case .b0:      return speed_t(B0)
        case .b50:     return speed_t(B50)
        case .b75:     return speed_t(B75)
        case .b110:    return speed_t(B110)
        case .b134:    return speed_t(B134)
        case .b150:    return speed_t(B150)
        case .b200:    return speed_t(B200)
        case .b300:    return speed_t(B300)
        case .b600:    return speed_t(B600)
        case .b1200:   return speed_t(B1200)
        case .b1800:   return speed_t(B1800)
        case .b2400:   return speed_t(B2400)
        case .b4800:   return speed_t(B4800)
        case .b9600:   return speed_t(B9600)
        case .b19200:  return speed_t(B19200)
        case .b38400:  return speed_t(B38400)
        case .b57600:  return speed_t(B57600)
        case .b115200: return speed_t(B115200)
        case .b230400: return speed_t(B230400)
        }
    }
}

internal extension SerialPort.OpenType {
    var flag: Int32 {
        switch self {
        case .readOnly: return O_RDONLY
        case .writeOnly: return O_WRONLY
        case .readWrite: return O_RDWR
        }
    }
}
