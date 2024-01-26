//
//  Symbol.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2023-03-02.
//

import SwiftUI

enum Symbol: String, Equatable, Hashable, CaseIterable, Identifiable {
    // Generic
    case calendar
    case music = "music.note"
    case ticket, tv, film, gamecontroller, iphone, gift, shippingbox, leaf, pawprint
    case figure = "figure.arms.open"
    case figurerun = "figure.run"
    case family = "figure.2.and.child.holdinghands"
    case birthdayCake = "birthday.cake"
    
    // Living
    case house, building, car, bus, tram, airplane, sailboat
    case bed = "bed.double"
    
    // Shapes
    case star, heart
    
    static let defaultSymbol = Symbol.calendar
    
    var id: Self { self }
    
}
