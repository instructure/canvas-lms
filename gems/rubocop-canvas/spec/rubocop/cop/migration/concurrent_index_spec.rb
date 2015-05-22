describe RuboCop::Cop::Migration::ConcurrentIndex do
  subject(:cop) { described_class.new }

  it 'complains about concurrent indexes in ddl transaction' do
    inspect_source(cop, %{
      class TestMigration < ActiveRecord::Migration

        def up
          add_index :my_index, algorithm: :concurrently
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/disable_ddl/)
  end

  it 'ignores non-concurrent indexes' do
    inspect_source(cop, %{
      class TestMigration < ActiveRecord::Migration

        def up
          add_index :my_index
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end

  it 'is ok with concurrent indexes added non-transactionally' do
    inspect_source(cop, %{
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          add_index :my_index, algorithm: :concurrently
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end

  it 'complains about unknown algorithm' do
    inspect_source(cop, %{
      class TestMigration < ActiveRecord::Migration
        def up
          add_index :my_index, algorithm: :concurrent
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/unknown algorithm/i)
  end
end
