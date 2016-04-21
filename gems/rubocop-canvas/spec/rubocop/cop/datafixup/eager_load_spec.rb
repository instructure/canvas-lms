describe RuboCop::Cop::Datafixup::EagerLoad do
  subject(:cop) { described_class.new }

  it 'disallows eager_load' do
    inspect_source(cop, %{
      module DataFixup::RecomputeRainbowAsteroidField
        def self.run
          AccountUser.eager_load(:account)
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/eager_load/)
    expect(cop.offenses.first.severity.name).to eq(:error)
  end
end
