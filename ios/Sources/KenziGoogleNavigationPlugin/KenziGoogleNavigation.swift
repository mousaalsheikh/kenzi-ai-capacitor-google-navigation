import UIKit
import MapKit

final class NavigationViewController: UIViewController, MKMapViewDelegate {

    // inputs from the plugin
    var origin: CLLocationCoordinate2D?
    var destination: CLLocationCoordinate2D!
    var showHeader: Bool = true
    var logoUrl: String = ""
    var simulate: Bool = false  // (not used with Apple Maps embedded)

    // UI
    private let mapView = MKMapView()
    private let headerView = UIView()
    private let logoView = UIImageView()
    private let closeButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupMap()
        if showHeader { setupHeader() }
        plotRoute()
    }

    private func setupMap() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)

        if showHeader {
            NSLayoutConstraint.activate([
                mapView.topAnchor.constraint(equalTo: view.topAnchor),
                mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        } else {
            mapView.frame = view.bounds
            mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }

    private func setupHeader() {
        headerView.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        // Pin to the safe area
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Logo
        if let url = URL(string: logoUrl), !logoUrl.isEmpty {
            logoView.contentMode = .scaleAspectFit
            logoView.clipsToBounds = true
            logoView.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(logoView)
            loadLogo(from: url)

            NSLayoutConstraint.activate([
                logoView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 12),
                logoView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                logoView.heightAnchor.constraint(equalToConstant: 36),
                logoView.widthAnchor.constraint(lessThanOrEqualTo: headerView.widthAnchor, multiplier: 0.5)
            ])
        }

        // Close button
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        headerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -12),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            closeButton.widthAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func loadLogo(from url: URL) {
        // simple loader (no caching lib needed)
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async { self.logoView.image = image }
            }
        }
    }

    private func plotRoute() {
        let req = MKDirections.Request()

        if let o = origin, o.latitude != 0, o.longitude != 0 {
            req.source = MKMapItem(placemark: MKPlacemark(coordinate: o))
        } else {
            req.source = MKMapItem.forCurrentLocation()
        }

        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        req.transportType = .automobile
        req.requestsAlternateRoutes = false

        let dir = MKDirections(request: req)
        dir.calculate { [weak self] res, err in
            guard let self = self, let route = res?.routes.first else { return }
            self.mapView.addOverlay(route.polyline)
            let pad = UIEdgeInsets(top: 80, left: 40, bottom: 60, right: 40)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: pad, animated: true)
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else { return MKOverlayRenderer() }
        let r = MKPolylineRenderer(polyline: polyline)
        r.strokeColor = .systemBlue
        r.lineWidth = 6
        return r
    }
}
