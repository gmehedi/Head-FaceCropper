//
//  TemplateCollectionViewCell.swift
//  DetectFaceLandmarks
//
//  Created by Mehedi Hasan on 20/7/22.
//  Copyright © 2022 mathieu. All rights reserved.
//

import UIKit

class TemplateCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    static let id = "TemplateCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
