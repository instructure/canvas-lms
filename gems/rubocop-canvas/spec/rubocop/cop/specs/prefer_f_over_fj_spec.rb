describe RuboCop::Cop::Specs::PreferFOverFj do
  subject(:cop) { described_class.new }

  it 'disallows fj' do
    inspect_source(cop, %{
      describe "admin_tools" do
        it "should hide tab if account setting disabled" do
          tab = fj('#adminToolsTabs .notifications > a')
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/Prefer `f`/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'disallows ffj' do
    inspect_source(cop, %{
      describe "admin_tools" do
        it "should not include login activity option for revoked permission" do
          options = ffj("#loggingType > option")
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/Prefer `ff`/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
