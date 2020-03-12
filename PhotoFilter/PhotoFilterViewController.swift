import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

class PhotoFilterViewController: UIViewController {
    
    // 1. Photo is selected and stored in originalImage
    // 2. Original image scales it down and stores it in scaledImage
    // 3. The sliders each call updateImage.
    // 4. updateImage calls the image(byFiltering:) method
    // 5. The image is adjusted based on the slider values and the output image is set
    // 6. The output image is returned to updateImage as a UIImage
    // 7. updateImage sets the UIImageView image to the value of the returned image

	@IBOutlet weak var brightnessSlider: UISlider!
	@IBOutlet weak var contrastSlider: UISlider!
	@IBOutlet weak var saturationSlider: UISlider!
    @IBOutlet weak var blurSlider: UISlider!
	@IBOutlet weak var imageView: UIImageView!
    
    var originalImage: UIImage? {
        didSet {
            guard let originalImage = originalImage else { return }
            
            var scaledSize = imageView.bounds.size
            let scale = UIScreen.main.scale // could also hard code the size smaller to make it faster
            
            scaledSize = CGSize(width: scaledSize.width * scale, height: scaledSize.height * scale)
            
            let scaledUIImage = originalImage.imageByScaling(toSize: scaledSize)
            
            guard let scaledCGImage = scaledUIImage?.cgImage else { return }
            
            scaledImage = CIImage(cgImage: scaledCGImage)
        }
    }
    
    var scaledImage: CIImage? {
        didSet {
            updateImage()
        }
    }
    
    private let context = CIContext()
    private let colorControlsFilter = CIFilter.colorControls()
    private let blurFilter = CIFilter.gaussianBlur()
	
	override func viewDidLoad() {
		super.viewDidLoad()

        originalImage = imageView.image
	}
    
    private func image(byFiltering inputImage: CIImage) -> UIImage {
        
        colorControlsFilter.inputImage = inputImage
        colorControlsFilter.saturation = saturationSlider.value
        colorControlsFilter.brightness = brightnessSlider.value
        colorControlsFilter.contrast = contrastSlider.value
        
        blurFilter.inputImage = colorControlsFilter.outputImage?.clampedToExtent()
        blurFilter.radius = blurSlider.value
        
        guard let outputImage = blurFilter.outputImage else { return UIImage(ciImage: inputImage) }
        
        guard let renderedImage = context.createCGImage(outputImage, from: inputImage.extent) else { return UIImage(ciImage: inputImage) }
        
        return UIImage(cgImage: renderedImage)
    }
    
    private func updateImage() {
        if let scaledImage = scaledImage {
            imageView.image = image(byFiltering: scaledImage)
        } else {
            imageView.image = nil
        }
    }
	
	// MARK: Actions
	
	@IBAction func choosePhotoButtonPressed(_ sender: Any) {
        presentImagePickerController()
	}
    
    private func presentImagePickerController() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
    }
	
	@IBAction func savePhotoButtonPressed(_ sender: UIButton) {
		guard let originalImage = originalImage,
            let cgImage = originalImage.cgImage else { return }
        
        let processedImage = self.image(byFiltering: CIImage(cgImage: cgImage))
        
        PHPhotoLibrary.requestAuthorization { (status) in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.creationRequestForAsset(from: processedImage)
            }) { (success, error) in
                if let error = error {
                    print("Error saving photo: \(error)")
                    return
                }
                DispatchQueue.main.async {
                    self.presentSuccessfulSaveAlert()
                }
            }
        }
	}
    
    private func presentSuccessfulSaveAlert() {
        let alert = UIAlertController(title: "Photo Saved!", message: "The photo has been saved to your Photo Library!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
	

	// MARK: Slider events
	
	@IBAction func brightnessChanged(_ sender: UISlider) {
        updateImage()
	}
	
	@IBAction func contrastChanged(_ sender: Any) {
        updateImage()
	}
	
	@IBAction func saturationChanged(_ sender: Any) {
        updateImage()
	}
    @IBAction func blurChanged(_ sender: Any) {
        updateImage()
    }
    
}

extension PhotoFilterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.editedImage] as? UIImage {
            originalImage = image
        } else if let image = info[.originalImage] as? UIImage {
            originalImage = image
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

