//
//  DirectionsController.swift
//  MapsDirectionsGooglePlaces_LBTA
//
//  Created by Brian Voong on 11/9/19.
//  Copyright © 2019 Brian Voong. All rights reserved.
//

import UIKit
import LBTATools
import MapKit
import SwiftUI
import JGProgressHUD

class DirectionsController: UIViewController {
    
    let mapView = MKMapView()
    
    let navBar = UIView(backgroundColor: #colorLiteral(red: 0.2587935925, green: 0.5251715779, blue: 0.9613835216, alpha: 1))
    let startTextField = IndentedTextField(padding: 12, cornerRadius: 5)
    let endTextField = IndentedTextField(padding: 12, cornerRadius: 5)
    
    var startMapItem: MKMapItem?
    var endMapItem: MKMapItem?
    
    var currentlyShowingRoute: MKRoute?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mapView)
        setupNavBarUI()
        setupMapView()
        setupRegionForMap() // San Francisco
        setupRouteButton()
    }
    
    private func setupRouteButton() {
        let routeButton = UIButton(title: "Route", titleColor: .black, font: .boldSystemFont(ofSize: 16), backgroundColor: .white, target: self, action: #selector(handleShowRoute))
        view.addSubview(routeButton)
        routeButton.layer.opacity = 0.8
        routeButton.layer.cornerRadius = 5
        routeButton.setupShadow(opacity: 0.2, radius: 5)
        routeButton.anchor(top: nil, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor, padding: .allSides(16), size: .init(width: 0, height: 50))
    }
    
    @objc private func handleShowRoute() {
        let routeViewController = RouteViewController()
        routeViewController.route = currentlyShowingRoute
        routeViewController.items = currentlyShowingRoute?.steps.filter({!$0.instructions.isEmpty}) ?? [] // filter empty rows
        present(routeViewController, animated: true)
    }
    
    private func setupMapView() {
        mapView.anchor(top: navBar.bottomAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        mapView.showsUserLocation = true
        mapView.delegate = self
    }

    private func requestForDirections() {
        
        let request = MKDirections.Request()
        request.source = startMapItem
        request.destination = endMapItem
        
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Routing..."
        hud.show(in: view)
        
            let directions = MKDirections(request: request)
            directions.calculate { (resp, err) in
                
                hud.dismiss()
                
                if let err = err {
                    print("Failed to find routing info:", err)
                    return
                }
                
                // success
                if let firstRoute = resp?.routes.first {
                    self.mapView.addOverlay(firstRoute.polyline)
                }
                
                self.currentlyShowingRoute = resp?.routes.first
            }
    }
    
    private func setupNavBarUI() {
        view.addSubview(navBar)
        navBar.setupShadow(opacity: 0.5, radius: 5)
        navBar.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: -120, right: 0))
        
        startTextField.attributedPlaceholder = .init(string: "Start", attributes: [.foregroundColor: UIColor.init(white: 1, alpha: 0.7)])
        
        endTextField.attributedPlaceholder = .init(string: "End", attributes: [.foregroundColor: UIColor.init(white: 1, alpha: 0.7)])
        
        [startTextField, endTextField].forEach { (tf) in
            tf.backgroundColor = .init(white: 1, alpha: 0.3)
            tf.textColor = .white
        }
        
        let containerView = UIView(backgroundColor: .clear)
        navBar.addSubview(containerView)
        containerView.fillSuperviewSafeAreaLayoutGuide()
        
        
        let startIcon = UIImageView(image: #imageLiteral(resourceName: "start_location_circles"), contentMode: .scaleAspectFit)
        startIcon.constrainWidth(20)
        
        let endIcon = UIImageView(image: #imageLiteral(resourceName: "annotation_icon").withRenderingMode(.alwaysTemplate), contentMode: .scaleAspectFit)
        endIcon.constrainWidth(20)
        endIcon.tintColor = .white
        
        containerView.stack(
            containerView.hstack(startIcon, startTextField, spacing: 16),
            containerView.hstack(endIcon, endTextField, spacing: 16),
                            spacing: 12,
                            distribution: .fillEqually)
            .withMargins(.init(top: 0, left: 16, bottom: 12, right: 16))
        
        startTextField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleChangeStartLocation)))
        
        endTextField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleChangeEndLocation)))
        
        navigationController?.navigationBar.isHidden = true
    }
    
    @objc private func handleChangeStartLocation() {
        let vc = LocationSearchController()
        vc.selectionHandler = { [weak self] mapItem in
            self?.startTextField.text = mapItem.name
            
            // add starting annotaton and show it on the map
            self?.startMapItem = mapItem
            self?.refreshMap()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func handleChangeEndLocation() {
        let vc = LocationSearchController()
        vc.selectionHandler = { [weak self] mapItem in
            self?.endTextField.text = mapItem.name
            
            // add ending annotation and show it on the map
            self?.endMapItem = mapItem
            self?.refreshMap()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func refreshMap() {
        mapView.removeAnnotations(mapView.annotations) // remove old annotation
        mapView.removeOverlays(mapView.overlays) // remove old route
        
        if let mapItem = startMapItem {
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapItem.placemark.coordinate
            annotation.subtitle = mapItem.name
            mapView.addAnnotation(annotation)
        }
        
        if let mapItem = endMapItem {
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapItem.placemark.coordinate
            annotation.subtitle = mapItem.name
            mapView.addAnnotation(annotation)
        }
        requestForDirections()
        mapView.showAnnotations(mapView.annotations, animated: false)
    }
    
    private func setupRegionForMap() {
        let centerCoordinate = CLLocationCoordinate2D(latitude: 37.7666, longitude: -122.427290)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}

extension DirectionsController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRenderer.strokeColor = #colorLiteral(red: 0.2587935925, green: 0.5251715779, blue: 0.9613835216, alpha: 1)
        polylineRenderer.lineWidth = 5
        return polylineRenderer
    }
}

// MARK: - SwiftUI Preview

struct DirectionsPreview: PreviewProvider {
    
    static var previews: some View {
        ContainerView().edgesIgnoringSafeArea(.all)
    }
    
    struct ContainerView: UIViewControllerRepresentable {
        
        func makeUIViewController(context: UIViewControllerRepresentableContext<DirectionsPreview.ContainerView>) -> UIViewController {
            return UINavigationController(rootViewController: DirectionsController())
        }
        
        func updateUIViewController(_ uiViewController: DirectionsPreview.ContainerView.UIViewControllerType, context: UIViewControllerRepresentableContext<DirectionsPreview.ContainerView>) {
            
        }
    }
}
