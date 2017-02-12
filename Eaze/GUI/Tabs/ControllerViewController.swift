//
//  ControllerViewController.swift
//  Eaze
//
//  Created by John Silvester on 10/20/16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit


let leftControlTag = 0
let rightControlTag = 1

var counter = 0
var counterAlt = 0

var has_landed = false

var runFullTimer:NSTimer!

var initAlt = 0.0
var desiredAltitude = 120.0 // in cm 152.4 = 5ft

let launchThrottleValue = 1650
let hoverThrottleValue = 1500
let landThrottleValue = 1400
let spoolUpThrottleValue = 1330





class ControllerViewController: UIViewController, MSPUpdateSubscriber {
    
    @IBOutlet var rightLabel: UILabel!
    
    @IBOutlet var altitudeLabel: UILabel!
    
    @IBOutlet var leftLabel: UILabel!
    
    private let fastMSPCodes = [MSP_SET_RAW_RC,MSP_ALTITUDE]
  
    
    
    
   var leftControlStick:GBSControlStick = GBSControlStick.init()
   var rightContolStick:GBSControlStick = GBSControlStick.init()
    
    
    func setBaseValues(){
        
        dataStorage.rcPitch = 1500;
        dataStorage.rcRoll = 1500;
        dataStorage.rcYaw = 1500;
        dataStorage.rcThrottle = 1000;
        dataStorage.rcAuxOne = 1000;
        dataStorage.rcAuxTwo = 1000;
        dataStorage.rcAuxThree = 1000;
        
    }
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setBaseValues()
        
        
        var fastUpdateTimer = NSTimer.scheduledTimerWithTimeInterval( 0.15,
                                                                  target: self,
                                                                  selector: #selector(self.sendFastDataRequest),
                                                                  userInfo: nil,
                                                                  repeats: true)
        
        msp.addSubscriber(self, forCodes: fastMSPCodes)
        
        
        altitudeLabel.text = "Altitude: \(dataStorage.altitude)"

        leftControlStick = GBSControlStick.init(atPoint: CGPointMake(self.view.center.x * 0.65, 250), withDelegate: self)
        leftControlStick.isThrottle = true
       
        rightContolStick = GBSControlStick.init(atPoint: CGPointMake(self.view.center.x * 0.65, 500), withDelegate: self)
        rightContolStick.isThrottle = false

        leftControlStick.tag = leftControlTag
       
        rightContolStick.tag = rightControlTag
     
        leftControlStick.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI))
        rightContolStick.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))

        
        self.view.addSubview(leftControlStick)
       self.view.addSubview(rightContolStick)
        
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    //Delegate methods
    
    
    @IBAction func backPressed(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    

    
    // MARK: - Data request / update
    
    func sendFastDataRequest() {
        
        //test code for splitting up set rc raw
        for code in fastMSPCodes{
            
            if code == MSP_SET_RAW_RC{
                //ROLL/PITCH/YAW/THROTTLE/AUX1/AUX2/AUX3AUX4
                
                //create values
                let rcChannels: [UInt16] = [UInt16(dataStorage.rcRoll),UInt16(dataStorage.rcPitch),UInt16(dataStorage.rcThrottle),UInt16(1500),UInt16(dataStorage.rcAuxOne),UInt16(dataStorage.rcAuxTwo),UInt16(dataStorage.rcAuxThree)]
                
                msp.sendRawRC(rcChannels) //send raw rc
            }
            else{
              
                msp.sendMSP(code)
            }
        }
        
        
        
    }
    
  
    
    func mspUpdated(code: Int) {
        switch code {
        
        case MSP_SET_RAW_RC:
            print("")
        case MSP_ALTITUDE:
            altitudeLabel.text = "Altitude: \(dataStorage.altitude)"
            
        default:
            log(.Warn, "Invalid MSP code update sent to HomeViewController: \(code)")
        }
    }
    
    
    
  // MARK: - Aux methods
    
    @IBAction func auxOneValueChanged(sender: UISwitch) {
        if sender.on {
            dataStorage.rcAuxOne = 2000
        }
        else
        {
            dataStorage.rcAuxOne = 1000
        }
        
    }
    
    @IBAction func auxTwoValueChanged(sender: UISwitch) {
        if sender.on {
            dataStorage.rcAuxTwo = 2000
        }
        else
        {
            dataStorage.rcAuxTwo = 1000
        }
    }
    
    
    
    @IBAction func auxThreeValueChanged(sender: UISwitch) {
        
//        if sender.on {
//            dataStorage.rcAuxThree = 2000
//            self.leftControlStick.isThrottle = false; //unsticks controller
//            self.leftControlStick.resetStickView();
//            //NOTE: only used in this situation for alt hold
//        }
//        else
//        {
//            self.leftControlStick.isThrottle = true; // sticks controller
//            dataStorage.rcAuxThree = 1000
//        }
        
       
        //TEST FOR GTUNE
        if sender.on {
            dataStorage.rcAuxThree = 2000
           // self.leftControlStick.isThrottle = false; //unsticks controller
           // self.leftControlStick.resetStickView();
            //NOTE: only used in this situation for alt hold
        }
        else
        {
            self.leftControlStick.isThrottle = true; // sticks controller
            dataStorage.rcAuxThree = 1000
        }
    }
    
    
    
    
    
    // MARK: - autcontrolled flight
    
    /// Run function for autoflight
    
    
    func runAuto() {
        
        //controls the overall time of section
        
        
        if counter > 25{//FAILSAFE land after 10 no matter what
            
            if !has_landed {
                
                //decrease throttle to land quad
                
            }
                
            else
            {
                runFullTimer.invalidate() // end timer
            }
            
            
            
        }
        else
            
        {
            
            
            
            if counter == 0 { //arm - Horizon //set throttle to 0
                
            initAlt = dataStorage.altitude // find init alt used for landing
                
            }
            
            if counter == 2{ //spool up throttle to near takeoff speed
                dataStorage.rcThrottle = spoolUpThrottleValue
                
            }
            
            if counter == 4{//set throttle to take off speed
                dataStorage.rcThrottle = launchThrottleValue
                
                
            }
            
            if dataStorage.altitude >= desiredAltitude {//set to hover mode - change throttle hover speed
                //uses inner counter which counts to 2
                
                counterAlt += 1
                
                if counterAlt == 3 {  //set to hover mode
                    dataStorage.rcThrottle = hoverThrottleValue
                    dataStorage.rcAuxThree = 2000 // set auxThree to
                    
                }
//                else
//                { //set throttle to land value
//                    dataStorage.rcThrottle = landThrottleValue
//                   
//                }
                
            }
            
//            if counter > 4 && dataStorage.altitude <= initAlt+2 { //cut the motors and disarm
//                has_landed = true
//                dataStorage.rcThrottle = 1000 // set throttle to 0
//                dataStorage.rcAuxOne = 1000 // set auxOne to low to deactivate arm
//                runFullTimer.invalidate()//end timer
//                
//            
//            }
            
            
            
        }
        counter += 1
        
        self.leftLabel.text = "Thr: \(dataStorage.rcThrottle)"
        self.rightLabel.text = "aux3: \(dataStorage.rcAuxThree)"
        
        
        
        
    }
    
  
    
    
    @IBAction func stopHasClicked(sender: AnyObject) {
        
        runFullTimer.invalidate()
        dataStorage.rcThrottle = 1000 // set throttle to 0
        dataStorage.rcAuxOne = 1000
        
        
        self.leftLabel.text = "Thr: \(dataStorage.rcThrottle)"
        self.rightLabel.text = "aux1: \(dataStorage.rcAuxOne)"
         altitudeLabel.text = "Altitude: \(dataStorage.altitude)"
    }
    
    
    
    func beginAuto() {
        
        self.setBaseValues()
        
        dataStorage.rcThrottle = 1000 // set throttle to 0
        dataStorage.rcAuxOne = 2000 // set auxOne to high to activate arm

        counter = 0
        has_landed = false
        runFullTimer = NSTimer.scheduledTimerWithTimeInterval( 1,target: self,
                                                               selector: #selector(self.runAuto),
                                                               userInfo: nil,
                                                               repeats: true)
        
        
    }
    func endAuto(){
        
    }
    
    func overrideAuto(){
        
    }

    @IBAction func didBeginAuto(sender: AnyObject) {
        
        beginAuto()
    }
}

extension ControllerViewController: GBSControlStickDelegate {
    
    //converts RC input from 1 to -1  ---> 1000-2000 which is RC input
    
    func convertControlToOutputRC(incomingRC: CGFloat) -> Int {
        
        //orignal full control
        
//        var convertedValue = (((incomingRC*1)*1000)+1000)
//        
//        convertedValue = convertedValue / 2
//        
//        convertedValue += 1000
        
        var convertedValue = ((((incomingRC)*1400)+1400)*0.214)
        
        convertedValue = convertedValue / 2
        
        convertedValue += 1400

    
        
        return Int(convertedValue)
    
    }
    
    func convertControlToOutputThrottleRC(incomingRC: CGFloat) -> Int {
        
                var convertedValue = (((incomingRC*1)*1000)+1000)
        
                convertedValue = convertedValue / 2
        
                convertedValue += 1000
     
        
        
        return Int(convertedValue)
        
    }
    
    
    func didUpdateValuesX(x: CGFloat, andY y: CGFloat, withTag tag: CGFloat) {
        
      
        switch Int(tag) {
            
        case leftControlTag:
            
            dataStorage.rcThrottle = self.convertControlToOutputThrottleRC(x)
            dataStorage.rcYaw = self.convertControlToOutputRC(y)
            
            self.leftLabel.text = "T: \(dataStorage.rcThrottle)"
            self.rightLabel.text = "Y: \(dataStorage.rcYaw)"
            
            break;
            
        case rightControlTag:
           let newY = self.convertControlToOutputRC(y);
           let newX = self.convertControlToOutputRC(x);
           

           
            dataStorage.rcPitch = newX
            dataStorage.rcRoll = newY
           
         
        
           
            break;

        default:
            break;
        }
        
        
        
    }
    
    
   
    
    
    

    
    
    
    
   
    
}
