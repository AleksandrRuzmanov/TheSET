//
//  Card.swift
//  The game SET
//
//  Created by Aleksandr on 30/01/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import Foundation

class Card: Hashable {
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    var hashValue: Int {
        return identifier
    }
    
    
    // current state of card
    var isMatched: Bool
    var isChosen: Bool
    var isOnTable: Bool
    
    // card's identifier
    private(set) var identifier: Int
    
    init(identifier: Int) {
        self.identifier = identifier
        isMatched = false
        isChosen = false
        isOnTable = false
    }
}
