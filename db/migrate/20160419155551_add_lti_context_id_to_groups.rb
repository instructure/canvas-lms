class AddLtiContextIdToGroups < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :groups, :lti_context_id, :string
  end
end
