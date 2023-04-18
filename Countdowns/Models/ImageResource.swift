//
//  ImageResource.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2023-01-11.
//

import Foundation

enum ImageResource: Equatable, Hashable, Codable {
    case symbolIcon(name: String)
    case remote(URL)
    case preloaded(Data)
}
