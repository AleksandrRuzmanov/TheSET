//
//  CardView.swift
//  The game SET
//
//  Created by Aleksandr on 03/02/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import UIKit

@IBDesignable class CardView: UIView {
    
    var card: Card? 
    
    var isHighlighted: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private func generatePath(for card: Card) -> UIBezierPath {
        let identifier = card.identifier.array.map({$0-1})
        let path = UIBezierPath()
        path.lineWidth = SizeRation.lineWidthToBoundsHeight*bounds.height
        let numberOfSymbols = CardView.numberOfSymbols[identifier[1]]
        CardView.colors[identifier[2]].setStroke()
        CardView.colors[identifier[2]].setFill()
        if let symbol = Symbols.init(rawValue: identifier[0]), let texture = Textures.init(rawValue: identifier[3]){
            let symbolHeight = SizeRation.symbolHeightToBoundsHeight * bounds.height
            let horizontalSymbolsOffset = SizeRation.horizontalElementsOffsetToBoundsWidth * bounds.width
            let verticalSymbolsOffset = SizeRation.verticalElementsOffsetToBoundsHeight * bounds.height
            if numberOfSymbols == 1 {
                path.append(symbol.getPathIn(CGRect(origin: CGPoint(x: bounds.minX+horizontalSymbolsOffset, y: bounds.midY-symbolHeight/2), size: CGSize(width: bounds.width-2*horizontalSymbolsOffset, height: symbolHeight))))
            } else if numberOfSymbols == 2 {
                path.append(symbol.getPathIn(CGRect(origin: CGPoint(x: bounds.minX+horizontalSymbolsOffset, y: bounds.midY-symbolHeight-0.5*verticalSymbolsOffset), size: CGSize(width: bounds.width-2*horizontalSymbolsOffset, height: symbolHeight))))
                path.append(symbol.getPathIn(CGRect(origin: CGPoint(x: bounds.minX+horizontalSymbolsOffset, y: bounds.midY+0.5*verticalSymbolsOffset), size: CGSize(width: bounds.width-2*horizontalSymbolsOffset, height: symbolHeight))))
            } else if numberOfSymbols == 3 {
                path.append(symbol.getPathIn(CGRect(origin: CGPoint(x: bounds.minX+horizontalSymbolsOffset, y: bounds.midY-symbolHeight/2), size: CGSize(width: bounds.width-2*horizontalSymbolsOffset, height: symbolHeight))))
                path.append(symbol.getPathIn(CGRect(origin: CGPoint(x: bounds.minX+horizontalSymbolsOffset, y: bounds.midY-1.5*symbolHeight-verticalSymbolsOffset), size: CGSize(width: bounds.width-2*horizontalSymbolsOffset, height: symbolHeight))))
                path.append(symbol.getPathIn(CGRect(origin: CGPoint(x: bounds.minX+horizontalSymbolsOffset, y: bounds.midY+verticalSymbolsOffset+0.5*symbolHeight), size: CGSize(width: bounds.width-2*horizontalSymbolsOffset, height: symbolHeight))))
            }
            path.addClip()
            switch texture {
            case .solid:
                path.fill()
            case .unfilled:
                break
            case.striped:
                for horizontalOffset in stride(from: bounds.minX, to: bounds.maxX, by: SizeRation.stripeOffsetToBoundsWidth*bounds.width) {
                    path.move(to: CGPoint(x: bounds.minX+horizontalOffset, y: bounds.minY))
                    path.addLine(to: CGPoint(x: bounds.minX+horizontalOffset, y: bounds.maxY))
                }
            }
        }
        return path
    }
    
    override func draw(_ rect: CGRect) {
        let roundedRect = UIBezierPath(roundedRect: bounds, cornerRadius: SizeRation.cornerRadiusToBoundsHeight * bounds.height)
        roundedRect.addClip()
        if isHighlighted {
            ColorScheme.highlightedCard.getColor().setFill()
        } else {
            UIColor.white.setFill()
        }
        roundedRect.fill()
        if let cardForDrawing = card {
            if cardForDrawing.isChosen {
                if cardForDrawing.isMatched {
                    ColorScheme.matchedCard.getColor().setStroke()
                    roundedRect.lineWidth = SizeRation.borderWidthToBoundsWidth * roundedRect.bounds.width
                    roundedRect.stroke()
                } else {
                    ColorScheme.chosenCard.getColor().setStroke()
                    roundedRect.lineWidth = SizeRation.borderWidthToBoundsWidth * roundedRect.bounds.width
                    roundedRect.stroke()
                }
            }
            let symbolsPath = generatePath(for: cardForDrawing)
            symbolsPath.stroke()
        }
    }
}

extension CardView {
    private struct SizeRation {
        static let cornerRadiusToBoundsHeight: CGFloat = 0.05
        static let symbolHeightToBoundsHeight: CGFloat = 0.2
        static let lineWidthToBoundsHeight: CGFloat = 0.01
        static let verticalElementsOffsetToBoundsHeight: CGFloat = 0.02
        static let horizontalElementsOffsetToBoundsWidth: CGFloat = 0.1
        static let stripeOffsetToBoundsWidth: CGFloat = 0.05
        static let borderWidthToBoundsWidth: CGFloat = 0.1
    }
    
    private var cornerRadius: CGFloat {
        return SizeRation.cornerRadiusToBoundsHeight * bounds.size.height
        
    }
    
    private enum Symbols: Int {
        case diamond = 0
        case oval = 1
        case squiggle = 2
        
        func getPathIn(_ rect: CGRect) -> UIBezierPath {
            let path = UIBezierPath()
            switch self {
            case .diamond:
                path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
                path.close()
            case .oval:
                let radius = rect.height / 2
                path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
                path.addArc(withCenter: CGPoint(x: rect.minX + radius, y: rect.midY), radius: radius, startAngle: 1.5*CGFloat.pi , endAngle: CGFloat.pi/2, clockwise: false)
                path.addLine(to: CGPoint(x: rect.maxX - radius , y: rect.maxY))
                path.addArc(withCenter: CGPoint(x: rect.maxX - radius, y: rect.midY), radius: radius, startAngle: CGFloat.pi/2, endAngle: 1.5*CGFloat.pi, clockwise: false)
                path.close()
            case .squiggle:
                path.move(to: CGPoint(x: rect.minX + rect.width/10, y: rect.maxY))
                path.addCurve(to: CGPoint(x: rect.maxX-rect.width/10, y: rect.minY), controlPoint1: CGPoint(x: rect.minX+rect.width/3, y: rect.minY), controlPoint2: CGPoint(x: rect.minX+2*rect.width/3, y: rect.minY+rect.height/3))
                path.addCurve(to: CGPoint(x: rect.minX + rect.width/10, y: rect.maxY), controlPoint1: CGPoint(x: rect.maxX-rect.width/3, y: rect.maxY), controlPoint2: CGPoint(x: rect.maxX-2*rect.width/3, y: rect.maxY-rect.height/3))
            }
            return path
        }
    }
    
    private static let colors = [#colorLiteral(red: 0.5791940689, green: 0.1280144453, blue: 0.5726861358, alpha: 1), #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1), #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)]
    
    private static let numberOfSymbols = [1,2,3]
    
    private enum Textures: Int {
        case solid = 0
        case unfilled = 1
        case striped = 2
    }
    
    
    private enum ColorScheme {
        case matchedCard
        case chosenCard
        case cardBackground
        case highlightedCard
        
        func getColor() -> UIColor {
            switch self {
            case .matchedCard:
                return #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
            case .chosenCard:
                return #colorLiteral(red: 0.9977241158, green: 0.9840803742, blue: 0.003218021942, alpha: 1)
            case .cardBackground:
                return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            case .highlightedCard:
                return #colorLiteral(red: 0.9994240403, green: 0.9855536819, blue: 0, alpha: 1)
                
            }
        }
    }
}
