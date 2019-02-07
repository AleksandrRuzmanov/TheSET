//
//  GameZoneView.swift
//  The game SET
//
//  Created by Aleksandr on 03/02/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import UIKit

class GameZoneView: UIView {
    
    private var grid = Grid(layout: Grid.Layout.aspectRatio(5/7))
    
    func place(cards: [Card]) {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        setNeedsDisplay()
        grid.cellCount = cards.count
        grid.frame = self.bounds
        for index in cards.indices {
            let cardView = CardView()
            cardView.backgroundColor = UIColor.clear
            cardView.card = cards[index]
            if let frame = grid[index] {
                cardView.frame = frame.insetBy(dx: cardsOffsetToWidthRadio*frame.width, dy: cardsOffsetToWidthRadio*frame.width)
                self.addSubview(cardView)
            }
        }
    }
    
    private let cardsOffsetToWidthRadio: CGFloat = 0.02
}
