//
//  Canvas.swift
//  CanvasKit
//
//  Created by Sam Soffes on 11/3/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

import Foundation
import ISO8601

public struct Canvas {

	// MARK: - Properties

	public let id: String
	public let organization: Organization
	public let isWritable: Bool
	public let isPublicWritable: Bool
	public let title: String
	public let summary: String
	public let nativeVersion: String
	public let updatedAt: Date
	public let archivedAt: Date?

	public var isEmpty: Bool {
		return summary.isEmpty
	}

	public var url: URL? {
		return URL(string: "https://usecanvas.com/\(organization.slug)/-/\(id)")
	}
}


extension Canvas: Resource {
	init(data: ResourceData) throws {
		id = data.id
		organization = try data.decode(relationship: "org")
		isWritable = try data.decode(attribute: "is_writable")
		isPublicWritable = try data.decode(attribute: "is_public_writable")
		updatedAt = try data.decode(attribute: "updated_at")
		title = try data.decode(attribute: "title")
		summary = try data.decode(attribute: "summary")
		nativeVersion = try data.decode(attribute: "native_version")
		archivedAt = data.decode(attribute: "archived_at")
	}
}


extension Canvas: JSONSerializable, JSONDeserializable {
	public var dictionary: JSONDictionary {
		var dictionary: JSONDictionary = [
			"id": id,
			"collection": organization.dictionary,
			"is_writable": isWritable,
			"is_public_writable": isPublicWritable,
			"updated_at": (updatedAt as NSDate).iso8601String()!,
			"title": title,
			"summary": summary,
			"native_version": nativeVersion
		]

		if let archivedAt = archivedAt {
			dictionary["archived_at"] = (archivedAt as NSDate).iso8601String()
		}

		return dictionary
	}

	public init?(dictionary: JSONDictionary) {
		guard let id = dictionary["id"] as? String,
			let org = dictionary["org"] as? JSONDictionary,
			let organization = Organization(dictionary: org),
			let isWritable = dictionary["is_writable"] as? Bool,
			let isPublicWritable = dictionary["is_public_writable"] as? Bool,
			let updatedAtString = dictionary["updated_at"] as? String,
			let updatedAt = NSDate(iso8601String: updatedAtString) as? Date,
			let title = dictionary["title"] as? String,
			let summary = dictionary["summary"] as? String,
			let nativeVersion = dictionary["native_version"] as? String
		else { return nil }

		self.id = id
		self.organization = organization
		self.isWritable = isWritable
		self.isPublicWritable = isPublicWritable
		self.title = title
		self.summary = summary
		self.nativeVersion = nativeVersion
		self.updatedAt = updatedAt

		let archivedAtString = dictionary["archived_at"] as? String
		archivedAt = archivedAtString.flatMap { NSDate(iso8601String: $0) as? Date }
	}
}


extension Canvas: Hashable {
	public var hashValue: Int {
		return id.hashValue
	}
}


public func ==(lhs: Canvas, rhs: Canvas) -> Bool {
	return lhs.id == rhs.id
}
