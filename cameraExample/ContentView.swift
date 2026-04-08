//
//  ContentView.swift
//  cameraExample
//
//  Created by MacBook on 06/07/2025.
//

import SwiftUI // Podstawowa biblioteka do tworzenia interfejsu
import Combine // Biblioteka do obsługi strumieni danych (używamy jej do migawki)



struct ContentView: View { // Definicja głównego widoku aplikacji
    
    @State private var selectedImage: UIImage? = nil //Przechowanie zdjec, ignoruj puste
    @State private var isPhotoLibraryPresented = false // zmienna sprawdza czy okno galeri jest otwarte
    @State private var showLightSettings = false //sprawdzam aktywnosc panelu do obslugi swiatla
    @State private var showSuccessStatus = false // Kontroluje tymczasowe wyświetlanie "Połączono"
    
    // Zarządzanie Bluetooth
    @StateObject var bleManager = BleManager() //instancja Bluetooth low manager
    
    // Wyzwalacz zdjęcia
    private let takePhotoTrigger = PassthroughSubject<Void, Never>() // kanal dla migawki

    var body: some View {
        ZStack { // warstwy logiki wertykalne
            // warstwa kamery
            CameraView(takePhotoTrigger: takePhotoTrigger)
                .ignoresSafeArea() // pelen zasieg ekranu dla widoku kamery

            VStack {
               
                HStack {//warstwy logiki horyzontalne
                    // warstwa logiki dla statusu polaczenia ble - chmurka
                    if !bleManager.isConnected || (bleManager.isConnected && showSuccessStatus) {//jesli ble nie polaczone lub polaczone i pokazuje status do 3 sekund - funkcja .onChange(of: bleManager.isConnected)
                        VStack(alignment: .leading, spacing: 4) {//warstwa pionowa dla wyswietlania od pozycji Text i Label
                            Text("Status połączenia:")
                                .font(.caption)                     //mala czcionk
                                .foregroundColor(.white.opacity(0.7)) //kolor czcionki bialy 0.7 przezroczystosc
                            
                            if bleManager.isConnected {     // Jeśli moduł Bluetooth potwierdza połączenie
                                // Label łączy tekst z ikoną systemową (checkmark w kółku)
                                // bleManager.connectedPeripheralName ?? "Ledy" - bierze nazwę urządzenia, a jeśli jej nie ma, wpisuje "Ledy"
                                Label(bleManager.connectedPeripheralName ?? "Ledy", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)    // Kolor zielony dla aktywnego połączenia
                                    .font(.subheadline)            // Nieco większa czcionka niż tytuł "Status połączenia"
                            } else {        // W przeciwnym wypadku (gdy brak połączenia)
                                // Label z napisem "Brak połączenia" i ikoną iksa (xmark)
                                Label("Brak połączenia", systemImage: "xmark.circle.fill")
                                    .foregroundColor(.red)      // Kolor czerwony jako ostrzeżenie
                                    .font(.subheadline)
                            }
                        }                                       // Koniec wewnętrznego VStack
                        .padding(10)                            // Wewnętrzny odstęp od treści do krawędzi dymka
                        // BlurView tworzy efekt "mrożonego szkła", cornerRadius zaokrągla rogi dymka
                        .background(BlurView(style: .systemUltraThinMaterialDark).cornerRadius(10))
                        // Definicja animacji: dymek płynnie się pojawia (opacity) i jednocześnie wjeżdża z góry (move)
                        .transition(.opacity.combined(with: .move(edge: .top))) // Ładne pojawianie się
                    }
                    
                    Spacer()                // Wypycha cały powyższy dymek statusu maksymalnie do lewej strony ekranu
                    
                    // Opcjonalne ikony systemowe (bolt, timer itp.)
                   // HStack(spacing: 20) {
                    //    Image(systemName: "bolt.circle").foregroundColor(.white)
                     //   Image(systemName: "timer").foregroundColor(.white)
                    //}
                    .padding()
                }       // Koniec głównego HStack (tego, który zawiera status i Spacer)
                .padding(.horizontal)       // Dodaje standardowy margines po lewej i prawej stronie (żeby dymek nie dotykał krawędzi ekranu)
                .padding(.top, 50)          // Odpycha cały pasek o 50 punktów od góry (bezpieczna odległość od Notcha/Dynamic Island)

                Spacer()

                // DÓŁ - Panel sterowania
                HStack(spacing: 40) {       // Poziomy rząd przycisków z dużym odstępem (40 pkt) między nimi/
                    // Galeria
                    Button(action: { isPhotoLibraryPresented = true }) {    // Po kliknięciu zmień flagę na true (otwórz galerię)
                        Image(systemName: "photo.on.rectangle.angled")      // Ikona systemowa dwóch zdjęć pod kątem
                            .resizable()                                    // Pozwala na zmianę rozmiaru ikony
                            .scaledToFit()                                  // Zachowuje proporcje ikony (nie rozciąga jej)
                            .frame(width: 35, height: 35)                   // Ustawia stały, wygodny rozmiar przycisku
                            .foregroundColor(.white)                        // Kolor ikony (biały, żeby odcinał się od podglądu kamery)
                    }

                    // Migawka (Główny przycisk)
                    Button(action: {
                        takePhotoTrigger.send()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 85, height: 85)
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 4)
                                .frame(width: 75, height: 75)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                        }
                    }

                    // Ustawienia światła (Żarówka)
                    Button(action: {
                        withAnimation(.spring()) {
                            showLightSettings.toggle()
                        }
                    }) {
                        Image(systemName: showLightSettings ? "lightbulb.fill" : "lightbulb")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                            .foregroundColor(showLightSettings ? .yellow : .white)
                    }
                }
                .padding(.bottom, 40)
            }

            // Nakładka ustawień światła
            if showLightSettings {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { showLightSettings = false }

                LightSettingsView(isPresented: $showLightSettings)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                    .environmentObject(bleManager)
            }
        }
        .sheet(isPresented: $isPhotoLibraryPresented) {
            PhotoPicker(image: $selectedImage)
        }
        .onChange(of: bleManager.isConnected) { oldValue, newValue in
            if newValue {
                // Jeśli właśnie się połączono (newValue to true):
                withAnimation {
                    showSuccessStatus = true
                }
                
                // Odlicz 3 sekundy i schowaj
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showSuccessStatus = false
                    }
                }
            } else {
                // Jeśli rozłączono (newValue to false), upewnij się, że flaga sukcesu jest wyłączona
                withAnimation {
                    showSuccessStatus = false
                }
            }
        }
    }
}

// Pomocniczy widok rozmycia tła dla statusu
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
