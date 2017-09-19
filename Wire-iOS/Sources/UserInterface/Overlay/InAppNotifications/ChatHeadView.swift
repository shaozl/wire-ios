//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import UIKit
import Cartography
import PureLayout

class ChatHeadView: UIView {

    private var userImageView: ContrastUserImageView!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var labelContainer: UIView!
    private var labelContainerLeftConstraint: NSLayoutConstraint!
    private var labelContainerRightConstraint: NSLayoutConstraint!
    
    private let isActiveAccount: Bool
    private let isOneToOneConversation: Bool
    
    private let message: ZMConversationMessage
    private let conversationName: String
    private let senderName: String
    private let teamName: String?
    
    public var onSelect: ((ZMConversationMessage) -> Void)?
    
    public var imageToTextInset: CGFloat = 0 {
        didSet {
            let inset = imageToTextInset
            let tileToContentGap = cgFloat("box_tile_to_content_gap")
            labelContainerLeftConstraint.constant = inset + tileToContentGap
            labelContainerRightConstraint.constant = -(cgFloat("corner_radius")) + inset
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: cgFloat("corner_radius") * 2.0)
    }

    private let cgFloat: (String) -> CGFloat = {
        return WAZUIMagic.cgFloat(forIdentifier: "notifications.\($0)")
    }
    
    init?(notification: UILocalNotification) {
        
        let isSelfAccount: (Account) -> Bool = { return $0.userIdentifier == notification.zm_selfUserUUID }
        
        guard
            let accountManager = SessionManager.shared?.accountManager,
            let account = accountManager.accounts.first(where: isSelfAccount),
            let session = SessionManager.shared?.backgroundUserSessions[account],
            let conversation = notification.conversation(in: session.managedObjectContext),
            let message = notification.message(in: conversation, in: session.managedObjectContext),
            let sender = message.sender
            else {
                return nil
        }
        
        self.message = message
        self.conversationName = conversation.displayName
        self.senderName = sender.displayName
        self.teamName = account.teamName
        self.isActiveAccount = account == accountManager.selectedAccount
        self.isOneToOneConversation = conversation.conversationType == .oneOnOne
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = .white
        layer.cornerRadius = cgFloat("corner_radius")
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapInAppNotification(_:)))
        addGestureRecognizer(tap)
        
        titleLabel = UILabel()
        subtitleLabel = UILabel()
        labelContainer = UIView()
        
        [titleLabel, subtitleLabel].forEach {
            labelContainer.addSubview($0!)
            $0!.backgroundColor = .clear
            $0!.isUserInteractionEnabled = false
            $0!.translatesAutoresizingMaskIntoConstraints = false
        }
        
        titleLabel.text = titleText()
        titleLabel.font = UIFont(magicIdentifier: "notifications.user_name_font")
        titleLabel.textColor = UIColor(magicIdentifier: "notifications.author_text_color")
        titleLabel.lineBreakMode = .byTruncatingTail
        
        subtitleLabel.text = subtitleText()
        subtitleLabel.font = messageFont()
        subtitleLabel.textColor = UIColor(magicIdentifier: "notifications.text_color")
        subtitleLabel.lineBreakMode = .byTruncatingTail
        
        userImageView = ContrastUserImageView(magicPrefix: "notifications")
        userImageView.userSession = ZMUserSession.shared()
        userImageView.isUserInteractionEnabled = false
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(userImageView)
        userImageView.user = message.sender
        userImageView.accessibilityIdentifier = "ChatheadAvatarImage"
        
        createConstraints()
    }
    
    private func titleText() -> String {
        
        if let teamName = teamName, !isActiveAccount {
            return isOneToOneConversation ? "in \(teamName)" : "\(conversationName) in \(teamName)"
        } else {
            return conversationName
        }
    }
    
    private func subtitleText() -> String {
        let content = messageText()
        return (isActiveAccount && isOneToOneConversation) ? content : "\(senderName): \(content)"
    }
    
    private func messageText() -> String {
        var result = ""
        
        if Message.isText(message) {
            return (message.textMessageData!.messageText as NSString).resolvingEmoticonShortcuts()
        } else if Message.isImage(message) {
            result = "notifications.shared_a_photo".localized
        } else if Message.isKnock(message) {
            result = "notifications.pinged".localized
        } else if Message.isVideo(message) {
            result = "notifications.sent_video".localized
        } else if Message.isAudio(message) {
            result = "notifications.sent_audio".localized
        } else if Message.isFileTransfer(message) {
            result = "notifications.sent_file".localized
        } else if Message.isLocation(message) {
            result = "notifications.sent_location".localized
        }
        
        return result
    }

    private func messageFont() -> UIFont {
        let font = UIFont(magicIdentifier: "style.text.small.font_spec_light")!
        if message.isEphemeral {
            return UIFont(name: "RedactedScript-Regular", size: font.pointSize)!
        }
        return font
    }
    
    @objc private func didTapInAppNotification(_ gestureRecognizer: UITapGestureRecognizer) {
        if let onSelect = onSelect, gestureRecognizer.state == .recognized {
            onSelect(message)
        }
    }
    
    func createConstraints() {

        let tileDiameter = cgFloat("tile_diameter")
        let padding: CGFloat = 10
        let tileToContentGap = cgFloat("box_tile_to_content_gap")
        let cornerRadius = cgFloat("corner_radius")
        
        constrain(labelContainer, titleLabel, subtitleLabel) { container, titleLabel, subtitleLabel in
            titleLabel.leading == container.leading
            titleLabel.top == container.top
            titleLabel.trailing == container.trailing
            titleLabel.bottom == container.centerY
            
            subtitleLabel.leading == container.leading
            subtitleLabel.top == container.centerY
            subtitleLabel.trailing == container.trailing
            subtitleLabel.bottom == container.bottom
        }
        
        constrain(self, userImageView, labelContainer) { selfView, imageView, labelContainer in
            
            imageView.height == tileDiameter
            imageView.width == imageView.height
            imageView.leading == selfView.leading + padding
            imageView.centerY == selfView.centerY
            
            selfView.height == imageView.height + 2 * padding
            
            labelContainerLeftConstraint = (labelContainer.leading == imageView.trailing + imageToTextInset + tileToContentGap)
            labelContainerRightConstraint = (labelContainer.trailing == selfView.trailing + imageToTextInset - cornerRadius)
            labelContainer.height == selfView.height
            labelContainer.centerY == selfView.centerY
        }
    }
}
