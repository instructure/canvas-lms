describe RuboCop::Cop::Specs::NoBeforeAll do
  subject(:cop) { described_class.new }

  it 'disallows before(:all)' do
    inspect_source(cop, %{
      before(:all) { puts "yarrr" }
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/Use `before\(:once\)`/)
    expect(cop.offenses.first.severity.name).to eq(:convention)
  end

  it 'allows before(:each)' do
    inspect_source(cop, %{
        before(:each) { puts "yarrr" }
      })
    expect(cop.offenses.size).to eq(0)
  end

  it 'allows before(:once)' do
    inspect_source(cop, %{
        before(:once) { puts "yarrr" }
      })
    expect(cop.offenses.size).to eq(0)
  end
end
