describe RuboCop::Cop::Specs::NoSkipWithoutTicket do
  subject(:cop) { described_class.new }

  it 'disallows skipping without referencing a ticket' do
    inspect_source(cop, %{
      describe "date stuff" do
        it 'should do date stuff' do
          skip("fragile")
          next_year = 1.year.from_now
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/Reference a ticket if skipping/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'allows skipping if referencing a ticket' do
    inspect_source(cop, %{
      describe "date stuff" do
        it 'should do date stuff' do
          skip("CNVS-1234")
          next_year = 1.year.from_now
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end
end
