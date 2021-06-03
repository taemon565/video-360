///// Copyright (c) 2017 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import GLKit
import CoreMotion

class VideoViewController: GLKViewController {
  var renderer: Renderer?
  var videoPlayer: VideoPlayer?
  let motionManager = CMMotionManager()
  
  private var rotationX: Float = 0.0
  private var rotationY: Float = 0.0
  @IBOutlet weak var startButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    setupRenderer()
    setupVideoPlayer()
    setupGesture()
    delegate = self
  }
  
  private func setupRenderer() {
    if let context = EAGLContext(api: .openGLES3) {
      EAGLContext.setCurrent(context)
      let glkView = view as! GLKView
      glkView.context = context
      let shader = Shader()
      let model = Sphere()
      renderer = Renderer(context: context, shader: shader, model: model)
    }
  }
  
  private func setupVideoPlayer() {
    if let path = Bundle.main.path(forResource: "Sample", ofType: "qt") {
      let url = URL(fileURLWithPath: path)
      videoPlayer = VideoPlayer(url: url, framesPerSecond: framesPerSecond)
      videoPlayer?.play()
    }
  }
  
  override func glkView(_ view: GLKView, drawIn rect: CGRect) {
    // Retrieve the video pixel buffer
    guard let pixelBufer = videoPlayer?.retrievePixelBuffer() else { return }
    // Update the OpenGL ES texture by using the current video pixel buffer
    renderer?.updateTexture(pixelBufer)
    renderer?.render()
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {    
    let radiansPerPoint: Float = 0.005
    let touch = touches.first!
    let location = touch.location(in: touch.view)
    let previousLocation = touch.previousLocation(in: touch.view)
    var diffX = Float(location.x - previousLocation.x)
    var diffY = Float(location.y - previousLocation.y)
    
    diffX *= -radiansPerPoint
    diffY *= -radiansPerPoint
    rotationX += diffY
    rotationY += diffX
  }
  
  private func setupGesture() {
    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
    doubleTap.numberOfTapsRequired = 2
    view.addGestureRecognizer(doubleTap)
  }
  
  @objc func doubleTap() {
    rotationX = 0
    rotationY = 0
  }
  
  @IBAction func changeStateTapped(_ sender: UIButton) {
    
    if sender.titleLabel?.text == "start" {
      motionManager.gyroUpdateInterval = 1/60
      
      motionManager.startGyroUpdates(to: OperationQueue.current!) { (data, error) in
        if let data = data {
          if data.rotationRate.y > 0.1 || data.rotationRate.y < -0.1 {
              self.rotationX += Float(data.rotationRate.y)/50
          }
          if data.rotationRate.x > 0.1 || data.rotationRate.x < -0.1 {
              self.rotationY += -Float(data.rotationRate.x)/50
          }
          
          print(data.rotationRate.y)
        }
      }
    } else {
      motionManager.stopGyroUpdates()
    }
    
    let title = sender.titleLabel?.text == "start" ? "stop" : "start"
    startButton.setAttributedTitle(NSAttributedString(string: title), for: .normal)
  }
  
}

// MARK: - GLKViewControllerDelegate
extension VideoViewController: GLKViewControllerDelegate {
  func glkViewControllerUpdate(_ controller: GLKViewController) {
    // Update the model view projection matrix
    renderer?.updateModelViewProjectionMatrix(rotationX, rotationY)
  }
}
