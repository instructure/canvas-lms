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
  include Api::V1::Submission

  def stream_item_json(stream_item, current_user, session)
    data = stream_item.data(current_user.id)
    {}.tap do |hash|

      # generic attributes common to all stream item types
      hash['created_at'] = stream_item.created_at
      hash['updated_at'] = stream_item.updated_at
      hash['id'] = stream_item.id
      hash['title'] = data.respond_to?(:title) ? data.title : nil
      hash['message'] = data.respond_to?(:body) ? data.body : nil
      hash['type'] = stream_item.data.class.name
      hash.merge!(context_data(stream_item))
      context_type, context_id = stream_item.context_type.try(:underscore), stream_item.context_id

      case stream_item.asset_type
      when 'DiscussionTopic', 'Announcement'
        context = stream_item.asset.context
        hash['message'] = api_user_content(data.message, context)
        if stream_item.data.class.name == 'DiscussionTopic'
          if context_type == "collection_item"
            # TODO: build the html_url for the collection item (we want to send them
            # there instead of directly to the discussion.)
            # These html routes aren't enabled yet, so we can't build them here yet.
          else
            hash['discussion_topic_id'] = stream_item.asset_id
            hash['html_url'] = send("#{context_type}_discussion_topic_url", context_id, stream_item.asset_id)
          end
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
      when "CollectionItem"
        item = stream_item.asset
        hash['title'] = item.data.title
        hash['message'] = item.data.description
        hash['collection_item'] = collection_items_json([item], current_user, session).first
      else
        raise("Unexpected stream item type: #{stream_item.asset_type}")
      end
    end
  end

  def api_render_stream_for_contexts(contexts, paginate_url)
    # for backwards compatibility, since this api used to be hard-coded to return 21 items
    params[:per_page] ||= 21
    opts = {}
    opts[:contexts] = contexts if contexts.present?

    items = @current_user.shard.activate do
      scope = @current_user.visible_stream_item_instances(opts).includes(:stream_item)
      Api.paginate(scope, self, self.send(paginate_url, @context)).to_a
    end
    render :json => items.map(&:stream_item).compact.map { |i| stream_item_json(i, @current_user, session) }
  end
end
