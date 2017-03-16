class SplitUsers
  ENROLLMENT_DATA_UPDATES = [
    {table: 'asset_user_accesses',
     scope: -> { where(context_type: 'Course') }}.freeze,
    {table: 'asset_user_accesses',
     scope: -> { joins(:context_group).where(groups: {context_type: 'Course'}) }, context_id: 'groups.context_id'}.freeze,
    {table: 'calendar_events',
     scope: -> { where(context_type: 'Course') }}.freeze,
    {table: 'calendar_events',
     scope: -> { joins(:context_group).where(groups: {context_type: 'Course'}) },
     context_id: 'groups.context_id'}.freeze,
    {table: 'collaborations',
     scope: -> { where(context_type: 'Course') }}.freeze,
    {table: 'collaborations',
     scope: -> { joins(:group).where(groups: {context_type: 'Course'}) },
     context_id: 'groups.context_id'}.freeze,
    {table: 'context_module_progressions',
     scope: -> { joins(:context_module) },
     context_id: 'context_modules.context_id'}.freeze,
    {table: 'discussion_entries',
     scope: -> { joins(:discussion_topic).where(discussion_topics: {context_type: 'Course'}) },
     context_id: 'discussion_topics.context_id'}.freeze,
    {table: 'discussion_entries',
     scope: -> { joins({discussion_topic: :group}).where(groups: {context_type: 'Course'}) },
     context_id: 'groups.context_id'}.freeze,
    {table: 'discussion_entries', foreign_key: :editor_id,
     scope: -> { joins(:discussion_topic).where(discussion_topics: {context_type: 'Course'}) },
     context_id: 'discussion_topics.context_id'}.freeze,
    {table: 'discussion_entries', foreign_key: :editor_id,
     scope: -> { joins({discussion_topic: :group}).where(groups: {context_type: 'Course'}) },
     context_id: 'groups.context_id'}.freeze,
    {table: 'discussion_topics',
     scope: -> { where(context_type: 'Course') }}.freeze,
    {table: 'discussion_topics',
     scope: -> { joins(:group).where(groups: {context_type: 'Course'}) },
     context_id: 'groups.context_id'}.freeze,
    {table: 'discussion_topics', foreign_key: :editor_id,
     scope: -> { where(context_type: 'Course') }}.freeze,
    {table: 'discussion_topics', foreign_key: :editor_id,
     scope: -> { joins(:group).where(groups: {context_type: 'Course'}) },
     context_id: 'groups.context_id'}.freeze,
    {table: 'page_views',
     scope: -> { where(context_type: 'Course') }}.freeze,
    {table: 'rubric_assessments',
     scope: -> { joins({submission: :assignment}) },
     context_id: 'assignments.context_id'}.freeze,
    {table: 'rubric_assessments', foreign_key: :assessor_id,
     scope: -> { joins({submission: :assignment}) },
     context_id: 'assignments.context_id'}.freeze,
    {table: 'submission_comment_participants',
     scope: -> { joins(:submission_comment) },
     context_id: 'submission_comments.context_id'}.freeze,
    {table: 'submission_comments', foreign_key: :author_id}.freeze,
    {table: 'web_conference_participants',
     scope: -> { joins(:web_conference).where(web_conferences: {context_type: 'Course'}) },
     context_id: 'web_conferences.context_id'}.freeze,
    {table: 'web_conference_participants',
     scope: -> { joins({web_conference: :group}).where(web_conferences: {context_type: 'Course'}, groups: {context_type: 'Course'}) },
     context_id: 'groups.context_id'}.freeze,
    {table: 'web_conferences',
     scope: -> { where(context_type: 'Course') }}.freeze,
    {table: 'web_conferences',
     scope: -> { joins(:group).where(web_conferences: {context_type: 'Course'}, groups: {context_type: 'Course'}) },
     context_id: 'groups.context_id'}.freeze,
    {table: 'wiki_pages',
     scope: -> { joins({wiki: :course}) },
     context_id: 'courses.id'}.freeze
  ].freeze

  def self.split_db_users(user, merge_data = nil)
    if merge_data
      users = split_users(user, merge_data)
    else
      users = []
      UserMergeData.active.splitable.where(user_id: user).shard(user).find_each do |data|
        splitters = split_users(user, data)
        users = splitters | users
      end
    end
    users
  end

  class << self
    private

    def split_users(user, merge_data)
      user.shard.activate do
        ActiveRecord::Base.transaction do
          records = merge_data.user_merge_data_records
          old_user = User.find(merge_data.from_user_id)
          old_user = restore_old_user(old_user, records)
          move_records_to_old_user(user, old_user, records)
          # update account associations for each split out user
          users = [old_user, user]
          User.update_account_associations(users, all_shards: !(old_user.shard == user.shard))
          merge_data.destroy
          update_grades(users, records)
          User.where(id: users).touch_all
          users
        end
      end
    end

    def move_records_to_old_user(source_user, user, records)
      fix_communication_channels(source_user, user, records.where(context_type: 'CommunicationChannel'))
      move_user_observers(source_user, user, records.where(context_type: 'UserObserver', previous_user_id: user))
      move_attachments(source_user, user, records.where(context_type: 'Attachment'))
      enrollment_ids = records.where(context_type: 'Enrollment', previous_user_id: user).pluck(:context_id)
      enrollments = Enrollment.where(id: enrollment_ids).where.not(user_id: user)
      courses = []
      enrollments.each do |e|
        # skip conflicting enrollments
        next if Enrollment.where(user_id: user,
                                 course_section_id: e.course_section_id,
                                 type: e.type,
                                 role_id: e.role_id).where.not(id: e).shard(e.shard).exists?

        e.user_id = user
        e.save_without_callbacks
        courses << e.course_id
      end
      transfer_enrollment_data(source_user, user, Course.where(id: courses))

      account_users_ids = records.where(context_type: 'AccountUser').pluck(:context_id)
      AccountUser.where(id: account_users_ids).update_all(user_id: user)
      restore_worklow_states_from_records(records)
    end

    def fix_communication_channels(source_user, user, cc_records)
      if source_user.shard != user.shard
        user.shard.activate do
          # remove communication channels that didn't exist prior to the merge
          CommunicationChannel.where(id: cc_records.where(previous_workflow_state: 'non_existent').pluck(:context_id)).delete_all
        end
      end
      # move moved communication channels back
      max_position = user.communication_channels.last.try(:position) || 0
      scope = source_user.communication_channels.where(id: cc_records.where(previous_user_id: user).pluck(:context_id))
      scope.update_all(["user_id=?, position=position+?", user, max_position]) unless scope.empty?

      cc_records.where.not(previous_workflow_state: 'non existent').each do |cr|
        CommunicationChannel.where(id: cr.context_id).update_all(workflow_state: cr.previous_workflow_state)
      end
    end

    def move_user_observers(source_user, user, records)
      # skip when the user observer is between the two users. Just undlete the record
      not_obs = UserObserver.where(user_id: [source_user, user], observer_id: [source_user, user])
      obs = UserObserver.where(id: records.pluck(:context_id)).where.not(id: not_obs)

      source_user.user_observers.where(id: obs).update_all(user_id: user)
      source_user.user_observees.where(id: obs).update_all(observer_id: user)
    end

    def move_attachments(source_user, user, records)
      attachments = source_user.attachments.where(id: records.pluck(:context_id))
      Attachment.migrate_attachments(source_user, user, attachments)
    end

    def update_grades(users, records)
      users.each do |user|
        e_ids = records.where(previous_user_id: user, context_type: 'Enrollment').pluck(:context_id)
        user.enrollments.where(id: e_ids).joins(:course).
          where.not(courses: {workflow_state: 'deleted'}).
          select(&:student?).uniq { |e| [e.user_id, e.course_id] }.
          each { |e| Enrollment.recompute_final_score_in_singleton(e.user_id, e.course_id) }
      end
    end

    def restore_old_user(user, records)
      pseudonyms_ids = records.where(context_type: 'Pseudonym').pluck(:context_id)
      pseudonyms = Pseudonym.where(id: pseudonyms_ids)
      user ||= User.create!(name: pseudonyms.first.unique_id)
      user.workflow_state = 'registered'
      user.save!
      move_pseudonyms_to_user(pseudonyms, user)
      user
    end

    def move_pseudonyms_to_user(pseudonyms, target_user)
      pseudonyms.each do |pseudonym|
        pseudonym.update_attribute(:user_id, target_user.id)
      end
    end

    def transfer_enrollment_data(source_user, target_user, courses)
      Shard.partition_by_shard(courses) do |shard_course|
        source_user_id = source_user.id
        target_user_id = target_user.id
        ENROLLMENT_DATA_UPDATES.each do |update|
          relation = update[:table].classify.constantize.all
          relation = relation.instance_exec(&update[:scope]) if update[:scope]

          relation.
            where((update[:context_id] || :context_id) => shard_course,
                  (update[:foreign_key] || :user_id) => source_user_id).
            update_all((update[:foreign_key] || :user_id) => target_user_id)
        end
        # avoid conflicting submissions for the unique index on user and assignment
        handle_submissions(courses, source_user, target_user, target_user_id)
      end
    end

    def handle_submissions(courses, source_user, target_user, target_user_id)
      source_user.submissions.where(assignment_id: Assignment.where(context_id: courses)).
        where.not(assignment_id: target_user.submissions.select(:assignment_id)).
        update_all(user_id: target_user_id)
      source_user.quiz_submissions.where(quiz_id: Quizzes::Quiz.where(context_id: courses)).
        where.not(quiz_id: target_user.quiz_submissions.select(:quiz_id)).
        update_all(user_id: target_user_id)
    end

    def restore_worklow_states_from_records(records)
      records.each do |r|
        c = r.context
        next unless c && c.class.columns_hash.key?('workflow_state')
        c.workflow_state = r.previous_workflow_state unless c.class == Attachment
        c.file_state = r.previous_workflow_state if c.class == Attachment
        c.save! if c.changed? && c.valid?
      end
    end
  end
end
