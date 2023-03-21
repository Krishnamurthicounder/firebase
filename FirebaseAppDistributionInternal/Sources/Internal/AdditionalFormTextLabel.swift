//
//  AdditionFormInfoLabel.swift
//  FirebaseAppDistributionInternal
//
//  Created by Tejas Deshpande on 3/21/23.
//

import UIKit

class AdditionalFormTextLabel: UILabel {
  var topInset = 10.0
  var bottomInset = 15.0
  var leftInset = 10.0
  var rightInset = 10.0
  
  override func drawText(in rect: CGRect) {
    let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
    super.drawText(in: rect.inset(by: insets))
  }
  
  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    return CGSize(width: size.width + leftInset + rightInset,
                  height: size.height + topInset + bottomInset)
  }
  
  override var bounds: CGRect {
    didSet {
      preferredMaxLayoutWidth = bounds.width - (leftInset + rightInset)
    }
  }
}
