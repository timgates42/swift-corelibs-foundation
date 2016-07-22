//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_exported import Foundation // Clang module

@_silgen_name("__NSTimeZoneIsAutoupdating")
internal func __NSTimeZoneIsAutoupdating(_ timezone: NSTimeZone) -> Bool

@_silgen_name("__NSTimeZoneAutoupdating")
internal func __NSTimeZoneAutoupdating() -> NSTimeZone

@_silgen_name("__NSTimeZoneCurrent")
internal func __NSTimeZoneCurrent() -> NSTimeZone

/**
 `TimeZone` defines the behavior of a time zone. Time zone values represent geopolitical regions. Consequently, these values have names for these regions. Time zone values also represent a temporal offset, either plus or minus, from Greenwich Mean Time (GMT) and an abbreviation (such as PST for Pacific Standard Time).
 
 `TimeZone` provides two static functions to get time zone values: `current` and `autoupdatingCurrent`. The `autoupdatingCurrent` time zone automatically tracks updates made by the user.
 
 Note that time zone database entries such as "America/Los_Angeles" are IDs, not names. An example of a time zone name is "Pacific Daylight Time". Although many `TimeZone` functions include the word "name", they refer to IDs.
 
 Cocoa does not provide any API to change the time zone of the computer, or of other applications.
 */
public struct TimeZone : CustomStringConvertible, CustomDebugStringConvertible, Hashable, Equatable, ReferenceConvertible {
    public typealias ReferenceType = NSTimeZone
    
    private var _wrapped : NSTimeZone
    private var _autoupdating : Bool
    
    /// The time zone currently used by the system.
    public static var current : TimeZone {
        return TimeZone(adoptingReference: __NSTimeZoneCurrent(), autoupdating: false)
    }
    
    /// The time zone currently used by the system, automatically updating to the user's current preference.
    ///
    /// If this time zone is mutated, then it no longer tracks the application time zone.
    ///
    /// The autoupdating time zone only compares equal to itself.
    public static var autoupdatingCurrent : TimeZone {
        return TimeZone(adoptingReference: __NSTimeZoneAutoupdating(), autoupdating: true)
    }
    
    // MARK: -
    //
    
    /// Returns a time zone initialized with a given identifier.
    ///
    /// An example identifier is "America/Los_Angeles".
    ///
    /// If `identifier` is an unknown identifier, then returns `nil`.
    public init?(identifier: String) {
        if let r = NSTimeZone(name: identifier) {
            _wrapped = r
            _autoupdating = false
        } else {
            return nil
        }
    }
    
    @available(*, unavailable, renamed: "init(secondsFromGMT:)")
    public init(forSecondsFromGMT seconds: Int) { fatalError() }
    
    /// Returns a time zone initialized with a specific number of seconds from GMT.
    ///
    /// Time zones created with this never have daylight savings and the offset is constant no matter the date. The identifier and abbreviation do NOT follow the POSIX convention (of minutes-west).
    ///
    /// - parameter seconds: The number of seconds from GMT.
    /// - returns: A time zone, or `nil` if a valid time zone could not be created from `seconds`.
    public init?(secondsFromGMT seconds: Int) {
        if let r = NSTimeZone(forSecondsFromGMT: seconds) as NSTimeZone? {
            _wrapped = r
            _autoupdating = false
        } else {
            return nil
        }
    }
    
    /// Returns a time zone identified by a given abbreviation.
    ///
    /// In general, you are discouraged from using abbreviations except for unique instances such as "GMT". Time Zone abbreviations are not standardized and so a given abbreviation may have multiple meanings—for example, "EST" refers to Eastern Time in both the United States and Australia
    ///
    /// - parameter abbreviation: The abbreviation for the time zone.
    /// - returns: A time zone identified by abbreviation determined by resolving the abbreviation to an identifier using the abbreviation dictionary and then returning the time zone for that identifier. Returns `nil` if there is no match for abbreviation.
    public init?(abbreviation: String) {
        if let r = NSTimeZone(abbreviation: abbreviation) {
            _wrapped = r
            _autoupdating = false
        } else {
            return nil
        }
    }
    
    private init(reference: NSTimeZone) {
        if __NSTimeZoneIsAutoupdating(reference) {
            // we can't copy this or we lose its auto-ness (27048257)
            // fortunately it's immutable
            _autoupdating = true
            _wrapped = reference
        } else {
            _autoupdating = false
            _wrapped = reference.copy() as! NSTimeZone
        }
    }

    private init(adoptingReference reference: NSTimeZone, autoupdating: Bool) {
        // this path is only used for types we do not need to copy (we are adopting the ref)
        _wrapped = reference
        _autoupdating = autoupdating
    }

    // MARK: -
    //
    
    @available(*, unavailable, renamed: "identifier")
    public var name: String { fatalError() }

    /// The geopolitical region identifier that identifies the time zone.
    public var identifier: String {
        return _wrapped.name
    }
    
    @available(*, unavailable, message: "use the identifier instead")
    public var data: Data { fatalError() }
    
    /// The current difference in seconds between the time zone and Greenwich Mean Time.
    ///
    /// - parameter date: The date to use for the calculation. The default value is the current date.
    public func secondsFromGMT(for date: Date = Date()) -> Int {
        return _wrapped.secondsFromGMT(for: date)
    }
    
    /// Returns the abbreviation for the time zone at a given date.
    ///
    /// Note that the abbreviation may be different at different dates. For example, during daylight saving time the US/Eastern time zone has an abbreviation of "EDT." At other times, its abbreviation is "EST."
    /// - parameter date: The date to use for the calculation. The default value is the current date.
    public func abbreviation(for date: Date = Date()) -> String? {
        return _wrapped.abbreviation(for: date)
    }
    
    /// Returns a Boolean value that indicates whether the receiver uses daylight saving time at a given date.
    ///
    /// - parameter date: The date to use for the calculation. The default value is the current date.
    public func isDaylightSavingTime(for date: Date = Date()) -> Bool {
        return _wrapped.isDaylightSavingTime(for: date)
    }
    
    /// Returns the daylight saving time offset for a given date.
    ///
    /// - parameter date: The date to use for the calculation. The default value is the current date.
    public func daylightSavingTimeOffset(for date: Date = Date()) -> TimeInterval {
        return _wrapped.daylightSavingTimeOffset(for: date)
    }
    
    /// Returns the next daylight saving time transition after a given date.
    ///
    /// - parameter date: A date.
    /// - returns: The next daylight saving time transition after `date`. Depending on the time zone, this function may return a change of the time zone's offset from GMT. Returns `nil` if the time zone of the receiver does not observe daylight savings time as of `date`.
    public func nextDaylightSavingTimeTransition(after date: Date) -> Date? {
        return _wrapped.nextDaylightSavingTimeTransition(after: date)
    }
    
    /// Returns an array of strings listing the identifier of all the time zones known to the system.
    public static var knownTimeZoneIdentifiers : [String] {
        return NSTimeZone.knownTimeZoneNames
    }
    
    /// Returns the mapping of abbreviations to time zone identifiers.
    public static var abbreviationDictionary : [String : String] {
        get {
            return NSTimeZone.abbreviationDictionary
        }
        set {
            NSTimeZone.abbreviationDictionary = newValue
        }
    }
    
    /// Returns the time zone data version.
    public static var timeZoneDataVersion : String {
        return NSTimeZone.timeZoneDataVersion
    }
    
    /// Returns the date of the next (after the current instant) daylight saving time transition for the time zone. Depending on the time zone, the value of this property may represent a change of the time zone's offset from GMT. Returns `nil` if the time zone does not currently observe daylight saving time.
    public var nextDaylightSavingTimeTransition: Date? {
        return _wrapped.nextDaylightSavingTimeTransition
    }

    @available(*, unavailable, renamed: "localizedName(for:locale:)")
    public func localizedName(_ style: NSTimeZone.NameStyle, locale: Locale?) -> String? { fatalError() }

    /// Returns the name of the receiver localized for a given locale.
    public func localizedName(for style: NSTimeZone.NameStyle, locale: Locale?) -> String? {
        return _wrapped.localizedName(style, locale: locale)
    }
    
    // MARK: -
    
    public var description: String {
        return _wrapped.description
    }
    
    public var debugDescription : String {
        return _wrapped.debugDescription
    }
    
    public var hashValue : Int {
        if _autoupdating {
            return 1
        } else {
            return _wrapped.hash
        }
    }

    public static func ==(lhs: TimeZone, rhs: TimeZone) -> Bool {
        if lhs._autoupdating || rhs._autoupdating {
            return lhs._autoupdating == rhs._autoupdating
        } else {
            return lhs._wrapped.isEqual(rhs._wrapped)
        }
    }
}

extension TimeZone : _ObjectiveCBridgeable {
    public static func _isBridgedToObjectiveC() -> Bool {
        return true
    }
    
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSTimeZone {
        // _wrapped is immutable
        return _wrapped
    }
    
    public static func _forceBridgeFromObjectiveC(_ input: NSTimeZone, result: inout TimeZone?) {
        if !_conditionallyBridgeFromObjectiveC(input, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ input: NSTimeZone, result: inout TimeZone?) -> Bool {
        result = TimeZone(reference: input)
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSTimeZone?) -> TimeZone {
        var result: TimeZone? = nil
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}

