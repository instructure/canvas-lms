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

  def stream_item_json(stream_item, viewing_user_id)
    data = stream_item.stream_data(viewing_user_id)
    {}.tap do |hash|

      # generic attributes common to all stream item types
      hash['created_at'] = stream_item.created_at
      hash['updated_at'] = stream_item.updated_at
      hash['id'] = stream_item.id
      hash['title'] = data.title
      hash['message'] = data.body
      hash['type'] = data.type
      hash.merge!(context_data(data))

      case data.type
      when 'DiscussionTopic', 'Announcement'
        hash['message'] = data.message
        if data.type == 'DiscussionTopic'
          hash['discussion_topic_id'] = data.id
        else
          hash['announcement_id'] = data.id
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
      when 'Message'
        hash['message_id'] = data.id
        # this type encompasses a huge number of different types of messages,
        # anything that gets send to communication channels
        hash['title'] = data.subject
        hash['notification_category'] = data.notification_category
        hash['url'] = data.url
      when 'Submission'
        hash['title'] = data.assignment.try(:title)
        hash['grade'] = data.grade
        hash['score'] = data.score
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
      when /Collaboration/
        hash['collaboration_id'] = data.id
        # TODO: this type isn't even shown on the web activity stream yet
        hash['type'] = 'Collaboration'
      else
        raise("Unexpected stream item type: #{data.type}")
      end
    end
  end
end
