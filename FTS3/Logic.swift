//
//  Logic.swift
//  FTS3
//
//  Created by Dylan Ireland on 5/13/20.
//  Copyright © 2020 Dylan Ireland. All rights reserved.
//

import Foundation
import SpriteKit

struct Defaults {
    let defaults = UserDefaults.standard
    
    func set(level: Int) {
        defaults.set(level, forKey: "level")
    }
    
    func getLevel() -> Int {
        return defaults.integer(forKey: "level")
    }
    
    func isNotFirstRun() -> Bool {
        let bool = defaults.bool(forKey: "firstRun")
        defaults.set(true, forKey: "firstRun")
        return bool
    }
}

struct Colors {
    func getBackgroundColor() -> SKColor {
        switch Defaults().getLevel() {
        case 1...9:
            print("running")
            return SKColor(red: 85/255, green: 239/255, blue: 196/255, alpha: 1.0)
        case 10...19:
            return SKColor(red: 162/255, green: 155/255, blue: 254/255, alpha: 1.0)
        case 20...29:
            return SKColor(red: 253/255, green: 121/255, blue: 168/255, alpha: 1.0)
        case 30...39:
            return SKColor(red: 9/255, green: 132/255, blue: 227/255, alpha: 1.0)
        default:
            return SKColor(red: CGFloat(arc4random_uniform(255))/255, green: CGFloat(arc4random_uniform(255))/255, blue: CGFloat(arc4random_uniform(255))/255, alpha: 1.0)
        }
    }
}

struct Logic {
    let defaults = Defaults()
    func getDuration() -> Double {
        let level = defaults.getLevel()
        let exponentialized: Double = Double(pow(29/30, Double(level)))
        let duration = 0.9+(3*exponentialized)
        
        return duration
    }
    
    func getBarStartingDirection() -> Int {
        let rand = arc4random_uniform(2)
        return Int(rand)
    }
    
    func getSafezonePosition(areaFrame: CGRect, safezoneFrame: CGRect) -> CGFloat {
        let available = areaFrame.maxX - areaFrame.minX
        let randomLocation: CGFloat = CGFloat(arc4random_uniform(UInt32(available)))// add minX
        var x: CGFloat = CGFloat()
        if randomLocation < CGFloat(safezoneFrame.width / 2) + 18 {
            x = areaFrame.minX + CGFloat(safezoneFrame.width / 2) + 18
        } else if randomLocation > available - (safezoneFrame.width / 2) - 18 {
            x = areaFrame.maxX - CGFloat(safezoneFrame.width / 2) - 18
        } else {
            x = randomLocation + areaFrame.minX
        }
        return x
    }
    
    func getQuote() -> (String, String?, String?, String) {
        
        let path = Bundle.main.path(forResource: "quotes", ofType: "txt")
        do {
            let string = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
            let quotes = string.split{$0 == "\n"}.map(String.init)
            let line = quotes[Int(arc4random_uniform(UInt32(quotes.count)))]
            let quoteAndAuthor = line.split{$0 == "#"}.map(String.init)
            let quote = quoteAndAuthor[0]
            let author = quoteAndAuthor[1]
            var line1 = String()
            var line2: String? = nil
            var line3: String? = nil
            if quote.contains("%") {
                let lines = quote.split{$0 == "%"}.map(String.init)
                line1 = lines[0]
                line2 = lines[1]
                if lines.count == 3 {
                    line3 = lines.last!
                }
            } else {
                line1 = quote
            }
            return (line1, line2, line3, author)
        } catch {return ("No quote found", nil, nil, "No one")}
        return ("No quote found", nil, nil, "No one")
    }
}
