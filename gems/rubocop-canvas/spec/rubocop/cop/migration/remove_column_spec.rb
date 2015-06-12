describe RuboCop::Cop::Migration::RemoveColumn do
  subject(:cop) { described_class.new }

  context 'predeploy' do
    it 'disallows remove_column in `up`' do
      inspect_source(cop, %{
        class MyMigration < ActiveRecord::Migration
          tag :predeploy

          def up
            remove_column :x, :y
          end
        end
      })
      expect(cop.offenses.size).to eq(1)
      expect(cop.messages.first).to match(/remove_column/)
    end

    it 'disallows remove_column in `self.up`' do
      inspect_source(cop, %{
        class MyMigration < ActiveRecord::Migration
          tag :predeploy

          def self.up
            remove_column :x, :y
          end
        end
      })
      expect(cop.offenses.size).to eq(1)
      expect(cop.messages.first).to match(/remove_column/)
    end

    it 'allows remove_column in `down`' do
      inspect_source(cop, %{
        class MyMigration < ActiveRecord::Migration
          tag :predeploy

          def down
            remove_column :x, :y
          end
        end
      })
      expect(cop.offenses.size).to eq(0)
    end
  end
end
