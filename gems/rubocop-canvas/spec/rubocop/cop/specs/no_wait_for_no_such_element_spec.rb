describe RuboCop::Cop::Specs::NoWaitForNoSuchElement do
  subject(:cop) { described_class.new }

  it 'disallows wait_for_no_such_element' do
    inspect_source(cop, %{
      describe "sis imports ui" do
        it 'should properly show sis stickiness options' do
          wait_for_no_such_element(method: :contain_css) do
            f("#studentAvatar", f('#courses'))
          end
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/wait_for_no_such_element/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
