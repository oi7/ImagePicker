//
//  ViewController.swift
//  ImagePicker
//
//  Created by Poseidon Ho on 1/23/16.
//  Copyright © 2016 oi7. All rights reserved.
//

import UIKit
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // Meme text and image
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    // Top bar
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    // Bottom bar
    @IBOutlet weak var toolBar: UIToolbar!
    
    // Existing meme reference. Used only when the editor will edit an existing meme
    var meme: Meme?
    
    
    // MARK: -
    // MARK: View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let existingMeme = meme {
            // Existing meme. Use self.meme
            setupTextField(existingMeme.top, textField: topTextField)
            setupTextField(existingMeme.bottom, textField: bottomTextField)
            imageView.image = existingMeme.image
            shareButton.enabled = true
        } else {
            // New meme. self.meme is not used
            setupTextField("TOP", textField: topTextField)
            setupTextField("BOTTOM", textField: bottomTextField)
            shareButton.enabled = false
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        // Enable the camera button if is supported by the device
        cameraButton.enabled = UIImagePickerController.isSourceTypeAvailable(.Camera)
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeToKeyboardNotifications()
    }
    
    // MARK: -
    // MARK: NSNotification subscriptions and selectors
    
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
    }
    
    func unsubscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if bottomTextField.isFirstResponder() {
            self.view.frame.origin.y -= getKeyboardHeight(notification)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if bottomTextField.isFirstResponder() {
            self.view.frame.origin.y += getKeyboardHeight(notification)
        }
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    // MARK: -
    // MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        // When a user taps inside a textfield, the default text should clear.
        textField.text = ""
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // When a user presses return, the keyboard should be dismissed
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: -
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = originalImage
            // Enable share button now that we have an image
            shareButton.enabled = true
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: -
    // MARK: Actions
    
    @IBAction func cancelMeme(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func shareMeme(sender: UIBarButtonItem) {
        //  generate a memed image
        let memedImage = generateMemedImage()
        
        // define an instance of the ActivityViewController
        // pass the ActivityViewController a memedImage as an activity item
        let activity = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        
        activity.completionWithItemsHandler = { (activityType: String?, completed: Bool, returnedItems: [AnyObject]?, activityError: NSError?) -> Void in
            if completed {
                // Save meme and dismiss
                self.saveMeme(memedImage)
                activity.dismissViewControllerAnimated(true, completion: nil)
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        
        // present the ActivityViewController
        presentViewController(activity, animated: true, completion: nil)
    }
    
    @IBAction func pickAnImageFromAlbum(sender: UIBarButtonItem) {
        presentImagePickerOfType(.PhotoLibrary)
    }
    
    @IBAction func pickAnImageFromCamera(sender: UIBarButtonItem) {
        presentImagePickerOfType(.Camera)
    }
    
    // MARK: -
    // MARK: Utility methods
    
    // Setup Text filed to approximate to the "Impact" font, all caps, white with a black outline
    func setupTextField(string: String, textField: UITextField) {
        let memeTextAttributes = [
            NSStrokeColorAttributeName : UIColor.blackColor(),
            NSForegroundColorAttributeName : UIColor.whiteColor(),
            NSFontAttributeName : UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
            NSStrokeWidthAttributeName : -3
        ]
        
        let attributedString = NSAttributedString(string: string, attributes: memeTextAttributes)
        textField.attributedText = attributedString
        textField.defaultTextAttributes = memeTextAttributes
        // Text should be center-aligned
        textField.textAlignment = .Center
        textField.delegate = self
    }
    
    // Present the image picker depending on the specified sourceType
    func presentImagePickerOfType(sourceType: UIImagePickerControllerSourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = sourceType
        presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func toolbarVisible(visible: Bool) {
        toolBar.hidden = !visible
        navigationBar.hidden = !visible
    }
    
    func generateMemedImage() -> UIImage {
        // hide toolbar
        toolbarVisible(false)
        
        // Render view to image
        UIGraphicsBeginImageContext(self.view.frame.size)
        self.view.drawViewHierarchyInRect(self.view.frame, afterScreenUpdates: true)
        let memedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // show toolbar
        toolbarVisible(true)
        
        return memedImage
    }
    
    // Saves the meme correctly. Is the meme is new it saves a new one in the shared model
    // If the meme already exists the method only updates its values
    func saveMeme(memedImage: UIImage) {
        if var existingMeme = meme {
            // Meme exists. Just change its existing properties
            existingMeme.top = topTextField.text!
            existingMeme.bottom = bottomTextField.text!
            existingMeme.image = imageView.image!
            existingMeme.memedImage = memedImage
        } else {
            // New meme. Create one and add it to the sahred model
            let meme = Meme(top: topTextField.text!, bottom: bottomTextField.text!, image: imageView.image!, memedImage: memedImage)
            // Add the saved meme to the shared model
            MemeManager.sharedInstance.appendMeme(meme)
        }
    }
}
