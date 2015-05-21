describe RuboCop::Cop::Migration::SendLater do
  subject(:cop) { described_class.new }

  it 'catches other forms of send_later' do
    inspect_source(cop, %{
      class TestMigration < ActiveRecord::Migration

        def up
          MyClass.send_later_enqueue_args(:run, max_attempts: 1)
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/if_production/)
  end

  it 'disallows send_later in predeploys' do
    inspect_source(cop, %{
      class TestMigration < ActiveRecord::Migration
        tag :predeploy

        def up
          MyClass.send_later_if_production(:run, max_attempts: 1)
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/predeploy/)
  end
end
