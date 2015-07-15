class EnsureSubmissionsForDiscussions < ActiveRecord::Migration
  def self.up
    # entries from graded topics where the poster is enrolled as a student in
    # the topic's assignment's course and there's no current submission for the
    # poster and that assignment, but only one entry per (topic, user) pair
    entries = DiscussionTopic.select(["discussion_entries.discussion_topic_id", "discussion_entries.user_id"]).
        uniq.
        joins("
      INNER JOIN #{Assignment.quoted_table_name} ON
        assignments.id=discussion_topics.assignment_id AND
        assignments.context_type='Course' AND
        assignments.submission_types='discussion_topic'
      INNER JOIN #{DiscussionEntry.quoted_table_name} ON
        discussion_entries.discussion_topic_id=discussion_topics.id AND
        discussion_entries.workflow_state!='deleted'
      INNER JOIN #{Enrollment.quoted_table_name} ON
        enrollments.course_id=assignments.context_id AND
        enrollments.user_id=discussion_entries.user_id AND
        enrollments.type='StudentEnrollment' AND
        enrollments.workflow_state NOT IN ('deleted', 'completed', 'rejected', 'inactive')
      LEFT JOIN #{Submission.quoted_table_name} ON
        submissions.assignment_id=assignments.id AND
        submissions.user_id=discussion_entries.user_id AND
        submissions.submission_type='discussion_topic'").
        where(discussion_topics: { workflow_state: 'active' },
              submissions: { id: nil })

    touched_course_ids = [].to_set
    touched_user_ids = [].to_set

    # don't touch the user on each submission, we'll do them in bulk later
    Submission.suspend_callbacks(:touch_user) do
      entries.each do |entry|
        # streamlined entry.discussiont_topic.ensure_submission(entry.user)
        assignment = Assignment.select(["assignments.id", :group_category_id, "assignments.context_id"]).
          joins("INNER JOIN #{DiscussionTopic.quoted_table_name} ON
            discussion_topics.assignment_id=assignments.id AND
            discussion_topics.id=#{entry.discussion_topic_id}").first

        # even if there's a group, we're only doing the one student on this pass,
        # since other group members will have their own row from the main query.
        # but we still need to know the group
        if assignment.group_category_id
          group_id = Group.joins("
            INNER JOIN #{GroupMembership.quoted_table_name} ON
              group_memberships.group_id=groups.id AND
              group_memberships.workflow_state<>'deleted' AND
              group_memberships.user_id=#{entry.user_id}").
            where(group_category_id: assignment.group_category_id).
            where("workflow_state<>'deleted'").
            limit(1).
            pluck(:id)
        end

        homework = Submission.where(assignment_id: assignment.id, user_id: entry.user_id).first_or_initialize
        homework.grade_matches_current_submission = homework.score ? false : true
        homework.attributes = {
          :attachment => nil,
          :processed => false,
          :process_attempts => 0,
          :workflow_state => "submitted",
          :group_id => group_id,
          :submission_type => 'discussion_topic'
        }

        # don't broadcast due to these fixes, period.
        homework.with_versioning(:explicit => true) do
          homework.save_without_broadcast
        end

        # set aside to do bulk course- and user-touch below
        touched_course_ids << assignment.context_id
        touched_user_ids << entry.user_id
      end
    end

    # touch all the courses and users
    Course.where(:id => touched_course_ids.to_a).update_all(:updated_at => Time.now.utc) unless touched_course_ids.empty?
    User.where(:id => touched_user_ids.to_a).update_all(:updated_at => Time.now.utc) unless touched_user_ids.empty?
  end
end
