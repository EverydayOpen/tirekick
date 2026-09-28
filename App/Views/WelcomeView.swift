import AppKit
import SwiftUI
import TirekickCore

struct WelcomeView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: Space.l) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)
            VStack(spacing: Space.xs) {
                Text("Kick the tires before you pay")
                    .font(.title.weight(.semibold))
                Text("Check a used Mac for company locks, battery and SSD wear, then test its keyboard, screen, speakers and camera. It takes about two minutes.")
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: 500)

            HStack(spacing: Space.m) {
                choice(.buying, title: "I'm Buying", detail: "Check a Mac before you pay for it", symbol: "cart")
                choice(.selling, title: "I'm Selling", detail: "Get it ready and make a report card for your listing", symbol: "tag")
            }
            .fixedSize(horizontal: false, vertical: true)   // with maxHeight below: both tiles as tall as the taller
            .frame(maxWidth: 520)

            Label {
                // Setup connected to the internet is where a Mac registered to an organization shows its Remote
                // Management screen (Apple Platform Deployment, "Manage Setup Assistant"), so never advise offline setup.
                Text("At a meetup: if the Mac was just erased, go through setup connected to Wi-Fi or a phone hotspot and watch: a Remote Management screen means walk away. Then finish with a throwaway local account and open Tirekick from a USB stick or a download.")
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "lightbulb").foregroundStyle(.secondary)
            }
            .font(.callout)
            .frame(maxWidth: 520, alignment: .leading)

            Text("Runs offline. Sends nothing. Changes nothing.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(Space.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func choice(_ mode: Mode, title: String, detail: String, symbol: String) -> some View {
        Button { model.start(mode) } label: {
            VStack(spacing: Space.xs) {
                Image(systemName: symbol)
                    .font(.system(size: 28))
                    .foregroundStyle(.tint)
                    .frame(height: 34)
                    .accessibilityHidden(true)
                Text(title).font(.headline)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Space.xs)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .buttonStyle(TileButtonStyle())
    }
}
