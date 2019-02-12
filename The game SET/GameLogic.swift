//
//  GameLogic.swift
//  The game SET
//
//  Created by Aleksandr on 30/01/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import Foundation

class GameLogic {
    
    // public methods and properties
    
    func setPlayer(number: Int) {
        if let player = Players.init(rawValue: number) {
            playerInGame = player
        }
        for card in cards {
            if !card.isMatched {
                 card.isChosen = false
            }
        }
    }
    
    private(set) var playerInGame: Players?
    
    enum Players: Int {
        case player1 = 1
        case player2 = 2
        func getOppositePlayerRawValue() -> Int {
            switch self {
            case .player1:
                return 2
            case .player2:
                return 1
            }
        }
    }
    
    func resetAllPlayers() {
        playerInGame = nil
    }
    
    var isEnded: Bool {
        if cards.filter({!($0.isOnTable)}).filter({!($0.isMatched)}).isEmpty && setsOnTable.isEmpty {
            return true
        }
        return false
    }
    
    var setsOnTable: [[Card]] {
        return findSetsIn(cards.filter({$0.isOnTable}).filter({!($0.isMatched)}))
    }
    
    private(set) var cards = [Card]()
    
    func shuffleCards() {
        cards.shuffle()
    }
    
    func getTheSetForEnemy() -> [Card]? {
        if let randomSet = setsOnTable.randomElement() {
            for card in cards {
                card.isChosen = false
            }
            for card in randomSet {
                card.isMatched = true
            }
            dealCards(amount: randomSet.count)
            enemyScore += extraPointsForMatchedCards - userIndependentPenaltyPoints
            return randomSet
        }
        return nil
    }
    
    func useCheat() -> [Card]? {
        let penaltyPoints = -userActionPenaltyPointsCases.usedCheat.getPenaltyPoints()
        updateUserScore(with: penaltyPoints)
        if !setsOnTable.isEmpty {
            return setsOnTable.randomElement()
        }
        return nil
    }
    
    func addThreeCards() {
        if !setsOnTable.isEmpty {
            let penaltyPoints = -userActionPenaltyPointsCases.addedThreeCards.getPenaltyPoints()
            updateUserScore(with: penaltyPoints)
        }
        dealCards(amount: 3)
    }
    
    func startNewGame() {
        resetAllPlayers()
        createNewDeckOfCards()
        timeWhenGameStarted = Date()
        firstPlayerScore = 0
        secondPlayerScore = 0
        enemyScore = 0
        dealCards(amount: 12)
    }
    
    func chooseCard(_ card: Card) {
        var amountOfChosenCards: Int {
            return cards.filter{$0.isChosen}.count
        }
        if card.isOnTable, !card.isMatched {
            if card.isChosen, amountOfChosenCards < 3 {
                card.isChosen = false
                let penaltyPoints = -userActionPenaltyPointsCases.cancelledCardSelection.getPenaltyPoints()
                updateUserScore(with: penaltyPoints)
                
            } else {
                card.isChosen = true
                if amountOfChosenCards == 3 {
                    let cardsAreMatch = checkCardsSet(for: cards.filter{$0.isChosen})
                    if cardsAreMatch {
                        for chosenCard in cards.filter({$0.isChosen}) {
                            chosenCard.isMatched = cardsAreMatch
                        }
                        let matchedCardsAmount = cards.filter({$0.isChosen && $0.isMatched}).count
                        dealCards(amount: matchedCardsAmount)
                    }
                    for chosenCard in cards.filter({$0.isChosen}) {
                        chosenCard.isChosen = false
                    }
                    let points = cardsAreMatch ? (extraPointsForMatchedCards - userIndependentPenaltyPoints) : (-userActionPenaltyPointsCases.cardsAreNotMatched.getPenaltyPoints())
                    updateUserScore(with: points)
                }
            }
        }
    }
    
    
    
    
    // private methods and properties
    
    // score calculating stuff
    
    private var timeWhenGameStarted: Date?
    
    private(set) var enemyScore = 0
    
    private(set) var secondPlayerScore = 0
    
    private(set) var firstPlayerScore = 0
    
    private func updateUserScore(with points: Int) {
        if let player = playerInGame {
            switch player {
            case .player1:
                firstPlayerScore += points
            case .player2:
                secondPlayerScore += points
            }
        }
    }
    
    
    
    private let extraPointsForMatchedCards = 200
    
    private enum userActionPenaltyPointsCases {
        case addedThreeCards
        case cancelledCardSelection
        case usedCheat
        case cardsAreNotMatched
        
        func getPenaltyPoints() -> Int {
            switch self {
            case .addedThreeCards:
                return 10
            case .cancelledCardSelection:
                return 10
            case .usedCheat:
                return 50
            case .cardsAreNotMatched:
                return 100
            }
            
        }
    }
    
    private var userIndependentPenaltyPoints: Int {
        var timePenaltyPoints = 0
        if timeWhenGameStarted != nil {
            let timeIntervalSinceGameStarted = Double(Date.init().timeIntervalSince(timeWhenGameStarted!))
            timePenaltyPoints = Int(round(timeIntervalSinceGameStarted / 6))
        }
        return (timePenaltyPoints + cards.filter({$0.isOnTable}).count)
    }
    
    

    
    // main game methods
    
    private func dealCards(amount: Int) {
        //if there are matched cards on table it should replace them with new cards
        let matchedCards = cards.filter({$0.isMatched && $0.isOnTable})
        let matchedCardsAmount = matchedCards.count
        for card in matchedCards {
            card.isOnTable = false
            card.isChosen = false
        }
        let requiredIterationsQuantity = max(matchedCardsAmount, amount)
        var iteration = 0
        repeat {
            let cardsInTheDeck = cards.filter({!($0.isOnTable) && !($0.isMatched)})
            if let randomCard = cardsInTheDeck.randomElement(){
                randomCard.isOnTable = true
            }
            iteration += 1
        } while iteration < requiredIterationsQuantity
    }
    
    private func findSetsIn(_ cards: [Card]) -> [[Card]] {
        var setsOnTable = [[Card]]()
        for firstIterator in cards.indices {
            for secondIterator in firstIterator...(cards.count-1) {
                for thirdIterator in secondIterator...(cards.count-1) {
                    // iterate all identifiers to create every possible three of cards
                    if cards[firstIterator] != cards[secondIterator] && cards[firstIterator] != cards[thirdIterator] && cards[secondIterator] != cards[thirdIterator] {
                        var cardsAreMatch = true
                        var parametersMatches = [Bool]()
                        for index in cards[firstIterator].identifier.array.indices {
                            parametersMatches.append(checkTheElements(
                                cards[firstIterator].identifier.array[index], cards[secondIterator].identifier.array[index], cards[thirdIterator].identifier.array[index]))
                        }
                        cardsAreMatch = !(parametersMatches.contains(false))
                        if cardsAreMatch {
                            setsOnTable.append([cards[firstIterator], cards[secondIterator], cards[thirdIterator]])
                        }
                    }
                }
            }
        }
        return setsOnTable
    }
    
    // check the elements of three cards identifiers if they satisfy the conditions
    private func checkTheElements(_ e1: Int, _ e2: Int, _ e3: Int) -> Bool {
        var match = false
        if ((e1 == e2 && e2 == e3) || (e1 != e2 && e2 != e3 && e3 != e1)) {
            match = true
        }
        return match
    }
    
    private func checkCardsSet(for cards: [Card]) -> Bool {
        assert(cards.count == 3, "checkTheMatch(for cards:) - there should be 3 cards to check the match")
        var cardsAreMatch = true
        var identifiers = [[Int]]()
        for card in cards {
            identifiers.append(card.identifier.array)
        }
        var parametersMatches = [Bool]()
        for index in identifiers[0].indices {
            parametersMatches.append(checkTheElements(identifiers[0][index], identifiers[1][index], identifiers[2][index]))
        }
        cardsAreMatch = !(parametersMatches.contains(false))
        return cardsAreMatch
    }

    private func createNewDeckOfCards() {
        cards.removeAll()
        for symbol in 1...3 {
            for color in 1...3 {
                for texture in 1...3 {
                    for numberOfSymbols in 1...3 {
                        let identifier = ((symbol*10 + color)*10+texture)*10+numberOfSymbols
                        cards.append(Card(identifier: identifier))
                    }
                }
            }
        }
        shuffleCards()
    }
    
    init() {
        startNewGame()
    }
}

extension Int {
    var array: [Int] {
        return String(self).compactMap{Int(String($0))}
    }
}
