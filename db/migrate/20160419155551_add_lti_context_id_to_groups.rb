class AddLtiContextIdToGroups < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :groups, :lti_context_id, :string
  end
end
