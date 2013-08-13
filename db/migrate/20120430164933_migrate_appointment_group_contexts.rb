class MigrateAppointmentGroupContexts < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    records = AppointmentGroup.all.map { |ag|
      {
        :appointment_group_id => ag.id,
        :context_code         => ag.context_code,
        :context_type         => ag.context_type,
        :context_id           => ag.context_id,
        :updated_at           => ag.updated_at,
        :created_at           => ag.created_at
      }
    }

    AppointmentGroupContext.bulk_insert records
  end

  def self.down
  end
end
