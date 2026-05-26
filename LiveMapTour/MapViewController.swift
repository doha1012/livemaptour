import UIKit
import MapKit
import CoreLocation
import WebKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    var mapView: MKMapView!
    var popupPlayerView: VideoPopupView?
    var activeAnnotation: MKPointAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "LiveMap Tour"
        self.view.backgroundColor = .systemBackground
        
        mapView = MKMapView(frame: self.view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        self.view.addSubview(mapView)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let touchPoint = gesture.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        if let active = activeAnnotation {
            mapView.removeAnnotation(active)
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        activeAnnotation = annotation
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 🚀 터치 물결 파동 효과 추가
        let ripple = RipplePulseView(centerPoint: touchPoint)
        mapView.addSubview(ripple)
        
        // 🚀 즉시 스켈레톤 로딩 팝업 표출
        presentPopupPlayer(with: nil)
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "ko_KR")) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                self.popupPlayerView?.dismissCleanly()
                if let clError = error as? CLError, clError.code == .network {
                    self.showNetworkErrorAlert()
                } else {
                    self.showErrorAlert()
                }
                return
            }
            
            guard let placemark = placemarks?.first else {
                self.popupPlayerView?.dismissCleanly()
                self.showErrorAlert()
                return
            }
            
            let country = placemark.country ?? ""
            let city = placemark.locality ?? placemark.administrativeArea ?? ""
            let subLocality = placemark.subLocality ?? ""
            
            var addressParts: [String] = []
            if !country.isEmpty { addressParts.append(country) }
            if !city.isEmpty { addressParts.append(city) }
            if !subLocality.isEmpty { addressParts.append(subLocality) }
            
            let address = addressParts.joined(separator: " ")
            
            if address.isEmpty || (country.isEmpty && city.isEmpty) {
                self.popupPlayerView?.dismissCleanly()
                self.showErrorAlert()
                return
            }
            
            let searchQuery = "\(city.isEmpty ? country : city) walking tour vlog"
            
            TourRepository.shared.findDynamicTour(forAddress: address, query: searchQuery, coordinate: coordinate) { [weak self] tour in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let tour = tour {
                        // 🚀 로드 완료 시 스켈레톤 뷰에 데이터 주입하여 콘텐츠 노출
                        self.popupPlayerView?.configure(with: tour)
                    } else {
                        self.popupPlayerView?.dismissCleanly()
                        self.showNoVideoAlert()
                    }
                }
            }
        }
    }
    
    func presentPopupPlayer(with item: TourItem?) {
        popupPlayerView?.dismissCleanly()
        
        let popup = VideoPopupView(tourItem: item)
        self.popupPlayerView = popup
        PopupPresentationManager.shared.present(popup, in: self.view, safeAreaGuide: self.view.safeAreaLayoutGuide)
    }
    
    func showErrorAlert() {
        if let active = activeAnnotation {
            mapView.removeAnnotation(active)
            activeAnnotation = nil
        }
        
        let alert = UIAlertController(
            title: "안내",
            message: "🌊 해당 위치는 생생한 영상을 찾을 수 없는 영역(바다 또는 무인도 등)입니다. 다른 멋진 도시나 관광 명소 위를 길게 눌러 여행을 떠나보세요!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showNetworkErrorAlert() {
        if let active = activeAnnotation {
            mapView.removeAnnotation(active)
            activeAnnotation = nil
        }
        
        let alert = UIAlertController(
            title: "안내",
            message: "네트워크 연결이 원활하지 않거나 요청 제한에 도달했습니다. 네트워크 설정을 확인한 다음 다시 시도해 주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showNoVideoAlert() {
        let alert = UIAlertController(
            title: "안내",
            message: "해당 위치의 유튜브 영상을 찾을 수 없습니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - MKMapViewDelegate - Premium Custom Annotation Pin View
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        
        let identifier = "CustomTourPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = false
            
            // Custom premium styling (rounded white circle with blue border)
            let size: CGFloat = 36
            let container = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
            container.backgroundColor = .white
            container.layer.cornerRadius = size / 2
            container.layer.borderWidth = 3
            container.layer.borderColor = UIColor.systemBlue.cgColor
            
            // Shadow for card feeling
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowOpacity = 0.25
            container.layer.shadowOffset = CGSize(width: 0, height: 4)
            container.layer.shadowRadius = 4
            container.layer.masksToBounds = false
            
            // Icon in center
            let iconView = UIImageView(frame: CGRect(x: 6, y: 6, width: 24, height: 24))
            iconView.image = UIImage(systemName: "mappin.circle.fill")
            iconView.tintColor = .systemBlue
            iconView.contentMode = .scaleAspectFit
            container.addSubview(iconView)
            
            annotationView?.addSubview(container)
            annotationView?.frame = container.frame
            
            // Center offset so it anchors correctly
            annotationView?.centerOffset = CGPoint(x: 0, y: -size / 2)
        } else {
            annotationView?.annotation = annotation
        }
        
        // Animate appearance
        annotationView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
            annotationView?.transform = .identity
        }, completion: nil)
        
        return annotationView
    }
}

