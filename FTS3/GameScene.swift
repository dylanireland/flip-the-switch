//
//  GameScene.swift
//  FTS3
//
//  Created by Dylan Ireland on 5/13/20.
//  Copyright © 2020 Dylan Ireland. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    let defaults = Defaults()
    let colors = Colors()
    let logic = Logic()
    var started = false
    var isOverlaid = false
    let overlay = SKSpriteNode()
    let quoteLabel0: SKLabelNode = SKLabelNode()
    let quoteLabel1: SKLabelNode = SKLabelNode()
    let quoteLabel2: SKLabelNode = SKLabelNode()
    let artistLabel: SKLabelNode = SKLabelNode()
    
    let swtch: SKSpriteNode = SKSpriteNode(texture: SKTexture(imageNamed: "switchOff"), size: CGSize(width: 200, height: 300))
    let levelabel = SKLabelNode(fontNamed: "ADAM.CGPRO")
    let area = SKSpriteNode(texture: SKTexture(imageNamed: "area"))
    let bulb = SKSpriteNode(texture: SKTexture(imageNamed: "bulbOff"))
    let bar = SKSpriteNode(imageNamed: "bar10")
    let safezone = SKSpriteNode(color: SKColor(red: 162/255, green: 155/255, blue: 254/255, alpha: 1.0), size: CGSize(width: 50, height: 80))
    
    override func didMove(to view: SKView) {
        setupInitialView()
    }
    
    func setupInitialView() {
        if let cam = self.childNode(withName: "camera") as? SKCameraNode {
            self.camera = cam
        }
        
        scene?.backgroundColor = colors.getBackgroundColor()
        
        swtch.position = CGPoint(x: frame.midX - 10, y: (frame.midY + (frame.minY / 2)))
        
        levelabel.position = CGPoint(x: frame.midX, y: swtch.frame.maxY + 15)
        levelabel.text = String(defaults.getLevel())
        levelabel.fontSize = 60
        levelabel.fontColor = UIColor.white
        
        area.size = CGSize(width: frame.size.width - (frame.size.width / 4), height: 100)
        area.position = CGPoint(x: frame.midX, y: frame.midY - (frame.minY / 3))
        
        bulb.size = CGSize(width: 175, height: 175)
        bulb.position = CGPoint(x: frame.midX, y: frame.midY - (frame.minY / 1.5))
        
        addChild(swtch)
        addChild(levelabel)
        addChild(area)
        addChild(bulb)
        safezone.zPosition = 2
        safezone.name = "safezone"
        bar.name = "bar"
        bar.size = CGSize(width: 10, height: 80)
        area.addChild(bar)
        bar.zPosition = 3
        area.childNode(withName: "bar")?.position = CGPoint(x: frame.midX, y: frame.midY)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isOverlaid {
            started = false
            removeOverlay()
            
            return
        }
        
        
        if !started {
            started = true
            startGame()
        } else {
            started = false
            stopGame()
        }
    }
    
    func startGame() {
        let rand = logic.getBarStartingDirection()
        let duration = logic.getDuration()
        let beginLeft = SKAction.moveTo(x: area.frame.minX + 18, duration: duration / 2)
        let beginRight = SKAction.moveTo(x: area.frame.maxX - 18, duration: duration / 2)
        
        let contRight = SKAction.moveTo(x: area.frame.maxX - 18, duration: duration)
        let contLeft = SKAction.moveTo(x: area.frame.minX + 18, duration: duration)
        
        
        
        area.addChild(safezone)
        area.childNode(withName: "safezone")?.position = CGPoint(x: logic.getSafezonePosition(areaFrame: area.frame, safezoneFrame: safezone.frame), y: frame.midY)
        
        if rand == 0 {
            bar.run(beginLeft, completion: {
                let sequence = SKAction.sequence([contRight, contLeft])
                self.bar.run(SKAction.repeatForever(sequence))
            })
        } else {
            bar.run(beginRight, completion: {
                let sequence = SKAction.sequence([contLeft, contRight])
                self.bar.run(SKAction.repeatForever(sequence))
            })
        }
    }
    
    func stopGame() {
        swtch.texture = SKTexture(imageNamed: "switchOn")
        if bar.frame.minX >= safezone.frame.minX && bar.frame.maxX <= safezone.frame.maxX {
            succeed()
            print("Nice!")
        } else {
            fail()
        }
    }
    
    func succeed() {
        isUserInteractionEnabled = false
        defaults.set(level: defaults.getLevel() + 1)
        bar.removeAllActions()
        ///Success sound
        bulb.texture = SKTexture(imageNamed: "light-bulb")
        if defaults.getLevel() % 10 == 0 {
            let color = colors.getBackgroundColor()
            //self.top.color = color
            //self.left.color = color
            //self.bottom.color = color
            //self.right.color = color
            ///Need to update these bar thingies
        }
        self.run(SKAction.wait(forDuration: 0.75), completion: {
            if self.defaults.getLevel() % 10 == 0 {
                let newColor: SKColor = self.colors.getBackgroundColor()
                let colorize = SKAction.colorize(with: newColor, colorBlendFactor: 0.5, duration: 1.0)
                self.run(colorize)
            }
            self.beginMovingSprites()
        })
    }
    
    func fail() {
        isUserInteractionEnabled = false
        isOverlaid = true
        //run(playFail)
        bar.removeAllActions()
        
        let scaleTo: SKAction = SKAction.scale(to: 1.1, duration: 0.25)
        
        camera?.run(scaleTo, completion: {
            self.isUserInteractionEnabled = true
        })
        
        let blink = SKAction.customAction(withDuration: 0.9, actionBlock: {
            node, float in
            node.alpha = 0.0
        })
        
        let unblink = SKAction.customAction(withDuration: 0.5, actionBlock: {
            node, float in
            node.alpha = 1.0
        })
        
        let seq = SKAction.sequence([unblink, blink])
        
        bar.run(SKAction.repeatForever(seq))
        
        bulb.texture = SKTexture(imageNamed: "light-bulb")
        
        self.run(SKAction.wait(forDuration: 0.1), completion: {
            self.bulb.texture = SKTexture(imageNamed: "bulb-exploded")
            ///self.run(self.playlightbulbexploding)
            self.emitShards()
        })
        
        shakeArea()
        placeOverlay()
        placeQuotes()
        
    }
    
    func placeOverlay() {
        overlay.size = CGSize(width: scene!.frame.size.width * 1.5, height: scene!.frame.size.height * 1.5)
        overlay.position = CGPoint(x: scene!.frame.midX, y: scene!.frame.midY)
        overlay.color = SKColor.black
        overlay.alpha = 0.0
        overlay.zPosition = 5
        self.addChild(overlay)
        overlay.run(SKAction.fadeAlpha(to: 0.8, duration: 0.5))
    }
    
    func removeOverlay() {
        isUserInteractionEnabled = false
        isOverlaid = false
        resetView()
        
        let scaleTo: SKAction = SKAction.scale(to: 1.0, duration: 0.25)
        camera?.run(scaleTo, completion: {
            self.isUserInteractionEnabled = true
        })
        let alpha = SKAction.fadeAlpha(to: 0.0, duration: 0.5)
        overlay.run(alpha, completion: {
            self.overlay.removeFromParent()
            self.isUserInteractionEnabled = true
        })
        
        quoteLabel0.run(alpha, completion: {
            self.quoteLabel0.removeFromParent()
        })
        
        if quoteLabel1.parent != nil {
            quoteLabel1.run(alpha, completion: {
                self.quoteLabel1.removeFromParent()
            })
        }
        
        if quoteLabel2.parent != nil {
            quoteLabel2.run(alpha, completion: {
                self.quoteLabel2.removeFromParent()
            })
        }
        
        artistLabel.run(alpha, completion: {
            self.artistLabel.removeFromParent()
        })
    }
    
    func placeQuotes() {
        let quoteTuple = logic.getQuote()
        let line1 = quoteTuple.0
        let author = quoteTuple.3
        quoteLabel0.text = line1
        artistLabel.text = author
        
        quoteLabel0.fontColor = .white
        quoteLabel1.fontColor = .white
        quoteLabel2.fontColor = .white
        artistLabel.fontColor = .gray

        quoteLabel0.zPosition = 10
        quoteLabel1.zPosition = 10
        quoteLabel2.zPosition = 10
        artistLabel.zPosition = 10
        
        quoteLabel0.fontSize = 26
        quoteLabel1.fontSize = 26
        quoteLabel2.fontSize = 26
        artistLabel.fontSize = 24
        
        quoteLabel0.fontName = "ADAM.CGPRO"
        quoteLabel1.fontName = "ADAM.CGPRO"
        quoteLabel2.fontName = "ADAM.CGPRO"
        artistLabel.fontName = "ADAM.CGPRO"
        
        let alpha = SKAction.fadeAlpha(to: 0.8, duration: 0.5)
        
        self.addChild(quoteLabel0)
        self.addChild(artistLabel)
        
        if let line2 = quoteTuple.1, let line3 = quoteTuple.2 {
            quoteLabel0.position = CGPoint(x: scene!.frame.midX, y: scene!.frame.midY + 30)
            quoteLabel1.position = CGPoint(x: scene!.frame.midX, y: scene!.frame.midY)
            quoteLabel2.position = CGPoint(x: scene!.frame.midX, y: scene!.frame.midY - 30)
            artistLabel.position = CGPoint(x: scene!.frame.midX, y: scene!.frame.midY - 60)
            quoteLabel1.text = line2
            quoteLabel2.text = line3
            
            self.addChild(quoteLabel1)
            self.addChild(quoteLabel2)
            quoteLabel1.run(alpha)
            quoteLabel2.run(alpha)
        } else if let line2 = quoteTuple.1 {
            quoteLabel0.position = CGPoint(x: scene!.frame.midX, y: scene!.frame.midY + 10)
            quoteLabel1.position = CGPoint(x: scene!.frame.midX, y: scene!.frame.midY - 20)
            artistLabel.position = CGPoint(x: scene!.frame.midX, y: scene!.frame.midY - 50)
            quoteLabel1.text = line2
            self.addChild(quoteLabel1)
            quoteLabel1.run(alpha)
        } else {
            quoteLabel0.position = CGPoint(x: scene!.frame.midX, y: scene!.frame.midY)
            artistLabel.position = CGPoint(x: scene!.frame.midX, y: scene!.frame.midY - 27.5)
        }
        
        quoteLabel0.run(alpha)
        artistLabel.run(alpha)
    }
    
    func resetView() {
        bar.removeAllActions()
        area.childNode(withName: "bar")?.position = CGPoint(x: frame.midX, y: frame.midY)
        safezone.removeFromParent()
        bar.alpha = 1.0
        bulb.texture = SKTexture(imageNamed: "bulbOff")
        swtch.texture = SKTexture(imageNamed: "switchOff")
        
        /*self.top.removeAllActions()
        self.left.removeAllActions()
        self.bottom.removeAllActions()
        self.right.removeAllActions()
        self.top.size = CGSize(width: 0, height: self.top.frame.size.height)
        self.left.size = CGSize(width: self.left.frame.size.width, height: 0)
        self.bottom.size = CGSize(width: 0, height: self.bottom.frame.size.height)
        self.right.size = CGSize(width: self.right.frame.size.width, height: 0)*/
    }
    
    func beginMovingSprites() {
        let areaPositionY = area.frame.midY
        let areaWidth = area.frame.size.width
        let bulbY = bulb.frame.midY
        let pos = scene!.view!.frame.minX - areaWidth
        let switchY = swtch.position.y
        let duration: TimeInterval = 0.8
        let move = SKAction.moveTo(x: pos, duration: duration)
        let moveLabel = SKAction.moveTo(x: pos - (swtch.size.width / 28), duration: duration)
        let repositionSwitch = SKAction.moveTo(x: self.scene!.frame.midX - 10, duration: duration / 2)
        let reposition = SKAction.moveTo(x: self.scene!.frame.midX, duration: duration / 2)
        let repositionLabel = SKAction.moveTo(x: self.scene!.frame.midX, duration: duration / 2)
        bar.removeFromParent()
        safezone.removeFromParent()
        area.run(move, completion: {
            self.area.removeFromParent()
            self.bar.removeFromParent()
            self.area.position = CGPoint(x: self.scene!.frame.maxX + (areaWidth / 2), y: areaPositionY)
            self.addChild(self.area)
            self.area.run(reposition)
            self.levelabel.text = String(self.defaults.getLevel())
        })
        swtch.run(move, completion: {
            self.swtch.removeFromParent()
            self.swtch.position = CGPoint(x: self.scene!.frame.maxX + (areaWidth / 2), y: switchY)
            self.swtch.texture = SKTexture(imageNamed: "switchOff")
            self.addChild(self.swtch)
            self.swtch.run(repositionSwitch, completion: {
                self.area.addChild(self.bar)
                self.area.childNode(withName: "bar")?.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
                self.isUserInteractionEnabled = true
            })
        })
        levelabel.run(moveLabel, completion: {
            self.levelabel.removeFromParent()
            self.levelabel.position = CGPoint(x: self.scene!.frame.maxX + (areaWidth / 2), y: self.swtch.frame.maxY + 15)
            self.addChild(self.levelabel)
            self.levelabel.run(repositionLabel)
        })
        
        bulb.run(move, completion: {
            self.bulb.removeFromParent()
            self.bulb.texture = SKTexture(imageNamed: "bulbOff")
            self.bulb.position = CGPoint(x: self.scene!.frame.maxX + (areaWidth / 2), y: bulbY)
            self.addChild(self.bulb)
            self.bulb.run(reposition)
        })
    }
    
    
    func shakeArea() {
        let back = SKAction.moveTo(x: scene!.frame.midX - 15, duration: 0.05)
        let forward = SKAction.moveTo(x: scene!.frame.midX + 15, duration: 0.05)
        let seqe = SKAction.sequence([back, forward])
        
        area.run(SKAction.repeat(seqe, count: 3), completion: {
            let act = SKAction.moveTo(x: self.scene!.frame.midX, duration: 0.05)
            self.area.run(act)
        })
    }
    
    func emitShards() {
        let emitter: SKEmitterNode = SKEmitterNode()
        let lifetime: CGFloat = 7.0
        
        emitter.particleTexture = SKTexture(imageNamed: "shard")
        emitter.particleSize = CGSize(width: 27, height: 27)
        emitter.particleBirthRate = 600
        emitter.numParticlesToEmit = 40
        emitter.particleLifetime = lifetime
        emitter.yAcceleration = 0
        emitter.xAcceleration = 0
        emitter.particleSpeed = 800
        emitter.particleSpeedRange = 25
        emitter.emissionAngle = 1.5707963268
        emitter.emissionAngleRange = 4.7123889804
        emitter.particleRotation = 0.25
        emitter.particleRotationRange = 15
        emitter.particleRotationSpeed = 5
        emitter.position = CGPoint(x: bulb.frame.midX, y: bulb.frame.midY + (bulb.size.height / 6))
        emitter.zPosition = 2
        
        self.addChild(emitter)
        self.run(SKAction.wait(forDuration: TimeInterval(lifetime)), completion: {
            emitter.removeFromParent()
        })
    }
    
}
