//
//  GameScene.swift
//  JointLab
//
//  Created by victor on 7/7/14.
//  Copyright (c) 2014 AOTK. All rights reserved.
//

import SpriteKit

let kPinnedNode = "pinned"
let kSatelliteNode = "satellite"
let kJointOutlineNode = "jointoutline"
let kPinDotNode = "pindot"
let kSatelliteDotNode = "satellitedot"
let kLineNode = "lineNode"

enum JointLabels : String
{
    case Pin = "Pin"
    case Fixed = "Fixed"
    case Spring = "Spring"
    case Sliding = "Sliding"
    case Limit = "Limit"
}


class JointOutline : SKNode
{
    class func create(scene:SKScene) -> SKNode
    {
        var parent = JointOutline()
        parent.name = kJointOutlineNode
        
        var pinDot = SKShapeNode(circleOfRadius: 6)
        pinDot.fillColor = UIColor.redColor()
        pinDot.name = kPinDotNode
        
        var satelliteDot = SKShapeNode(circleOfRadius: 6)
        satelliteDot.fillColor = UIColor.redColor()
        satelliteDot.name = kSatelliteDotNode
        
        var lineNode = SKShapeNode()
        lineNode.name = kLineNode
        lineNode.strokeColor = UIColor.redColor()
        lineNode.lineWidth = 3.0
        
        parent.addChild(pinDot)
        parent.addChild(satelliteDot)
        parent.addChild(lineNode)
        
        scene.addChild(parent)
        parent.updateOutline()
        
        return parent
    }
    
    func updateOutline()
    {
        var pin = scene.childNodeWithName(kPinnedNode)
        var satellite = scene.childNodeWithName(kSatelliteNode)
        var pinDot = childNodeWithName(kPinDotNode)
        var satelliteDot = childNodeWithName(kSatelliteDotNode)
        var line = childNodeWithName(kLineNode) as SKShapeNode
        
        pinDot.position = scene.convertPoint(CGPointZero, fromNode: pin)
        satelliteDot.position = scene.convertPoint(CGPointZero, fromNode: satellite)
        
        var bez = UIBezierPath()
        bez.moveToPoint(pinDot.position)
        bez.addLineToPoint(satelliteDot.position)
        line.path = bez.CGPath
        
    }
    
}

/*
Some notes:

Much of UIKit is rather 'stateless' - which means the order in which you set properties
on a UIView are generally not order dependent. For example, you can set the text of button before
or after setting the background color. You can do either before or after adding to it's
parent view.

SpriteKit on the other hand has some passive-agressive tendencies and somewhat subtle preferences.
Doing things 'wrong' will not strictly cause errors or even 'undefined' behavior so much as
'ill-defined' behavoir and definitely unintentional.

For example, once you start using phyiscs (applyImpulse, etc.) that's an implicit 'mode' that
SpriteKit will start to work in and moving a node through it's 'position' property will be, er,
awkward.

The code below might look a little convoluted and heavy handed but it really is all necessary if
you're going to use the same two nodes with different joint types. Here's the order of things
that must be maintained:

1) Create a node
2) Set it's initial position
3) Create/Attach the physics body
4) Create the joint and put it into the physicsWorld

Putting the node into the parent scene can happen after steps 1, 2 or 3

In the code below, because I'm creating new joints dynamically (based on user choice) and
resetting the nodes position (back to a 'home' position based on user request) I have to
rewind the process and perform steps 2 & 3 before I can do step 4.

If your code sets up the joints and leaves them there (more realistic for most games) then
you only have to pay attention to the order when you create the nodes and the joint relationships
and then forget about it.

*/
class GameScene: SKScene {
    
    var statusOutput:GameViewStatus!
    
    var midPt:CGPoint {
    return CGPoint( x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
    }
    
    var pinnedHome:CGPoint {
    var mid = midPt
        mid.y += 120
        return mid
    }
    
    var satelliteHome:CGPoint {
    var mid = midPt
        mid.y -= 120
        return mid
    }
    
    override func didMoveToView(view: SKView)
    {
        physicsWorld.gravity = CGVectorMake(0, 0)
        
        var pinned = SKSpriteNode(color: UIColor.greenColor(), size: CGSizeMake(20,20))
        pinned.position = pinnedHome
        pinned.name = kPinnedNode
        
        var satellite = SKSpriteNode(color: UIColor.yellowColor(), size: CGSizeMake(20,20))
        satellite.position = satelliteHome
        satellite.name = kSatelliteNode
        
        addChild(pinned)
        addChild(satellite)
        
        resetPhysicsBodies()
        
        JointOutline.create(self)
        
        makeJoint(JointLabels.Pin)
    }
    
    func resetPhysicsBodies()
    {
        var pinned = childNodeWithName(kPinnedNode) as SKSpriteNode
        var satellite = childNodeWithName(kSatelliteNode) as SKSpriteNode
        
        // remember if the pinned body is currently dynamic
        var dynamic = false
        if let pbody = pinned.physicsBody
        {
            dynamic = pbody.dynamic
        }
        
        pinned.physicsBody = SKPhysicsBody(rectangleOfSize: pinned.size)
        pinned.physicsBody.dynamic = dynamic
        pinned.physicsBody.affectedByGravity = false
        
        satellite.physicsBody = SKPhysicsBody(rectangleOfSize: satellite.size)
        satellite.physicsBody.dynamic = true
    }
    
    func resetNodes()
    {
        childNodeWithName(kPinnedNode).position = pinnedHome
        childNodeWithName(kSatelliteNode).position = satelliteHome
    }
    
    func makeJoint(name:JointLabels)
    {
        physicsWorld.removeAllJoints()
        
        resetNodes()
        if( name != .Pin )
        {
            resetPhysicsBodies()
        }
        
        var pinned = childNodeWithName(kPinnedNode)
        var satellite = childNodeWithName(kSatelliteNode)
        var vz = CGVectorMake(0, 0)
        var pinnedAnchor = convertPoint(CGPointZero, fromNode: pinned)
        var satelliteAnchor = convertPoint(CGPointZero, fromNode: satellite)
        var joint:SKPhysicsJoint!
        
        switch(name)
            {
        case .Pin:
            pinned.position.y -= (pinned.position.y - satellite.position.y) / 2.0
            resetPhysicsBodies()
            var pin = SKPhysicsJointPin.jointWithBodyA(pinned.physicsBody,
                bodyB: satellite.physicsBody,
                anchor: pinned.position)
            joint = pin
        case .Fixed:
            var fixed = SKPhysicsJointFixed.jointWithBodyA(pinned.physicsBody,
                bodyB: satellite.physicsBody,
                anchor: pinnedAnchor)
            joint = fixed
        case JointLabels.Sliding:
            var sliding = SKPhysicsJointSliding.jointWithBodyA(pinned.physicsBody,
                bodyB: satellite.physicsBody,
                anchor: pinnedAnchor, axis: CGVectorMake(0, 1))
            sliding.lowerDistanceLimit = 40
            sliding.upperDistanceLimit = pinned.position.y - satellite.position.y
            sliding.shouldEnableLimits = true
            joint = sliding
        case JointLabels.Spring:
            var spring = SKPhysicsJointSpring.jointWithBodyA(pinned.physicsBody,
                bodyB: satellite.physicsBody,
                anchorA: pinnedAnchor,
                anchorB: satelliteAnchor)
            spring.frequency = 0.5
            joint = spring
        case JointLabels.Limit:
            var limit = SKPhysicsJointLimit.jointWithBodyA(pinned.physicsBody,
                bodyB: satellite.physicsBody,
                anchorA: pinnedAnchor,
                anchorB: satelliteAnchor)
            joint = limit
        }
        
        physicsWorld.addJoint(joint)
    }
    
    var alternating:Bool = false {
    didSet {
        statusOutput.statusMessage("Alternating Impulse set to: \(self.alternating)")
    }
    }
    
    var impulseVelocity = CGVectorMake(0, 0)
    
    func _doImpulse(direction:CGVector)
    {
        var node = childNodeWithName(kSatelliteNode)
        var mass = node.physicsBody.mass
        node.physicsBody.applyImpulse( CGVectorMake(mass * direction.dx, mass * direction.dy) )
        statusOutput.statusMessage("Applying impulse: { \(direction.dx), \(direction.dy) } alternating: \(alternating)")
    }
    
    func applyImpulse(direction:CGVector)
    {
        impulseVelocity = direction
        if( !alternating )
        {
            _doImpulse(direction)
        }
    }
    
    var lastTimeMark:CFTimeInterval?
    var alternatingThreshold = 1.5 // seconds
    
    override func update(currentTime: CFTimeInterval)
    {
        var jointOutline = childNodeWithName(kJointOutlineNode) as JointOutline
        jointOutline.updateOutline()
        
        if( alternating )
        {
            if let timeMark = lastTimeMark
            {
                if( currentTime - timeMark > alternatingThreshold )
                {
                    impulseVelocity = CGVectorMake( impulseVelocity.dx * -1.0, impulseVelocity.dy * -1.0)
                    _doImpulse(impulseVelocity)
                    lastTimeMark = currentTime
                }
            }
            else
            {
                lastTimeMark = currentTime
            }
        }
    }
}
