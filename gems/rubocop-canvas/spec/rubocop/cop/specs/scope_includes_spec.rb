describe RuboCop::Cop::Specs::ScopeIncludes do
  subject(:cop) { described_class.new }

  context "within describe" do
    it 'allows includes' do
      inspect_source(cop, %{
        describe JumpStick do
          include Foo
        end
      })
      expect(cop.offenses.size).to eq(0)
    end
  end

  context "within module" do
    it 'allows includes' do
      inspect_source(cop, %{
        module JumpStick
          include Foo
        end
      })
      expect(cop.offenses.size).to eq(0)
    end
  end

  it "disallows defs on Object" do
    inspect_source(cop, %{
      include Foo
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/Never `include`/)
    expect(cop.offenses.first.severity.name).to eq(:error)
  end
end
