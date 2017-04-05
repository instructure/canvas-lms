class AddColumnsToLinkedinExport < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :linkedin_exports, :most_recent_school, :string
    add_column :linkedin_exports, :graduation_year, :string
    add_column :linkedin_exports, :major, :string
    add_column :linkedin_exports, :job_title, :string
    add_column :linkedin_exports, :current_employer, :string
  end
end

