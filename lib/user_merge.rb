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
    [:strong, :weak, :shadow].each do |strength|
      from_user.associated_shards(strength).each do |shard|
        target_user.associate_with_shard(shard, strength)
      end
    end

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

    destroy_conflicting_module_progressions(@from_user, target_user)

    Shard.with_each_shard(from_user.associated_shards + from_user.associated_shards(:weak) + from_user.associated_shards(:shadow)) do
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
      unless to_delete_ids.empty?
        Enrollment.where(:id => to_delete_ids).update_all(:workflow_state => 'deleted')
        target_user.communication_channels.email.unretired.each do |cc|
          Rails.cache.delete([cc.path, 'invited_enrollments'].cache_key)
        end
      end
      [
        [:quiz_id, :quiz_submissions],
        [:assignment_id, :submissions]
      ].each do |unique_id, table|
        begin
          # Submissions are a special case since there's a unique index
          # on the table, and if both the old user and the new user
          # have a submission for the same assignment there will be
          # a conflict.
          model = table.to_s.classify.constantize
          already_scope = model.where(:user_id => target_user)
          scope = model.where(:user_id => from_user)
          # empty submission objects from e.g. what_if grades will show up in the scope
          # these records will not have associated quiz_submission records even if the assignment in question is a quiz,
          # so we only need to fine-tune the scope for Submission
          if model.name == "Submission"
            # we prefer submissions that are not simply empty objects
            # also we delete empty objects in cases of collision so that we don't end up with multiple submission records for a given assignment
            # for the target user, we
            # a) delete empty submissions where there is a non-empty submission in the from user
            # b) don't delete otherwise
            already_scope.where(unique_id => scope.having_submission.select(unique_id)).without_submission.delete_all
          end
          # for the from user
          # a) we ignore the empty submissions in our update unless the target user has no submission
          # b) move the empty submission over to the new user if there is no collision, as we don't mind persisting the what_if history in this case
          # c) if there is an empty submission for each user for this assignment, prefer the target user
          scope.where("#{unique_id} NOT IN (?)", already_scope.select(unique_id)).update_all(:user_id => target_user)
        rescue => e
          Rails.logger.error "migrating #{table} column user_id failed: #{e.to_s}"
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
            klass.where(column => from_user).update_all(column => target_user.id)
          end
        rescue => e
          Rails.logger.error "migrating #{table} column #{column} failed: #{e.to_s}"
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

  def destroy_conflicting_module_progressions(from_user, target_user)
    # there is a unique index on the context_module_progressions table
    # we need to delete all the conflicting context_module_progressions
    # without impacting the users module progress and without having to
    # recalculate the progressions.
    # find all the modules progressions and delete the most restrictive
    # context_module_progressions
    ContextModuleProgression.
      where("context_module_progressions.user_id = ?", from_user.id).
      where("EXISTS (SELECT *
                     FROM context_module_progressions cmp2
                     WHERE context_module_progressions.context_module_id=cmp2.context_module_id
                       AND cmp2.user_id = ?)", target_user.id).find_each do |cmp|

      ContextModuleProgression.
        where(context_module_id: cmp.context_module_id, user_id: [from_user, target_user]).
        order("CASE WHEN workflow_state = 'Completed' THEN 0
                    WHEN workflow_state = 'Started' THEN 1
                    WHEN workflow_state = 'Unlocked' THEN 2
                    WHEN workflow_state = 'Locked' THEN 3
                END DESC").first.destroy
    end
  end

end
