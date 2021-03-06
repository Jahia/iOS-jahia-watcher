//
//  PostDetailInterfaceController.swift
//  Jahia Watcher
//
//  Created by Serge Huber on 08.04.15.
//  Copyright (c) 2015 Jahia Solutions. All rights reserved.
//

import WatchKit
import Foundation

class PostDetailInterfaceController: WKInterfaceController {

    let serverServices = ServerServices.sharedInstance
    let jahiaJahiaServerSettings = JahiaServerSettings.sharedInstance
    
    @IBOutlet weak var postTitleLabel: WKInterfaceLabel!
    @IBOutlet weak var postDateLabel: WKInterfaceLabel!
    @IBOutlet weak var postAuthorLabel: WKInterfaceLabel!
    @IBOutlet weak var postBodyLabel: WKInterfaceLabel!
    @IBOutlet weak var postSpamMarkerLabel: WKInterfaceLabel!
    
    var postDetailContext : PostDetailContext?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        postDetailContext = context as? PostDetailContext
        if (postDetailContext == nil) {
            print("Unexpected nil postDetailContext !")
            return
        }
        postTitleLabel.setText(postDetailContext!.post!.title)
        postBodyLabel.setText(postDetailContext!.post!.content)
        postDateLabel.setText("\(postDetailContext!.post!.date!.relativeTime)")
        postAuthorLabel.setText(postDetailContext!.post!.author!)
        
        buildPostActionsMenu()
    }
    
    func buildPostActionsMenu() {
        clearAllMenuItems()
        let updatedPost = postDetailContext!.jahiaServerSession!.getPostActions(postDetailContext!.post!)
        if (updatedPost.actions != nil) {
            for action in updatedPost.actions! {
                let actionSelector = Selector(action.name! + "Pressed:")
                addMenuItemWithItemIcon(WKMenuItemIcon.Accept, title: action.displayName!, action: actionSelector)
            }
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if (postDetailContext == nil) {
            print("Post detail context is nil, won't update handoff or spam markers")
            return
        }
        if (postDetailContext!.post!.spam!) {
            postSpamMarkerLabel.setHidden(false)
        } else {
            postSpamMarkerLabel.setHidden(true)
        }
        
        let userInfo : [NSObject : AnyObject] = [ "aps" : [
            "alert" : "View post",
            "category" : "newPost"
            ],
            "nodeIdentifier" : "\(postDetailContext!.post!.identifier!)"]
        
        self.updateUserActivity("com.jahia.mobile.apps.Jahia-Watcher.watchkitapp.activities.viewPost", userInfo: userInfo, webpageURL: nil)
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func markAsSpamPressed(sender : AnyObject?) {
        presentControllerWithName("confirmationDialog", context: ConfirmationDialogContext(identifier: "markAsSpamDialog", title: "Mark as spam", message: "Are you sure you want to mark this post as spam ?", yesHandler : { context in
            print("Marking post \(self.postDetailContext!.post!.path!) as spam...")
            self.postDetailContext!.jahiaServerSession!.markAsSpam(self.postDetailContext!.post!.identifier!)
            self.postDetailContext!.post!.spam = true
            let postsInterfaceController = self.postDetailContext!.postsController! as! PostsInterfaceController
            postsInterfaceController.needsRefreshing = true
            }, noHandler : {context in }))
    }

    func unmarkAsSpamPressed(sender : AnyObject?) {
        presentControllerWithName("confirmationDialog", context: ConfirmationDialogContext(identifier: "markAsSpamDialog", title: "Unmark as spam", message: "Are you sure you want to unmark this post as spam ?", yesHandler : { context in
            print("Unmarking post \(self.postDetailContext!.post!.path!) as spam...")
            self.postDetailContext!.jahiaServerSession!.unmarkAsSpam(self.postDetailContext!.post!.identifier!)
            self.postDetailContext!.post!.spam = false
            let postsInterfaceController = self.postDetailContext!.postsController! as! PostsInterfaceController
            postsInterfaceController.needsRefreshing = true
            }, noHandler : {context in }))
    }
    
    func deletePressed(sender : AnyObject?) {
        presentControllerWithName("confirmationDialog", context: ConfirmationDialogContext(identifier: "deletePostDialog", title: "Delete ?", message: "Are you sure you want to delete this post ?", yesHandler : { context in
            print("Deleting post...")
            self.postDetailContext!.jahiaServerSession!.deleteNode(self.postDetailContext!.post!.identifier!, workspace: "live")
            let postsInterfaceController = self.postDetailContext!.postsController! as! PostsInterfaceController
            postsInterfaceController.latestPosts.removeAtIndex(self.postDetailContext!.postIndex!)
            postsInterfaceController.needsRefreshing = true
            self.popController()
            }, noHandler : {context in }))
    }
    
    func blockUserPressed(sender : AnyObject?) {
        presentControllerWithName("confirmationDialog", context: ConfirmationDialogContext(identifier: "blockUserDialog", title: "Block user", message: "Are you sure you want to block the account of this posts author", yesHandler : { context in
            print("Blocking user account \(self.postDetailContext!.post!.author!)...")
            self.postDetailContext!.jahiaServerSession!.blockUser(self.postDetailContext!.post!.author!)
            }, noHandler : {context in }))
    }

    func unblockUserPressed(sender : AnyObject?) {
        presentControllerWithName("confirmationDialog", context: ConfirmationDialogContext(identifier: "blockUserDialog", title: "Unblock user", message: "Are you sure you want to unblock the account of this posts author", yesHandler : { context in
            print("Unblocking user account \(self.postDetailContext!.post!.author!)...")
            self.postDetailContext!.jahiaServerSession!.unblockUser(self.postDetailContext!.post!.author!)
            }, noHandler : {context in }))
    }
    
    func replyPressed(sender : AnyObject?) {
        let suggestions = [ "lol", "Couldn't agree more !", "I'm busy right now but I'll answer with more details later"]
        presentTextInputControllerWithSuggestions(suggestions, allowedInputMode: WKTextInputMode.Plain, completion: { input in
            let body = input![0] as! String
            self.postDetailContext!.jahiaServerSession!.replyToPost(self.postDetailContext!.post!, title: "Re: " + self.postDetailContext!.post!.title!, body: body)
        } )
    }
}
