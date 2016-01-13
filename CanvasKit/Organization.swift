//
//  Organization.swift
//  CanvasKit
//
//  Created by Sam Soffes on 11/3/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

public struct Organization {

	// MARK: - Properties

	public let ID: String
	public let name: String
	public let slug: String
}


extension Organization: JSONSerializable, JSONDeserializable {
	public var dictionary: JSONDictionary {
		return [
			"id": ID,
			"name": name,
			"slug": slug
		]
	}

	public init?(dictionary: JSONDictionary) {
		guard let ID = dictionary["id"] as? String,
			name = dictionary["name"] as? String,
			slug = dictionary["slug"] as? String
		else { return nil }

		self.ID = ID
		self.name = name
		self.slug = slug
	}
}


extension Organization: Hashable {
	public var hashValue: Int {
		return ID.hashValue
	}
}


public func ==(lhs: Organization, rhs: Organization) -> Bool {
	return lhs.ID == rhs.ID
}
