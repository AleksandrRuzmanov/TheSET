//
//  GameMechanism.swift
//  The game SET
//
//  Created by Aleksandr on 30/01/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import Foundation

class GameMechanism {
    
    func setInGamePlayerWith(number: Int) {
        if let player = Players.init(rawValue: number) {
            playerInGame = player
        }
        for card in cards {
            if !card.isMatched {
                 card.isChosen = false
            }
        }
    }
    
    func resetPlayersFromGame() {
        playerInGame = nil
    }
    
    // if there aren't not matched card in deck of card and there are not sets among card on the table, then game over
    var isGameOver: Bool {
        if cards.filter({!($0.isOnTable)}).filter({!($0.isMatched)}).isEmpty && setsOnTable.isEmpty {
            return true
        }
        return false
    }
    
    // contain information about identifiers of sets placed currently on table
    var setsOnTable: [[Card]] {
        return findSetsIn(cards.filter({$0.isOnTable}).filter({!($0.isMatched)}))
    }
    
    // deck of cards
    private(set) var cards = [Card]()
    
    // shuffle the deck of cards
    func shuffleTheCards() {
        cards.shuffle()
    }
    
    // find a set for the enemy and return indices of cards from this set
    func findSetForEnemy() -> [Card]? {
        if let randomSet = setsOnTable.randomElement() {
            for card in cards {
                card.isChosen = false
            }
            for card in randomSet{
                card.isMatched = true
            }
            dealRandomCards(amount: randomSet.count)
            enemyScore += extraPointsForMatchedCards - userIndependentPenaltyPoints
            return randomSet
        }
        return nil
    }
    
    func useCheat() -> [Card]? {
        let penaltyPoints = -userActionPenaltyPoints.usedCheat.getPenaltyPoints()
        updateScore(with: penaltyPoints)
        if !setsOnTable.isEmpty {
            return setsOnTable.randomElement()
        }
        return nil
    }
    
    func addThreeCards() {
        if !setsOnTable.isEmpty {
            let penaltyPoints = -userActionPenaltyPoints.addedThreeCards.getPenaltyPoints()
            updateScore(with: penaltyPoints)
        }
        dealRandomCards(amount: 3)
    }
    
    func startNewGame() {
        createDeckOfCards()
        timeWhenGameStarted = Date()
        firstPlayerScore = 0
        secondPlayerScore = 0
        resetPlayersFromGame()
        enemyScore = 0
        dealRandomCards(amount: 12)
    }
    
    func chooseCard(_ card: Card) {
        if card.isOnTable, !card.isMatched {
            var numberOfCardsChosen: Int {
                return cards.filter{$0.isChosen}.count
            }
            if card.isChosen, numberOfCardsChosen < 3 {
                card.isChosen = false
                let penaltyPoints = -userActionPenaltyPoints.cancelledCardSelection.getPenaltyPoints()
                updateScore(with: penaltyPoints)
                
            } else {
                switch numberOfCardsChosen{
                case 2:
                    card.isChosen = true
                    let areMatch = checkTheSetForMatch(for: cards.filter{$0.isChosen})
                    for chosenCard in cards.filter({$0.isChosen}) {
                        chosenCard.isMatched = areMatch
                    }
                    let points = areMatch ? (extraPointsForMatchedCards - userIndependentPenaltyPoints) : (-userActionPenaltyPoints.cardsAreNotMatched.getPenaltyPoints())
                    updateScore(with: points)
                case 3:
                    // if cards are matched then replace those cards with new cards
                    if cards.filter({$0.isChosen}).filter({$0.isMatched}).count > 0 {
                        dealRandomCards(amount: cards.filter({$0.isChosen}).filter({$0.isMatched}).count)
                    }
                    for chosenCard in cards.filter({$0.isChosen}) {
                        chosenCard.isChosen = false
                    }
                    card.isChosen = true
                default:
                    card.isChosen = true
                }
            }
        }
    }
    
    // score calculating stuff
    
    private var timeWhenGameStarted: Date?
    
    private(set) var enemyScore = 0
    
    private(set) var secondPlayerScore = 0
    
    private(set) var firstPlayerScore = 0
    
    private func updateScore(with points: Int) {
        if let player = playerInGame {
            switch player {
            case .player1:
                firstPlayerScore += points
            case .player2:
                secondPlayerScore += points
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
    
    private let extraPointsForMatchedCards = 200
    
    private enum userActionPenaltyPoints {
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
        return (timePenaltyPoints + numberOfCardsOnTable)
    }
    
    // game table information
    
    private var numberOfCardsOnTable: Int {
        var container = 0
        for card in cards {
            if card.isOnTable {
                container += 1
            }
        }
        return container
    }
    
    // private methods
    
    private func dealRandomCards(amount: Int) {
        //if there are matched cards on table then replace them with new cards
        let matchedCards = cards.filter({$0.isMatched}).filter({$0.isOnTable})
        let matchedCardsQuantity = matchedCards.count
        for card in matchedCards {
            card.isOnTable = false
            card.isChosen = false
        }
        let requiredIterationsQuantity = (matchedCardsQuantity <= amount) ? amount : matchedCardsQuantity
        var iteration = 0
        repeat {
            let cardsNotInTheGame = cards.filter({!($0.isOnTable)}).filter({!($0.isMatched)})
            if let randomCard = cardsNotInTheGame.randomElement(), let indexOfRandomCard = cards.firstIndex(of: randomCard) {
                cards[indexOfRandomCard].isOnTable = true
            }
            iteration += 1
        } while iteration < requiredIterationsQuantity
    }
    
    // find all sets among cards and return their identifiers in arrays
    private func findSetsIn(_ cards: [Card]) -> [[Card]] {
        var setsOnTable = [[Card]]()
        for firstIterator in cards.indices {
            for secondIterator in firstIterator...(cards.count-1) {
                for thirdIterator in secondIterator...(cards.count-1) {
                    // iterate all identifiers to create every possible three of cards
                    if cards[firstIterator] != cards[secondIterator] && cards[firstIterator] != cards[thirdIterator] && cards[secondIterator] != cards[thirdIterator] {
                        var areMatch = true
                        var matches = [Bool]()
                        for index in cards[firstIterator].identifier.array.indices {
                            matches.append(checkTheElements(cards[firstIterator].identifier.array[index], cards[secondIterator].identifier.array[index], cards[thirdIterator].identifier.array[index]))
                        }
                        areMatch = !(matches.contains(false))
                        if areMatch {
                            setsOnTable.append([cards[firstIterator], cards[secondIterator], cards[thirdIterator]])
                        }
                    }
                }
            }
        }
        return setsOnTable
    }
    
    // check the elements of 3 cards identifiers if they satisfy the conditions
    private func checkTheElements(_ e1: Int, _ e2: Int, _ e3: Int) -> Bool {
        var match = false
        if ((e1 == e2 && e2 == e3) || (e1 != e2 && e2 != e3 && e3 != e1)) {
            match = true
        }
        return match
    }
    
    // check the set of 3 cards if they match or not according to the rules
    private func checkTheSetForMatch(for cards: [Card]) -> Bool {
        assert(cards.count == 3, "checkTheMatch(for cards:) - there should be 3 cards to check the match")
        var areMatch = true
        var identifiers = [[Int]]()
        for card in cards {
            identifiers.append(card.identifier.array)
        }
        var matches = [Bool]()
        for index in identifiers[0].indices {
            matches.append(checkTheElements(identifiers[0][index], identifiers[1][index], identifiers[2][index]))
        }
        areMatch = !(matches.contains(false))
        return areMatch
    }
    
    
    // create a new deck of cards and shuffle it
    private func createDeckOfCards() {
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
        shuffleTheCards()
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
