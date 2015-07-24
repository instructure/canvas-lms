class AddNumberToVersionsIndex < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    # eliminate duplicates
    Version.select([:versionable_id, :versionable_type, :number]).
      group(:versionable_id, :versionable_type, :number).
      having("COUNT(*) > 1").
      # number DESC so that dups in earlier numbers don't alter the dups in later numbers,
      # since we've already cached them in a temp table
      order("number DESC").
      find_each do |version|
        versionable_object_scope = Version.where(:versionable_id => version.versionable_id,
                                                 :versionable_type => version.versionable_type)
        dups = versionable_object_scope.where(:number => version.number).order(:created_at, :id).to_a
        # leave the first one alone
        dups.shift
        next if dups.empty? # ???
        # move later versions out of the way
        versionable_object_scope.where("number>?", version.number).update_all("number=number+#{dups.length}")
        dups.each_with_index do |dup, idx|
          dup.number += idx + 1
          dup.save!
        end
      end

    add_index :versions, [:versionable_id, :versionable_type, :number], :unique => true, :algorithm => :concurrently, :name => "index_versions_on_versionable_object_and_number"
    remove_index :versions, [:versionable_id, :versionable_type]
  end

  def self.down
    add_index :versions, [:versionable_id, :versionable_type], :algorithm => :concurrently
    remove_index :versions, :name => "index_versions_on_versionable_object_and_number"
  end
end
