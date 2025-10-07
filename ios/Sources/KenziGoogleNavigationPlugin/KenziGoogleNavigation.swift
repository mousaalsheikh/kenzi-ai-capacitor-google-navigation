import UIKit
import MapKit
import Capacitor

class NavigationViewController: UIViewController, MKMapViewDelegate {
    weak var plugin: KenziGoogleNavigationPlugin?

    private let origin: CLLocationCoordinate2D?
    private let destination: CLLocationCoordinate2D
    private let waypoints: [CLLocationCoordinate2D]
    private let travelMode: String
    private let titleText: String
    private let preferGoogle: Bool

    private let mapView = MKMapView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let summaryLabel = UILabel()
    private let googleButton = UIButton(type: .system)
    private let appleButton = UIButton(type: .system)

    init(plugin: KenziGoogleNavigationPlugin,
         origin: CLLocationCoordinate2D?,
         destination: CLLocationCoordinate2D,
         waypoints: [CLLocationCoordinate2D],
         travelMode: String,
         titleText: String,
         preferGoogle: Bool) {
        self.plugin = plugin
        self.origin = origin
        self.destination = destination
        self.waypoints = waypoints
        self.travelMode = travelMode
        self.titleText = titleText
        self.preferGoogle = preferGoogle
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        renderRoutePreview()
    }

    private func setupUI() {
    // Header bar
    let headerBar = UIView()
    headerBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(headerBar)

    // Title
    titleLabel.text = titleText
    titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
    titleLabel.textColor = .label
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    headerBar.addSubview(titleLabel)

    // X button (plain, black) — iOS 13+ safe
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    if let img = UIImage(systemName: "xmark") {
        closeButton.setImage(img, for: .normal)
        closeButton.setTitle(nil, for: .normal)
        closeButton.imageView?.contentMode = .scaleAspectFit
    } else {
        // fallback if SF Symbols unavailable
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
    }
    closeButton.tintColor = .label
    closeButton.setTitleColor(.label, for: .normal)
    closeButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    headerBar.addSubview(closeButton)

    // Add the rest to the view
    [mapView, summaryLabel, googleButton, appleButton].forEach {
        $0.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview($0)
    }

    summaryLabel.text = "Calculating route…"
    summaryLabel.numberOfLines = 0
    summaryLabel.textAlignment = .center
    summaryLabel.textColor = .secondaryLabel

    googleButton.setTitle("Start in Google Maps", for: .normal)
    googleButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    googleButton.layer.cornerRadius = 12
    googleButton.layer.borderWidth = 1
    googleButton.layer.borderColor = UIColor.separator.cgColor
    googleButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    googleButton.addTarget(self, action: #selector(startGoogle), for: .touchUpInside)

    appleButton.setTitle("Start in Apple Maps", for: .normal)
    appleButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    appleButton.layer.cornerRadius = 12
    appleButton.backgroundColor = .label
    appleButton.setTitleColor(.systemBackground, for: .normal)
    appleButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    appleButton.addTarget(self, action: #selector(startApple), for: .touchUpInside)

    // Layout
    NSLayoutConstraint.activate([
        headerBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        headerBar.heightAnchor.constraint(equalToConstant: 44),

        titleLabel.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 16),
        titleLabel.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),

        closeButton.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor, constant: -16),
        closeButton.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
        closeButton.widthAnchor.constraint(equalToConstant: 32),
        closeButton.heightAnchor.constraint(equalToConstant: 32),

        mapView.topAnchor.constraint(equalTo: headerBar.bottomAnchor, constant: 8),
        mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

        summaryLabel.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 12),
        summaryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        summaryLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

        googleButton.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 12),
        googleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        googleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

        appleButton.topAnchor.constraint(equalTo: googleButton.bottomAnchor, constant: 10),
        appleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        appleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        appleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

        mapView.heightAnchor.constraint(greaterThanOrEqualToConstant: 240)
    ])

    // Google availability + primary styling
    let gmAvailable = UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!)
    googleButton.isEnabled = gmAvailable
    googleButton.alpha = gmAvailable ? 1.0 : 0.5

    if preferGoogle && gmAvailable {
        appleButton.layer.borderWidth = 1
        appleButton.layer.borderColor = UIColor.separator.cgColor
        appleButton.backgroundColor = .clear
        appleButton.setTitleColor(.label, for: .normal)

        googleButton.backgroundColor = .label
        googleButton.setTitleColor(.systemBackground, for: .normal)
    }
}


    private func renderRoutePreview() {
        mapView.delegate = self
        mapView.showsCompass = true
        mapView.pointOfInterestFilter = .includingAll

        // Pins
        if let o = origin {
            let ann = MKPointAnnotation()
            ann.coordinate = o
            ann.title = "Origin"
            mapView.addAnnotation(ann)
        }
        for (i, w) in waypoints.enumerated() {
            let ann = MKPointAnnotation()
            ann.coordinate = w
            ann.title = "Stop \(i+1)"
            mapView.addAnnotation(ann)
        }
        let destAnn = MKPointAnnotation()
        destAnn.coordinate = destination
        destAnn.title = "Destination"
        mapView.addAnnotation(destAnn)

        // Route (simple: origin→destination; waypoints are for launch)
        let req = MKDirections.Request()
        if let o = origin {
            req.source = MKMapItem(placemark: MKPlacemark(coordinate: o))
        } else {
            // if origin not provided, use current user location if available
            mapView.showsUserLocation = true
            if let loc = mapView.userLocation.location?.coordinate {
                req.source = MKMapItem(placemark: MKPlacemark(coordinate: loc))
            }
        }
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        switch travelMode {
            case "walking": req.transportType = .walking
            case "transit":  req.transportType = .transit
            default:         req.transportType = .automobile
        }

        MKDirections(request: req).calculate { [weak self] response, error in
            guard let self = self else { return }
            if let r = response?.routes.first {
                self.mapView.addOverlay(r.polyline)
                self.mapView.setVisibleMapRect(r.polyline.boundingMapRect,
                                               edgePadding: UIEdgeInsets(top: 40, left: 24, bottom: 200, right: 24),
                                               animated: true)
                let distKM = r.distance / 1000.0
                let mins = Int(ceil(r.expectedTravelTime / 60.0))
                self.summaryLabel.text = String(format: "Distance: %.1f km • ETA: %d min", distKM, mins)
            } else {
                self.summaryLabel.text = "Route preview unavailable."
            }
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        plugin?.dismiss(reason: "user")
    }

    @objc private func startGoogle() {
        plugin?.openInGoogleMaps(origin: origin, destination: destination, waypoints: waypoints, mode: travelMode)
        plugin?.dismiss(reason: "launch")
    }

    @objc private func startApple() {
        plugin?.openInAppleMaps(origin: origin, destination: destination, waypoints: waypoints, mode: travelMode)
        plugin?.dismiss(reason: "launch")
    }

    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let r = MKPolylineRenderer(overlay: overlay)
        r.lineWidth = 4
        r.strokeColor = .systemBlue
        return r
    }
}
