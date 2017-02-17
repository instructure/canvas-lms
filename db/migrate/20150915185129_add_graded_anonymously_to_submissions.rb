class AddGradedAnonymouslyToSubmissions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :submissions, :graded_anonymously, :boolean
  end
end
