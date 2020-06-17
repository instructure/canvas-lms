class DropSubmissionContextCode < ActiveRecord::Migration[5.2]
  tag :postdeploy

  def change
    remove_column :submissions, :context_code, :string
  end
end
