//
//  APIClient.swift
//  CanvasKit
//
//  Created by Sam Soffes on 11/2/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

import Foundation

open class APIClient: NetworkClient {
	
	// MARK: - Types

	enum Method: String {
		case get = "GET"
		case head = "HEAD"
		case post = "POST"
		case put = "PUT"
		case delete = "DELETE"
		case trace = "TRACE"
		case options = "OPTIONS"
		case connect = "CONNECT"
		case patch = "PATCH"
	}
	
	
	// MARK: - Properties

	public let accessToken: String
	public let baseURL: URL
	public let session: URLSession

	
	// MARK: - Initializers
	
	public init(accessToken: String, baseURL: URL = CanvasKit.baseURL as URL, session: URLSession = URLSession.shared) {
		self.accessToken = accessToken
		self.baseURL = baseURL
		self.session = session
	}


	// MARK: - Requests

	open func shouldComplete<T>(request: URLRequest, response: HTTPURLResponse?, data: Data?, error: Error?, completion: ((Result<T>) -> Void)?) -> Bool {
		if let error = error {
			networkCompletionQueue.async {
				completion?(.failure(error.localizedDescription))
			}
			return false
		}

		return true
	}


	// MARK: - Organizations

	/// List organizations.
	///
	/// - parameter completion: A function to call when the request finishes.
	public func listOrganizations(_ completion: ((Result<[Organization]>) -> Void)) {
		request(path: "orgs", completion: completion)
	}

	// MARK: - Canvases

	/// Show a canvas.
	///
	/// - parameter id: The canvas ID.
	/// - parameter completion: A function to call when the request finishes.
	public func showCanvas(id: String, completion: ((Result<Canvas>) -> Void)) {
		let params: JSONDictionary = ["include": "org"]
		request(path: "canvases/\(id)", parameters: params, completion: completion)
	}

	/// Create a canvas.
	///
	/// - parameter organizationID: The ID of the organization to own the created canvas.
	/// - parameter content: Optional content formatted as CanvasNative for the new canvas.
	/// - parameter isPublicWritable: Boolean indicating if the new canvas should be publicly writable.
	/// - parameter completion: A function to call when the request finishes.
	public func createCanvas(organizationID: String, content: String? = nil, isPublicWritable: Bool? = nil, completion: ((Result<Canvas>) -> Void)) {
		var attributes = JSONDictionary()

		if let content = content {
			attributes["native_content"] = content
		}

		if let isPublicWritable = isPublicWritable {
			attributes["is_public_writable"] = isPublicWritable
		}

		let params: JSONDictionary = [
			"data": [
				"type": "canvases",
				"attributes": attributes,
				"relationships": [
					"org": [
						"data": [
							"type": "orgs",
							"id": organizationID
						]
					]
				]
			],
			"include": "org"
		]

		request(method: .post, path: "canvases", parameters: params, completion: completion)
	}

	/// List canvases.
	///
	/// - parameter organizationID: Limit the results to a given organization.
	/// - parameter completion: A function to call when the request finishes.
	public func listCanvases(organizationID: String? = nil, completion: ((Result<[Canvas]>) -> Void)) {
		var params: JSONDictionary = [
			"include": "org"
		]

		if let organizationID = organizationID {
			params["filter[org.id]"] = organizationID
		}

		request(path: "canvases", parameters: params, completion: completion)
	}

	/// Search for canvases in an organization.
	///
	/// - parameter organizationID: The organization ID.
	/// - parameter query: The search query.
	/// - parameter completion: A function to call when the request finishes.
	public func searchCanvases(organizationID: String, query: String, completion: ((Result<[Canvas]>) -> Void)) {
		let params: JSONDictionary = [
			"query": query,
			"include": "org"
		]
		request(path: "orgs/\(organizationID)/actions/search", parameters: params, completion: completion)
	}

	/// Destroy a canvas.
	///
	/// - parameter id: The canvas ID.
	/// - parameter completion: A function to call when the request finishes.
	public func destroyCanvas(id: String, completion: ((Result<Void>) -> Void)? = nil) {
		request(method: .delete, path: "canvases/\(id)", completion: completion)
	}

	/// Archive a canvas.
	///
	/// - parameter id: The canvas ID.
	/// - parameter completion: A function to call when the request finishes.
	public func archiveCanvas(id: String, completion: ((Result<Canvas>) -> Void)? = nil) {
		canvasAction(name: "archive", id: id, completion: completion)
	}

	/// Unarchive a canvas.
	///
	/// - parameter id: The canvas ID.
	/// - parameter completion: A function to call when the request finishes.
	public func unarchiveCanvas(id: String, completion: ((Result<Canvas>) -> Void)? = nil) {
		canvasAction(name: "unarchive", id: id, completion: completion)
	}

	/// Change public edits setting for a canvas.
	///
	/// - parameter id: The canvas ID.
	/// - parameter completion: A function to call when the request finishes.
	public func changePublicEdits(id: String, enabled: Bool, completion: ((Result<Canvas>) -> Void)? = nil) {
		let params: JSONDictionary = [
			"data": [
				"attributes": [
					"is_public_writable": enabled
				]
			],
			"include": "org"
		]
		request(method: .patch, path: "canvases/\(id)", parameters: params, completion: completion)
	}

	
	// MARK: - Private

	private func request(method: Method = .get, path: String, parameters: JSONDictionary? = nil, completion: ((Result<Void>) -> Void)?) {
		let request = buildRequest(method: method, path: path, parameters: parameters)
		sendRequest(request: request, completion: completion) { _, response, _ in
			guard let completion = completion else { return }
			networkCompletionQueue.async {
				completion(.success(()))
			}
		}
	}

	private func request<T: Resource>(method: Method = .get, path: String, parameters: JSONDictionary? = nil, completion: ((Result<[T]>) -> Void)?) {
		let request = buildRequest(method: method, path: path, parameters: parameters)
		sendRequest(request: request, completion: completion) { data, _, _ in
			guard let completion = completion else { return }
			guard let data = data,
				let json = try? JSONSerialization.jsonObject(with: data, options: []),
				let dictionary = json as? JSONDictionary
			else {
				networkCompletionQueue.async {
					completion(.failure("Invalid response"))
				}
				return
			}

			guard let values = ResourceSerialization.deserialize(dictionary: dictionary) as [T]? else {
				let errors = (dictionary["errors"] as? [JSONDictionary])?.flatMap { $0["detail"] as? String }
				let error = errors?.joined(separator: " ")

				networkCompletionQueue.async {
					completion(.failure(error ?? "Invalid response"))
				}
				return
			}

			networkCompletionQueue.async {
				completion(.success(values))
			}
		}
	}

	private func request<T: Resource>(method: Method = .get, path: String, parameters: JSONDictionary? = nil, completion: ((Result<T>) -> Void)?) {
		let request = buildRequest(method: method, path: path, parameters: parameters)
		sendRequest(request: request, completion: completion) { data, _, _ in
			guard let completion = completion else { return }
			guard let data = data,
				let json = try? JSONSerialization.jsonObject(with: data, options: []),
				let dictionary = json as? JSONDictionary
				else {
					networkCompletionQueue.async {
						completion(.failure("Invalid response"))
					}
					return
			}

			guard let value = ResourceSerialization.deserialize(dictionary: dictionary) as T? else {
				let errors = (dictionary["errors"] as? [JSONDictionary])?.flatMap { $0["detail"] as? String }
				let error = errors?.joined(separator: " ")

				networkCompletionQueue.async {
					completion(.failure(error ?? "Invalid response"))
				}
				return
			}

			networkCompletionQueue.async {
				completion(.success(value))
			}
		}
	}
	
	private func buildRequest(method: Method = .get, path: String, parameters: JSONDictionary? = nil, contentType: String = "application/json; charset=utf-8") -> URLRequest {
		// Create URL
		var url = baseURL.appendingPathComponent(path)

		// Add GET params
		if method == .get {
			if let parameters = parameters, var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
				var queryItems = [URLQueryItem]()
				for (name, value) in parameters {
					if let value = value as? String {
						queryItems.append(URLQueryItem(name: name, value: value))
					} else {
						print("[APIClient] Failed to GET encode a non string value: `\(value)`")
					}
				}
				components.queryItems = queryItems

				if let updatedURL = components.url {
					url = updatedURL
				}
			}
		}

		// Create request
		var request = URLRequest(url: url)

		// Set HTTP method
		request.httpMethod = method.rawValue

		// Add content type
		request.setValue(contentType, forHTTPHeaderField: "Content-Type")

		// Add POST params
		if let parameters = parameters , method != .get {
			request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
		}

		// Accept JSON
		request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")

		// Add access token
		request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
		
		return request
	}

	private func sendRequest<T>(request: URLRequest, completion: ((Result<T>) -> Void)?, callback: @escaping (_ data: Data?, _ response: HTTPURLResponse?, _ error: Error?) -> Void) {
		session.dataTask(with: request) { data, res, error in
			let response = res as? HTTPURLResponse

			// We strongly capture self here on purpose so the client will last at least long enough for the
			// `shouldComplete` method to get called.
			guard self.shouldComplete(request: request, response: response, data: data, error: error, completion: completion) else { return }
			
			callback(data, response, error)
		}.resume()
	}

	private func canvasAction(name: String, id: String, completion: ((Result<Canvas>) -> Void)?) {
		let path = "canvases/\(id)/actions/\(name)"
		let params: JSONDictionary = ["include": "org"]
		request(method: .post, path: path, parameters: params, completion: completion)
	}
}
