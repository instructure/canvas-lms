describe RuboCop::Cop::Migration::PrimaryKey do
  subject(:cop) { described_class.new }

  it 'catches explicit id disabled' do
    inspect_source(cop, %{
      class CreateNotificationEndpoints < ActiveRecord::Migration
        tag :predeploy

        def self.up
          create_table(:notification_endpoints, id: false) do |t|
            t.integer :access_token_id, limit: 8, null: false
            t.string :token, null: false
            t.string :arn, null: false
            t.timestamps
          end
          add_index :notification_endpoints, :access_token_id
          add_foreign_key :notification_endpoints, :access_tokens
        end

        def self.down
          drop_table :notification_endpoints
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/include a primary key/)
  end
end
