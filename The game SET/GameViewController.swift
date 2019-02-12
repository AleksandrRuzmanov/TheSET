//
//  GameViewController.swift
//  The game SET
//
//  Created by Aleksandr on 30/01/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {
    
    // Model initialization
    
    private var game = GameLogic.init()
    
    
    
    // PvP mode buttons
    
    @IBAction private func touchPvPButton(_ sender: UIButton) {
        pvpModeOn = true
    }
    @IBAction private func touchPlayer1Button(_ sender: UIButton) {
        giveMoveForPlayer(number: 1, for: TimeIntervals.playerMoveDuration.getInterval())
    }
    @IBAction private func touchPlayer2Button(_ sender: UIButton) {
        giveMoveForPlayer(number: 2, for: TimeIntervals.playerMoveDuration.getInterval())
    }

    @IBOutlet private weak var player2Button: UIButton!
    
    @IBOutlet private weak var player1Button: UIButton!
    
    @IBOutlet private weak var pvpButton: UIButton!
 
    
    
    
    // Gesture recognizers
    
    @IBOutlet private weak var swipeGestureRecognizer: UISwipeGestureRecognizer!
    
    @IBOutlet private weak var rotationGestureRecognizer: UIRotationGestureRecognizer!
    
    @IBAction private func rotateOnGameZone(_ sender: UIRotationGestureRecognizer) {
        switch sender.state {
        case .ended:
            game.shuffleCards()
            updateViewFromModel()
        default:
            break
        }
    }
    @IBAction private func swipeOnGameZone(_ sender: UISwipeGestureRecognizer) {
        game.addThreeCards()
        updateViewFromModel()
    }
    
    
    
    
    // Main user interface stuff
    
    @IBOutlet private weak var bannerLabel: UILabel!
    
    @IBOutlet private weak var gameFieldView: GameFieldView!
    
    @IBOutlet private weak var newGameButton: UIButton!
    
    @IBOutlet private weak var enemyEmotionLabel: UILabel!
    
    @IBOutlet private weak var enemyScoreLabel: UILabel!
    
    @IBOutlet private weak var cheatButton: UIButton!
    
    @IBOutlet private weak var addThreeCardsButton: UIButton!
    
    @IBOutlet private weak var scoreLabel: UILabel!
    
    @IBAction private func touchCheatButton(_ sender: UIButton) {
        let cheatSet = game.useCheat()
        showCheatSet(cheatSet)
    }
    
    @IBAction private func touchAddThreeCardsButton(_ sender: UIButton) {
        if pvpModeOn {
            if let playerNumber = game.playerInGame?.getOppositePlayerRawValue() {
                playerMoveTimer?.invalidate()
                giveMoveForPlayer(number: playerNumber, for: 2*TimeIntervals.playerMoveDuration.getInterval())
            }
        }
        game.addThreeCards()
        updateViewFromModel()
    }
    
    @IBAction private func touchNewGameButton(_ sender: UIButton) {
        startNewGame()
    }
    
    @objc private func choseCard(sender: UITapGestureRecognizer) {
        if let cardView = sender.view as? CardView {
            if let card = cardView.card {
                game.chooseCard(card)
                updateViewFromModel()
            }
        }
    }
    
    
    
    
    private func startNewGame() {
        pvpModeOn = false
        startEnemyThinking()
        game.startNewGame()
        game.setPlayer(number: 1)
        gameFieldView.removeAllCards()
        updateViewFromModel()
    }
    
    private func showCheatSet(_ cheatSet: [Card]?) {
        if let cardSet = cheatSet {
            for card in cardSet {
                for view in gameFieldView.subviews {
                    if let cardView = view as? CardView {
                        if cardView.card == card {
                            cheatButton.isEnabled = false
                            cardView.isHighlighted = true
                            _ = Timer.scheduledTimer(withTimeInterval: TimeIntervals.displayingCheatDuration.getInterval(), repeats: false, block: {[unowned self] _ in
                                cardView.isHighlighted = false
                                self.updateViewFromModel()
                            })
                        }
                    }
                }
            }
        } else {
             updateViewFromModel()
        }
    }
    
   
    
    
    // Main game visualization methods

    private func updateViewFromModel() {
        setupGameField()
        scoreLabel.text = pvpModeOn ? "Player 1 score: \(game.firstPlayerScore)" : "Your score: \(game.firstPlayerScore)"
        enemyScoreLabel.text = pvpModeOn ? "Player 2 score: \(game.secondPlayerScore)" : "Enemy score: \(game.enemyScore)"
        // is enabled when there are cards in deck (never been on table before) and PvP mode off or PvP mode on but player currently in game
        addThreeCardsButton.isEnabled = !game.cards.filter({!($0.isOnTable) && !($0.isMatched)}).isEmpty && (!pvpModeOn || (pvpModeOn && game.playerInGame != nil))
        cheatButton.isEnabled = (!pvpModeOn || (pvpModeOn && game.playerInGame != nil)) && !game.isEnded
        player1Button.isEnabled = pvpModeOn && (game.playerInGame == nil) && !game.isEnded
        player2Button.isEnabled = pvpModeOn && (game.playerInGame == nil) && !game.isEnded
        pvpButton.isEnabled = !pvpModeOn && !game.isEnded
        rotationGestureRecognizer.isEnabled = (!pvpModeOn || (pvpModeOn && game.playerInGame != nil)) && !game.isEnded
        swipeGestureRecognizer.isEnabled = (!pvpModeOn || (pvpModeOn && game.playerInGame != nil)) && !game.isEnded
        bannerLabel.isHidden = !game.isEnded
        if pvpModeOn {
            if game.playerInGame == nil {
                enemyEmotionLabel.text = ""
                stopEnemyThinking()
                for view in gameFieldView.subviews {
                    view.gestureRecognizers?.removeAll()
                }
            } else if let playerNumber = game.playerInGame?.rawValue {
                enemyEmotionLabel.text = "PLAYER \(playerNumber)"
            }
        }
        if game.isEnded {
            endGame()
        }
    }
    
    private func endGame() {
        for view in gameFieldView.subviews {
            view.gestureRecognizers?.removeAll()
        }
        stopEnemyThinking()
        if pvpModeOn {
            enemyEmotionLabel.text = ""
            if game.firstPlayerScore == game.secondPlayerScore {
                bannerLabel.text = BannerCases.deadHeat.getText()
            } else {
                bannerLabel.text = game.firstPlayerScore > game.secondPlayerScore ? BannerCases.player1WinBanner.getText() : BannerCases.player2WinBanner.getText()
            }
        } else {
            if game.firstPlayerScore == game.enemyScore {
                bannerLabel.text = BannerCases.deadHeat.getText()
                enemyEmotionLabel.text = EnemyEmotions.neutral.getEmotion()
            } else {
                bannerLabel.text = game.firstPlayerScore > game.enemyScore ? BannerCases.userWinBanner.getText() : BannerCases.userLoseBanner.getText()
                enemyEmotionLabel.text = game.firstPlayerScore > game.enemyScore ? EnemyEmotions.sad.getEmotion() : EnemyEmotions.happy.getEmotion()
            }
        }
    }
    
    private func setupGameField() {
        gameFieldView.superview?.bringSubviewToFront(gameFieldView)
        gameFieldView.discardPileFrame = newGameButton.superview?.convert(newGameButton.frame, to: gameFieldView)
        gameFieldView.deckFrame = addThreeCardsButton.superview?.convert(addThreeCardsButton.frame, to: gameFieldView)
        gameFieldView.placeCards(game.cards.filter({$0.isOnTable}))
        for view in gameFieldView.subviews {
            view.gestureRecognizers?.removeAll()
            let tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(choseCard(sender:)))
            view.addGestureRecognizer(tapGestureRecogniser)
        }
    }
    
    
    
    
    // Enemy behavior methods and properties
    
    private var enemyThinkingTimer: Timer?
    
    private var displayingEnemyChoiceTimer: Timer?
    
    private weak var enemyWaitingTimer: Timer? {
        willSet {
            enemyThinkingTimer?.invalidate()
            displayingEnemyChoiceTimer?.invalidate()
            enemyWaitingTimer?.invalidate()
        }
    }
    
    private func stopEnemyThinking() {
        enemyWaitingTimer = nil
    }
    
    private func startEnemyThinking() {
        enemyEmotionLabel.text = EnemyEmotions.neutral.getEmotion()
        enemyWaitingTimer = Timer.scheduledTimer(withTimeInterval: TimeIntervals.enemyWaiting.getInterval(), repeats: true){
            [unowned self] _ in
            self.enemyEmotionLabel.text = EnemyEmotions.thinking.getEmotion()
            self.enemyThinkingTimer = Timer.scheduledTimer(withTimeInterval: TimeIntervals.enemhyThinking.getInterval(), repeats: false) {[unowned self] _ in
                if let enemySet = self.game.getTheSetForEnemy() {
                    self.view.isUserInteractionEnabled = false
                    self.enemyEmotionLabel.text = EnemyEmotions.smart.getEmotion()
                    for card in enemySet {
                        for view in self.gameFieldView.subviews {
                            if let cardView = view as? CardView {
                                if cardView.card == card {
                                    cardView.isHighlighted = true
                                }
                            }
                        }
                    }
                    self.displayingEnemyChoiceTimer = Timer.scheduledTimer(withTimeInterval: TimeIntervals.displayingEnemyChoice.getInterval(), repeats: false) { [unowned self] _ in
                        self.view.isUserInteractionEnabled = true
                        self.enemyEmotionLabel.text = EnemyEmotions.neutral.getEmotion()
                        self.updateViewFromModel()
                    }
                } else {
                    self.enemyEmotionLabel.text = EnemyEmotions.tired.getEmotion()
                    self.displayingEnemyChoiceTimer = Timer.scheduledTimer(withTimeInterval: TimeIntervals.displayingEnemyChoice.getInterval(), repeats: false, block: {[unowned self] _ in
                        self.enemyEmotionLabel.text = EnemyEmotions.neutral.getEmotion()})
                }
            }
        }
    }
    
    
    
    
    // PvP mode methods and properties

    private var pvpModeOn = false {
        didSet {
            if pvpModeOn {
                gameFieldView.removeAllCards()
                game.startNewGame()
                updateViewFromModel()
            }
        }
    }
    
    private var playerMoveTimer: Timer?

    private func giveMoveForPlayer(number: Int, for timeInterval: TimeInterval) {
        if pvpModeOn {
            let numberOfPreviouslyMatchedCards = game.cards.filter({$0.isMatched}).count
            game.setPlayer(number: number)
            updateViewFromModel()
            playerMoveTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [unowned self] _ in
                if self.game.cards.filter({$0.isMatched}).count > numberOfPreviouslyMatchedCards {
                    self.game.resetAllPlayers()
                    self.updateViewFromModel()
                } else {
                    if let oppositePlayerNumber = self.game.playerInGame?.getOppositePlayerRawValue() {
                        self.game.setPlayer(number: oppositePlayerNumber)
                        self.updateViewFromModel()
                        self.playerMoveTimer = Timer.scheduledTimer(withTimeInterval: 2*timeInterval, repeats: false) {[unowned self] _ in
                            self.game.resetAllPlayers()
                            self.updateViewFromModel()
                        }
                    }
                }
            }
        }
    }

    
    // VC lifecycle methods
    
    @objc private  func orientationChanged() {
        updateViewFromModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name:  Notification.Name("UIDeviceOrientationDidChangeNotification"), object: nil)
        startNewGame()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("UIDeviceOrientationDidChangeNotification"), object: nil)
    }
}



extension GameViewController {
    
    // Database
    
    private enum EnemyEmotions: String {
        case neutral = "😐"
        case thinking = "🤔"
        case smart = "🤓"
        case tired = "😓"
        case happy = "🤩"
        case sad = "😢"
        func getEmotion() -> String {
            return self.rawValue
        }
        
    }
    
    private enum TimeIntervals {
        case enemyWaiting
        case enemhyThinking
        case displayingEnemyChoice
        case displayingCheatDuration
        case playerMoveDuration
        
        func getInterval() -> Double {
            switch self {
            case .enemyWaiting:
                return 10.0
            case .enemhyThinking:
                return 5.0
            case .displayingEnemyChoice:
                return 2.0
            case .displayingCheatDuration:
                return 2.0
            case .playerMoveDuration:
                return 4.0
            }
        }
    }
    
    private enum BannerCases {
        case userWinBanner
        case userLoseBanner
        case player1WinBanner
        case player2WinBanner
        case deadHeat
        
        func getText() -> String {
            switch self {
            case .userLoseBanner:
                return "GAME OVER \n ENEMY WIN"
            case .userWinBanner:
                return "GAME OVER \n YOU WIN"
            case .player1WinBanner:
                return "GAME OVER \n PLAYER 1 WIN"
            case .player2WinBanner:
                return "GAME OVER \n PLAYER 2 WIN"
            case .deadHeat:
                return "GAME OVER \n DEAD HEAT"
            }
        }
    }
}







extension UIButton {
    open override var isEnabled: Bool {
        didSet{
            self.backgroundColor = isEnabled ? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) : #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        }
    }
    open override func setNeedsDisplay() {
        super.setNeedsDisplay()
        self.layer.cornerRadius = 0.2 * bounds.height
    }
}

    extension UILabel {
        open override func setNeedsDisplay() {
            super.setNeedsDisplay()
            self.layer.masksToBounds = true
            self.layer.cornerRadius = 0.2 * bounds.height
        }
}

