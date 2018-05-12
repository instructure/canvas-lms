module DataFixup::PopulateRootAccountIdOnUserObservers
  def self.run
    UserObservationLink.find_ids_in_ranges do |min_id, max_id|
      UserObservationLink.where(:id => min_id..max_id, :root_account_id => nil).
          where("user_id < ?", Shard::IDS_PER_SHARD). # otherwise it's a shadow record - handle it on the other side
          preload(:student, :observer).each do |link|

        student_ra_ids = link.student.associated_root_accounts.shard(link.student).pluck(:id)
        observer_ra_ids = link.observer.associated_root_accounts.shard(link.observer).pluck(:id)

        common_ra_ids = (student_ra_ids & observer_ra_ids)
        if common_ra_ids.empty? # boo
          set_root_account_id(link, UserObservationLink::MISSING_ROOT_ACCOUNT_ID, true)
        elsif common_ra_ids.count == 1 # easy peasy
          set_root_account_id(link, common_ra_ids.first)
        else
          set_root_account_id(link, common_ra_ids.shift) # replace it with one of them
          # create new links for the rest
          Account.where(:id => common_ra_ids).each do |ra|
            UserObservationLink.create_or_restore(student: link.student, observer: link.observer, root_account: ra)
          end
        end
      end
    end
  end

  def self.set_root_account_id(link, root_account_id, destroy=false)
    shadow = link.send(:shadow_record)
    UserObservationLink.unique_constraint_retry do |retry_count|
      if retry_count > 0
        # for the unlikely scenario that somehow an equivalent link was made after the deploy but before the fixup finished
        new_id = -1 * retry_count # just in case
        updates = {:root_account_id => new_id, :workflow_state => 'deleted'}
        shadow.update_attributes(updates) if shadow
        link.update_attributes(updates)
      else
        updates = {:root_account_id => root_account_id}
        updates.merge!(:workflow_state => 'deleted') if destroy
        shadow.update_attributes(updates) if shadow
        link.update_attributes(updates)
      end
    end
  end
end
