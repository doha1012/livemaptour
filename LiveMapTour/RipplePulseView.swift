import UIKit

class RipplePulseView: UIView {
    private let circleLayer = CAShapeLayer()
    
    init(centerPoint: CGPoint) {
        super.init(frame: CGRect(x: centerPoint.x - 40, y: centerPoint.y - 40, width: 80, height: 80))
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = false
        
        let circlePath = UIBezierPath(ovalIn: self.bounds)
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.6).cgColor
        circleLayer.lineWidth = 3
        circleLayer.position = CGPoint(x: 40, y: 40)
        circleLayer.bounds = self.bounds
        
        self.layer.addSublayer(circleLayer)
        
        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 0.1
        scaleAnim.toValue = 2.3
        
        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 1.0
        opacityAnim.toValue = 0.0
        
        let groupAnim = CAAnimationGroup()
        groupAnim.animations = [scaleAnim, opacityAnim]
        groupAnim.duration = 0.8
        groupAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        groupAnim.fillMode = .forwards
        groupAnim.isRemovedOnCompletion = false
        
        circleLayer.add(groupAnim, forKey: "ripple")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.removeFromSuperview()
        }
    }
}
