//
//  GameFieldView.swift
//  The game SET
//
//  Created by Aleksandr on 03/02/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//


import UIKit

class GameFieldView: UIView {
    
    let matchedCardsMovingView = MatchedCardsMovingView()
    
    var deckOfCardsFrame: CGRect?
    
    var cardsInTheEndFrame: CGRect?
    
    func place(cards: [Card]) {
        grid.frame = self.bounds
        grid.cellCount = cards.count
        separatedCards = separateCards(cards)
        if separatedCards != nil {
            createViewsFor(separatedCards!.newCards)
            removeViewsFor(separatedCards!.matchedCards)
        }
        setupViewsFor(cards)
        setNeedsDisplay()
    }
    
    private var separatedCards: (newCards: [Card], matchedCards: [Card], alreadyOnTableCards: [Card])?
    
    private func separateCards(_ cards: [Card]) -> (newCards: [Card], matchedCards: [Card], alreadyOnTableCards: [Card]) {
        var newCards = [Card]()
        var matchedCards = [Card]()
        var alreadyOnTableCards = [Card]()
        for view in self.subviews {
            if let cardView = view as? CardView {
                for card in cards {
                    if cardView.card == card {
                        alreadyOnTableCards.append(card)
                    }
                }
                if let card = cardView.card, !cards.contains(card) {
                    matchedCards.append(card)
                }
            }
        }
        newCards = cards.filter({!alreadyOnTableCards.contains($0)})
        return(newCards: newCards, matchedCards: matchedCards, alreadyOnTableCards: alreadyOnTableCards)
    }
    
    private func removeViewsFor(_ cards: [Card]) {
        matchedCardsMovingView.cardsInTheEndFrame = cardsInTheEndFrame
        matchedCardsMovingView.cardsMovingAnimationDuration = cardsMovingAnimationDuration
        matchedCardsMovingView.cardsFlippingAnimationDuration = cardsFlippingAnimationDuration
        var matchedCardsViews = [CardView]()
        matchedCardsMovingView.frame = self.bounds
        for view in self.subviews {
            if let cardView = view as? CardView, let card = cardView.card, cards.contains(card) {
                matchedCardsViews.append(cardView)
                cardView.removeFromSuperview()
            }
        }
        if !matchedCardsViews.isEmpty {
            self.addSubview(matchedCardsMovingView)
        }
        matchedCardsMovingView.matchedCardsViews = matchedCardsViews
    }
    
    private func createViewsFor(_ cards: [Card] ) {
        for card in cards {
            let cardView = CardView()
            cardView.card = card
            if let frame = deckOfCardsFrame {
                cardView.frame = frame
            }
            self.addSubview(cardView)
        }
    }
    
    private func setupViewsFor(_ cards: [Card]) {
        var delay = 0.0
        var actualSubviews = [UIView]()
        for view in self.subviews {
            if let cardView = view as? CardView, let card = cardView.card{
                if let alreadyOnTableCards = separatedCards?.alreadyOnTableCards, let newCards = separatedCards?.newCards {
                    if alreadyOnTableCards.contains(card) || newCards.contains(card) {
                        actualSubviews.append(cardView)
                    }
                }
            }
        }
        for view in actualSubviews {
            if let cardView = view as? CardView {
                for index in cards.indices {
                    if cardView.card == cards[index] {
                    if let frame = grid[index] {
                        cardView.backgroundColor = UIColor.clear
                        if cardView.frame == deckOfCardsFrame {
                            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: cardsMovingAnimationDuration, delay: delay, options: .curveEaseIn, animations: { [unowned self] in
                                cardView.frame = frame.insetBy(dx: self.cardsOffsetToWidthRadio * frame.width, dy: self.cardsOffsetToWidthRadio * frame.width)
                                }, completion: { [unowned self] finished in
                                    if finished == UIViewAnimatingPosition.end {
                                        UIView.transition(with: cardView, duration: self.cardsFlippingAnimationDuration, options: [UIView.AnimationOptions.transitionFlipFromLeft], animations: {
                                            cardView.isFaceUp = true
                                        })
                                    }
                            })
                            
                            delay += cardsMovingAnimationDuration
                        } else {
                            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: cardsMovingAnimationDuration, delay: delay, options: .curveEaseIn, animations: { [unowned self] in
                                cardView.frame = frame.insetBy(dx: self.cardsOffsetToWidthRadio * frame.width, dy: self.cardsOffsetToWidthRadio * frame.width)
                            })
                        }
                        }
                    }
                }
            }
        }
    }
   
    private var grid = GameFieldGrid(layout: GameFieldGrid.Layout.aspectRatio(5/7))
    
    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        for view in self.subviews {
            view.setNeedsDisplay()
        }
    }
    
    private let cardsMovingAnimationDuration = 0.15
    private let cardsFlippingAnimationDuration = 0.5
    
    private let cardsOffsetToWidthRadio: CGFloat = 0.02
}
