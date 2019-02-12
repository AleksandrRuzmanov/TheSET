//
//  GameFieldView.swift
//  The game SET
//
//  Created by Aleksandr on 03/02/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//


import UIKit

class GameFieldView: UIView {
    
    
    var deckFrame: CGRect?
    
    var discardPileFrame: CGRect? {
        didSet {
            flyingCardsView.discardPileFrame = discardPileFrame
        }
    }
    
    func removeAllCards() {
        var allCards = [Card]()
        for view in self.subviews {
            if let cardView = view as? CardView, let card = cardView.card {
                allCards.append(card)
            }
        }
        transferViewsFor(allCards)
    }
    
    func placeCards(_ cards: [Card]) {
        grid.frame = self.bounds
        grid.cellCount = cards.count
        sortedCards = sortCards(cards)
        if sortedCards != nil {
            createViewsFor(sortedCards!.newCards)
            transferViewsFor(sortedCards!.matchedCards)
        }
        setupViewsFor(cards)
        setNeedsDisplay()
    }
    
    
    
    
    
    private var grid = GameFieldGrid(layout: GameFieldGrid.Layout.aspectRatio(5/7))
    
    private let flyingCardsView = FlyingCardsView()
    
    private var sortedCards: (newCards: [Card], matchedCards: [Card], alreadyOnTableCards: [Card])?
    
    private var cardsOnTableViews: [UIView] {
        var cardsOnTableViews = [UIView]()
        for view in self.subviews {
            if let cardView = view as? CardView, let card = cardView.card{
                if let alreadyOnTableCards = sortedCards?.alreadyOnTableCards, let newCards = sortedCards?.newCards {
                    if alreadyOnTableCards.contains(card) || newCards.contains(card) {
                        cardsOnTableViews.append(cardView)
                    }
                }
            }
        }
        return cardsOnTableViews
    }
    
    private var hasFlyingCardsSubview: Bool {
        var hasFlyingCardsSubview = false
        for view in self.subviews {
            if view is FlyingCardsView {
                hasFlyingCardsSubview = true
            }
        }
        return hasFlyingCardsSubview
    }
    
    private func sortCards(_ cards: [Card]) -> (newCards: [Card], matchedCards: [Card], alreadyOnTableCards: [Card]) {
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
    
    private func transferViewsFor(_ cards: [Card]) {
        flyingCardsView.frame = self.bounds
        var matchedCardsViews = [CardView]()
        for view in self.subviews {
            if let cardView = view as? CardView, let card = cardView.card, cards.contains(card) {
                matchedCardsViews.append(cardView)
                cardView.removeFromSuperview()
            }
        }
        if !matchedCardsViews.isEmpty {
            self.addSubview(flyingCardsView)
        }
        flyingCardsView.matchedCardsViews = matchedCardsViews
    }
    
    private func createViewsFor(_ cards: [Card] ) {
        for card in cards {
            let cardView = CardView()
            cardView.card = card
            if let frame = deckFrame {
                cardView.frame = frame
            }
            self.addSubview(cardView)
        }
    }
    
    
    
    private func setupViewsFor(_ cards: [Card]) {
        var delay = 0.0
        for view in cardsOnTableViews {
            if let cardView = view as? CardView {
                for index in cards.indices {
                    if cardView.card == cards[index] {
                        if let frame = grid[index] {
                            if self.hasFlyingCardsSubview {
                                self.bringSubviewToFront(flyingCardsView)
                            }
                            let cardFrame = frame.insetBy(dx: cardsOffsetToWidthRadio * frame.width, dy: cardsOffsetToWidthRadio * frame.width)
                            cardView.backgroundColor = UIColor.clear
                            if cardView.frame == deckFrame {
                                rotateView(cardView, duration: cardsMovingAnimationDuration, delay: delay, completionAction: {[unowned self] in
                                    UIView.transition(with: cardView, duration: self.cardsFlippingAnimationDuration, options: [UIView.AnimationOptions.transitionFlipFromLeft], animations: {
                                        cardView.isFaceUp = true
                                    })
                                })
                                setupViewFrame(cardView, to: frame.insetBy(dx: cardsOffsetToWidthRadio * frame.width, dy: self.cardsOffsetToWidthRadio * frame.width), duration: cardsMovingAnimationDuration, delay: delay, completionAction: {
                                    cardView.frame = cardFrame
                                })
                                delay += cardsMovingAnimationDuration
                                // FIX ME IN GRID
                            } else if cardView.frame.center.rounded() != cardFrame.center.rounded() {
                                rotateView(cardView, duration: cardsMovingAnimationDuration, delay: 0.0, completionAction: {
                                    cardView.frame = cardFrame
                                })
                                setupViewFrame(cardView, to: frame.insetBy(dx: self.cardsOffsetToWidthRadio * frame.width, dy: self.cardsOffsetToWidthRadio * frame.width), duration: cardsMovingAnimationDuration, delay: 0.0)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    
    
    
    private func rotateView(_ view: UIView, duration: Double, delay: Double, completionAction: (()->(Void))?=nil ) {
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration/3, delay: delay, options: .curveLinear, animations: {
            view.transform = view.transform.rotated(by: 2*CGFloat.pi/3)
        }, completion: { finished in
            if finished == UIViewAnimatingPosition.end {
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration/3, delay: 0.0, options: .curveLinear, animations: {
                    view.transform = view.transform.rotated(by: 2*CGFloat.pi/3)
                }, completion: { finished in
                    if finished == UIViewAnimatingPosition.end {
                        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration/3, delay: 0.0, options: .curveLinear, animations: {
                            view.transform = view.transform.rotated(by: 2*CGFloat.pi/3)
                        }, completion: { finished in
                            if finished == UIViewAnimatingPosition.end, let action = completionAction {
                                action()
                            }
                        })
                    }
                })
            }
        })
    }
    
    private func setupViewFrame(_ view: UIView, to frame: CGRect, duration: Double, delay: Double, completionAction: (()->Void)? = nil) {
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration, delay: delay, options: .curveEaseIn, animations: {
            view.frame = frame
        }, completion: { finished in
            if finished == UIViewAnimatingPosition.end, let action = completionAction {
                action()
            }
        })
    }
   
    
    
    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        for view in self.subviews {
            view.setNeedsDisplay()
        }
    }
    
    private var cardsMovingAnimationDuration = 0.15 {
        didSet {
            flyingCardsView.cardsMovingAnimationDuration = cardsMovingAnimationDuration
        }
    }
    private var cardsFlippingAnimationDuration = 0.5 {
        didSet {
            flyingCardsView.cardsFlippingAnimationDuration = cardsFlippingAnimationDuration
        }
    }
    
    private let cardsOffsetToWidthRadio: CGFloat = 0.02
    
    
}


extension CGPoint {
    func rounded() -> CGPoint {
        return CGPoint(x: self.x.rounded(), y: self.y.rounded())
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }
}
