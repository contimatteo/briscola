//
//  VirtualDecisionMaker.swift
//  Briscola-Multiplayer
//
//  Created by Matteo Conti on 29/12/2019.
//  Copyright © 2019 Matteo Conti. All rights reserved.
//

import Foundation


class AIPlayerEmulator {
    //
    // MARK:
    
    private var trumpCard: CardModel;
    
    private var cardsHandClassification: Array<CardClassification> = [];
    private var cardsOnTableClassification: Array<CardClassification> = [];
    private var playerCardsHand: Array<CardModel> = [];
    private var cardsOnTable: Array<CardModel> = [];
    
    //
    // MARK:
    
    init(trumpCard: CardModel) {
        self.trumpCard = trumpCard;
    }
    
    //
    // MARK:
    
    public func playCard(playerIndex: Int, playersHands: Array<Array<CardModel>>, cardsOnTable: Array<CardModel>) -> Int {
        var cardToPlay: Int?;
        var classifToFind: CardClassification;
        let currentPlayerHand = playersHands[playerIndex];
        
        /// preparing vars used by all class' methods.
        _prepareGlobalAIVars(currentPlayerHand: currentPlayerHand, cardsOnTable: cardsOnTable);
        
        /// 1. - è già stata giocata almeno una carta ?
        if (cardsOnTable.count > 0) {
            /// TODO: missing multiplayer logic.
            let cardOnTable: CardModel = cardsOnTable.first!;
            /// let isPlayedByMyPartner: Bool = _isCardPlayedByMyPartner();
            
            /// 1.1. - c'è una briscola in tavola ?
            classifToFind = (isTrump: true, isSmooth: false, isCargo: false);
            let trumpOnTable: Bool = _existCardWithClassification(cardsOnTableClassification, cardToFind: classifToFind);
            if (trumpOnTable) {
                print("c'è una briscola in tavola");
                /// 1.1.1 - gioca il liscio più alto che ho.
                cardToPlay = _getSmooth(.higher);
                if (cardToPlay != nil) { return cardToPlay!; }
                /// 1.1.2 - gioco la briscola più bassa che ho
                cardToPlay = _getTrump(.lower);
                if (cardToPlay != nil) { return cardToPlay!; }
                /// 1.1.3 - gioco il carico più basso che ho.
                return _getCargo(.lower)!;
            }
            
            /// 1.2. - c'è una carico in tavola ?
            classifToFind = (isTrump: false, isSmooth: false, isCargo: true);
            let cargoOnTable: Bool = _existCardWithClassification(cardsOnTableClassification, cardToFind: classifToFind);
            if (cargoOnTable) {
                print("c'è un carico in tavola");
                /// 1.2.1 - gioco il carico più alto che ho di questo tipo ma solo se supera la carta in tavola.
                cardToPlay = _getCargo(.lower, withType: cardOnTable.type);
                if (cardToPlay != nil && playerCardsHand[cardToPlay!].points > cardOnTable.points) {
                    print("\(playerCardsHand[cardToPlay!].points) > \(cardOnTable.points)");
                    return cardToPlay!;
                }
                /// 1.2.2 - gioco la briscola più bassa che ho
                cardToPlay = _getTrump(.lower);
                if (cardToPlay != nil) { return cardToPlay!; }
                /// 1.2.3 - gioco il liscio più alto che ho
                cardToPlay = _getSmooth(.higher);
                if (cardToPlay != nil) { return cardToPlay!; }
                /// 1.2.4 - gioco il carico più basso che ho.
                return _getCargo(.lower)!;
            }
            
            /// 1.3. - c'è un liscio in tavola !
            print("c'è un liscio in tavola");
            /// 1.3.1 - gioco il carico più alto che ho di questo tipo.
            cardToPlay = _getCargo(.higher, withType: cardOnTable.type);
            if (cardToPlay != nil) { return cardToPlay!; }
            /// 1.3.2 - gioco il liscio più basso che ho
            cardToPlay = _getSmooth(.lower);
            if (cardToPlay != nil) { return cardToPlay!; }
            /// 1.3.3 - gioco la briscola più bassa che ho.
            return _getTrump(.lower)!;
        }
        
        /// 2    - nessuna carta presente in tavola.
        print("nessuna carta in tavola");
        /// 2.1 - gioco il liscio più basso che ho
        cardToPlay = _getSmooth(.lower);
        if (cardToPlay != nil) { return cardToPlay!; }
        /// 2.2 - gioca il carico più basso che ho.
        cardToPlay = _getCargo(.lower);
        if (cardToPlay != nil) { return cardToPlay!; }
        /// 2.3 - gioco la briscola più bassa che ho
        print("\n////// FINAL MATCH !! ///////")
        return _getTrump(.lower)!;
    }
    
    private func _prepareGlobalAIVars(currentPlayerHand: Array<CardModel>, cardsOnTable: Array<CardModel>) {
        /// init vars.
        cardsHandClassification.removeAll();
        cardsOnTableClassification.removeAll();
        self.playerCardsHand.removeAll();
        self.cardsOnTable.removeAll();
        
        /// prepare player vars.
        self.playerCardsHand = currentPlayerHand;
        self.cardsOnTable = cardsOnTable;
        
        /// classificazione di ogni carta.
        for (cIndex, card) in cardsOnTable.enumerated() { cardsOnTableClassification.insert(_classifySingleCard(card), at: cIndex); }
        for (cIndex, card) in currentPlayerHand.enumerated() { cardsHandClassification.insert(_classifySingleCard(card), at: cIndex); }
    }
    
    private func _classifySingleCard(_ card: CardModel) -> CardClassification {
        var classification: CardClassification = (isTrump: false, isCargo: false, isSmooth: false);
        
        if (card.type == trumpCard.type) { classification.isTrump = true; }
        if (card.type != trumpCard.type && card.points > 0) { classification.isCargo = true; }
        if (card.type != trumpCard.type && card.points < 1) { classification.isSmooth = true;}
        
        return classification;
    }
    
    private func _existCardWithClassification(_ classifications: Array<CardClassification>, cardToFind cToFind: CardClassification) -> Bool {
        let cIndex = classifications.firstIndex(where: {
            $0.isTrump == cToFind.isTrump && $0.isCargo == cToFind.isCargo && $0.isSmooth == cToFind.isSmooth
        });
        
        return cIndex != nil;
    }
    
    private func _getCargo(_ searchType: CardSearchingOrder, withType: CardType? = nil) -> Int? {
        let classifToFind = (isTrump: false, isSmooth: false, isCargo: true);
        let isCargoExist = _existCardWithClassification(cardsHandClassification, cardToFind: classifToFind);
        
        if (!isCargoExist) { return nil; }
        
        /// surely a 'cargo' cart exist!
        var cardFounded: Int = 0;
        for (cIndex, card) in playerCardsHand.enumerated() {
            if (_classifySingleCard(card).isCargo && (withType == nil || card.type == withType!)) {
                /// higher cargo
                if (searchType == .higher && card.points > playerCardsHand[cardFounded].points) {
                    cardFounded = cIndex;
                }
                /// lower cargo
                if (searchType == .lower && card.points < playerCardsHand[cardFounded].points) {
                    cardFounded = cIndex;
                }
            }
        }
        
        return cardFounded;
    }
    
    private func _getSmooth(_ searchType: CardSearchingOrder, withType: CardType? = nil) -> Int? {
        let classifToFind = (isTrump: false, isSmooth: true, isCargo: false);
        let isCargoExist = _existCardWithClassification(cardsHandClassification, cardToFind: classifToFind);
        
        if (!isCargoExist) { return nil; }
        
        /// surely a 'cargo' cart exist!
        var cardFounded: Int = 0;
        for (cIndex, card) in playerCardsHand.enumerated() {
            if (_classifySingleCard(card).isSmooth && (withType == nil || card.type == withType!)) {
                /// higher smooth
                if (searchType == .higher && card.number > playerCardsHand[cardFounded].number) {
                    cardFounded = cIndex;
                }
                /// lower smooth
                if (searchType == .lower && card.number < playerCardsHand[cardFounded].number) {
                    cardFounded = cIndex;
                }
            }
        }
        
        return cardFounded;
    }
    
    private func _getTrump(_ searchType: CardSearchingOrder) -> Int? {
        let classifToFind = (isTrump: true, isSmooth: false, isCargo: false);
        let isCargoExist = _existCardWithClassification(cardsHandClassification, cardToFind: classifToFind);
        
        if (!isCargoExist) { return nil; }
        
        /// surely a 'cargo' cart exist!
        var cardFounded: Int = 0;
        for (cIndex, card) in playerCardsHand.enumerated() {
            if (_classifySingleCard(card).isTrump) {
                /// higher trump
                if (searchType == .higher) {
                    if (card.points > playerCardsHand[cardFounded].points) {
                        cardFounded = cIndex;
                    } else if (card.points == playerCardsHand[cardFounded].points && card.number > playerCardsHand[cardFounded].number) {
                        cardFounded = cIndex;
                    }
                }
                /// lower trump
                if (searchType == .lower) {
                    if (card.points < playerCardsHand[cardFounded].points) {
                        cardFounded = cIndex;
                    } else if (card.points == playerCardsHand[cardFounded].points && card.number < playerCardsHand[cardFounded].number) {
                        cardFounded = cIndex;
                    }
                }
            }
        }
        
        return cardFounded;
    }
    
    private func _isCardPlayedByMyPartner() -> Bool {
        /// TODO: missing logic for handling multiple players.
        return false;
    }
}


private typealias CardClassification = (isTrump: Bool, isCargo: Bool, isSmooth: Bool);
private enum CardSearchingOrder { case higher; case lower; }
