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
  include Api::V1::Collection

  def stream_item_json(stream_item, current_user, session)
    data = stream_item.stream_data(current_user.id)
    {}.tap do |hash|

      # generic attributes common to all stream item types
      hash['created_at'] = stream_item.created_at
      hash['updated_at'] = stream_item.updated_at
      hash['id'] = stream_item.id
      hash['title'] = data.title
      hash['message'] = data.body
      hash['type'] = data.type
      hash.merge!(context_data(data))
      context_type, context_id = stream_item.context_code.try(:split, '_', 2)

      case data.type
      when 'DiscussionTopic', 'Announcement'
        hash['message'] = data.message
        if data.type == 'DiscussionTopic'
          hash['discussion_topic_id'] = data.id
          hash['html_url'] = send("#{context_type}_discussion_topic_url", context_id.to_i, data.id.to_i)
        else
          hash['announcement_id'] = data.id
          hash['html_url'] = send("#{context_type}_announcement_url", context_id.to_i, data.id.to_i)
        end
        hash['total_root_discussion_entries'] = data.total_root_discussion_entries
        hash['require_initial_post'] = data.require_initial_post
        hash['user_has_posted'] = data.user_has_posted
        hash['root_discussion_entries'] = (data.root_discussion_entries || [])[0,3].map do |entry|
          {
            'user' => {
              'user_id' => entry.user_id,
              'user_name' => entry.user_short_name,
            },
            'message' => entry.message,
          }
        end
      when 'ContextMessage'
        # pass, these were converted to Conversations but may still show up in
        # the stream for a few weeks
      when 'Conversation'
        hash['conversation_id'] = data.id
        hash['private'] = data.private
        hash['participant_count'] = data.participant_count
        hash['html_url'] = conversation_url(data.id.to_i)
      when 'Message'
        hash['message_id'] = data.id
        # this type encompasses a huge number of different types of messages,
        # anything that gets send to communication channels
        hash['title'] = data.subject
        hash['notification_category'] = data.notification_category
        hash['html_url'] = hash['url'] = data.url
      when 'Submission'
        hash['title'] = data.assignment.try(:title)
        hash['grade'] = data.grade
        hash['score'] = data.score
        hash['html_url'] = course_assignment_submission_url(context_id, data.assignment.id, data.user_id)
        hash['submission_comments'] = data.submission_comments.map do |comment|
          {
            'body' => comment.formatted_body,
            'user_name' => comment.user_short_name,
            'user_id' => comment.author_id,
          }
        end unless data.submission_comments.blank?
        hash['assignment'] = {
          'title' => hash['title'],
          'id' => data.assignment.try(:id),
          'points_possible' => data.assignment.try(:points_possible),
        }
      when /Conference/
        hash['web_conference_id'] = data.id
        hash['type'] = 'WebConference'
        hash['message'] = data.description
        hash['html_url'] = send("#{context_type}_conference_url", context_id.to_i, data.id.to_i) if context_type
      when /Collaboration/
        hash['collaboration_id'] = data.id
        # TODO: this type isn't even shown on the web activity stream yet
        hash['type'] = 'Collaboration'
        hash['html_url'] = send("#{context_type}_collaboration_url", context_id.to_i, data.id.to_i) if context_type
      when "CollectionItem"
        item = ::CollectionItem.find(data.id, :include => { :collection_item_data => :image_attachment })
        hash['title'] = item.data.title
        hash['message'] = item.data.description
        hash['collection_item'] = collection_items_json([item], current_user, session).first
      else
        raise("Unexpected stream item type: #{data.type}")
      end
    end
  end

  def api_render_stream_for_contexts(contexts, paginate_url)
    # for backwards compatibility, since this api used to be hard-coded to return 21 items
    params[:per_page] ||= 21
    opts = {}
    opts[:contexts] = contexts if contexts.present?

    items = @current_user.shard.activate do
      scope = @current_user.visible_stream_item_instances(opts).scoped(:include => :stream_item)
      Api.paginate(scope, self, self.send(paginate_url, @context)).to_a
    end
    render :json => items.map(&:stream_item).compact.map { |i| stream_item_json(i, @current_user, session) }
  end
end
