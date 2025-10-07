import Foundation
import Capacitor
import MapKit
import UIKit

@objc(KenziGoogleNavigationPlugin)
public class KenziGoogleNavigationPlugin: CAPPlugin {
    private var apiKey: String?
    private weak var navVC: NavigationViewController?

    @objc func initialize(_ call: CAPPluginCall) {
        self.apiKey = call.getString("iosApiKey")
        call.resolve()
    }

    @objc func isGoogleMapsInstalled(_ call: CAPPluginCall) {
        let can = UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!)
        call.resolve(["installed": can])
    }

    // -- helpers to read coords in multiple shapes --
    private func readLatLng(_ obj: JSObject?) -> CLLocationCoordinate2D? {
        guard let o = obj else { return nil }
        if let lat = o["lat"] as? Double, let lng = o["lng"] as? Double {
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        if let lat = o["latitude"] as? Double, let lng = o["longitude"] as? Double {
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        return nil
    }
    private func readWaypoint(from any: Any) -> CLLocationCoordinate2D? {
        if let o = any as? JSObject {
            return readLatLng(o)
        }
        if let arr = any as? [Any], arr.count >= 2,
           let lat = arr[0] as? Double, let lng = arr[1] as? Double {
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        return nil
    }

    @objc func startNavigation(_ call: CAPPluginCall) {
        // ---- Input compatibility layer ----
        // 1) Structured: { destination:{lat,lng}, origin:{lat,lng} }
        // 2) Flat: { destLat, destLng, originLat, originLng }
        // Extras we accept: title, travelMode|mode, preferGoogleMaps|preferGoogle, simulate (ignored)

        // destination
        var destCoord: CLLocationCoordinate2D?
        if let destObj = call.getObject("destination") {
            destCoord = readLatLng(destObj)
        }
        if destCoord == nil {
            if let dlat = call.getDouble("destLat"), let dlng = call.getDouble("destLng") {
                destCoord = CLLocationCoordinate2D(latitude: dlat, longitude: dlng)
            }
        }
        guard let destination = destCoord else {
            call.reject("destination is required (use { destination:{lat,lng} } or { destLat, destLng })")
            return
        }

        // origin (optional)
        var originCoord: CLLocationCoordinate2D?
        if let originObj = call.getObject("origin") {
            originCoord = readLatLng(originObj)
        }
        if originCoord == nil {
            if let olat = call.getDouble("originLat"), let olng = call.getDouble("originLng") {
                originCoord = CLLocationCoordinate2D(latitude: olat, longitude: olng)
            }
        }

        // waypoints (accept various shapes)
        var waypoints: [CLLocationCoordinate2D] = []
        if let wpAny = call.getArray("waypoints") {
            waypoints = wpAny.compactMap { readWaypoint(from: $0) }
        }

        let mode = (call.getString("travelMode") ?? call.getString("mode") ?? "driving").lowercased()
        let title = call.getString("title") ?? "Navigation"
        let preferGoogle = call.getBool("preferGoogleMaps") ?? call.getBool("preferGoogle") ?? true
        _ = call.getBool("simulate") // accepted but not used on iOS

        DispatchQueue.main.async {
            let vc = NavigationViewController(
                plugin: self,
                origin: originCoord,
                destination: destination,
                waypoints: waypoints,
                travelMode: mode,
                titleText: title,
                preferGoogle: preferGoogle
            )
            vc.modalPresentationStyle = .fullScreen
            self.bridge?.viewController?.present(vc, animated: true, completion: nil)
            self.navVC = vc
            call.resolve()
        }
    }

    @objc func close(_ call: CAPPluginCall) {
        dismiss(reason: "programmatic")
        call.resolve()
    }

    // MARK: - helpers
    func dismiss(reason: String) {
        DispatchQueue.main.async {
            if let presented = self.navVC {
                presented.dismiss(animated: true, completion: nil)
                self.navVC = nil
                self.notifyListeners("navigationClosed", data: ["reason": reason])
            }
        }
    }

    func notifyLaunched(app: String) {
        self.notifyListeners("navigationLaunched", data: ["app": app])
    }

    // Build comgooglemaps:// URL with optional origin & waypoints
    func googleMapsURL(origin: CLLocationCoordinate2D?, destination: CLLocationCoordinate2D, waypoints: [CLLocationCoordinate2D], mode: String) -> URL? {
        var comps = URLComponents(string: "comgooglemaps://")!
        var items: [URLQueryItem] = []
        if let o = origin {
            items.append(URLQueryItem(name: "saddr", value: "\(o.latitude),\(o.longitude)"))
        }
        items.append(URLQueryItem(name: "daddr", value: "\(destination.latitude),\(destination.longitude)"))
        let m = (mode == "walking" ? "walking" : mode == "transit" ? "transit" : "driving")
        items.append(URLQueryItem(name: "directionsmode", value: m))
        if !waypoints.isEmpty {
            let wp = waypoints.map { "\($0.latitude),\($0.longitude)" }.joined(separator: "|")
            items.append(URLQueryItem(name: "waypoints", value: wp))
        }
        comps.queryItems = items
        return comps.url
    }

    // Apple Maps launch with MKMapItems (supports multi-stop)
    func openInAppleMaps(origin: CLLocationCoordinate2D?, destination: CLLocationCoordinate2D,
                     waypoints: [CLLocationCoordinate2D], mode: String) {

    var items: [MKMapItem] = []

    if let o = origin {
        items.append(MKMapItem(placemark: MKPlacemark(coordinate: o)))
    } else {
        // ensure Maps opens directions, not just the POI
        items.append(MKMapItem.forCurrentLocation())
    }

    for w in waypoints {
        items.append(MKMapItem(placemark: MKPlacemark(coordinate: w)))
    }

    items.append(MKMapItem(placemark: MKPlacemark(coordinate: destination)))

    var opts: [String: Any] = [:]
    let m = (mode == "walking" ? MKLaunchOptionsDirectionsModeWalking :
             mode == "transit"  ? MKLaunchOptionsDirectionsModeTransit :
                                  MKLaunchOptionsDirectionsModeDriving)
    opts[MKLaunchOptionsDirectionsModeKey] = m

    MKMapItem.openMaps(with: items, launchOptions: opts)
    notifyLaunched(app: "apple")
}

    func openInGoogleMaps(origin: CLLocationCoordinate2D?, destination: CLLocationCoordinate2D, waypoints: [CLLocationCoordinate2D], mode: String) {
        guard let url = googleMapsURL(origin: origin, destination: destination, waypoints: waypoints, mode: mode) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        notifyLaunched(app: "google")
    }
}
