#
# Copyright (C) 2011 Instructure, Inc.
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

# @API Discussion Topics
class DiscussionTopicsApiController < ApplicationController
  include Api::V1::DiscussionTopics
  include Api::V1::User
  include SubmittableHelper

  before_filter :require_context_and_read_access
  before_filter :require_topic
  before_filter :require_initial_post, except: [:add_entry, :mark_topic_read,
                                                :mark_topic_unread, :show,
                                                :unsubscribe_topic]
  before_filter only: [:replies, :entries, :add_entry, :add_reply, :show,
                       :view, :entry_list, :subscribe_topic] do
    check_differentiated_assignments(@topic)
  end

  # @API Get a single topic
  #
  # Returns data on an individual discussion topic. See the List action for the response formatting.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id> \
  #         -H 'Authorization: Bearer <token>'
  def show
    render(json: discussion_topics_api_json([@topic], @context,
                                            @current_user, session).first)
  end

  # @API Get the full topic
  # Return a cached structure of the discussion topic, containing all entries,
  # their authors, and their message bodies.
  #
  # May require (depending on the topic) that the user has posted in the topic.
  # If it is required, and the user has not posted, will respond with a 403
  # Forbidden status and the body 'require_initial_post'.
  #
  # In some rare situations, this cached structure may not be available yet. In
  # that case, the server will respond with a 503 error, and the caller should
  # try again soon.
  #
  # The response is an object containing the following keys:
  # * "participants": A list of summary information on users who have posted to
  #   the discussion. Each value is an object containing their id, display_name,
  #   and avatar_url.
  # * "unread_entries": A list of entry ids that are unread by the current
  #   user. this implies that any entry not in this list is read.
  # * "entry_ratings": A map of entry ids to ratings by the current user. Entries
  #   not in this list have no rating. Only populated if rating is enabled.
  # * "forced_entries": A list of entry ids that have forced_read_state set to
  #   true. This flag is meant to indicate the entry's read_state has been
  #   manually set to 'unread' by the user, so the entry should not be
  #   automatically marked as read.
  # * "view": A threaded view of all the entries in the discussion, containing
  #   the id, user_id, and message.
  # * "new_entries": Because this view is eventually consistent, it's possible
  #   that newly created or updated entries won't yet be reflected in the view.
  #   If the application wants to also get a flat list of all entries not yet
  #   reflected in the view, pass include_new_entries=1 to the request and this
  #   array of entries will be returned. These entries are returned in a flat
  #   array, in ascending created_at order.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/view' \
  #        -H "Authorization: Bearer <token>"
  #
  # @example_response
  #   {
  #     "unread_entries": [1,3,4],
  #     "entry_ratings": {3: 1},
  #     "forced_entries": [1],
  #     "participants": [
  #       { "id": 10, "display_name": "user 1", "avatar_image_url": "https://...", "html_url": "https://..." },
  #       { "id": 11, "display_name": "user 2", "avatar_image_url": "https://...", "html_url": "https://..." }
  #     ],
  #     "view": [
  #       { "id": 1, "user_id": 10, "parent_id": null, "message": "...html text...", "replies": [
  #         { "id": 3, "user_id": 11, "parent_id": 1, "message": "...html....", "replies": [...] }
  #       ]},
  #       { "id": 2, "user_id": 11, "parent_id": null, "message": "...html..." },
  #       { "id": 4, "user_id": 10, "parent_id": null, "message": "...html..." }
  #     ]
  #   }
  def view
    return unless authorized_action(@topic, @current_user, :read_replies)

    structure, participant_ids, entry_ids, new_entries = @topic.materialized_view(:include_new_entries => params[:include_new_entries] == '1')

    if structure
      structure = resolve_placeholders(structure)

      # we assume that json_structure will typically be served to users requesting string IDs
      unless stringify_json_ids?
        entries = JSON.parse(structure)
        StringifyIds.recursively_stringify_ids(entries, reverse: true)
        structure = entries.to_json
      end

      participants = Shard.partition_by_shard(participant_ids) do |shard_ids|
        # Preload accounts because they're needed to figure out if a user's avatar should be shown in
        # AvatarHelper#avatar_url_for_user, which is used by user_display_json. We get an N+1 on the
        # number of discussion participants if we don't do this.
        User.where(id: shard_ids).preload({pseudonym: :account}).to_a
      end

      include_enrollment_state = params[:include_enrollment_state] && (@context.is_a?(Course) || @context.is_a?(Group)) &&
        @context.grants_right?(@current_user, session, :read_as_admin)
      enrollments = nil
      if include_enrollment_state
        enrollment_context = @context.is_a?(Course) ? @context : @context.context
        all_enrollments = enrollment_context.enrollments.where(:user_id => participants).to_a
        Canvas::Builders::EnrollmentDateBuilder.preload_state(all_enrollments)
        all_enrollments = all_enrollments.group_by(&:user_id)
      end

      participant_info = participants.map do |participant|
        json = user_display_json(participant, @context.is_a_context? && @context)
        if include_enrollment_state
          enrolls = all_enrollments[participant.id] || []
          json[:isInactive] = enrolls.any? && enrolls.all?(&:inactive?)
        end

        json
      end

      unread_entries = entry_ids - DiscussionEntryParticipant.read_entry_ids(entry_ids, @current_user)
      unread_entries = unread_entries.map(&:to_s) if stringify_json_ids?
      forced_entries = DiscussionEntryParticipant.forced_read_state_entry_ids(entry_ids, @current_user)
      forced_entries = forced_entries.map(&:to_s) if stringify_json_ids?
      entry_ratings = {}

      if @topic.allow_rating?
        entry_ratings  = DiscussionEntryParticipant.entry_ratings(entry_ids, @current_user)
        entry_ratings  = Hash[entry_ratings.map { |k, v| [k.to_s, v] }] if stringify_json_ids?
      end

      # as an optimization, the view structure is pre-serialized as a json
      # string, so we have to do a bit of manual json building here to fit it
      # into the response.
      fragments = {
        :unread_entries => unread_entries.to_json,
        :forced_entries => forced_entries.to_json,
        :entry_ratings  => entry_ratings.to_json,
        :participants   => json_cast(participant_info).to_json,
        :view           => structure,
        :new_entries    => json_cast(new_entries).to_json,
      }
      fragments = fragments.map { |k, v| %("#{k}": #{v}) }
      render :json => "{ #{fragments.join(', ')} }"
    else
      render :nothing => true, :status => 503
    end
  end

  # @API Post an entry
  # Create a new entry in a discussion topic. Returns a json representation of
  # the created entry (see documentation for 'entries' method) on success.
  #
  # @argument message [String] The body of the entry.
  #
  # @argument attachment a multipart/form-data form-field-style
  #   attachment. Attachments larger than 1 kilobyte are subject to quota
  #   restrictions.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/entries.json' \
  #        -F 'message=<message>' \
  #        -F 'attachment=@<filename>' \
  #        -H "Authorization: Bearer <token>"
  def add_entry
    @entry = build_entry(@topic.discussion_entries)
    if authorized_action(@topic, @current_user, :read) && authorized_action(@entry, @current_user, :create)
      save_entry
    end
  end

  # @API List topic entries
  # Retrieve the (paginated) top-level entries in a discussion topic.
  #
  # May require (depending on the topic) that the user has posted in the topic.
  # If it is required, and the user has not posted, will respond with a 403
  # Forbidden status and the body 'require_initial_post'.
  #
  # Will include the 10 most recent replies, if any, for each entry returned.
  #
  # If the topic is a root topic with children corresponding to groups of a
  # group assignment, entries from those subtopics for which the user belongs
  # to the corresponding group will be returned.
  #
  # Ordering of returned entries is newest-first by posting timestamp (reply
  # activity is ignored).
  #
  # @response_field id The unique identifier for the entry.
  #
  # @response_field user_id The unique identifier for the author of the entry.
  #
  # @response_field editor_id The unique user id of the person to last edit the entry, if different than user_id.
  #
  # @response_field user_name The name of the author of the entry.
  #
  # @response_field message The content of the entry.
  #
  # @response_field read_state The read state of the entry, "read" or "unread".
  #
  # @response_field forced_read_state Whether the read_state was forced (was set manually)
  #
  # @response_field created_at The creation time of the entry, in ISO8601
  #   format.
  #
  # @response_field updated_at The updated time of the entry, in ISO8601 format.
  #
  # @response_field attachment JSON representation of the attachment for the
  #   entry, if any. Present only if there is an attachment.
  #
  # @response_field attachments *Deprecated*. Same as attachment, but returned
  #   as a one-element array. Present only if there is an attachment.
  #
  # @response_field recent_replies The 10 most recent replies for the entry,
  #   newest first. Present only if there is at least one reply.
  #
  # @response_field has_more_replies True if there are more than 10 replies for
  #   the entry (i.e., not all were included in this response). Present only if
  #   there is at least one reply.
  #
  # @example_response
  #   [ {
  #       "id": 1019,
  #       "user_id": 7086,
  #       "user_name": "nobody@example.com",
  #       "message": "Newer entry",
  #       "read_state": "read",
  #       "forced_read_state": false,
  #       "created_at": "2011-11-03T21:33:29Z",
  #       "attachment": {
  #         "content-type": "unknown/unknown",
  #         "url": "http://www.example.com/files/681/download?verifier=JDG10Ruitv8o6LjGXWlxgOb5Sl3ElzVYm9cBKUT3",
  #         "filename": "content.txt",
  #         "display_name": "content.txt" } },
  #     {
  #       "id": 1016,
  #       "user_id": 7086,
  #       "user_name": "nobody@example.com",
  #       "message": "first top-level entry",
  #       "read_state": "unread",
  #       "forced_read_state": false,
  #       "created_at": "2011-11-03T21:32:29Z",
  #       "recent_replies": [
  #         {
  #           "id": 1017,
  #           "user_id": 7086,
  #           "user_name": "nobody@example.com",
  #           "message": "Reply message",
  #           "created_at": "2011-11-03T21:32:29Z"
  #         } ],
  #       "has_more_replies": false } ]
  def entries
    @entries = Api.paginate(root_entries(@topic).newest_first, self, entry_pagination_url(@topic))
    render :json => discussion_entry_api_json(@entries, @context, @current_user, session)
  end

  # @API Post a reply
  # Add a reply to an entry in a discussion topic. Returns a json
  # representation of the created reply (see documentation for 'replies'
  # method) on success.
  #
  # May require (depending on the topic) that the user has posted in the topic.
  # If it is required, and the user has not posted, will respond with a 403
  # Forbidden status and the body 'require_initial_post'.
  #
  # @argument message [String] The body of the entry.
  #
  # @argument attachment a multipart/form-data form-field-style
  #   attachment. Attachments larger than 1 kilobyte are subject to quota
  #   restrictions.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/entries/<entry_id>/replies.json' \
  #        -F 'message=<message>' \
  #        -F 'attachment=@<filename>' \
  #        -H "Authorization: Bearer <token>"
  def add_reply
    @parent = all_entries(@topic).find(params[:entry_id])
    @entry = build_entry(@parent.discussion_subentries)
    if authorized_action(@entry, @current_user, :create)
      save_entry
    end
  end

  # @API List entry replies
  # Retrieve the (paginated) replies to a top-level entry in a discussion
  # topic.
  #
  # May require (depending on the topic) that the user has posted in the topic.
  # If it is required, and the user has not posted, will respond with a 403
  # Forbidden status and the body 'require_initial_post'.
  #
  # Ordering of returned entries is newest-first by creation timestamp.
  #
  # @response_field id The unique identifier for the reply.
  #
  # @response_field user_id The unique identifier for the author of the reply.
  #
  # @response_field editor_id The unique user id of the person to last edit the entry, if different than user_id.
  #
  # @response_field user_name The name of the author of the reply.
  #
  # @response_field message The content of the reply.
  #
  # @response_field read_state The read state of the entry, "read" or "unread".
  #
  # @response_field forced_read_state Whether the read_state was forced (was set manually)
  #
  # @response_field created_at The creation time of the reply, in ISO8601
  #   format.
  #
  # @example_response
  #   [ {
  #       "id": 1015,
  #       "user_id": 7084,
  #       "user_name": "nobody@example.com",
  #       "message": "Newer message",
  #       "read_state": "read",
  #       "forced_read_state": false,
  #       "created_at": "2011-11-03T21:27:44Z" },
  #     {
  #       "id": 1014,
  #       "user_id": 7084,
  #       "user_name": "nobody@example.com",
  #       "message": "Older message",
  #       "read_state": "unread",
  #       "forced_read_state": false,
  #       "created_at": "2011-11-03T21:26:44Z" } ]
  def replies
    @parent = root_entries(@topic).find(params[:entry_id])
    @replies = Api.paginate(reply_entries(@parent).newest_first, self, reply_pagination_url(@topic, @parent))
    render :json => discussion_entry_api_json(@replies, @context, @current_user, session)
  end

  # @API List entries
  # Retrieve a paginated list of discussion entries, given a list of ids.
  #
  # May require (depending on the topic) that the user has posted in the topic.
  # If it is required, and the user has not posted, will respond with a 403
  # Forbidden status and the body 'require_initial_post'.
  #
  # @argument ids[] [String]
  #   A list of entry ids to retrieve. Entries will be returned in id order,
  #   smallest id first.
  #
  # @response_field id The unique identifier for the reply.
  #
  # @response_field user_id The unique identifier for the author of the reply.
  #
  # @response_field user_name The name of the author of the reply.
  #
  # @response_field message The content of the reply.
  #
  # @response_field read_state The read state of the entry, "read" or "unread".
  #
  # @response_field forced_read_state Whether the read_state was forced (was set manually)
  #
  # @response_field created_at The creation time of the reply, in ISO8601
  #   format.
  #
  # @response_field deleted If the entry has been deleted, returns true. The
  #   user_id, user_name, and message will not be returned for deleted entries.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/entry_list?ids[]=1&ids[]=2&ids[]=3' \
  #        -H "Authorization: Bearer <token>"
  #
  # @example_response
  #   [
  #     { ... entry 1 ... },
  #     { ... entry 2 ... },
  #     { ... entry 3 ... },
  #   ]
  def entry_list
    ids = Array(params[:ids])
    entries = @topic.discussion_entries.order(:id).find(ids)
    @entries = Api.paginate(entries, self, entry_pagination_url(@topic))
    render :json => discussion_entry_api_json(@entries, @context, @current_user, session, [:display_user])
  end

  # @API Mark topic as read
  # Mark the initial text of the discussion topic as read.
  #
  # No request fields are necessary.
  #
  # On success, the response will be 204 No Content with an empty body.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/read.json' \
  #        -X PUT \
  #        -H "Authorization: Bearer <token>" \
  #        -H "Content-Length: 0"
  def mark_topic_read
    change_topic_read_state("read")
  end

  # @API Mark topic as unread
  # Mark the initial text of the discussion topic as unread.
  #
  # No request fields are necessary.
  #
  # On success, the response will be 204 No Content with an empty body.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/read.json' \
  #        -X DELETE \
  #        -H "Authorization: Bearer <token>"
  def mark_topic_unread
    change_topic_read_state("unread")
  end

  # @API Mark all entries as read
  # Mark the discussion topic and all its entries as read.
  #
  # No request fields are necessary.
  #
  # @argument forced_read_state [Boolean]
  #   A boolean value to set all of the entries' forced_read_state. No change
  #   is made if this argument is not specified.
  #
  # On success, the response will be 204 No Content with an empty body.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/read_all.json' \
  #        -X PUT \
  #        -H "Authorization: Bearer <token>" \
  #        -H "Content-Length: 0"
  def mark_all_read
    change_topic_all_read_state('read')
  end

  # @API Mark all entries as unread
  # Mark the discussion topic and all its entries as unread.
  #
  # No request fields are necessary.
  #
  # @argument forced_read_state [Boolean]
  #   A boolean value to set all of the entries' forced_read_state. No change is
  #   made if this argument is not specified.
  #
  # On success, the response will be 204 No Content with an empty body.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/read_all.json' \
  #        -X DELETE \
  #        -H "Authorization: Bearer <token>"
  def mark_all_unread
    change_topic_all_read_state('unread')
  end

  # @API Mark entry as read
  # Mark a discussion entry as read.
  #
  # No request fields are necessary.
  #
  # @argument forced_read_state [Boolean]
  #   A boolean value to set the entry's forced_read_state. No change is made if
  #   this argument is not specified.
  #
  # On success, the response will be 204 No Content with an empty body.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/entries/<entry_id>/read.json' \
  #        -X PUT \
  #        -H "Authorization: Bearer <token>"\
  #        -H "Content-Length: 0"
  def mark_entry_read
    change_entry_read_state("read")
  end

  # @API Mark entry as unread
  # Mark a discussion entry as unread.
  #
  # No request fields are necessary.
  #
  # @argument forced_read_state [Boolean]
  #   A boolean value to set the entry's forced_read_state. No change is made if
  #   this argument is not specified.
  #
  # On success, the response will be 204 No Content with an empty body.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/entries/<entry_id>/read.json' \
  #        -X DELETE \
  #        -H "Authorization: Bearer <token>"
  def mark_entry_unread
    change_entry_read_state("unread")
  end

  # @API Rate entry
  # Rate a discussion entry.
  #
  # @argument rating [Integer]
  #   A rating to set on this entry. Only 0 and 1 are accepted.
  #
  # On success, the response will be 204 No Content with an empty body.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/entries/<entry_id>/rating.json' \
  #        -X POST \
  #        -H "Authorization: Bearer <token>"
  def rate_entry
    require_entry
    rating = params[:rating].to_i
    unless [0, 1].include? rating
      return render(:json => { :message => "Invalid rating given" }, :status => :bad_request)
    end

    if authorized_action(@entry, @current_user, :rate)
      render_state_change_result @entry.change_rating(rating, @current_user)
    end
  end

  # @API Subscribe to a topic
  # Subscribe to a topic to receive notifications about new entries
  #
  # On success, the response will be 204 No Content with an empty body
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/subscribed.json' \
  #        -X PUT \
  #        -H "Authorization: Bearer <token>" \
  #        -H "Content-Length: 0"
  def subscribe_topic
    render_state_change_result @topic.subscribe(@current_user)
  end

  # @API Unsubscribe from a topic
  # Unsubscribe from a topic to stop receiving notifications about new entries
  #
  # On success, the response will be 204 No Content with an empty body
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/subscribed.json' \
  #        -X DELETE \
  #        -H "Authorization: Bearer <token>"
  def unsubscribe_topic
    render_state_change_result @topic.unsubscribe(@current_user)
  end

  protected
  def require_topic
    @topic = @context.all_discussion_topics.active.find(params[:topic_id])
    return authorized_action(@topic, @current_user, :read)
  end

  def require_entry
    @entry = @topic.discussion_entries.find(params[:entry_id])
  end

  def require_initial_post
    return true if !@topic.initial_post_required?(@current_user, @context_enrollment, session)

    # neither the current user nor the enrollment user (if any) has posted yet,
    # so give them the forbidden status
    render :json => 'require_initial_post', :status => :forbidden
    return false
  end

  def build_entry(association)
    params[:message] = process_incoming_html_content(params[:message])
    @topic.save! if @topic.new_record?
    association.build(:message => params[:message], :user => @current_user, :discussion_topic => @topic)
  end

  def save_entry
    has_attachment = params[:attachment].present? && params[:attachment].size > 0 &&
      @entry.grants_right?(@current_user, session, :attach)
    return if has_attachment && !@topic.for_assignment? && params[:attachment].size > 1.kilobytes &&
      quota_exceeded(@current_user, named_context_url(@context, :context_discussion_topic_url, @topic.id))
    if @entry.save
      @entry.update_topic
      log_asset_access(@topic, 'topics', 'topics', 'participate')
      if has_attachment
        @attachment = (@current_user || @context).attachments.create(:uploaded_data => params[:attachment])
        @entry.attachment = @attachment
        @entry.save
      end
      render :json => discussion_entry_api_json([@entry], @context, @current_user, session, [:user_name, :display_user]).first, :status => :created
    else
      render :json => @entry.errors, :status => :bad_request
    end
  end

  def visible_topics(topic)
    # conflate entries from all child topics for groups the user can access
    topics = [topic]
    if topic.for_group_discussion? && !topic.child_topics.empty?
      groups = topic.group_category.groups.active.select do |group|
        group.grants_right?(@current_user, session, :read)
      end
      topic.child_topics.each{ |t| topics << t if groups.include?(t.context) }
    end
    topics
  end

  def all_entries(topic)
    DiscussionEntry.all_for_topics(visible_topics(topic)).active
  end

  def root_entries(topic)
    DiscussionEntry.top_level_for_topics(visible_topics(topic)).active
  end

  def reply_entries(entry)
    entry.flattened_discussion_subentries.active
  end

  def change_topic_read_state(new_state)
    render_state_change_result @topic.change_read_state(new_state, @current_user)
  end

  def get_forced_option()
    opts = {}
    opts[:forced] = value_to_boolean(params[:forced_read_state]) if params.has_key?(:forced_read_state)
    opts
  end

  def change_topic_all_read_state(new_state)
    opts = get_forced_option

    @topic.change_all_read_state(new_state, @current_user, opts)
    render :json => {}, :status => :no_content
  end

  def change_entry_read_state(new_state)
    require_entry
    opts = get_forced_option

    if authorized_action(@entry, @current_user, :read)
      render_state_change_result @entry.change_read_state(new_state, @current_user, opts)
    end
  end

  # the result of several state change functions are the following:
  #  nil - no current user
  #  true - state is already set to the requested state
  #  participant with errors - something went wrong with the participant
  #  participant with no errors - the change went through
  # this function renders a 204 No Content for a success, or a Bad Request
  # for failure with participant errors if there are any
  def render_state_change_result(result)
    if result == true || result.try(:errors).blank?
      render :nothing => true, :status => :no_content
    else
      render :json => result.try(:errors) || {}, :status => :bad_request
    end
  end
end
