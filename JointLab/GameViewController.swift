//
//  GameViewController.swift
//  JointLab
//
//  Created by victor on 7/7/14.
//  Copyright (c) 2014 AOTK. All rights reserved.
//

import UIKit
import SpriteKit

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        
        let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks")
        
        var sceneData = NSData.dataWithContentsOfFile(path, options: .DataReadingMappedIfSafe, error: nil)
        var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
        
        archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
        let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as GameScene
        archiver.finishDecoding()
        return scene
    }
}

protocol GameViewStatus
{
    func statusMessage(msg:String)
}

class GameViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, GameViewStatus
{
    @IBOutlet var tableView : UITableView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            // Configure the view.
            let skView = self.view as SKView
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            if let tv = tableView
            {
                tv.reloadData()
                tv.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: false, scrollPosition: .None)
            }
            
            scene.statusOutput = self
            
            skView.presentScene(scene)
            
            statusMessage("Presented scene")
        }
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
    {
        return 5
    }
    
    let jointTypeNames:Array<JointLabels> = [ .Pin, .Fixed, .Sliding, .Spring, .Limit ]
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!
    {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        cell.textLabel.text = jointTypeNames[ indexPath.row ].toRaw()
        return cell
    }
    
    @IBOutlet var messageLabel : UILabel
    
    func statusMessage(msg: String)
    {
        messageLabel.text = msg
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!)
    {
        var cell = tableView.cellForRowAtIndexPath(indexPath)
        gs.makeJoint(JointLabels.fromRaw(cell.textLabel.text)!)
    }
    
    var gs:GameScene {
        return (view as SKView).scene as GameScene
    }
    
    @IBAction func alternatingSwitchTap(sender : AnyObject)
    {
        gs.alternating = (sender as UISwitch).on
    }
    
    @IBAction func pinnedDynamicTap(sender : AnyObject)
    {
        var node = gs.childNodeWithName(kPinnedNode)
        node.physicsBody.dynamic = (sender as UISegmentedControl).selectedSegmentIndex == 1
    }
    
    // TODO: make this into a UISlider value
    let impulseAmount:CGFloat = 200
    
    let directions = [ CGVectorMake(-1,0), CGVectorMake(0,1), CGVectorMake(0,-1), CGVectorMake(1, 0) ];
    
    @IBAction func impulseTap(sender : AnyObject)
    {
        let directionVector = directions[ (sender as UIButton).tag - 1 ]
        
        let cgv = CGVectorMake( directionVector.dx * impulseAmount, directionVector.dy * impulseAmount)
        gs.applyImpulse( cgv )
    }
    
    @IBAction func resetTap(sender : AnyObject)
    {
        gs.resetNodes()
    }
    
}
