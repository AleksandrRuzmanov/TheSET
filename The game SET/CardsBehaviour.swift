//
//  CardsBehaviour.swift
//  The game SET
//
//  Created by Aleksandr on 11/02/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import UIKit

class CardsBehaviour: UIDynamicBehavior {
    
    
    lazy var collisionBehaviour: UICollisionBehavior = {
        let behaviour = UICollisionBehavior()
        behaviour.translatesReferenceBoundsIntoBoundary = true
        return behaviour
    }()
    
    lazy var itemBehaviour: UIDynamicItemBehavior = {
        let behaviour = UIDynamicItemBehavior()
        behaviour.allowsRotation = AnimationParameters.allowsRotation
        behaviour.elasticity = AnimationParameters.elasticity
        behaviour.resistance = AnimationParameters.resistance
        return behaviour
    }()
    
    private func push(_ item: UIDynamicItem) {
        let pushBehaviour = UIPushBehavior(items: [item], mode: .instantaneous)
        pushBehaviour.angle = AnimationParameters.randomAngle
        pushBehaviour.magnitude = AnimationParameters.magnitude
        pushBehaviour.action = { [unowned pushBehaviour, self] in
            self.removeChildBehavior(pushBehaviour)
        }
        addChildBehavior(pushBehaviour)
    }
    
    func addItem(_ item: UIDynamicItem) {
        collisionBehaviour.addItem(item)
        itemBehaviour.addItem(item)
        push(item)
    }
    
    func removeItem(_ item: UIDynamicItem) {
        collisionBehaviour.removeItem(item)
        itemBehaviour.removeItem(item)
    }
    
    override init() {
        super.init()
        addChildBehavior(collisionBehaviour)
        addChildBehavior(itemBehaviour)
    }
    
    convenience init(in animator: UIDynamicAnimator) {
        self.init()
        animator.addBehavior(self)
    }
}

extension CardsBehaviour {
    private struct AnimationParameters {
        static let elasticity: CGFloat = 1.03
        static let allowsRotation: Bool = true
        static let resistance: CGFloat = 0.0
        static let magnitude: CGFloat = 5.0
        static var randomAngle: CGFloat {
            return CGFloat.random(in: 0...(2*CGFloat.pi))
        }
    }
}
