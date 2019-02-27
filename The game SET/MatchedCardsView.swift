//
//  MatchedCardsMovingView.swift
//  The game SET
//
//  Created by Aleksandr on 08/02/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import UIKit

class FlyingCardsView: UIView {
    
    
    lazy var animator = UIDynamicAnimator(referenceView: self)
    
    lazy var cardsBehaviour = CardsBehaviour(in: animator)
    
    var discardPileFrame: CGRect?
    
    var matchedCardsViews = [CardView]() {
        didSet {
            removeMatchedCardsViews(matchedCardsViews)
        }
    }

    private func removeMatchedCardsViews(_ cardViews: [CardView]) {
        for cardView in cardViews {
            self.addSubview(cardView)
            cardsBehaviour.addItem(cardView)
        }
        var delay = 0.0
        for cardView in cardViews {
            _ = Timer.scheduledTimer(withTimeInterval: cardsPushAnimationDuration+delay, repeats: false, block: { [unowned self] _ in
                self.cardsBehaviour.removeItem(cardView)
                if let frame = self.discardPileFrame {
                    UIViewPropertyAnimator.runningPropertyAnimator(withDuration: self.cardsMovingAnimationDuration, delay: 0.0, options: .curveEaseIn, animations: {
                        cardView.transform = CGAffineTransform.identity
                        cardView.frame = frame
                    }, completion: { [unowned self] finished in
                        if finished == UIViewAnimatingPosition.end {
                            UIView.transition(with: cardView, duration: self.cardsFlippingAnimationDuration, options: [UIView.AnimationOptions.transitionFlipFromLeft], animations: {
                                cardView.isFaceUp = false
                            }, completion: { [unowned self] finished in
                                if finished {
                                    cardView.removeFromSuperview()
                                    if self.subviews.isEmpty {
                                        self.removeFromSuperview()
                                    }
                                }
                            })
                        }
                    })
                }
                
            })
            delay += cardsMovingAnimationDuration
        }
    }
    
    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        for subview in self.subviews {
            subview.setNeedsDisplay()
        }
    }
    
    var cardsMovingAnimationDuration = 0.1
    var cardsFlippingAnimationDuration = 0.5
    var cardsPushAnimationDuration = 1.0
}

extension CGFloat {
    func random() {
        arc4random()
    }
}
