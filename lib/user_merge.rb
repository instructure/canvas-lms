class UserMerge

  def self.from(user)
    new(user)
  end

  attr_reader :from_user

  def initialize(from_user)
    @from_user = from_user
  end

  def into(target_user)
    return unless target_user
    return if target_user == from_user
    target_user.save if target_user.changed?
    target_user.associate_with_shard(from_user.shard)

    max_position = target_user.communication_channels.last.try(:position) || 0
    to_retire_ids = []
    from_user.communication_channels.each do |cc|
      source_cc = cc
      # have to find conflicting CCs, and make sure we don't have conflicts
      # To avoid the case where a user has duplicate CCs and one of them is retired, don't look for retired ccs
      # it's okay to do that even if the only matching CC is a retired CC, because it would end up on the no-op
      # case below anyway.
      # Behavior is undefined if a user has both an active and an unconfirmed CC; it's not allowed with current
      # validations, but could be there due to older code that didn't enforce the uniqueness.  The results would
      # simply be that they'll continue to have duplicate unretired CCs
      target_cc = target_user.communication_channels.detect { |cc| cc.path.downcase == source_cc.path.downcase && cc.path_type == source_cc.path_type && !cc.retired? }

      if !target_cc && from_user.shard != target_user.shard
        User.clone_communication_channel(source_cc, target_user, max_position)
      end
      next unless target_cc

      # we prefer keeping the "most" active one, preferring the target user if they're equal
      # the comments inline show all the different cases, with the source cc on the left,
      # target cc on the right.  The * indicates the CC that will be retired in order
      # to resolve the conflict
      if target_cc.active?
        # retired, active
        # unconfirmed*, active
        # active*, active
        to_retire = source_cc
      elsif source_cc.active?
        # active, unconfirmed*
        # active, retired
        to_retire = target_cc
        if from_user.shard != target_user.shard
          target_cc.retire unless target_cc.retired?
          User.clone_communication_channel(source_cc, target_user, max_position)
        end
      elsif target_cc.unconfirmed?
        # unconfirmed*, unconfirmed
        # retired, unconfirmed
        to_retire = source_cc
      elsif source_cc.unconfirmed? && from_user.shard != target_user.shard
        # unconfirmed, retired
        User.clone_communication_channel(source_cc, target_user, max_position)
      end
      #elsif
      # retired, retired
      #end

      if to_retire && !to_retire.retired?
        to_retire_ids << to_retire.id
      end
    end

    if from_user.shard != target_user.shard
      from_user.communication_channels.update_all(:workflow_state => 'retired') unless from_user.communication_channels.empty?

      from_user.user_services.each do |us|
        new_us = us.clone
        new_us.shard = target_user.shard
        new_us.user = target_user
        new_us.save!
      end
      from_user.user_services.delete_all
    else
      from_user.shard.activate do
        CommunicationChannel.where(:id => to_retire_ids).update_all(:workflow_state => 'retired') unless to_retire_ids.empty?
      end
      from_user.communication_channels.update_all(["user_id=?, position=position+?", target_user, max_position]) unless from_user.communication_channels.empty?
    end

    Shard.with_each_shard(from_user.associated_shards) do
      max_position = Pseudonym.where(:user_id => target_user).order(:position).last.try(:position) || 0
      Pseudonym.where(:user_id => from_user).update_all(["user_id=?, position=position+?", target_user, max_position])

      to_delete_ids = []
      target_user_enrollments = Enrollment.where(:user_id => target_user).all
      Enrollment.where(:user_id => from_user).each do |enrollment|
        source_enrollment = enrollment
        # non-deleted enrollments should be unique per [course_section, type]
        target_enrollment = target_user_enrollments.detect { |enrollment| enrollment.course_section_id == source_enrollment.course_section_id && enrollment.type == source_enrollment.type && !['deleted', 'inactive', 'rejected'].include?(enrollment.workflow_state) }
        next unless target_enrollment

        # we prefer keeping the "most" active one, preferring the target user if they're equal
        # the comments inline show all the different cases, with the source enrollment on the left,
        # target enrollment on the right.  The * indicates the enrollment that will be deleted in order
        # to resolve the conflict.
        if target_enrollment.active?
          # deleted, active
          # inactive, active
          # rejected, active
          # invited*, active
          # creation_pending*, active
          # active*, active
          # completed*, active
          to_delete = source_enrollment
        elsif source_enrollment.active?
          # active, deleted
          # active, inactive
          # active, rejected
          # active, invited*
          # active, creation_pending*
          # active, completed*
          to_delete = target_enrollment
        elsif target_enrollment.completed?
          # deleted, completed
          # inactive, completed
          # rejected, completed
          # invited*, completed
          # creation_pending*, completed
          # completed*, completed
          to_delete = source_enrollment
        elsif source_enrollment.completed?
          # completed, deleted
          # completed, inactive
          # completed, rejected
          # completed, invited*
          # completed, creation_pending*
          to_delete = target_enrollment
        elsif target_enrollment.invited?
          # deleted, invited
          # inactive, invited
          # rejected, invited
          # creation_pending*, invited
          # invited*, invited
          to_delete = source_enrollment
        elsif source_enrollment.invited?
          # invited, deleted
          # invited, inactive
          # invited, rejected
          # invited, creation_pending*
          to_delete = target_enrollment
        elsif target_enrollment.creation_pending?
          # deleted, creation_pending
          # inactive, creation_pending
          # rejected, creation_pending
          # creation_pending*, creation_pending
          to_delete = source_enrollment
        end
        #elsif
          # creation_pending, deleted
          # creation_pending, inactive
          # creation_pending, rejected
          # deleted, rejected
          # inactive, rejected
          # rejected, rejected
          # rejected, deleted
          # rejected, inactive
          # deleted, inactive
          # inactive, inactive
          # inactive, deleted
          # deleted, deleted
        #end

        to_delete_ids << to_delete.id if to_delete && !['deleted', 'inactive', 'rejected'].include?(to_delete.workflow_state)
      end
      Enrollment.where(:id => to_delete_ids).update_all(:workflow_state => 'deleted') unless to_delete_ids.empty?

      [
        [:quiz_id, :quiz_submissions],
        [:assignment_id, :submissions]
      ].each do |unique_id, table|
        begin
          # Submissions are a special case since there's a unique index
          # on the table, and if both the old user and the new user
          # have a submission for the same assignment there will be
          # a conflict.
          already_there_ids = table.to_s.classify.constantize.find_all_by_user_id(target_user.id).map(&unique_id)
          already_there_ids = [0] if already_there_ids.empty?
          table.to_s.classify.constantize.where("user_id=? AND #{unique_id} NOT IN (?)", from_user, already_there_ids).update_all(:user_id => target_user)
        rescue => e
          logger.error "migrating #{table} column user_id failed: #{e.to_s}"
        end
      end
      from_user.all_conversations.find_each{ |c| c.move_to_user(target_user) } unless Shard.current != target_user.shard
      updates = {}
      ['account_users','asset_user_accesses',
        'attachments',
        'calendar_events','collaborations',
        'context_module_progressions','discussion_entries','discussion_topics',
        'enrollments','group_memberships','page_comments',
        'rubric_assessments',
        'submission_comment_participants','user_services','web_conferences',
        'web_conference_participants','wiki_pages'].each do |key|
        updates[key] = "user_id"
      end
      updates['submission_comments'] = 'author_id'
      updates['conversation_messages'] = 'author_id'
      updates = updates.to_a
      updates << ['enrollments', 'associated_user_id']
      updates.each do |table, column|
        begin
          klass = table.classify.constantize
          if klass.new.respond_to?("#{column}=".to_sym)
            klass.connection.execute("UPDATE #{table} SET #{column}=#{target_user.id} WHERE #{column}=#{from_user.id}")
          end
        rescue => e
          logger.error "migrating #{table} column #{column} failed: #{e.to_s}"
        end
      end

      unless Shard.current != target_user.shard
        # delete duplicate enrollments where this user is the observee
        target_user.observee_enrollments.remove_duplicates!

        # delete duplicate observers/observees, move the rest
        from_user.user_observees.where(:user_id => target_user.user_observees.map(&:user_id)).delete_all
        from_user.user_observees.update_all(:observer_id => target_user)
        xor_observer_ids = (Set.new(from_user.user_observers.map(&:observer_id)) ^ target_user.user_observers.map(&:observer_id)).to_a
        from_user.user_observers.where(:observer_id => target_user.user_observers.map(&:observer_id)).delete_all
        from_user.user_observers.update_all(:user_id => target_user)
        # for any observers not already watching both users, make sure they have
        # any missing observer enrollments added
        target_user.user_observers.where(:observer_id => xor_observer_ids).each(&:create_linked_enrollments)
      end

      Enrollment.send_later(:recompute_final_scores, target_user.id)
      target_user.update_account_associations
    end

    from_user.reload
    target_user.touch
    from_user.destroy
  end

end
