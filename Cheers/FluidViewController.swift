//
//  FluidViewController.swift
//  Cheers
//
//  Created by Minna Xiao on 3/10/17.
//  Copyright © 2017 Stanford. All rights reserved.
//

import UIKit
import BAFluidView
import CoreMotion

class FluidViewController: UIViewController, DCPathButtonDelegate {
    // MARK: - Outlets
    
    @IBOutlet var swipeUpGesture: UISwipeGestureRecognizer!
    
    @IBOutlet var swipeDownGesture: UISwipeGestureRecognizer!
    
    @IBOutlet weak var drinkLabel: UILabel!
    @IBOutlet weak var drinksInLabel: UILabel!
    @IBOutlet weak var handIcon: UIImageView!
    
    @IBAction func goToGroupPage(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let snapContainer = appDelegate.window?.rootViewController as! SnapContainerViewController
        let groupViewOffset = snapContainer.middleVertScrollVc.view.frame.origin
        snapContainer.scrollView.setContentOffset(groupViewOffset, animated: true)
    }
    
    @IBOutlet weak var exceedLabel: UILabel!
    

    
    // MARK: - Properties
    var fluidView: BAFluidView?
    //let numberView = NumberMorphView()
    let motionManager = CMMotionManager()
    
    var level = 0.0 //fluid level
    var alcIndex = 0
    var cupButton:DCPathButton!
    
    var drinkSelected = false
    var numDrinks = 0
    var percentIncrement: Double = 0.0

    var tutorialCompleted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        startFluidAnimation()
        configureButtons()
        
        // set up percentIncrement
        if (UserInfo.drinkLimit == 0) {
            percentIncrement = 1.0
        } else {
            percentIncrement = 0.9 / Double(UserInfo.drinkLimit)
        }

        drinkLabel.textColor = UIColor(hex: "4E4E4E")
        drinksInLabel.textColor = UIColor(hex: "4E4E4E")
        exceedLabel.isHidden = true
        handIcon.isHidden = true
    }
    
    @IBAction func swipeToAddDrink(_ sender: UISwipeGestureRecognizer) {
        // our dictionary only maps up to 10 drinks
        if (drinkSelected){
            tutorialCompleted = true
            handIcon.isHidden = true
            
            if (numDrinks < 10) {
                level += percentIncrement
                fluidView?.fill(to: level as NSNumber!)
                fluidView?.fillColor = cupButton.selectedButton.itemColor
                numDrinks += 1
                UserInfo.numDrinks = self.numDrinks
                // kinda hacky but wtv
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "drinkCountChange"), object: nil)
                
                drinksInLabel.text = (numDrinks == 1) ? "drink in" : "drinks in"
                
                animateDrinkCountChange()

            }
            if (UserInfo.drinkLimit == 0) {
                limitReachedAlert(soberLimit: true)
                drinkLabel.textColor = UIColor.white
                drinksInLabel.textColor = UIColor.white
            } else if (numDrinks == UserInfo.drinkLimit) {
                limitReachedAlert(soberLimit: false)
                drinkLabel.textColor = UIColor.white
                drinksInLabel.textColor = UIColor.white
            } else if (numDrinks > UserInfo.drinkLimit) {
                exceedLabel.isHidden = false
            }
        }
    }
    
    @IBAction func swipeToMinusDrink(_ sender: UISwipeGestureRecognizer) {
        if drinkSelected {
            if numDrinks > 0 {
                level -= percentIncrement
                fluidView?.fill(to: level as NSNumber!)
                numDrinks -= 1
                UserInfo.numDrinks = self.numDrinks
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "drinkCountChange"), object: nil)
            }
            
            drinksInLabel.text = (numDrinks == 1) ? "drink in" : "drinks in"
            
            animateDrinkCountChange()
            
            if (numDrinks < UserInfo.drinkLimit) {
                exceedLabel.isHidden = true
                drinkLabel.textColor = UIColor(hex: "4E4E4E")
                drinksInLabel.textColor = UIColor(hex: "4E4E4E")
            }
        }
    }
    
    private func limitReachedAlert(soberLimit: Bool) {
        let title = "Warning"
        let message = soberLimit ? "You have exceeded your drink limit for the night." : "You have reached your drink limit for the night."
        
        let popup = PopupDialog(title: title, message: message, image: nil)
        
        let button = DefaultButton(title: "OK") {
            print("button pressed")
        }
        
        popup.addButtons([button])
        self.present(popup, animated: true, completion: nil)
    }
    
    private func animateDrinkCountChange() {
        UIView.transition(with: drinkLabel,
                          duration: 1.0,
                          options: [.transitionCrossDissolve],
                          animations: {
                            self.drinkLabel.text = String(self.numDrinks)
        }, completion: nil)
    }
    
    public func pathButton(_ dcPathButton: DCPathButton!, clickItemButtonAt itemButtonIndex: UInt) {
        drinkSelected = true
        if (tutorialCompleted == false) {
            handIcon.isHidden = false
        }
        fluidView?.fillColor = cupButton.selectedButton.itemColor
    }
    
    func configureButtons() {
        cupButton = DCPathButton(center: UIImage(named: "plus"), highlightedImage: UIImage(named: "plus"))
        
        cupButton.delegate = self
        cupButton.dcButtonCenter = CGPoint(x: self.view.bounds.width/2, y: self.view.bounds.height - 70)
        cupButton.allowSounds = false
        cupButton.allowCenterButtonRotation = true
        cupButton.bloomRadius = 105

        let beerButton = DCPathItemButton(image: UIImage(named: "beer"), imageMain: UIImage(named: "beer-main"), color: UIColor(hex: "E7B90B"))
        let wineButton = DCPathItemButton(image: UIImage(named: "wine"), imageMain: UIImage(named: "wine-main"), color: UIColor(hex: "CC0F0F"))
        let cocktailButton = DCPathItemButton(image: UIImage(named: "cocktail"), imageMain: UIImage(named: "cocktail-main"), color: UIColor(hex: "9AD145"))
        let shotButton = DCPathItemButton(image: UIImage(named: "shot"), imageMain: UIImage(named: "shot-main"), color: UIColor(hex: "FF7902"))
        
        cupButton.addPathItems([beerButton!, wineButton!, cocktailButton!, shotButton!])
        
        self.view.addSubview(cupButton)

    }
    
    func startFluidAnimation() {
        // set up accelerometer
        if motionManager.isDeviceMotionAvailable {
            motionManager.startAccelerometerUpdates()
            motionManager.accelerometerUpdateInterval = 0.1
            print ("motion")
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: { [weak self] (data: CMDeviceMotion?, error: Error?) in
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name(kBAFluidViewCMMotionUpdate), object: self, userInfo: ["data":data!])
            })
        }
        
        // set up fluid view
        fluidView = BAFluidView(frame: self.view.frame, startElevation: level as NSNumber!)
        fluidView?.strokeColor = UIColor.white
        fluidView?.fillColor = UIColor(hex: "99d6ea")
        fluidView?.keepStationary()
        fluidView?.startAnimation()
        fluidView?.startTiltAnimation()
        
        self.view.insertSubview(fluidView!, at: 0)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
