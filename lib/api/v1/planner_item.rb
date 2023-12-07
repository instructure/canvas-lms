# frozen_string_literal: true

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
  include PlannerApiHelper

  API_PLANNABLE_FIELDS = %i[id
                            title
                            course_id
                            location_name
                            todo_date
                            details
                            url
                            unread_count
                            read_state
                            created_at
                            updated_at].freeze
  CALENDAR_PLANNABLE_FIELDS = %i[all_day
                                 location_address
                                 description
                                 start_at
                                 end_at
                                 online_meeting_url].freeze
  GRADABLE_FIELDS = %i[assignment_id points_possible due_at].freeze
  PLANNER_NOTE_FIELDS = [:user_id].freeze
  ASSESSMENT_REQUEST_FIELDS = [:workflow_state].freeze

  def planner_item_json(item, user, session, opts = {})
    planner_override = item.planner_override_for(user)
    planner_override.plannable = item if planner_override
    context_data(item, use_effective_code: true).merge({
                                                         plannable_id: item.id,
                                                         planner_override: planner_override_json(planner_override, user, session, item.class_name),
                                                         plannable_type: PlannerHelper::PLANNABLE_TYPES.key(item.class_name),
                                                         new_activity: new_activity(item, user, opts)
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
        hash[:plannable_type] = PlannerHelper::PLANNABLE_TYPES.key(quiz.class_name)
        hash[:plannable] = plannable_json(quiz.attributes, extra_fields: GRADABLE_FIELDS)
        hash[:html_url] = named_context_url(quiz.context, :context_quiz_url, quiz.id)
        hash[:planner_override] ||= planner_override_json(quiz.planner_override_for(user), user, session)
      elsif item.is_a?(WikiPage) || (item.respond_to?(:wiki_page?) && item.wiki_page?)
        item = item.wiki_page if item.respond_to?(:wiki_page?) && item.wiki_page?
        hash[:plannable_date] = item.todo_date || item.created_at
        hash[:plannable_type] = PlannerHelper::PLANNABLE_TYPES.key(item.class_name)
        hash[:plannable] = plannable_json(item.attributes)
        hash[:html_url] = named_context_url(item.context, :context_wiki_page_url, item.url)
        hash[:planner_override] ||= planner_override_json(item.planner_override_for(user), user, session)
      elsif item.is_a?(Announcement)
        ann_hash = item.attributes
        ann_hash.delete("todo_date")
        unread_count, read_state = topics_status_for(user, item.id, opts[:topics_status])[item.id]
        hash[:plannable_date] = item.posted_at || item.created_at
        hash[:plannable] = plannable_json({ unread_count:, read_state: }.merge(ann_hash))
        hash[:html_url] = named_context_url(item.context, :context_discussion_topic_url, item.id)
      elsif item.is_a?(DiscussionTopic) || (item.respond_to?(:discussion_topic?) && item.discussion_topic?)
        topic = item.is_a?(DiscussionTopic) ? item : item.discussion_topic
        unread_count, read_state = topics_status_for(user, topic.id, opts[:topics_status])[topic.id]
        unread_attributes = { unread_count:, read_state: }
        hash[:plannable_id] = topic.id
        hash[:plannable_date] = item[:user_due_date] || topic.todo_date || topic.posted_at || topic.created_at
        hash[:plannable_type] = PlannerHelper::PLANNABLE_TYPES.key(topic.class_name)
        hash[:plannable] = plannable_json(unread_attributes.merge(item.attributes).merge(topic.attributes), extra_fields: GRADABLE_FIELDS)
        hash[:html_url] = discussion_topic_html_url(topic, user, hash[:submissions])
        hash[:planner_override] ||= planner_override_json(topic.planner_override_for(user), user, session, topic.class_name)
      elsif item.is_a?(AssessmentRequest)
        hash[:plannable_type] = PlannerHelper::PLANNABLE_TYPES.key(item.class_name)
        hash[:plannable_date] = item.asset.assignment.peer_reviews_due_at || item.assessor_asset.cached_due_date
        title_date = { title: item.asset&.assignment&.title, todo_date: hash[:plannable_date] }
        hash[:plannable] = plannable_json(title_date.merge(item.attributes), extra_fields: ASSESSMENT_REQUEST_FIELDS)
        hash[:html_url] = Submission::ShowPresenter.new(
          submission: item.asset,
          current_user: user,
          assessment_request: item
        ).submission_data_url
      else
        hash[:plannable_date] = item[:user_due_date] || item.due_at
        hash[:plannable] = plannable_json(item.attributes, extra_fields: GRADABLE_FIELDS)
        hash[:html_url] = assignment_html_url(item, user, hash[:submissions])
      end
      if item.respond_to?(:restrict_quantitative_data?) && item.restrict_quantitative_data?(@current_user)
        hash[:plannable][:restrict_quantitative_data] = true
      end
    end.tap do |hash|
      if (context = item.try(:context) || item.try(:course))
        hash[:context_name] = context.try(:nickname_for, @user) || context.name
        if context.is_a?(::Course)
          hash[:context_image] = context.image
        end
      end
    end
  end

  def planner_items_json(items, user, session, opts = {})
    preload_items = items.each_with_object([]) do |item, memo|
      memo << item
      if item.try(:submittable_object)
        item.submittable_object.assignment = item # fixes loading for inverse associations that don't seem to be working
        memo << item.submittable_object
      end
    end

    ActiveRecord::Associations.preload(preload_items, :planner_overrides, ::PlannerOverride.where(user:))
    events, other_items = preload_items.partition { |i| i.is_a?(::CalendarEvent) }
    ActiveRecord::Associations.preload(events, :context) if events.any?
    assessment_requests, plannable_items = other_items.partition { |i| i.is_a?(::AssessmentRequest) }
    ActiveRecord::Associations.preload(assessment_requests, [:assessor_asset, asset: { assignment: :context }]) if assessment_requests.any?
    notes, context_items = plannable_items.partition { |i| i.is_a?(::PlannerNote) }
    ActiveRecord::Associations.preload(notes, user: { pseudonym: :account }) if notes.any?
    ActiveRecord::Associations.preload(context_items, { context: :root_account }) if context_items.any?
    ss = submission_statuses(context_items.select { |i| i.is_a?(::Assignment) }, user)
    discussions = context_items.select { |i| i.is_a?(::DiscussionTopic) }
    topics_status = topics_status_for(user, discussions.map(&:id))

    items.map do |item|
      planner_item_json(item, user, session, opts.merge(submission_statuses: ss, topics_status:))
    end
  end

  # This method was built to save time from the standard assignment/quiz/discussion_topic_json
  # methods.  DO NOT add fields that are not on the object unless you load them all at once
  # as has been done with discussion topics unread count
  def plannable_json(item_hash, extra_fields: [])
    item_hash = item_hash.with_indifferent_access
    item_hash[:due_at] = item_hash.delete(:user_due_date) if item_hash.key?(:user_due_date)
    url = online_meeting_url(item_hash[:description], item_hash[:location_name])
    item_hash[:online_meeting_url] = url if url
    item_hash.slice(*API_PLANNABLE_FIELDS, *extra_fields)
  end

  def submission_statuses_for(user, item, opts = {})
    submission_status = { submissions: false }
    return submission_status unless item.is_a?(Assignment)

    ss = opts[:submission_statuses] || submission_statuses(item, user)
    submission_status[:submissions] = ss[item.id]&.except(:new_activity)
    submission_status
  end

  def submission_statuses(assignments, user)
    subs = Submission.where(assignment: assignments, user:)
                     .preload([:content_participations, visible_submission_comments: :author])
    subs_hash = subs.index_by(&:assignment_id)
    subs_data_hash = {}
    Array(assignments).each do |assign|
      submission = subs_hash[assign.id]
      submission.assignment = assign if submission # fixes loading for inverse associations that don't seem to be working
      sub_data_hash = {
        submitted: submission&.has_submission?,
        excused: submission&.excused?,
        graded: submission&.graded?,
        posted_at: submission&.posted_at,
        late: submission&.late?,
        missing: submission&.missing?,
        needs_grading: submission&.needs_grading?,
        has_feedback: submission&.last_teacher_comment.present?,
        new_activity: submission&.unread?(user),
        redo_request: submission&.redo_request?
      }
      sub_data_hash[:feedback] = feedback_data(submission, user) if sub_data_hash[:has_feedback]
      subs_data_hash[assign.id] = sub_data_hash
    end
    subs_data_hash
  end

  def feedback_data(submission, user)
    feedback_hash = {}
    last_teacher_comment = submission.last_teacher_comment
    last_teacher_comment.submission = submission # otherwise you get a couple more queries, because the association is lost somehow
    feedback_hash[:comment] = last_teacher_comment.comment
    feedback_hash[:is_media] = last_teacher_comment.media_comment_id?
    if last_teacher_comment.can_read_author?(user, nil)
      feedback_hash[:author_name] = last_teacher_comment.author_name
      feedback_hash[:author_avatar_url] = last_teacher_comment.author&.avatar_url
    end
    feedback_hash
  end

  def topics_status_for(user, topic_ids, topics_status = {})
    topics_status ||= {}
    unknown_topic_ids = Array(topic_ids) - topics_status.keys
    if unknown_topic_ids.any?
      Shard.partition_by_shard(unknown_topic_ids) do |u_topic_ids|
        DiscussionTopic
          .select("discussion_topics.id,
                   COALESCE(dtp.unread_entry_count, COUNT(de.id)) AS unread_entry_count,
                   COALESCE(dtp.workflow_state, 'unread') AS unread_state")
          .joins("LEFT JOIN #{DiscussionTopicParticipant.quoted_table_name} AS dtp
                    ON dtp.discussion_topic_id = discussion_topics.id
                    AND dtp.user_id = #{User.connection.quote(user&.id_for_database)}
                  LEFT JOIN #{DiscussionEntry.quoted_table_name} AS de
                    ON de.discussion_topic_id = discussion_topics.id
                    AND dtp.id IS NULL")
          .where(id: u_topic_ids)
          .group("discussion_topics.id, dtp.id")
          .each do |pi|
          topics_status[pi[:id]] = [pi[:unread_entry_count], pi[:unread_state]]
        end
      end
    end
    topics_status
  end

  def new_activity(item, user, opts = {})
    if item.is_a?(Assignment) || item.try(:assignment)
      assign = item.try(:assignment) || item
      ss = opts[:submission_statuses] || submission_statuses(assign, user)
      return true if ss.dig(assign.id, :new_activity)
    end
    if item.is_a?(DiscussionTopic) || item.try(:discussion_topic)
      topic = item.try(:discussion_topic) || item
      unread_count, read_state = opts.dig(:topics_status, topic.id)
      return read_state == "unread" || unread_count > 0 if unread_count && read_state
      return topic.unread?(user) || topic.unread_count(user) > 0 if topic
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

  def online_meeting_url(event_description, event_location)
    config = DynamicSettings.find("canvas", tree: "config", service: "canvas")
    default_regex = <<~'REGEX'
      https:\/\/[\w-]+\.zoom\.us\/\d+(\?[\w\/\-=%]*)?
      https:\/\/[\w-]+\.zoom\.us\/my\/[\w.]+(\?[\w\/\-=%]*)?
      https:\/\/[\w-]+\.zoom\.us\/j\/\d+(\?[\w\/\-=%]*)?
      https:\/\/teams\.microsoft\.com\/l\/meetup-join\/[\w.\/\-=%]+(\?[\w\/\-=%]*)?
      https:\/\/teams\.live\.com\/meet\/\d+(\?[\w\/\-=%]*)?
      https:\/\/[\w-]+\.webex\.com\/meet\/[\w.\/\-=%]+(\?[\w\/\-=%]*)?
      https:\/\/[\w-]+\.webex\.com\/\w+\/j\.php(\?[\w\/\-=%]*)?
      https:\/\/meet\.google\.com\/[\w\/\-=%]+(\?[\w\/\-=%]*)?
      https?:\/\/.*\/conferences\/\d+\/join
    REGEX
    url_regex_str = config["online-meeting-url-regex"] || default_regex
    url_regex_str = url_regex_str.split("\n").join("|")
    url_regex = Regexp.new "(#{url_regex_str})"

    if event_description
      m = event_description.match(url_regex)
      return m[0] if m
    end

    if event_location
      m = event_location.match(url_regex)
      return m[0] if m
    end

    nil
  end
end
