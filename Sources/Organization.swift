//
//  Organization.swift
//  CanvasKit
//
//  Created by Sam Soffes on 11/3/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

public struct Organization {

	// MARK: - Types

	public struct Color {
		public var red: Double
		public var green: Double
		public var blue: Double

		public var hex: String {
			return String(Int(red * 255), radix: 16) + String(Int(green * 255), radix: 16) + String(Int(blue * 255), radix: 16)
		}

		// From https://github.com/soffes/X
		public init?(hex string: String) {
			var hex = string

			// Remove `#` and `0x`
			if hex.hasPrefix("#") {
				hex = hex.substring(from: hex.index(hex.startIndex, offsetBy: 1))
			} else if hex.hasPrefix("0x") {
				hex = hex.substring(from: hex.index(hex.startIndex, offsetBy: 2))
			}

			// Invalid if not 3, 6, or 8 characters
			let length = hex.characters.count
			if length != 3 && length != 6 && length != 8 {
				return nil
			}

			// Make the string 8 characters long for easier parsing
			if length == 3 {
				let r = hex.substring(with: hex.startIndex..<hex.index(hex.startIndex, offsetBy: 1))
				let g = hex.substring(with: hex.index(hex.startIndex, offsetBy: 1)..<hex.index(hex.startIndex, offsetBy: 2))
				let b = hex.substring(with: hex.index(hex.startIndex, offsetBy: 2)..<hex.index(hex.startIndex, offsetBy: 3))
				hex = r + r + g + g + b + b + "ff"
			} else if length == 6 {
				hex = String(hex) + "ff"
			}

			// Convert 2 character strings to CGFloats
			func hexValue(_ string: String) -> Double {
				let value = Double(strtoul(string, nil, 16))
				return value / 255
			}

			red = hexValue(hex.substring(with: hex.startIndex..<hex.index(hex.startIndex, offsetBy: 2)))
			green = hexValue(hex.substring(with: hex.index(hex.startIndex, offsetBy: 2)..<hex.index(hex.startIndex, offsetBy: 4)))
			blue = hexValue(hex.substring(with: hex.index(hex.startIndex, offsetBy: 4)..<hex.index(hex.startIndex, offsetBy: 6)))
		}
	}


	// MARK: - Properties

	public let id: String
	public let name: String
	public let slug: String
	public let membersCount: UInt
	public let color: Color?
}


extension Organization: Resource {
	init(data: ResourceData) throws {
		id = data.id
		name = try data.decode(attribute: "name")
		slug = try data.decode(attribute: "slug")
		membersCount = try data.decode(attribute: "members_count")
		color = (data.attributes["color"] as? String).flatMap(Color.init)
	}
}


extension Organization: JSONSerializable, JSONDeserializable {
	public var dictionary: JSONDictionary {
		var dictionary: JSONDictionary = [
			"id": id,
			"name": name,
			"slug": slug,
			"members_count": membersCount
		]

		if let color = color {
			dictionary["color"] = color.hex
		}

		return dictionary
	}

	public init?(dictionary: JSONDictionary) {
		guard let id = dictionary["id"] as? String,
			let name = dictionary["name"] as? String,
			let slug = dictionary["slug"] as? String,
			let membersCount = dictionary["members_count"] as? UInt
		else { return nil }

		self.id = id
		self.name = name
		self.slug = slug
		self.membersCount = membersCount
		color = (dictionary["color"] as? String).flatMap(Color.init)
	}
}


extension Organization: Hashable {
	public var hashValue: Int {
		return id.hashValue
	}
}


public func ==(lhs: Organization, rhs: Organization) -> Bool {
	return lhs.id == rhs.id
}
