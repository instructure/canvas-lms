class CreateCohortInfos < ActiveRecord::Migration
  tag :predeploy
  def change
    create_table :cohort_infos do |t|
      t.integer :course_id, limit => 8
      t.string :section_name
      t.string :lc_name
      t.string :lc_email
      t.string :lc_phone
      t.string :ta_name
      t.string :ta_phone
      t.string :ta_email
      t.text :ta_office
      t.text :ll_times
      t.text :ll_location

      t.timestamps
    end
  end
end
