class UpdateAccountAssociationsForUsersWithDuplicates < ActiveRecord::Migration
  def self.up
    # Do this in batches so that we don't try to load too many users into memory at once.
    begin
      loop do
        users = User.find_by_sql("select u.* from (select user_id, account_id, updated_at, count(*) from user_account_associations group by user_id, account_id, updated_at having count(*) > 1 order by updated_at desc) foo, users u where foo.user_id = u.id limit 1000")
        break if users.length == 0
        
        User.update_account_associations(users)
      end
    rescue => e
      puts " !! Exception encountered updating account associations for users with duplicates: #{e.inspect}"
      puts " !! This is a non-fatal error and migrations will continue, but it should be investigated."
    end
  end

  def self.down
  end
end
