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

module Api::V1::StreamItem
  include Api::V1::Context
  include Api::V1::Submission

  def stream_item_json(stream_item_instance, stream_item, current_user, session)
    data = stream_item.data(current_user.id)
    {}.tap do |hash|

      # generic attributes common to all stream item types
      hash['created_at'] = stream_item.created_at
      hash['updated_at'] = stream_item.updated_at
      hash['id'] = stream_item.id
      hash['title'] = data.respond_to?(:title) ? data.title : nil
      hash['message'] = data.respond_to?(:body) ? data.body : nil
      hash['type'] = stream_item.data.class.name
      hash['read_state'] = stream_item_instance.read?
      hash.merge!(context_data(stream_item))
      context_type, context_id = stream_item.context_type.try(:underscore), stream_item.context_id

      case stream_item.asset_type
      when 'DiscussionTopic', 'Announcement'
        context = stream_item.asset.context
        hash['message'] = api_user_content(data.message, context)
        if stream_item.data.class.name == 'DiscussionTopic'
          hash['discussion_topic_id'] = stream_item.asset_id
          hash['html_url'] = send("#{context_type}_discussion_topic_url", context_id, stream_item.asset_id)
        else
          hash['announcement_id'] = stream_item.asset_id
          hash['html_url'] = send("#{context_type}_announcement_url", context_id, stream_item.asset_id)
        end
        hash['total_root_discussion_entries'] = data.total_root_discussion_entries
        hash['require_initial_post'] = data.require_initial_post
        hash['user_has_posted'] = data.respond_to?(:user_has_posted) ? data.user_has_posted : nil
        hash['root_discussion_entries'] = (data.root_discussion_entries || [])[0,StreamItem::ROOT_DISCUSSION_ENTRY_LIMIT].map do |entry|
          {
            'user' => {
              'user_id' => entry.user_id,
              'user_name' => entry.user_short_name,
            },
            'message' => api_user_content(entry.message, context),
          }
        end
      when 'ContextMessage'
        # pass, these were converted to Conversations but may still show up in
        # the stream for a few weeks
      when 'Conversation'
        hash['conversation_id'] = stream_item.asset_id
        hash['private'] = data.private
        hash['participant_count'] = data.participant_count
        hash['html_url'] = conversation_url(stream_item.asset_id)
      when 'Message'
        hash['message_id'] = stream_item.asset_id
        # this type encompasses a huge number of different types of messages,
        # anything that gets send to communication channels
        hash['title'] = data.subject
        hash['notification_category'] = data.notification_category
        hash['html_url'] = hash['url'] = data.url
      when 'Submission'
        json = submission_json(stream_item.asset, stream_item.asset.assignment, current_user, session, nil, ['submission_comments', 'assignment', 'course', 'html_url', 'user'])
        json.delete('id')
        hash.merge! json

        # backwards compat from before using submission_json
        hash['assignment']['title'] = hash['assignment']['name']
        hash['title'] = hash['assignment']['name']
        hash['submission_comments'].each {|c| c['body'] = c['comment']}
      when /Conference/
        hash['web_conference_id'] = stream_item.asset_id
        hash['type'] = 'WebConference'
        hash['message'] = data.description
        hash['html_url'] = send("#{context_type}_conference_url", context_id, stream_item.asset_id) if context_type
      when /Collaboration/
        hash['collaboration_id'] = stream_item.asset_id
        # TODO: this type isn't even shown on the web activity stream yet
        hash['type'] = 'Collaboration'
        hash['html_url'] = send("#{context_type}_collaboration_url", context_id, stream_item.asset_id) if context_type
      when /AssessmentRequest/
        assessment_request = stream_item.asset
        assignment = assessment_request.asset.assignment
        hash['assessment_request_id'] = assessment_request.id
        hash['html_url'] = course_assignment_submission_url(assignment.context_id, assignment.id, assessment_request.user_id)
        hash['title'] = I18n.t("stream_items_api.assessment_request_title", 'Peer Review for %{title}', title: assignment.title)
      else
        raise("Unexpected stream item type: #{stream_item.asset_type}")
      end
    end
  end

  def api_render_stream_for_contexts(contexts, paginate_url)
    opts = {}
    opts[:contexts] = contexts if contexts.present?

    items = @current_user.shard.activate do
      scope = @current_user.visible_stream_item_instances(opts).includes(:stream_item)
      Api.paginate(scope, self, self.send(paginate_url, @context), default_per_page: 21).to_a
    end
    render :json => items.select(&:stream_item).map { |i| stream_item_json(i, i.stream_item, @current_user, session) }
  end

  def api_render_stream_summary(contexts = nil)
    opts = {}
    opts[:contexts] = contexts
    items = @current_user.shard.activate do
      # not ideal, but 1. we can't aggregate in the db (boo yml) and
      # 2. stream_item_json is where categorizing logic lives :(
      @current_user.visible_stream_item_instances(opts).includes(:stream_item).map { |i|
        stream_item_json(i, i.stream_item, @current_user, session)
      }.inject({}) { |result, i|
        key = [i['type'], i['notification_category']]
        result[key] ||= {type: i['type'], count: 0, unread_count: 0, notification_category: i['notification_category']}
        result[key][:count] += 1
        result[key][:unread_count] += 1 if !i['read_state']
        result
      }.values.sort_by{ |i| i[:type] }
    end
    render :json => items
  end
end
