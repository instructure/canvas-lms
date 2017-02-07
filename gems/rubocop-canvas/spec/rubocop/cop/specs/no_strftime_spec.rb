describe RuboCop::Cop::Specs::NoStrftime do
  subject(:cop) { described_class.new }

  it 'disallows strftime' do
    inspect_source(cop, %{
      describe "date stuff" do
        it 'should do date stuff' do
          next_year = 1.year.from_now.strftime("%Y")
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/Avoid using strftime/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
