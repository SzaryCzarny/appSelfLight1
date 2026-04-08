//
//  LightSettingsView.swift
//  cameraExample
//
//  Created by MacBook on 08/07/2025.
//

import SwiftUI
import UIKit

extension Color {
    func toRGB() -> (r: UInt8, g: UInt8, b: UInt8)? {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return nil
        }

        return (UInt8(r * 255), UInt8(g * 255), UInt8(b * 255))
    }
}

struct LightSettingsView: View {
    @Binding var isPresented: Bool
    
    // To MUSI być wewnątrz struct LightSettingsView
    @State private var brightness: Double = 0.5
    @State private var intensity: Double = 0.5
    @State private var selectedColor: Color = .white
    @EnvironmentObject var bleManager: BleManager

    @State private var isStronaOn: Bool = false
    @State private var isOnOff: Bool = false
    @State private var isModeListVisible = false
    @State private var selectedMode: String = "Tryb"
    
    let modes: [String: UInt8] = [
        "Ciągły": 0x10,
        "Syrena": 0x11,
        "Strobo": 0x12,
        "Cyclon": 0x13,
        "Fire"  : 0x14,
        "Rainbow": 0x15,
        "Twinkle":0x16
    ]
    var body: some View {
        VStack(spacing: 30) {
            // 🔲 Sekcja Suwaków
            HStack(spacing: 60) { // Zwiększyłem odstęp między suwakami dla czytelności
                
                // Suwak 1: Intensywność
                HStack(alignment: .bottom, spacing: 10) { // Wyrównanie do dołu
                    VStack(spacing: 2) {
                        let text = Array("Intensywność")
                        ForEach(0..<text.count, id: \.self) { index in
                            Text(String(text[index]))
                                .font(.system(size: 10, weight: .bold)) // Nieco mniejsza, grubsza czcionka
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.bottom, 10) // Lekki odstęp od dołu dla tekstu
                    
                    VerticalBarSlider(value: $intensity)
                        .frame(height: 180)
                        .offset(y: 40)
                        .onChange(of: intensity) {
                            let value = UInt8(clamping: Int(intensity * 44))
                            bleManager.sendData(Data([0x04, value]))
                        }
                }
                
                // Suwak 2: Jasność
                HStack(alignment: .bottom, spacing: 10) { // Wyrównanie do dołu
                    VStack(spacing: 2) {
                        let text = Array("Jasność")
                        ForEach(0..<text.count, id: \.self) { index in
                            Text(String(text[index]))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.bottom, 50)
                    
                    VerticalBarSlider(value: $brightness)
                        .frame(height: 180)
                        .offset(y: 40)
                        .onChange(of: brightness) { _, newValue in
                            let brightnessByte = UInt8(clamping: Int(newValue * 255))
                            bleManager.sendData(Data([0x07, brightnessByte]))
                        }
                }
            }
            .padding(.top, 50)
                
                // 🎨 Koło kolorów
                ColorWheelPicker(selectedColor: $selectedColor)
                    .scaleEffect(1.3)
                    .environmentObject(bleManager)
                
                // 🔘 Przyciski (Usunięty przycisk "Strona")
                HStack(spacing: 40) {
                    // ON/OFF
                    Button(action: {
                        isOnOff.toggle()
                        let stateByte: UInt8 = isOnOff ? 0x01 : 0x00
                        bleManager.sendData(Data([0x01, stateByte]))
                    }) {
                        Text(isOnOff ? "OFF" : "ON")
                                    .bold()
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 80, height: 45)
                                    // Zmienione na "zgniłą" zieleń i przybrudzony czerwony
                                    .background(isOnOff ?
                                                Color(red: 0.4, green: 0.2, blue: 0.2) : // Ciemna, matowa czerwień
                                                Color(red: 0.25, green: 0.35, blue: 0.2)) // Zgniła, ciemna zieleń
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    
                    // Wybór trybu
                    Button(action: {
                        withAnimation { isModeListVisible.toggle() }
                    }) {
                        HStack {
                            Text(selectedMode)
                            Image(systemName: "chevron.up")
                                .rotationEffect(.degrees(isModeListVisible ? 180 : 0))
                        }
                        .bold()
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 130, height: 45)
                                // Stonowany, stalowo-niebieski / szary tryb
                                .background(Color(red: 0.2, green: 0.25, blue: 0.3))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                }

                // Lista trybów (wyświetlana nad przyciskami, gdy aktywna)
                if isModeListVisible {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(Array(modes.keys.sorted()), id: \.self) { mode in
                                Button(mode) {
                                    selectedMode = mode
                                    isModeListVisible = false
                                    let modeID = modes[mode] ?? 0x00
                                    bleManager.sendData(Data([0x03, modeID]))
                                }
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Capsule())
                                .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 50)
                }
            }
            .padding()
            .background(BlurView(style: .systemUltraThinMaterialDark).cornerRadius(30))
            .padding()
        }
    }
struct VerticalBarSlider: View {
    @Binding var value: Double

    var body: some View {
        GeometryReader { geometry in
            Slider(value: $value)
                .rotationEffect(.degrees(-90))
                .frame(width: geometry.size.height)
                .offset(x: (geometry.size.width - geometry.size.height) / 2)
                .accentColor(.white)
        }
        .frame(width: 40) // szerokość suwaka
    }
}
struct ColorWheelPicker: View {
    @Binding var selectedColor: Color
    
    @State private var isExpanded = false
    @GestureState private var dragLocation: CGPoint? = nil
    
    var body: some View {
        ZStack {
            // Małe kółko pokazujące aktualny kolor
            Circle()
                .fill(selectedColor)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(radius: 4)
                .onTapGesture {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }
            
            if isExpanded {
                ColorWheelView(selectedColor: $selectedColor, isExpanded: $isExpanded)
                    .frame(width: 250, height: 250)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

struct ColorWheelView: View {
    @Binding var selectedColor: Color
    @Binding var isExpanded: Bool
    
    @GestureState private var dragLocation: CGPoint? = nil
    @State private var indicatorPosition: CGPoint = .zero
    @State private var lastHueByteSent: UInt8 = 255
    @EnvironmentObject var bleManager: BleManager   // ⬅️ DODAJ TO
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            
            ZStack {
                ColorWheel()
                
                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .frame(width: 30, height: 30)
                    .position(indicatorPosition == .zero ? center : indicatorPosition)
                    .shadow(radius: 2)
                
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let brightness: CGFloat = 1.0 // jasność 1.0 w kole kolorów
                        
                        let loc = CGPoint(x: value.location.x - center.x,
                                          y: value.location.y - center.y)
                        let angleOffset: CGFloat = -0.2
                        let rawAngle = atan2(loc.y, loc.x)
                        let adjustedAngle = rawAngle + angleOffset
                        let normalizedAngle = (adjustedAngle < 0 ? adjustedAngle + 2 * .pi : adjustedAngle)
                        
                        let distance = sqrt(loc.x * loc.x + loc.y * loc.y)
                        let limitedDistance = min(distance, radius)
                        
                        let angle = atan2(loc.y, loc.x)
                        let hue = normalizedAngle / (2 * .pi)
                        let saturation = max(0, min(1, limitedDistance / radius))
                        
                        let x = center.x + cos(angle) * limitedDistance
                        let y = center.y + sin(angle) * limitedDistance
                        
                        indicatorPosition = CGPoint(x: x, y: y)
                        
                        // 🎨 Ustaw kolor
                        let newColor = Color(hue: Double(hue), saturation: Double(saturation), brightness: 1.0)
                        selectedColor = Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness))
                        
                        let uiColor = UIColor(selectedColor)
                            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

                            let redByte = UInt8(r * 255)
                            let greenByte = UInt8(g * 255)
                            let blueByte = UInt8(b * 255)

                        
                        // 📤 Wyślij tylko, jeśli wartość się zmieniła
                        
                        bleManager.sendData(Data([0x06, redByte, greenByte, blueByte]))
                    }
                    .onEnded { _ in
                        withAnimation {
                            isExpanded = false
                        }
                    }
            )
            .onAppear {
                // Domyślne ustawienie wskaźnika na środku
                indicatorPosition = center
            }
        }
    }
}

// Prosty gradient koła kolorów
struct ColorWheel: View {
    var body: some View {
        AngularGradient(gradient: Gradient(colors: [
            .red, .orange, .yellow, .green, .blue, .purple, .red
        ]), center: .center)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
