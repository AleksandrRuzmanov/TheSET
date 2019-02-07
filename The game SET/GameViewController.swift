//
//  GameViewController.swift
//  The game SET
//
//  Created by Aleksandr on 30/01/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {
    
    
    // PvP mode stuff
    
    private var isPvPModeOn = false {
        didSet {
            add3CardsButton.isEnabled = !isPvPModeOn
            cheatButton.isEnabled = !isPvPModeOn
            player1Button.isEnabled = isPvPModeOn
            player2Button.isEnabled = isPvPModeOn
            pvpButton.isEnabled = !isPvPModeOn
            rotationGestureRecognizer.isEnabled = !isPvPModeOn
            swipeGestureRecognizer.isEnabled = !isPvPModeOn
            scoreLabel.text = isPvPModeOn ? "Player 1 score: \(game.firstPlayerScore)" : "Your score: \(game.firstPlayerScore)"
            enemyScoreLabel.text = isPvPModeOn ? "Player 2 score: \(game.secondPlayerScore)" : "Enemy score: \(game.enemyScore)"
            if isPvPModeOn {
                stopEnemyThinking()
                enemyEmotionLabel.text = ""
                for view in gameZoneView.subviews {
                    view.gestureRecognizers?.removeAll()
                }
            }
        }
    }
    
    private var playerMoveTimer: Timer?
    
    @IBAction private func touchPvPButton(_ sender: UIButton) {
        startNewGame()
        isPvPModeOn = true
    }
    @IBAction private func touchPlayer1Button(_ sender: UIButton) {
        setupGameForPlayer(number: 1, for: TimeIntervals.playerMoveDuration.getInterval())
    }
    @IBAction func touchPlayer2Button(_ sender: UIButton) {
        setupGameForPlayer(number: 2, for: TimeIntervals.playerMoveDuration.getInterval())
    }
    
    
    private func setupGameForPlayer(number: Int, for timeInterval: TimeInterval) {
        
        func setupViewForCard(number: Int) {
            game.setInGamePlayerWith(number: number)
            updateViewFromModel()
            cheatButton.isEnabled = true
            add3CardsButton.isEnabled = !game.cards.filter({!($0.isOnTable)}).filter({!($0.isMatched)}).isEmpty
            player1Button.isEnabled = false
            player2Button.isEnabled = false
            enemyEmotionLabel.text = "PLAYER \(number)"
            rotationGestureRecognizer.isEnabled = true
            swipeGestureRecognizer.isEnabled = true
        }
        
        func resetViewSettings() {
            self.player1Button.isEnabled = true
            self.player2Button.isEnabled = true
            self.updateViewFromModel()
            self.game.resetPlayersFromGame()
            self.rotationGestureRecognizer.isEnabled = false
            self.swipeGestureRecognizer.isEnabled = false
            self.enemyEmotionLabel.text = ""
            for view in self.gameZoneView.subviews {
                view.gestureRecognizers?.removeAll()
            }
        }
        
        
        if isPvPModeOn {
            let numberOfPreviouslyMatchedCards = game.cards.filter({$0.isMatched}).count
            setupViewForCard(number: number)
            playerMoveTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [unowned self] _ in
                if self.game.cards.filter({$0.isMatched}).count > numberOfPreviouslyMatchedCards {
                 resetViewSettings()
                } else {
                    if let oppositePlayerNumber = self.game.playerInGame?.getOppositePlayerRawValue() {
                        setupViewForCard(number: oppositePlayerNumber)
                        self.playerMoveTimer = Timer.scheduledTimer(withTimeInterval: 2*timeInterval, repeats: false) {_ in
                          resetViewSettings()
                        }
                    }
                }
            }
        }
    }

    @IBOutlet private weak var player2Button: UIButton!
    
    @IBOutlet private weak var player1Button: UIButton!
    
    @IBOutlet private weak var pvpButton: UIButton!
 
    
    
    
    
    
    // Gesture recognizers from gameZoneView
    @IBOutlet private weak var swipeGestureRecognizer: UISwipeGestureRecognizer!
    @IBOutlet private weak var rotationGestureRecognizer: UIRotationGestureRecognizer!
    
    
    @IBAction private func rotateOnGameZone(_ sender: UIRotationGestureRecognizer) {
        switch sender.state {
        case .ended:
            game.shuffleTheCards()
            updateViewFromModel()
        default:
            break
        }
    }
    @IBAction private func swipeOnGameZone(_ sender: UISwipeGestureRecognizer) {
        game.addThreeCards()
        updateViewFromModel()
    }
    
    @IBOutlet private weak var bannerLabel: UILabel!
    
    @IBOutlet private weak var gameZoneView: GameZoneView!
    
    
    private var game = GameMechanism.init()
    
    @objc func choseCard(sender: UITapGestureRecognizer) {
        if let cardView = sender.view as? CardView {
            if let card = cardView.card {
                game.chooseCard(card)
                updateViewFromModel()
            }
        }
    }
    
    @IBOutlet private weak var newGameButton: UIButton!
    
    @IBOutlet private weak var enemyEmotionLabel: UILabel!
    
    @IBOutlet private weak var enemyScoreLabel: UILabel!
    
    @IBOutlet private weak var cheatButton: UIButton!
    
    @IBAction private func touchCheatButton(_ sender: UIButton) {
        let cheatSet = game.useCheat()
        showCheatSet(cheatSet)
    }
    
    @IBOutlet private weak var add3CardsButton: UIButton!
    
    @IBOutlet private weak var scoreLabel: UILabel!
    
    @IBAction private func touchAdd3CardsButton(_ sender: UIButton) {
        if isPvPModeOn {
            if let playerNumber = game.playerInGame?.getOppositePlayerRawValue() {
                playerMoveTimer?.invalidate()
                setupGameForPlayer(number: playerNumber, for: 2*TimeIntervals.playerMoveDuration.getInterval())
            }
        }
        game.addThreeCards()
        updateViewFromModel()
    }
    
    @IBAction private func touchNewGameButton(_ sender: UIButton) {
        startNewGame()
    }
    
    private func startNewGame() {
        isPvPModeOn = false
        startEnemyThinking()
        game.startNewGame()
        game.setInGamePlayerWith(number: 1)
        updateViewFromModel()
    }
    
    // displaying enemy activity
    private var enemyThinkingPeriodTimer: Timer?
    
    private var displayingResultsOfEnemyThinkingPeriodTimer: Timer?
    
    private weak var enemyDoingNothingPeriodTimer: Timer? {
        willSet {
            enemyThinkingPeriodTimer?.invalidate()
            displayingResultsOfEnemyThinkingPeriodTimer?.invalidate()
            enemyDoingNothingPeriodTimer?.invalidate()
        }
    }
    
    private func stopEnemyThinking() {
        enemyDoingNothingPeriodTimer = nil
    }
    
    private func startEnemyThinking() {
        enemyEmotionLabel.text = EnemyEmotions.neutral.rawValue
        enemyDoingNothingPeriodTimer = Timer.scheduledTimer(withTimeInterval: TimeIntervals.doNothingPeriodDuration.getInterval(), repeats: true){
            [unowned self] _ in
            self.enemyEmotionLabel.text = EnemyEmotions.thinking.rawValue
            self.enemyThinkingPeriodTimer = Timer.scheduledTimer(withTimeInterval: TimeIntervals.thinkingPeriodDuration.getInterval(), repeats: false) {[unowned self] _ in
                if let enemySet = self.game.findSetForEnemy() {
                    self.view.isUserInteractionEnabled = false
                    self.enemyEmotionLabel.text = EnemyEmotions.smart.rawValue
                    for card in enemySet {
                        for view in self.gameZoneView.subviews {
                            if let cardView = view as? CardView {
                                if cardView.card == card {
                                    cardView.isHighlighted = true
                                }
                            }
                        }
                    }
                    self.displayingResultsOfEnemyThinkingPeriodTimer = Timer.scheduledTimer(withTimeInterval: TimeIntervals.displayingResultsPeriodDuration.getInterval(), repeats: false) { [unowned self] _ in
                        self.view.isUserInteractionEnabled = true
                        self.enemyEmotionLabel.text = EnemyEmotions.neutral.rawValue
                        self.updateViewFromModel()
                    }
                } else {
                    self.enemyEmotionLabel.text = EnemyEmotions.tired.rawValue
                    self.displayingResultsOfEnemyThinkingPeriodTimer = Timer.scheduledTimer(withTimeInterval: TimeIntervals.displayingResultsPeriodDuration.getInterval(), repeats: false, block: {[unowned self] _ in
                        self.enemyEmotionLabel.text = EnemyEmotions.neutral.rawValue})
                }
            }
        }
    }
    
    
    //    // highlights one random set on table for 2 seconds
    private func showCheatSet(_ cheatSet: [Card]?) {
        if let cardSet = cheatSet {
            for card in cardSet {
                for view in gameZoneView.subviews {
                    if let cardView = view as? CardView {
                        if cardView.card == card {
                            cheatButton.isEnabled = false
                            cardView.isHighlighted = true
                            _ = Timer.scheduledTimer(withTimeInterval: TimeIntervals.displayingCheatDuration.getInterval(), repeats: false, block: {_ in
                                cardView.isHighlighted = false
                            })
                        }
                    }
                }
            }
        }
    }
    
    func updateViewFromModel() {
        setupGameZone()
        scoreLabel.text = isPvPModeOn ? "Player 1 score: \(game.firstPlayerScore)" : "Your score: \(game.firstPlayerScore)"
        enemyScoreLabel.text = isPvPModeOn ? "Player 2 score: \(game.secondPlayerScore)" : "Enemy score: \(game.enemyScore)"
        // activate or deactivate buttons
        add3CardsButton.isEnabled = (!game.cards.filter({!($0.isOnTable)}).filter({!($0.isMatched)}).isEmpty && !isPvPModeOn)
        
        // if GAME OVER
        if game.isGameOver {
            for view in gameZoneView.subviews {
                view.gestureRecognizers?.removeAll()
            }
            stopEnemyThinking()
            cheatButton.isEnabled = false
            player1Button.isEnabled = false
            player2Button.isEnabled = false
            pvpButton.isEnabled = false
            bannerLabel.isHidden = false
            if isPvPModeOn {
                if game.firstPlayerScore == game.secondPlayerScore {
                    bannerLabel.text = BannersTexts.deadHeat.getText()
                } else {
                    bannerLabel.text = game.firstPlayerScore > game.secondPlayerScore ? BannersTexts.player1WinBanner.getText() : BannersTexts.player2WinBanner.getText()
                }
                enemyEmotionLabel.text = ""
            } else {
                if game.firstPlayerScore == game.enemyScore {
                    bannerLabel.text = BannersTexts.deadHeat.getText()
                    enemyEmotionLabel.text = EnemyEmotions.neutral.rawValue
                } else {
                bannerLabel.text = game.firstPlayerScore > game.enemyScore ? BannersTexts.userWinBanner.getText() : BannersTexts.userLoseBanner.getText()
                    enemyEmotionLabel.text = game.firstPlayerScore > game.enemyScore ? EnemyEmotions.sad.rawValue : EnemyEmotions.happy.rawValue
                }
            }
        } else {
            bannerLabel.isHidden = true
            cheatButton.isEnabled = !isPvPModeOn
        }
    }
    
    private func setupGameZone() {
        gameZoneView.place(cards: game.cards.filter({$0.isOnTable}))
        for view in gameZoneView.subviews {
            let tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(choseCard(sender:)))
            view.addGestureRecognizer(tapGestureRecogniser)
        }
    }
    
    @objc private  func orientationChanged() {
        updateViewFromModel()
    }
    
    
    
    // create new game table after view loading
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name:  Notification.Name("UIDeviceOrientationDidChangeNotification"), object: nil)
        roundRectangleElements()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("UIDeviceOrientationDidChangeNotification"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startNewGame()
    }
    
    private func roundRectangleElements() {
        let cornerRadiusForRectangleElementsToElementsWidthRatio: CGFloat = 0.05
        cheatButton.layer.cornerRadius = cornerRadiusForRectangleElementsToElementsWidthRatio * cheatButton.bounds.width
        add3CardsButton.layer.cornerRadius = cornerRadiusForRectangleElementsToElementsWidthRatio * add3CardsButton.bounds.width
        newGameButton.layer.cornerRadius = cornerRadiusForRectangleElementsToElementsWidthRatio * newGameButton.bounds.width
        scoreLabel.layer.cornerRadius = cornerRadiusForRectangleElementsToElementsWidthRatio * scoreLabel.bounds.width
        enemyScoreLabel.layer.cornerRadius = cornerRadiusForRectangleElementsToElementsWidthRatio * enemyScoreLabel.bounds.width
        enemyEmotionLabel.layer.cornerRadius = cornerRadiusForRectangleElementsToElementsWidthRatio * enemyEmotionLabel.bounds.width
        player1Button.layer.cornerRadius = cornerRadiusForRectangleElementsToElementsWidthRatio * enemyEmotionLabel.bounds.width
        player2Button.layer.cornerRadius = cornerRadiusForRectangleElementsToElementsWidthRatio * enemyEmotionLabel.bounds.width
        pvpButton.layer.cornerRadius = cornerRadiusForRectangleElementsToElementsWidthRatio * enemyEmotionLabel.bounds.width
    }
}


extension GameViewController {
    
    // some kind of database
    
    private enum EnemyEmotions: String {
        case neutral = "😐"
        case thinking = "🤔"
        case smart = "🤓"
        case tired = "😓"
        case happy = "🤩"
        case sad = "😢"
        
    }
    
    private enum TimeIntervals {
        case doNothingPeriodDuration
        case thinkingPeriodDuration
        case displayingResultsPeriodDuration
        case displayingCheatDuration
        case playerMoveDuration
        
        func getInterval() -> Double {
            switch self {
            case .doNothingPeriodDuration:
                return 10.0
            case .thinkingPeriodDuration:
                return 5.0
            case .displayingResultsPeriodDuration:
                return 2.0
            case .displayingCheatDuration:
                return 2.0
            case .playerMoveDuration:
                return 4.0
            }
        }
    }
    
    private enum BannersTexts {
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
}

