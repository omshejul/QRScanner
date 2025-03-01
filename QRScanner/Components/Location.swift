//
//  Location.swift
//  QRScanner
//
//  Created by Om Shejul on 01/03/25.
//

import SwiftUI
import MapKit
import CoreLocation


// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private(set) var locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var isAuthorized = false
    @Published var isLoading = false
    private var locationTimer: Timer?
    private var hasInitializedLocationServices = false
    @Published var didChangeAuthorizationStatus = false
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // Less accurate but faster
        // Check current authorization status without requesting
        updateAuthorizationStatus()
    }
    
    private func updateAuthorizationStatus() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }
    
    func checkLocationAuthorization() {
        updateAuthorizationStatus()
        
        // Only request authorization if not determined yet
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let oldAuthStatus = isAuthorized
        updateAuthorizationStatus()
        
        // If authorization status changed from unauthorized to authorized,
        // automatically request location
        if !oldAuthStatus && isAuthorized {
            didChangeAuthorizationStatus = true
            requestLocation()
        }
    }
    
    func requestLocation() {
        // Initialize location services if not already done
        if !hasInitializedLocationServices {
            hasInitializedLocationServices = true
            checkLocationAuthorization()
        }
        
        // Only proceed if authorized
        guard isAuthorized else {
            // If not authorized, request authorization
            checkLocationAuthorization()
            return
        }
        
        isLoading = true
        
        // If we already have a location, use it immediately
        if let existingLocation = locationManager.location {
            self.location = existingLocation
            isLoading = false
            return
        }
        
        // Cancel any existing timer
        locationTimer?.invalidate()
        
        // Start continuous updates for faster response
        locationManager.startUpdatingLocation()
        
        // Set a timeout to ensure we don't wait forever
        locationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // If we still don't have a location after timeout, use whatever we have
            if self.location == nil {
                self.location = self.locationManager.location
                self.locationManager.stopUpdatingLocation()
                self.isLoading = false
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        
        // Stop updates once we get a location
        locationManager.stopUpdatingLocation()
        locationTimer?.invalidate()
        isLoading = false
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        // Even on error, use whatever location we might have
        self.location = locationManager.location
        locationManager.stopUpdatingLocation()
        locationTimer?.invalidate()
        isLoading = false
    }
}

// MARK: - Map View
struct LocationMapView: View {
    @StateObject private var locationManager = LocationManager()
    @Binding var latitude: String
    @Binding var longitude: String
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
    )
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var annotations: [MapPin] = []
    @State private var showUserLocation = false
    @State private var hasRequestedLocation = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if locationManager.isLoading {
                    ProgressView("Getting your location...")
                        .padding()
                } else {
                    // Use a custom map view that can handle taps properly
                    TappableMapView(
                        region: $region,
                        selectedLocation: $selectedLocation,
                        annotations: $annotations,
                        showUserLocation: showUserLocation
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    if let selectedLocation = selectedLocation {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Selected Location:")
                                .font(.headline)
                            Text("Latitude: \(String(format: "%.6f", selectedLocation.latitude))")
                            Text("Longitude: \(String(format: "%.6f", selectedLocation.longitude))")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                
                HStack {
                    Button(action: {
                        // Enable showing user location on map
                        showUserLocation = true
                        hasRequestedLocation = true
                        
                        // Request location
                        locationManager.requestLocation()
                    }) {
                        Label("My Location", systemImage: "location.fill")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(locationManager.isLoading)
                    
                    Spacer()
                    
                    Button(action: {
                        if let location = selectedLocation {
                            latitude = String(format: "%.6f", location.latitude)
                            longitude = String(format: "%.6f", location.longitude)
                            dismiss()
                        }
                    }) {
                        Label("Use This Location", systemImage: "checkmark.circle.fill")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(selectedLocation == nil)
                }
                .padding()
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // If coordinates are already entered, center the map there
                if let lat = Double(latitude), let lon = Double(longitude),
                   (-90...90).contains(lat), (-180...180).contains(lon) {
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    selectedLocation = coordinate
                    region = MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                    // Set initial annotation
                    annotations = [MapPin(coordinate: coordinate)]
                } else {
                    // Set a world view with maximum zoom out
                    region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                        span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
                    )
                }
            }
            .onChange(of: locationManager.location) { oldValue, newValue in
                if let location = newValue, hasRequestedLocation {
                    // When location becomes available after user request, automatically use it
                    showUserLocation = true
                    selectedLocation = location.coordinate
                    region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                    // Update annotations
                    annotations = [MapPin(coordinate: location.coordinate)]
                }
            }
            .onChange(of: locationManager.didChangeAuthorizationStatus) {
                if locationManager.isAuthorized && hasRequestedLocation {
                    // If authorization status just changed to authorized after user request,
                    // show user location
                    showUserLocation = true
                }
            }
        }
    }
}

// Custom pin for map annotations
struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// A UIViewRepresentable for a tappable map
struct TappableMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var annotations: [MapPin]
    var showUserLocation: Bool = false
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Completely disable user tracking and location display initially
        mapView.showsUserLocation = false
        mapView.userTrackingMode = .none
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Only set the region if it's significantly different from the current region
        // This prevents overriding the zoom level set by the tap handler
        let currentRegion = mapView.region
        let newRegion = region
        
        // Check if we need to update the region (significant change in center or first load)
        let centerChanged = abs(currentRegion.center.latitude - newRegion.center.latitude) > 0.01 ||
                           abs(currentRegion.center.longitude - newRegion.center.longitude) > 0.01
        
        if centerChanged {
            // Preserve the current zoom level (span) if possible
            let span = mapView.region.span
            let updatedRegion = MKCoordinateRegion(
                center: newRegion.center,
                span: span.latitudeDelta < 1.0 ? span : newRegion.span
            )
            mapView.setRegion(updatedRegion, animated: true)
        }
        
        // Update user location display
        mapView.showsUserLocation = showUserLocation
        
        // Update annotations
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        
        let newAnnotations = annotations.map { pin -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinate
            annotation.title = "Selected Location"
            return annotation
        }
        
        mapView.addAnnotations(newAnnotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TappableMapView
        
        init(_ parent: TappableMapView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // Update the selected location
            parent.selectedLocation = coordinate
            
            // Update the annotations
            parent.annotations = [MapPin(coordinate: coordinate)]
            
            // Update the region to center on the tapped location
            parent.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        
        // Customize the annotation view
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "CustomPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Customize the pin
            if let markerView = annotationView as? MKMarkerAnnotationView {
                markerView.markerTintColor = .red
                markerView.glyphImage = UIImage(systemName: "mappin")
            }
            
            return annotationView
        }
    }
}