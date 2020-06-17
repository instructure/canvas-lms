class ChangeScheduleSmartAlertsContextIdToBigInt < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    change_column :scheduled_smart_alerts, :context_id, :bigint
    change_column_null :scheduled_smart_alerts, :context_id, false
    change_column_null :scheduled_smart_alerts, :due_at, false
    change_column_null :scheduled_smart_alerts, :root_account_id, false
  end

  def down
    change_column_null :scheduled_smart_alerts, :root_account_id, true
    change_column_null :scheduled_smart_alerts, :due_at, true
    change_column_null :scheduled_smart_alerts, :context_id, true
    change_column :scheduled_smart_alerts, :context_id, :integer
  end
end
