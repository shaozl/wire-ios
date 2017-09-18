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
import PureLayout

class ChatHeadView: UIView {

    private var userImageView: ContrastUserImageView!
    private var nameLabel: UILabel!
    private var messageLabel: UILabel!
    private var constraintsCreated: Bool = false
    private var nameLabelLeftConstraint = NSLayoutConstraint()
    private var messageLabelLeftConstraint = NSLayoutConstraint()
    private var nameLabelRightConstraint = NSLayoutConstraint()
    private var messageLabelRightConstraint = NSLayoutConstraint()
    
    public let message: ZMConversationMessage
    
    public var onSelect: ((ZMConversationMessage) -> Void)?
    
    public var imageToTextInset: CGFloat = 0 {
        didSet {
            let inset = imageToTextInset
            let tileToContentGap = cgFloat("box_tile_to_content_gap")
            nameLabelLeftConstraint.constant = inset + tileToContentGap
            messageLabelLeftConstraint.constant = inset + tileToContentGap
            nameLabelRightConstraint.constant = -(cgFloat("corner_radius")) + inset
            messageLabelRightConstraint.constant = -(cgFloat("corner_radius")) + inset
        }
    }
    
    public var isMessageInCurrentConversation: Bool = false {
        didSet { nameLabel.text = senderText() }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: cgFloat("corner_radius") * 2.0)
    }

    private let cgFloat: (String) -> CGFloat = {
        return WAZUIMagic.cgFloat(forIdentifier: "notifications.\($0)")
    }
    
    init(message: ZMConversationMessage) {
        self.message = message
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = message.sender!.accentColor
        layer.cornerRadius = WAZUIMagic.cgFloat(forIdentifier: "notifications.corner_radius")
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapInAppNotification(_:)))
        addGestureRecognizer(tap)
        
        nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)
        nameLabel.backgroundColor = .clear
        nameLabel.isUserInteractionEnabled = false
        nameLabel.text = senderText()
        nameLabel.font = UIFont(magicIdentifier: "notifications.user_name_font")
        nameLabel.textColor = UIColor(magicIdentifier: "notifications.author_text_color")
        nameLabel.lineBreakMode = .byTruncatingTail
        
        messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        messageLabel.backgroundColor = .clear
        messageLabel.isUserInteractionEnabled = false
        messageLabel.text = messageText()
        messageLabel.font = messageFont()
        messageLabel.textColor = UIColor(magicIdentifier: "notifications.text_color")
        messageLabel.lineBreakMode = .byTruncatingTail
        
        userImageView = ContrastUserImageView(magicPrefix: "notifications")
        userImageView.userSession = ZMUserSession.shared()
        userImageView.isUserInteractionEnabled = false
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(userImageView)
        userImageView.user = message.sender
        userImageView.accessibilityIdentifier = "ChatheadAvatarImage"
        
        setNeedsUpdateConstraints()
    }
    
    private func senderText() -> String {
        
        guard let sender = message.sender, let conversation = message.conversation else {
            return ""
        }
        
        let nameString = (sender.displayName as NSString).uppercasedWithCurrentLocale
        
        if conversation.conversationType == .oneOnOne {
            return nameString
        } else if isMessageInCurrentConversation {
            return String(format: "%s %s", "notifications.this_conversation".localized, nameString)
        } else {
            return String(format: "%s %s %s", "notifications.in_conversation".localized, nameString, (message.conversation!.displayName as NSString).uppercasedWithCurrentLocale)
        }
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
    
    override func updateConstraints() {
        if !constraintsCreated {
            constraintsCreated = true
            
            let tileDiameter = cgFloat("tile_diameter")
            let tileToContentGap = cgFloat("box_tile_to_content_gap")
            let tileLeftMargin = cgFloat("tile_left_margin")
            
            let topLabelInset = cgFloat("top_label_inset")
            let bottomLabelInset = cgFloat("bottom_label_inset")
            let ephemeralBottomLabelInset = cgFloat("ephemeral_bottom_label_inset")
            
            userImageView.autoSetDimension(.height, toSize: tileDiameter)
            userImageView.autoAlignAxis(toSuperviewAxis: .horizontal)
            userImageView.autoPinEdge(toSuperviewEdge: .leading, withInset: tileLeftMargin)
            userImageView.autoConstrainAttribute(.width, to: .height, of: userImageView)
            
            nameLabel.autoPinEdge(toSuperviewEdge: .top, withInset: topLabelInset)
            nameLabelLeftConstraint = nameLabel.autoPinEdge(.left, to: .right, of: userImageView, withOffset: tileToContentGap + imageToTextInset)
            nameLabelRightConstraint = nameLabel.autoPinEdge(toSuperviewEdge: .right, withInset: WAZUIMagic.cgFloat(forIdentifier: "notifications.corner_radius") - imageToTextInset)
            
            messageLabelLeftConstraint = messageLabel.autoPinEdge(.left, to: .right, of: userImageView, withOffset: tileToContentGap + imageToTextInset)
            messageLabelRightConstraint = messageLabel.autoPinEdge(toSuperviewEdge: .right, withInset: cgFloat("corner_radius") - imageToTextInset)
            
            let bottomInset = message.isEphemeral ? ephemeralBottomLabelInset : bottomLabelInset
            messageLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: bottomInset)
        }
        
        super.updateConstraints()
    }
}
