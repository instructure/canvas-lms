class CreateOriginalityReport < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :originality_reports do |t|
      t.integer :attachment_id, limit: 8, null: false
      t.decimal :originality_score, null:false
      t.integer :originality_report_attachment_id, limit: 8
      t.text :originality_report_url
      t.text :originality_report_lti_url
      t.timestamps null: false
    end

    add_foreign_key :originality_reports, :attachments
    add_foreign_key :originality_reports, :attachments, column: :originality_report_attachment_id

    add_index :originality_reports, :attachment_id, unique: true
    add_index :originality_reports, :originality_report_attachment_id, unique: true
  end
end
