//
//  OAuthClient.swift
//  CanvasKit
//
//  Created by Sam Soffes on 8/12/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import Foundation

/// This client is soley used to obtain and revoke OAuth access tokens.
public struct OAuthClient: NetworkClient {

	// MARK: - Properties

	public let clientID: String
	private let clientSecret: String
	public let baseURL: URL
	public let session: URLSession


	// MARK: - Initializers

	public init(clientID: String, clientSecret: String, baseURL: URL = CanvasKit.baseURL as URL, session: URLSession = URLSession.shared) {
		self.clientID = clientID
		self.clientSecret = clientSecret
		self.baseURL = baseURL
		self.session = session
	}


	// MARK: - Obtaining an Account with Access Token

	public func createAccessToken(username: String, password: String, completion: @escaping (Result<Account>) -> Void) {
		let params = [
			URLQueryItem(name: "username", value: username),
			URLQueryItem(name: "password", value: password),
			URLQueryItem(name: "scope", value: "global"),
			URLQueryItem(name: "grant_type", value: "password")
		]

		let baseURL = self.baseURL
		var request = URLRequest(url: baseURL.appendingPathComponent("oauth/access-tokens"))
		request.httpMethod = "POST"
		request.httpBody = formEncode(params).data(using: String.Encoding.utf8)
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

		send(request: request, completion: completion)
	}


	/// Revoke an access token.
	///
	/// - parameter accessToken: The access token to revoke.
	/// - parameter completion: A function to call when the request finishes.
	/// Revoke an access token.
	///
	/// - parameter completion: A function to call when the request finishes.
	public func revokeAccessToken(_ accessToken: String, completion: ((Result<Void>) -> Void)? = nil) {
		let params = [
			URLQueryItem(name: "access_token", value: accessToken),
		]

		let baseURL = self.baseURL
		var request = URLRequest(url: baseURL.appendingPathComponent("oauth/access-tokens/actions/revoke"))
		request.httpMethod = "POST"
		request.httpBody = formEncode(params).data(using: String.Encoding.utf8)
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		send(request: request, completion: completion)
	}


	// MARK: - Private

	private func formEncode(_ queryItems: [URLQueryItem]) -> String {
		let characterSet = NSMutableCharacterSet.alphanumeric()
		characterSet.addCharacters(in: "-._~")

		return queryItems.flatMap { item -> String? in
			guard var output = item.name.addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet) else { return nil }

			output += "="

			if let value = item.value?.addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet) {
				output += value
			}

			return output
			}.joined(separator: "&")
	}

	private func authorizationHeader(username: String, password: String) -> String? {
		guard let data = "\(username):\(password)".data(using: String.Encoding.utf8)
			else { return nil }

		let base64 = data.base64EncodedString(options: [])
		return "Basic \(base64)"
	}

	private func send(request: URLRequest, completion: ((Result<Void>) -> Void)?) {
		var request = request
		request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")

		if let authorization = authorizationHeader(username: clientID, password: clientSecret) {
			request.setValue(authorization, forHTTPHeaderField: "Client-Authorization")
		} else {
			networkCompletionQueue.async {
				completion?(.failure("Failed to create request"))
			}
			return
		}

		let session = self.session
		session.dataTask(with: request) { _, response, _ in
			guard let status = (response as? HTTPURLResponse)?.statusCode
			, status == 201
			else {
				networkCompletionQueue.async {
					completion?(.failure("Invalid response."))
				}
				return
			}

			networkCompletionQueue.async {
				completion?(.success())
			}
		}.resume()
	}

	private func send(request: URLRequest, completion: @escaping (Result<Account>) -> Void) {
		var request = request
		request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")

		// Set the client credentials to the "Authorization" header per the OAuth spec
		if let authorization = authorizationHeader(username: clientID, password: clientSecret) {
			request.setValue(authorization, forHTTPHeaderField: "Authorization")
		} else {
			networkCompletionQueue.async {
				completion(.failure("Failed to create request"))
			}
			return
		}

		let session = self.session
		session.dataTask(with: request) { responseData, response, error in
			guard let responseData = responseData,
				let json = try? JSONSerialization.jsonObject(with: responseData, options: []),
				let dictionary = json as? JSONDictionary
				else {
					networkCompletionQueue.async {
						completion(.failure("Invalid response."))
					}
					return
			}

			// Log in
			if dictionary["access_token"] is String, let account = Account(dictionary: dictionary) {
				networkCompletionQueue.async {
					completion(.success(account))
				}
				return
			}

			if let message = dictionary["message"] as? String {
				networkCompletionQueue.async {
					completion(.failure(message))
				}
				return
			}

			if let error = dictionary["error"] as? String , error == "invalid_resource_owner" {
				networkCompletionQueue.async {
					completion(.failure("Username/email or password incorrect."))
				}
				return
			}

			networkCompletionQueue.async {
				completion(.failure("Invalid response."))
			}
		}.resume()
	}
}
