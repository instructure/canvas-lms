class OptimizeScribdRecyclableIndex < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      remove_index :attachments, name: 'scribd_attempts_smt_workflow_state'
      add_index :attachments, :scribd_attempts, concurrently: true, conditions: "workflow_state='errored' AND scribd_mime_type_id IS NOT NULL", name: 'scribd_attempts_smt_workflow_state'
    end
  end

  def self.down
    if connection.adapter_name == 'PostgreSQL'
      remove_index :attachments, name: 'scribd_attempts_smt_workflow_state'
      add_index :attachments, [:scribd_attempts, :scribd_mime_type_id, :workflow_state], concurrently: true, name: 'scribd_attempts_smt_workflow_state'
    end
  end
end
