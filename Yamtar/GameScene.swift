//
//  GameScene.swift
//  Yamtar
//
//   Created by Turgutalp Tug,Enes Aktas,Ahmet Rahmanoglu,Baran Aslankan on 12/12/2019.
//  
//

import SpriteKit
import GameplayKit

var player: SKSpriteNode?
var projectile: SKSpriteNode?
//var enemy: SKSpriteNode?
var enemyXPositionRandomSource: GKRandomDistribution?
var star: SKSpriteNode?

var scoreLabel: SKLabelNode?
var mainLabel: SKLabelNode?

var starSize: CGSize?
var starXPositionRandomSource: GKRandomDistribution?
var starSpeedRandomSource: GKRandomDistribution?
var starSizeRandomSource: GKRandomDistribution?

var isAlive = true
var score = 0
var touchLocation: CGPoint?

struct physicsCategory {
    static let player: UInt32 = 1
    static let projectile: UInt32 = 2
    static let enemy: UInt32 = 4
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var fireProjectileRate: Double = 0.0
    var projectileSpeed: Double = 0.0
    
    var enemySpeed: Double = 0.0
    var enemySpawnRate: Double = 0.0
    var starSpawnRate: Double = 0.0
    var minStarSpeed: Int = 2
    var maxStarSpeed: Int = 10
    var starDensity: Int = 12
    var minStarSize: Int = 3
    var maxStarSize: Int = 7
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    
    override func sceneDidLoad() {
        self.lastUpdateTime = 0
        physicsWorld.contactDelegate = self
        
        isAlive = true
        score = 0
        
        let path = Bundle.main.path(forResource: "GameProperties", ofType: "plist")
        let dict:NSDictionary = NSDictionary(contentsOfFile: path!)!
        
        self.fireProjectileRate = (dict.object(forKey: "fireProjectileRate") as? Double)!
        self.projectileSpeed = (dict.object(forKey: "projectileSpeed") as? Double)!
        self.enemySpeed = (dict.object(forKey: "enemySpeed") as? Double)!
        self.enemySpawnRate = (dict.object(forKey: "enemySpawnRate") as? Double)!
        self.starSpawnRate = (dict.object(forKey: "starSpawnRate") as? Double)!
        self.minStarSpeed = (dict.object(forKey: "minStarSpeed") as? Int)!
        self.maxStarSpeed = (dict.object(forKey: "maxStarSpeed") as? Int)!
        self.starDensity = (dict.object(forKey: "starDensity") as? Int)!
        self.minStarSize = (dict.object(forKey: "minStarSize") as? Int)!
        self.maxStarSize = (dict.object(forKey: "maxStarSize") as? Int)!
        
        player = self.childNode(withName: "player") as? SKSpriteNode
        player?.physicsBody?.categoryBitMask = physicsCategory.player
        player?.physicsBody?.contactTestBitMask = physicsCategory.enemy
        
        mainLabel = self.childNode(withName: "mainLabel")  as? SKLabelNode
        scoreLabel = self.childNode(withName: "scoreLabel") as? SKLabelNode
        scoreLabel?.text = "Score: \(score)"
        
        starXPositionRandomSource = GKRandomDistribution(lowestValue: Int(self.frame.minX), highestValue: Int(self.frame.maxX))
        starSpeedRandomSource = GKRandomDistribution(lowestValue: Int(self.minStarSpeed), highestValue: Int(self.maxStarSpeed))
        starSizeRandomSource = GKRandomDistribution(lowestValue: 3, highestValue: 7)
        enemyXPositionRandomSource = GKRandomDistribution(
            lowestValue: Int(self.frame.minX),
            highestValue: Int(self.frame.maxX)
        )

        self.fireProjectile()
        self.timerSpawnEnemies()
        self.timerSpawnStars()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchLocation = t.location(in: self)
            self.movePlayerOnTouch()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            touchLocation = touch.location(in: self)
            self.movePlayerOnTouch()
        }
    }
    
    func movePlayerOnTouch() {
        if isAlive == true {
            player?.position.x = (touchLocation?.x)!
        }
    }
    
    func spawnProjectile()
    {
        projectile = (self.childNode(withName: "projectile")?.copy())! as? SKSpriteNode
        projectile?.position = CGPoint(x: (player?.position.x)!, y: (player?.position.y)!)
        projectile?.physicsBody?.categoryBitMask = physicsCategory.projectile
        projectile?.physicsBody?.contactTestBitMask = physicsCategory.enemy
        self.moveProjectileToTop()
        self.addChild(projectile!)
    }
    
    func moveProjectileToTop() {
        let moveForward = SKAction.moveTo(y: 1000, duration: projectileSpeed)
        let destroy = SKAction.removeFromParent()
        projectile?.run(SKAction.sequence([moveForward, destroy]))
    }
    
    func spawnEnemy()
    {
        let randomX = enemyXPositionRandomSource?.nextInt()
        let e = (self.childNode(withName: "enemy")?.copy())! as? SKSpriteNode
        e?.position = CGPoint(x: CGFloat(randomX!), y: self.frame.maxY)
        e?.physicsBody?.categoryBitMask = physicsCategory.enemy
        e?.physicsBody?.contactTestBitMask = physicsCategory.projectile
        self.moveEnemyToFloor(enemyToMove: e!)
        self.addChild(e!)
    }
    
    func moveEnemyToFloor(enemyToMove: SKSpriteNode) {
        let moveTo = SKAction.moveTo(y: self.frame.minY - 10, duration: enemySpeed)
        let decrementScore = SKAction.run {
            if isAlive {
                score -= 1
                self.updateScore()
            }
        }
        let destroy = SKAction.removeFromParent()
        enemyToMove.run(SKAction.sequence([moveTo, decrementScore, destroy]))
    }
    
    func spawnStar() {
        let randomSize = starSizeRandomSource?.nextInt()
        starSize = CGSize(width: randomSize!, height: randomSize!)
        let randomX = starXPositionRandomSource!.nextInt()
        star = (self.childNode(withName: "star")?.copy())! as? SKSpriteNode
        star?.size = starSize!
        star?.position = CGPoint(x: CGFloat(randomX), y: self.frame.maxY)
        star?.name = "starName"
        self.addChild(star!)
        self.moveStarToFloor(star: star!)
    }
    
    func moveStarToFloor (star: SKSpriteNode) {
        let starSpeed = Double((starSpeedRandomSource?.nextInt())!)
        let moveTo = SKAction.moveTo(y: self.frame.minY - 150, duration: starSpeed)
        let destroy = SKAction.removeFromParent()
        star.run(SKAction.sequence([moveTo, destroy]))
    }
    
    func fireProjectile() {
        let timer = SKAction.wait(forDuration: fireProjectileRate)
        let spawn = SKAction.run({
            if isAlive == true {
                self.spawnProjectile()
            }
        })
        let sequence = SKAction.sequence([timer, spawn])
        self.run(SKAction.repeatForever(sequence))
    }
    
    func timerSpawnEnemies() {
        let wait = SKAction.wait(forDuration: enemySpawnRate)
        let spawn = SKAction.run({
            if isAlive == true {
                self.spawnEnemy()
            }
        })
        let sequence = SKAction.sequence([wait, spawn])
        self.run(SKAction.repeatForever(sequence))
    }
    
    func timerSpawnStars() {
        let wait = SKAction.wait(forDuration: self.starSpawnRate)
        let spawn = SKAction.run({
            if isAlive == true {
                for _ in [0...self.starDensity] {
                    self.spawnStar()
                }
            }
        })
        let sequence = SKAction.sequence([wait, spawn])
        self.run(SKAction.repeatForever(sequence))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        // Handle projectile contact with the enemy
        if (
            (firstBody.categoryBitMask == physicsCategory.enemy) && (secondBody.categoryBitMask == physicsCategory.projectile) ||
            (firstBody.categoryBitMask == physicsCategory.projectile) && (secondBody.categoryBitMask == physicsCategory.enemy)
            ) {
            self.spawnExplosion(collidingEnemy: firstBody.node as! SKSpriteNode)
            self.enemyProjectileCollision(contactA: firstBody.node as! SKSpriteNode, contactB: secondBody.node as! SKSpriteNode)
        }
        
        // Handle enemy contact with the player
        if (
            (firstBody.categoryBitMask == physicsCategory.enemy) && (secondBody.categoryBitMask == physicsCategory.player) ||
                (firstBody.categoryBitMask == physicsCategory.player) && (secondBody.categoryBitMask == physicsCategory.enemy)
            ) {
            self.playerEnemyCollision(contactA: firstBody.node as! SKSpriteNode, contactB: secondBody.node as! SKSpriteNode)
        }
        
    }
    
    func enemyProjectileCollision(contactA: SKSpriteNode, contactB: SKSpriteNode) {
        let destroy = SKAction.removeFromParent()
        let seq = SKAction.sequence([destroy])
        
        if contactA.name == "enemy" {
            score += 1
            contactA.run(seq)
            contactB.removeFromParent()
            self.updateScore()
        }
        
        if contactB.name == "enemy" {
            score += 1
            contactB.run(seq)
            contactA.removeFromParent()
            self.updateScore()
        }
    }
    
    func gameOverLogic() {
        isAlive = false
        mainLabel?.text = "Game Over"
        mainLabel?.isHidden = false
        self.resetTheGame()
    }
    
    func resetTheGame() {
        let wait = SKAction.wait(forDuration: 3.0)
        let titleScene = TitleScene(fileNamed: "TitleScene")
        titleScene?.scaleMode = .aspectFill
        let changeScene = SKAction.run {
            self.scene!.view?.presentScene(titleScene!, transition: SKTransition.doorway(withDuration: 0.4))
        }
        let sequence = SKAction.sequence([wait, changeScene])
        self.run(SKAction.repeat(sequence, count: 1))
    }
    
    func updateScore() {
        scoreLabel?.text = "Score: \(score)"
    }
    
    func movePlayerOffScreen() {
        player?.isHidden = true
    }
    
    func playerEnemyCollision(contactA: SKSpriteNode, contactB: SKSpriteNode) {
        if contactA.name == "enemy" && contactB.name == "player" {
            self.spawnExplosion(collidingEnemy: contactA)
            self.gameOverLogic()
        }
        
        if contactB.name == "enemy" && contactA.name == "player" {
            self.spawnExplosion(collidingEnemy: contactB)
            self.gameOverLogic()
        }
    }
    
    func spawnExplosion(collidingEnemy: SKSpriteNode) {
        let explosion = SKEmitterNode(fileNamed: "ParticleSpark.sks")!
        explosion.position = collidingEnemy.position
        explosion.zPosition = 1
        explosion.targetNode = self
        self.addChild(explosion)
        
        let wait = SKAction.wait(forDuration: 0.5)
        let removeExplosion = SKAction.run({
            explosion.removeFromParent()
        })
        self.run(SKAction.sequence([wait, removeExplosion]))
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        if isAlive == false {
            self.movePlayerOffScreen()
        }
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
}
