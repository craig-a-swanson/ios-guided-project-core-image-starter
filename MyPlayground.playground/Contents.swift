import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

let filter = CIFilter.gaussianBlur()

print(filter.attributes["inputRadius"])
