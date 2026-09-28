import SwiftUI
import TirekickCore

struct WelcomeView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: Space.l) {
            LaptopView()
                .padding(.bottom, Space.xs)   // air for the floor's glow

            VStack(spacing: Space.xs) {
                (Text("Kick the tires ") + Text("before you pay").foregroundColor(.secondary))
                    .font(.system(size: 28, weight: .bold).width(.expanded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("Check a used Mac for company locks, battery and SSD wear, then test its keyboard, screen, speakers and camera. It takes about two minutes.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 500)
            }
            .multilineTextAlignment(.center)

            HStack(spacing: Space.m) {
                choice(.buying, title: "I'm Buying", detail: "Check a Mac before you pay for it", symbol: "cart")
                choice(.selling, title: "I'm Selling", detail: "Get it ready and make a report card for your listing", symbol: "tag")
            }
            .fixedSize(horizontal: false, vertical: true)   // with maxHeight below: both tiles as tall as the taller
            .frame(maxWidth: 520)

            tip

            Text("Runs offline. Sends nothing. Changes nothing.")
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Space.xxl)
        .padding(.bottom, Space.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func choice(_ mode: Mode, title: String, detail: String, symbol: String) -> some View {
        Button { model.start(mode) } label: {
            VStack(spacing: Space.xs) {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Brand.hiVisInk)
                    .well(.secondary, size: 44)
                    .accessibilityHidden(true)
                Text(title).font(.headline)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .buttonStyle(KeyCapStyle())
    }

    /// A recessed note well under the choices.
    private var tip: some View {
        HStack(spacing: Space.s) {
            Image(systemName: "lightbulb")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .well(.secondary, size: 28)
                .accessibilityHidden(true)
            // Setup connected to the internet is where a Mac registered to an organization shows its Remote
            // Management screen (Apple Platform Deployment, "Manage Setup Assistant"), so never advise offline setup.
            Text("At a meetup: if the Mac was just erased, go through setup connected to Wi-Fi or a phone hotspot and watch: a Remote Management screen means walk away. Then finish with a throwaway local account, run the company check from that account (it's harder to fake there, though not impossible) and open Tirekick from a USB stick or a download.")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Space.xs)
        .background(scheme == .dark ? AnyShapeStyle(Color.black.opacity(0.25)) : AnyShapeStyle(.quaternary),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .frame(maxWidth: 520)
    }
}
