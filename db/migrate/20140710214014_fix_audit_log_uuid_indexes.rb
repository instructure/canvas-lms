class FixAuditLogUuidIndexes < ActiveRecord::Migration
  tag :postdeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.up
    DataFixup::FixAuditLogUuidIndexes.send_later_if_production(:run)
  end

  def self.down
  end
end
