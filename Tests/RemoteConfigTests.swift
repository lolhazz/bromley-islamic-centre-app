import Testing
import Foundation
@testable import BromleyIslamicCentre

@Suite("Remote config")
struct RemoteConfigTests {
    private func decode(_ json: String) throws -> RemoteConfig {
        try JSONDecoder().decode(RemoteConfig.self, from: Data(json.utf8))
    }

    @Test func decodesEditorOutputWithNulls() throws {
        let c = try decode(#"{"jumuah":[{"label":"1st","khutbah":"1:15 pm","jamaah":"1:30 pm","venue":null,"note":null}],"venueBanner":"x","ramadanStart":"2027-02-08"}"#)
        #expect(c.jumuah?.count == 1)
        #expect(c.jumuah?[0].venue == nil)
        #expect(c.ramadanStart == "2027-02-08")
        #expect(c.announcements == nil)
    }

    @Test func emptyObjectIsValid() throws {
        let c = try decode("{}")
        #expect(c.jumuah == nil && c.events == nil && c.venueBanner == nil)
    }

    @Test func missingRequiredFieldFails() {
        #expect(throws: (any Error).self) { try decode(#"{"jumuah":[{"label":"1st"}]}"#) }
    }

    @Test func bundledDefaultsMatchCentreWebsite() {
        #expect(Content.jumuah.map(\.khutbah) == ["1:15 pm", "2:00 pm"])
        #expect(Content.jumuah.map(\.jamaah) == ["1:30 pm", "2:15 pm"])
    }

    @Test func contentHasNoDuplicateIds() {
        #expect(Set(Content.events.map(\.id)).count == Content.events.count)
        #expect(Set(Content.announcements.map(\.id)).count == Content.announcements.count)
    }
}
