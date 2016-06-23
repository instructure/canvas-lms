describe RuboCop::Cop::Lint::NoFileUtilsRmRf do
  subject(:cop) { described_class.new }

  it 'disallows FileUtils.rm_rf' do
    inspect_source(cop, %{
      def rm_sekrets
        FileUtils.rm_rf
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/avoid FileUtils.rm_rf/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
