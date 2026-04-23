require "./spec_helper"

# Baseline check: the converter runs without raising on trivial input
# and produces the minimal expected output.
describe "Integration · sanity" do
  it "always ends non-empty output with a trailing newline" do
    result = IntegrationHelper.convert("<p>Hello.</p>")
    result.ends_with?("\n").should be_true
  end

  it "preserves author words from a paragraph" do
    result = IntegrationHelper.convert(
      "<p>This paragraph mentions Paris, Crystal and HTML by name.</p>"
    )
    result.should contain("Paris")
    result.should contain("Crystal")
    result.should contain("HTML")
  end

  it "leaves no stray HTML tags in the output of a mixed paragraph" do
    result = IntegrationHelper.convert(
      "<p>A <strong>bold</strong> and <em>italic</em> phrase.</p>"
    )
    # All HTML tags should be consumed and converted to Markdown markup.
    result.should_not contain("<strong>")
    result.should_not contain("</strong>")
    result.should_not contain("<em>")
    result.should_not contain("<p>")
    # Markdown markers are present instead.
    result.should contain("**bold**")
    # This converter emits `*italic*` (asterisks) rather than `_italic_`
    # (underscores) — both are valid CommonMark italic markers.
    result.should contain("*italic*")
  end

  it "produces the same output when called twice (determinism)" do
    html = "<h1>T</h1><p>A <strong>paragraph</strong>.</p>"
    a = IntegrationHelper.convert(html)
    b = IntegrationHelper.convert(html)
    a.should eq(b)
  end
end
