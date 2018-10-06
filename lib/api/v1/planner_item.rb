#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

module Api::V1::PlannerItem
  include Api::V1::Json
  include Api::V1::Assignment
  include Api::V1::Quiz
  include Api::V1::Context
  include Api::V1::DiscussionTopics
  include Api::V1::WikiPage
  include Api::V1::PlannerOverride
  include Api::V1::CalendarEvent
  include Api::V1::PlannerNote
  include Api::V1::AssessmentRequest
  include PlannerHelper

  API_PLANNABLE_FIELDS = [:id, :title, :course_id, :location_name, :todo_date, :details, :url, :unread_count,
                          :read_state, :created_at, :updated_at].freeze
  CALENDAR_PLANNABLE_FIELDS = [:all_day, :description, :start_at, :end_at].freeze
  GRADABLE_FIELDS = [:assignment_id, :points_possible, :due_at].freeze
  PLANNER_NOTE_FIELDS = [:user_id].freeze
  ASSESSMENT_REQUEST_FIELDS = [:workflow_state].freeze

  def planner_item_json(item, user, session, opts = {})
    context_data(item, use_effective_code: true).merge({
      :plannable_id => item.id,
      :planner_override => planner_override_json(item.planner_override_for(user), user, session, item.class_name),
      :plannable_type => PLANNABLE_TYPES.key(item.class_name),
      :new_activity => new_activity(item, user, opts)
    }).merge(submission_statuses_for(user, item, opts)).tap do |hash|
      if item.is_a?(::CalendarEvent)
        hash[:plannable_date] = item.start_at || item.created_at
        hash[:plannable] = plannable_json(item.attributes, extra_fields: CALENDAR_PLANNABLE_FIELDS)
        hash[:html_url] = calendar_url_for(item.effective_context, event: item)
      elsif item.is_a?(::PlannerNote)
        hash[:plannable_date] = item.todo_date || item.created_at
        hash[:plannable] = plannable_json(item.attributes, extra_fields: PLANNER_NOTE_FIELDS)
        # TODO: We don't currently have an html_url for individual planner items.
        # hash[:html_url] = ???
      elsif item.is_a?(Quizzes::Quiz) || (item.respond_to?(:quiz?) && item.quiz?)
        hash[:plannable_date] = item[:user_due_date] || item.due_at
        quiz = item.is_a?(Quizzes::Quiz) ? item : item.quiz
        hash[:plannable_id] = quiz.id
        hash[:plannable_type] = PLANNABLE_TYPES.key(quiz.class_name)
        hash[:plannable] = plannable_json(quiz.attributes, extra_fields: GRADABLE_FIELDS)
        hash[:html_url] = named_context_url(quiz.context, :context_quiz_url, quiz.id)
        hash[:planner_override] ||= planner_override_json(quiz.planner_override_for(user), user, session)
      elsif item.is_a?(WikiPage) || (item.respond_to?(:wiki_page?) && item.wiki_page?)
        item = item.wiki_page if item.respond_to?(:wiki_page?) && item.wiki_page?
        hash[:plannable_date] = item.todo_date || item.created_at
        hash[:plannable_type] = PLANNABLE_TYPES.key(item.class_name)
        hash[:plannable] = plannable_json(item.attributes)
        hash[:html_url] = named_context_url(item.context, :context_wiki_page_url, item.url)
        hash[:planner_override] ||= planner_override_json(item.planner_override_for(user), user, session)
      elsif item.is_a?(Announcement)
        ann_hash = item.attributes
        ann_hash.delete('todo_date')
        unread_count, read_state = topics_status_for(user, item.id, opts[:topics_status])[item.id]
        hash[:plannable_date] = item.posted_at || item.created_at
        hash[:plannable] = plannable_json({unread_count: unread_count, read_state: read_state}.merge(ann_hash))
        hash[:html_url] = named_context_url(item.context, :context_discussion_topic_url, item.id)
      elsif item.is_a?(DiscussionTopic) || (item.respond_to?(:discussion_topic?) && item.discussion_topic?)
        topic = item.is_a?(DiscussionTopic) ? item : item.discussion_topic
        unread_count, read_state = topics_status_for(user, topic.id, opts[:topics_status])[topic.id]
        unread_attributes = {unread_count: unread_count, read_state: read_state}
        hash[:plannable_id] = topic.id
        hash[:plannable_date] = item[:user_due_date] || topic.todo_date || topic.posted_at || topic.created_at
        hash[:plannable_type] = PLANNABLE_TYPES.key(topic.class_name)
        hash[:plannable] = plannable_json(unread_attributes.merge(item.attributes).merge(topic.attributes), extra_fields: GRADABLE_FIELDS)
        hash[:html_url] = discussion_topic_html_url(topic, user, hash[:submissions])
        hash[:planner_override] ||= planner_override_json(topic.planner_override_for(user), user, session, topic.class_name)
      elsif item.is_a?(AssessmentRequest)
        hash[:plannable_type] = PLANNABLE_TYPES.key(item.class_name)
        hash[:plannable_date] = item.asset.assignment.peer_reviews_due_at || item.assessor_asset.cached_due_date
        title_date = {title: item.asset&.assignment&.title, todo_date: hash[:plannable_date]}
        hash[:plannable] = plannable_json(title_date.merge(item.attributes), extra_fields: ASSESSMENT_REQUEST_FIELDS)
        hash[:html_url] = course_assignment_submission_url(item.asset.assignment.context_id, item.asset.assignment_id, item.user_id)
      else
        hash[:plannable_date] = item[:user_due_date] || item.due_at
        hash[:plannable] = plannable_json(item.attributes, extra_fields: GRADABLE_FIELDS)
        hash[:html_url] = assignment_html_url(item, user, hash[:submissions])
      end
    end.tap do |hash|
      if (context = item.try(:context) || item.try(:course))
        hash[:context_name] = context.try(:nickname_for, @user) || context.name
        if context.is_a?(::Course) && context.feature_enabled?(:course_card_images)
          hash[:context_image] = context.image
        end
      end
    end
  end

  def planner_items_json(items, user, session, opts = {})
    preload_items = items.map do |i|
      if i.try(:wiki_page?)
        i.wiki_page
      elsif i.try(:discussion_topic?)
        i.discussion_topic
      elsif i.try(:quiz?)
        i.quiz
      else
        i
      end
    end

    ActiveRecord::Associations::Preloader.new.preload(preload_items, :planner_overrides, ::PlannerOverride.where(user: user))
    events, other_items = preload_items.partition{|i| i.is_a?(::CalendarEvent)}
    ActiveRecord::Associations::Preloader.new.preload(events, :context) if events.any?
    assessment_requests, plannable_items = other_items.partition{|i| i.is_a?(::AssessmentRequest)}
    ActiveRecord::Associations::Preloader.new.preload(assessment_requests, [:assessor_asset, submission: {assignment: :context}]) if assessment_requests.any?
    notes, context_items = plannable_items.partition{|i| i.is_a?(::PlannerNote)}
    ActiveRecord::Associations::Preloader.new.preload(notes, user: {pseudonym: :account}) if notes.any?
    wiki_pages, other_context_items = context_items.partition{|i| i.is_a?(::WikiPage)}
    ActiveRecord::Associations::Preloader.new.preload(wiki_pages, {context: :root_account}) if wiki_pages.any?
    ActiveRecord::Associations::Preloader.new.preload(other_context_items, {context: :root_account}) if other_context_items.any?
    ss = user.submission_statuses(opts)
    discussions, _assign_quiz_items = other_context_items.partition{|i| i.is_a?(::DiscussionTopic)}
    topics_status = topics_status_for(user, discussions.map(&:id))

    items.map do |item|
      planner_item_json(item, user, session, opts.merge(submission_statuses: ss, topics_status: topics_status))
    end
  end

  # This method was built to save time from the standard assignment/quiz/discussion_topic_json
  # methods.  DO NOT add fields that are not on the object unless you load them all at once
  # as has been done with discussion topics unread count
  def plannable_json(item_hash, extra_fields: [])
    item_hash = item_hash.with_indifferent_access
    item_hash[:due_at] = item_hash.delete(:user_due_date) if item_hash.key?(:user_due_date)
    item_hash.slice(*API_PLANNABLE_FIELDS, *extra_fields)
  end

  def submission_statuses_for(user, item, opts = {})
    submission_status = {submissions: false}
    return submission_status unless item.is_a?(Assignment)
    ss = opts[:submission_statuses] || user.submission_statuses(opts)
    submission_status[:submissions] = {
      submitted: ss[:submitted].include?(item.id),
      excused: ss[:excused].include?(item.id),
      graded: ss[:graded].include?(item.id),
      late: ss[:late].include?(item.id),
      missing: ss[:missing].include?(item.id),
      needs_grading: ss[:needs_grading].include?(item.id),
      has_feedback: ss[:has_feedback].include?(item.id)
    }

    # planner will display the most recent comment not made by the user herself
    if submission_status[:submissions][:has_feedback]
      relevant_submissions = user.recent_feedback.select {|s| s.assignment_id == item.id}
      ActiveRecord::Associations::Preloader.new.preload(relevant_submissions, [visible_submission_comments: [:author, submission: :assignment]])
      feedback_data = relevant_submissions.
        flat_map(&:visible_submission_comments).
        reject{|comment| comment.author_id == user.id}. # omit comments by the user's own self
        sort_by(&:updated_at).
        last

      if feedback_data.present?
        submission_status[:submissions][:feedback] = {
          comment: feedback_data.comment,
          is_media: feedback_data.media_comment_id?
        }
        if feedback_data.can_read_author?(user, nil)
          submission_status[:submissions][:feedback].merge!({
            author_name: feedback_data.author_name,
            author_avatar_url: feedback_data.author.avatar_url,
          })
        end
      end
    end

    submission_status
  end

  def topics_status_for(user, topic_ids, topics_status={})
    topics_status ||= {}
    unknown_topic_ids = Array(topic_ids) - topics_status.keys
    if unknown_topic_ids.any?
      participant_info = DiscussionTopic.select("discussion_topics.id, COALESCE(dtp.unread_entry_count, COUNT(de.id)) AS unread_entry_count,
        COALESCE(dtp.workflow_state, 'unread') AS unread_state").
        joins("LEFT JOIN #{DiscussionTopicParticipant.quoted_table_name} AS dtp
                 ON dtp.discussion_topic_id = discussion_topics.id
                AND dtp.user_id = #{User.connection.quote(user)}
               LEFT JOIN #{DiscussionEntry.quoted_table_name} AS de
                 ON de.discussion_topic_id = discussion_topics.id
                AND dtp.id IS NULL").
        where(id: unknown_topic_ids).
        group("discussion_topics.id, dtp.id")
      participant_info.each do |pi|
        topics_status[pi[:id]] = [pi[:unread_entry_count], pi[:unread_state]]
      end
    end
    topics_status
  end

  def new_activity(item, user, opts = {})
    if item.is_a?(Assignment) || item.try(:assignment)
      ss = opts[:submission_statuses] || user.submission_statuses(opts)
      assign = item.try(:assignment) || item
      return true if ss.dig(:new_activity).include?(assign.id)
    end
    if item.is_a?(DiscussionTopic) || item.try(:discussion_topic)
      topic = item.try(:discussion_topic) || item
      unread_count, read_state = opts.dig(:topics_status, topic.id)
      return (read_state == 'unread' || unread_count > 0) if unread_count && read_state
      return (topic.unread?(user) || topic.unread_count(user) > 0) if topic
    end
    false
  end

  private

  def assignment_feedback_url(assignment, user, submission_info)
    return nil unless assignment
    return nil unless submission_info
    return nil unless submission_info[:submitted] || submission_info[:graded] || submission_info[:has_feedback]
    context_url(assignment.context, :context_assignment_submission_url, assignment.id, user.id)
  end

  def assignment_html_url(assignment, user, submission_info)
    assignment_feedback_url(assignment, user, submission_info) || named_context_url(assignment.context, :context_assignment_url, assignment.id)
  end

  def discussion_topic_html_url(topic, user, submission_info)
    assignment_feedback_url(topic.assignment, user, submission_info) || named_context_url(topic.context, :context_discussion_topic_url, topic.id)
  end
end
