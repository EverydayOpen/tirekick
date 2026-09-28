import AppKit
import SwiftUI
import TirekickCore

struct ReportView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.l) {
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text("Report card").font(.title2.weight(.semibold))
                    Text(model.mode == .buying
                         ? "Save the picture for your records or to show the seller. The PDF adds every command's output."
                         : "Share the picture with a listing. The PDF adds every command's output.")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: Space.xs) {
                    Toggle("Mask serial", isOn: $model.maskSerial)
                    Spacer()
                    Button("Save PNG…") {
                        if let card = model.card { Export.png(card) }
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Save PDF…") {
                        if let report = model.report { Export.pdf(ReportText.full(report, maskSerial: model.maskSerial)) }
                    }
                    CopyButton { model.copyReport() }
                }
                .disabled(model.report == nil)

                if let card = model.card {
                    let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    ReportCardView(card: card)
                        .clipShape(shape)
                        .overlay(shape.strokeBorder(Color(nsColor: .separatorColor)))
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                        .frame(maxWidth: .infinity)
                }

                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("What Tirekick can't tell you").font(.headline)
                    ForEach(ReportText.cantTell, id: \.self) { item in
                        Label {
                            Text(item).fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "questionmark.circle").foregroundStyle(.secondary)
                        }
                    }
                }
                .font(.callout)
            }
            .padding(Space.xxl)
        }
    }
}
