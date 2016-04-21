describe RuboCop::Cop::Specs::NoExecuteScript do
  subject(:cop) { described_class.new }

  it 'disallows execute_script' do
    inspect_source(cop, %{
      describe "sis imports ui" do
        it 'should properly show sis stickiness options' do
          expect(driver.execute_script("stuff"))
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/execute_script/)
    expect(cop.offenses.first.severity.name).to eq(:convention)
  end
end
