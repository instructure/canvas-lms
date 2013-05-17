class RestoreUsersSortableName < ActiveRecord::Migration
  self.transactional = false

  def self.up
    User.find_in_batches do |batch|
      User.transaction do
        batch.each do |user|
          user.sortable_name = nil
          user.sortable_name
          User.where(:id => user).update_all(:sortable_name => user.sortable_name) if user.changed?
        end
      end
    end
  end

  def self.down
  end
end
