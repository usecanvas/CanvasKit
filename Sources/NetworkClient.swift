//
//  NetworkClient.swift
//  CanvasKit
//
//  Created by Sam Soffes on 11/13/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

import Foundation

let baseURL = URL(string: "https://api.usecanvas.com/")!
let networkCompletionQueue = DispatchQueue(label: "com.usecanvas.canvaskit.network-callback", attributes: DispatchQueue.Attributes.concurrent)


public protocol NetworkClient {

	var baseURL: URL { get }
	var session: URLSession { get }
}


public enum Result<T> {
	case success(T)
	case failure(String)
}
