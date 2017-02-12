//
//  HomeViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 04-04-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//
//  Idea for future update: "More Info" button on bottom. On tap: blurview moves up (à la yahoo weather) with
//  FC version info, and other stats. This would replace the info box. The more info button would have a light
//  40% alpha background.
//

import UIKit

final class HomeViewController: UIViewController, MSPUpdateSubscriber {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var efis: EFIS!
    @IBOutlet weak var infoBox: GlassBox!
    @IBOutlet var sensorLabels: [GlassLabel]!
    @IBOutlet weak var referenceModeLabel: GlassLabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var voltageIndicator: GlassIndicator!
    @IBOutlet weak var amperageIndicator: GlassIndicator!
    @IBOutlet weak var RSSIIndicator: GlassIndicator!
    @IBOutlet weak var BluetoothRSSIIndicator: GlassIndicator!
    @IBOutlet weak var bottomMarginConstraint: NSLayoutConstraint?
    @IBOutlet weak var flyButtonm: UIButton!
    
    
    
    // MARK: - Variables
    
    private var fastUpdateTimer: NSTimer?,
                slowUpdateTimer: NSTimer?,
                currentModes: [String] = [],
                modeLabels: [GlassLabel] = []
    
    private let mspCodes = [MSP_BOARD_INFO, MSP_FC_VARIANT, MSP_FC_VERSION, MSP_BUILD_INFO],
                fastMSPCodes = [MSP_ATTITUDE,MSP_ALTITUDE],
                slowMSPCodes = [MSP_STATUS, MSP_ANALOG]
    
    
    // MARK: - Functions
    
    func setBaseValues(){
        
        dataStorage.rcPitch = 1500;
        dataStorage.rcRoll = 1500;
        dataStorage.rcYaw = 1500;
        dataStorage.rcThrottle = 1000;
        dataStorage.rcAuxOne = 1000;
        dataStorage.rcAuxTwo = 1000;
        dataStorage.rcAuxThree = 1000;
        
    }
    
    var sticky = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //set base values for RC
        self.setBaseValues()
        
        print(OpenCVWrapper.openCVVersionString())
        
        
        msp.addSubscriber(self, forCodes: mspCodes + fastMSPCodes + slowMSPCodes)
        
        
        
        referenceModeLabel.hidden = true
        
        connectButton.backgroundColor = UIColor.clearColor()
        connectButton.setBackgroundColor(UIColor.blackColor().colorWithAlphaComponent(0.18), forState: .Normal)
        connectButton.setBackgroundColor(UIColor.blackColor().colorWithAlphaComponent(0.08), forState: .Highlighted)
        
        if UIDevice.isPhone && UIScreen.mainScreen().bounds.size.height < 568 {
            // 3.5" - use this constraint to place the bottom indicators a little lower
            bottomMarginConstraint?.constant = 6
        }

        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.serialOpened),
                                  name: BluetoothSerialDidConnectNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.serialClosed),
                                  name: BluetoothSerialDidDisconnectNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.serialWillAutoConnect),
                                  name: BluetoothSerialWillAutoConnectNotification,
                                object: nil)
    
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.serialDidFailToConnect),
                                  name: BluetoothSerialDidFailToConnectNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.serialDidDiscoverPeripheral),
                                  name: BluetoothSerialDidDiscoverNewPeripheralNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.serialDidStopScanning),
                                  name: BluetoothSerialDidStopScanningNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.serialDidUpdateState),
                                  name: BluetoothSerialDidUpdateStateNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.willResignActive),
                                  name: AppWillResignActiveNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.didBecomeActive),
                                  name: AppDidBecomeActiveNotification,
                                object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if bluetoothSerial.isConnected {
            serialOpened() // send request & schedule timer
        } else {
            serialClosed() // reset UI
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if bluetoothSerial.isConnected {
            fastUpdateTimer?.invalidate()
            slowUpdateTimer?.invalidate()
        } else if bluetoothSerial.isConnecting || bluetoothSerial.isReconnecting {
            bluetoothSerial.disconnect()
        } else if bluetoothSerial.isScanning {
            bluetoothSerial.stopScan()
        }
    }
    
    func didBecomeActive() {
        guard isBeingShown else { return }
        if bluetoothSerial.isConnected {
            serialOpened()
        }
    }
    
    func willResignActive() {
        guard isBeingShown else { return }
        if bluetoothSerial.isConnected {
            fastUpdateTimer?.invalidate()
            slowUpdateTimer?.invalidate()
        } else if bluetoothSerial.isConnecting {
            bluetoothSerial.disconnect()
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    
    private func reloadModeLabels() {
        var x = referenceModeLabel.frame.maxX
        for mode in currentModes {
            let newLabel = GlassLabel(frame: referenceModeLabel.frame)
            newLabel.background = .Green
            newLabel.text = mode
            newLabel.adjustToTextSize()
            newLabel.frame.origin.x = x - newLabel.frame.width
            
            view.addSubview(newLabel)
            modeLabels.append(newLabel)
            x = newLabel.frame.minX - 5
        }
    }
    
    
    // MARK: - Data request / update
    
    func sendFastDataRequest() {
       
        
      
    //test code for splitting up set rc raw
        for code in fastMSPCodes{
            if code == MSP_SET_RAW_RC{
                //ROLL/PITCH/YAW/THROTTLE/AUX1/AUX2/AUX3AUX4
                
                //create values
                let rcChannels: [UInt16] = [UInt16(dataStorage.rcRoll),UInt16(dataStorage.rcPitch),UInt16(dataStorage.rcThrottle),UInt16(dataStorage.rcYaw),UInt16(dataStorage.rcAuxOne),UInt16(dataStorage.rcAuxTwo),UInt16(dataStorage.rcAuxThree)]
               
                
                msp.sendRawRC(rcChannels) //send raw rc
                
            }
            else{
                msp.sendMSP(code)
            }
        }


        
    }
    
    func sendSlowDataRequest() {
        msp.sendMSP(slowMSPCodes)
        bluetoothSerial.readRSSI(rssiUpdated)
    }
    
    func rssiUpdated(RSSI: NSNumber) {
       // BluetoothRSSIIndicator.text = "\(RSSI.integerValue)"
        BluetoothRSSIIndicator.setIndication((RSSI.doubleValue+100.0)/60.0)
    }
    
    func mspUpdated(code: Int) {
        switch code {
        case MSP_ATTITUDE:
            efis.roll = dataStorage.attitude[0]
            efis.pitch = dataStorage.attitude[1]
            efis.heading = dataStorage.attitude[2]
            
        case MSP_BOARD_INFO:
            infoBox.firstUpperText = dataStorage.boardName
            infoBox.secondUpperText = dataStorage.boardVersion > 0 ? "version \(dataStorage.boardVersion)" : ""
            infoBox.reloadText()
            
        case MSP_FC_VARIANT, MSP_FC_VERSION:
            infoBox.firstLowerText = dataStorage.flightControllerName + " " + dataStorage.flightControllerVersion.stringValue
            infoBox.reloadText()
            
        case MSP_BUILD_INFO:
            infoBox.secondLowerText = dataStorage.buildInfo
            infoBox.reloadText()
            
        case MSP_STATUS:
            for label in sensorLabels {
                label.background = dataStorage.activeSensors.bitCheck(label.tag)  ? .Dark : .Red
            }
            
            if dataStorage.activeFlightModes != currentModes {
                // remove previous and add new
                currentModes = dataStorage.activeFlightModes
                modeLabels.forEach { $0.removeFromSuperview() }
                modeLabels = []
                
                let height = referenceModeLabel.frame.height,
                    y = referenceModeLabel.frame.minY
                var x = referenceModeLabel.frame.maxX
                
                for mode in currentModes {
                    let label = GlassLabel(frame: CGRect(x: 0, y: y, width: 0, height: height))
                    label.background = .Green
                    label.text = mode
                    label.adjustToTextSize()
                    label.frame.origin.x = x - label.frame.width
                    x = label.frame.origin.x - 9 // add margin
                    
                    modeLabels.append(label)
                    view.addSubview(label)
                }
            }
            
        case MSP_ANALOG:
            voltageIndicator.text = "\(dataStorage.voltage.stringWithDecimals(1))V"
            amperageIndicator.text = "\(Int(round(dataStorage.amperage)))A"
            //RSSIIndicator.text = "\(dataStorage.rssi)%"
            
            // Note: We don't set the voltage indicator, since voltage cannot be used
            // to get an accurate % charged of a battery (not while using it, at least)
            amperageIndicator.setIndication(dataStorage.amperage/50)
           // RSSIIndicator.setIndication(Double(dataStorage.rssi)/100)
        case MSP_SET_RAW_RC:
            voltageIndicator.text = "\(dataStorage.rssi)%"
        case MSP_ALTITUDE:
             RSSIIndicator.text = "\(dataStorage.altitude)%"
             print(dataStorage.altitude)

        default:
            log(.Warn, "Invalid MSP code update sent to HomeViewController: \(code)")
        }
    }
    
    
    // MARK: - Serial events
    
    func serialOpened() {
        connectButton.setTitle("Disconnect", forState: .Normal)
        connectButton.setTitleColor(UIColor(hex: 0xFF8C8C), forState: .Normal)
        activityIndicator.stopAnimating()
        
        slowUpdateTimer?.invalidate()
        fastUpdateTimer?.invalidate()
        
        slowUpdateTimer = NSTimer.scheduledTimerWithTimeInterval( 0.6,
                                                                  target: self,
                                                                  selector: #selector(HomeViewController.sendSlowDataRequest),
                                                                  userInfo: nil,
                                                                  repeats: true)
        
        fastUpdateTimer = NSTimer.scheduledTimerWithTimeInterval( 0.15,
                                                                  target: self,
                                                                  selector: #selector(HomeViewController.sendFastDataRequest),
                                                                  userInfo: nil,
                                                                  repeats: true)
    }
    
    func serialClosed() {
        connectButton.setTitle("Connect", forState: .Normal)
        connectButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        activityIndicator.stopAnimating()
        
        efis.roll = 0
        efis.pitch = 0
        efis.heading = 0
        
        infoBox.firstUpperText = ""
        infoBox.secondUpperText = ""
        infoBox.firstLowerText = ""
        infoBox.secondLowerText = ""
        infoBox.reloadText()
        
        voltageIndicator.text = "0.0V"
        amperageIndicator.text = "0A"
        RSSIIndicator.text = "0%"
        BluetoothRSSIIndicator.text = "0"
        
        voltageIndicator.setIndication(1.0)
        amperageIndicator.setIndication(1.0)
        RSSIIndicator.setIndication(1.0)
        BluetoothRSSIIndicator.setIndication(1.0)
        
        for label in sensorLabels {
            label.background = .Dark
        }
        
        fastUpdateTimer?.invalidate()
        slowUpdateTimer?.invalidate()
    }
    
    func serialWillAutoConnect() {
        connectButton.setTitle("Connecting", forState: .Normal)
        activityIndicator.startAnimating()
    }
    
    func serialDidFailToConnect() {
        connectButton.setTitle("Connect", forState: .Normal)
        activityIndicator.stopAnimating()
    }
    
    func serialDidDiscoverPeripheral(notification: NSNotification) {
        guard presentedViewController == nil && notification.userInfo!["WillAutoConnect"] as! Bool == false else { return }
        
        let bundle = NSBundle.mainBundle(),
            storyboard = UIStoryboard(name: "Uni", bundle: bundle),
            connectViewController = storyboard.instantiateViewControllerWithIdentifier("ConnectViewController")
        
        presentViewController(connectViewController, animated: true, completion: nil)
    }
    
    func serialDidStopScanning() {
        connectButton.setTitle("Connnect", forState: .Normal)
        activityIndicator.stopAnimating()
    }
    
    func serialDidUpdateState() {
        if bluetoothSerial.state != .PoweredOn {
            connectButton.setTitle("Connnect", forState: .Normal)
            activityIndicator.stopAnimating()
        }
    }
    
    
    // MARK: - IBActions
    
    @IBAction func connect(sender: AnyObject) {
        if bluetoothSerial.isConnected || bluetoothSerial.isReconnecting {
            
            bluetoothSerial.disconnect()
            

        } else if bluetoothSerial.isConnecting {
            
            connectButton.setTitle("Connect", forState: .Normal) // we have to do this here because
            activityIndicator.stopAnimating() // serialClosed may not be called while connecting
            bluetoothSerial.disconnect()
            
        } else if bluetoothSerial.isScanning {
            bluetoothSerial.stopScan()
                    
        } else {
            if bluetoothSerial.state != .PoweredOn {
                let alert = UIAlertController(title: "Bluetooth is turned off",
                                            message: nil,
                                     preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
                presentViewController(alert, animated: true, completion: nil)
                return
            }
            
            connectButton.setTitle("Scanning", forState: .Normal)
            activityIndicator.startAnimating()
            bluetoothSerial.startScan()
        }
    }
    //controller
    
    @IBAction func touchUpInsideRoll(sender: AnyObject) {
        sender.setValue(1500, animated: true)
        dataStorage.rcRoll = 1500
    }
    @IBAction func touchUpInsidePitch(sender: AnyObject) {
        sender.setValue(1500, animated: true)
        dataStorage.rcPitch = 1500
    }
    @IBAction func touchUpInsideYaw(sender: UISlider) {
        
        sender.setValue(1500, animated: true)
        dataStorage.rcYaw = 1500
    }
   
    @IBAction func yawDidChange(sender: UISlider) {
        
       
        dataStorage.rcYaw = Int(sender.value)
    }
    
    @IBAction func pitchDidChange(sender: UISlider) {
        dataStorage.rcPitch = Int(sender.value)
    }
    
    @IBAction func rollDidChange(sender: UISlider) {
        dataStorage.rcRoll = Int(sender.value)
    }
    @IBAction func throttleDidChange(sender: UISlider) {
        dataStorage.rcThrottle = Int(sender.value)
    }
    
    @IBAction func auxTwoClicked(sender: UIButton) {
        if sender.tag == 0 {
            dataStorage.rcAuxTwo = 2000
            sender.tag = 1
        }else{
            dataStorage.rcAuxTwo = 1000
            sender.tag = 0
        }
    }
    @IBAction func auxOneClicked(sender: UIButton) {
        if sender.tag == 0 {
            dataStorage.rcAuxOne = 2000
            sender.tag = 1
        }else{
             dataStorage.rcAuxOne = 1000
            sender.tag = 0
        }
        
    }
}




