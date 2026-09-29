import SwiftUI
import TirekickCore

/// The laptop stands on the lime laser with its reflection (DESIGN.md §5.3), the title, the two key-cap choices, the
/// meetup field note and the privacy line. Everything fits the fixed 720×560 window without scrolling.
struct WelcomeView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: Space.m) {
            OnFloor(height: LaptopView.height) { LaptopView() }
                .modifier(HoverTilt(max: 8))
                .background(alignment: .top) {
                    // The laser, still while the laptop tilts: its line sits in OnFloor's 2pt gap at the laptop's base.
                    Horizon(tint: Brand.hiVis, width: 440, soft: false)
                        .frame(height: 0)
                        .offset(y: LaptopView.height + 1)
                }

            VStack(spacing: Space.xs) {
                (Text("Kick the tires ") + Text("before you pay").foregroundColor(.secondary))
                    .font(.system(size: 28, weight: .heavy).width(.expanded))   // VERIFY Font.width(.expanded) renders on macOS 13
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("Check a used Mac for company locks, battery and SSD wear, then test its keyboard, screen, speakers and camera. It takes about two minutes.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 520)
            }
            .multilineTextAlignment(.center)

            HStack(spacing: Space.m) {
                choice(.buying, title: "I'm Buying", detail: "Check a Mac before you pay for it", symbol: "cart")
                choice(.selling, title: "I'm Selling", detail: "Get it ready and make a report card for your listing", symbol: "tag")
            }
            .fixedSize(horizontal: false, vertical: true)   // with maxHeight below: both keys as tall as the taller
            .frame(maxWidth: 560)

            fieldNote

            Text("Runs offline. Sends nothing. Changes nothing.")
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Space.xxl)
        .padding(.bottom, Space.m)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// A key-cap, legend left: the symbol in a well, the title, one secondary line.
    private func choice(_ mode: Mode, title: String, detail: String, symbol: String) -> some View {
        Button { model.start(mode) } label: {
            HStack(spacing: Space.s) {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Brand.hiVisInk)
                    .well(.secondary, size: 44)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15, weight: .semibold))
                    Text(detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
        }
        .buttonStyle(KeyCapStyle())
    }

    /// The meetup tip as a field note: a hairline box with a lime tick, a small-caps label and the tip. It stays
    /// open: a disclosure would hide safety advice. Secondary text, so the choices stay loudest.
    private var fieldNote: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        return VStack(alignment: .leading, spacing: Space.xxs) {
            Text("At a meetup")
                .font(.system(size: 12, weight: .semibold).smallCaps())   // VERIFY small caps with SF
                .tracking(0.5)
            // Setup connected to the internet is where a Mac registered to an organization shows its Remote
            // Management screen (Apple Platform Deployment, "Manage Setup Assistant"), so never advise offline setup.
            Text("If the Mac was just erased, go through setup connected to Wi-Fi or a phone hotspot and watch: a Remote Management screen means walk away. Then finish with a throwaway local account, run the company check from that account (it's harder to fake there, though not impossible) and open Tirekick from a USB stick or a download.")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.s)
        .padding(.leading, Space.xxs)                     // clear of the tick
        .background(Color.primary.opacity(0.04), in: shape)
        .overlay(shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
        .overlay(alignment: .leading) { Capsule().fill(Brand.hiVisInk).frame(width: 2).padding(.vertical, Space.s).accessibilityHidden(true) }
        .accessibilityElement(children: .combine)
        .frame(maxWidth: 560)
    }
}
