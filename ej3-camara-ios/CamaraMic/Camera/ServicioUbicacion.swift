import CoreLocation

/// Obtiene la ubicación para guardarla como metadato. Es opcional: si el
/// usuario no da permiso, las capturas se guardan sin ubicación.
final class ServicioUbicacion: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let gestor = CLLocationManager()
    @Published private(set) var ultima: CLLocation?

    override init() {
        super.init()
        gestor.delegate = self
        gestor.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func actualizar() {
        switch gestor.authorizationStatus {
        case .notDetermined: gestor.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: gestor.requestLocation()
        default: break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async { self.ultima = locations.last }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Sin ubicación no es un error para el usuario: el metadato queda vacío.
    }
}
