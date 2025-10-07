import Foundation
import Capacitor
import UIKit
import MapKit

@objc(KenziGoogleNavigationPlugin)
public class KenziGoogleNavigationPlugin: CAPPlugin {

    @objc public func initialize(_ call: CAPPluginCall) {
        call.resolve(["ok": true])
    }

    @objc public func startNavigation(_ call: CAPPluginCall) {
        guard
            let destLat = call.getDouble("destLat"),
            let destLng = call.getDouble("destLng")
        else {
            call.reject("destLat and destLng are required")
            return
        }

        let originLat = call.getDouble("originLat") ?? 0
        let originLng = call.getDouble("originLng") ?? 0
        let showHeader = call.getBool("showHeader", true)
        let logoUrl = call.getString("logoUrl") ?? ""
        let simulate = call.getBool("simulate", false)

        DispatchQueue.main.async { [weak self] in
            guard let presenter = self?.bridge?.viewController else {
                call.reject("No presenting view controller")
                return
            }

            let vc = NavigationViewController()
            vc.origin = CLLocationCoordinate2D(latitude: originLat, longitude: originLng)
            vc.destination = CLLocationCoordinate2D(latitude: destLat, longitude: destLng)
            vc.showHeader = showHeader
            vc.logoUrl = logoUrl
            vc.simulate = simulate
            vc.modalPresentationStyle = .fullScreen

            presenter.present(vc, animated: true)
            call.resolve(["started": true])
        }
    }
}
