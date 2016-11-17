class CreateQuizQuestionRegrades < ActiveRecord::Migration[4.2]
  tag :predeploy
  def self.up
    create_table :quiz_question_regrades do |t|
      t.integer :quiz_regrade_id, limit: 8, null: false
      t.integer :quiz_question_id, limit: 8, null: false
      t.string :regrade_option, null: false

      t.timestamps null: true
    end

    add_index :quiz_question_regrades, [:quiz_regrade_id, :quiz_question_id], unique: true, name: 'index_qqr_on_qr_id_and_qq_id'
  end

  def self.down
    drop_table :quiz_question_regrades
  end
end
