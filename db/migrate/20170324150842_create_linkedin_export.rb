class CreateLinkedinExport < ActiveRecord::Migration
  tag :predeploy
  def change
    create_table :linkedin_exports do |t|
      t.references :user, index: true, foreign_key: true, :limit => 8
      t.string :linkedin_id
      t.string :first_name
      t.string :last_name
      t.string :maiden_name
      t.string :email_address
      t.string :location
      t.string :industry
      t.integer :num_connections
      t.boolean :num_connections_capped
      t.text :summary
      t.string :public_profile_url
      t.text :three_current_positions
      t.text :three_past_positions
      t.text :skills
      t.text :certifications
      t.text :educations
      t.text :courses
      t.text :volunteer
      t.text :specialties
      t.text :associations
      t.text :interests
      t.integer :num_recommenders
      t.text :recommendations_received
      t.text :languages
      t.text :following
      t.text :publications
      t.text :patents
      t.text :job_bookmarks
      t.text :honors_awards
      t.datetime :last_modified_timestamp
    end
  end
end
