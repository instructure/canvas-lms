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

  def stream_item_preloads(stream_items)
    discussion_topics = stream_items.select { |si| ['DiscussionTopic', 'Announcement'].include?(si.asset_type) }
    ActiveRecord::Associations::Preloader.new.preload(discussion_topics, :context)
    assessment_requests = stream_items.select { |si| si.asset_type == 'AssessmentRequest' }.map(&:data)
    ActiveRecord::Associations::Preloader.new.preload(assessment_requests, asset: :assignment)
    submissions = stream_items.select { |si| si.asset_type == 'Submission' }
    ActiveRecord::Associations::Preloader.new.preload(submissions, asset: { assignment: :context })
  end

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
        context = stream_item.context
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
        hash['submission_id'] = stream_item.asset_id

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
        assessment_request = stream_item.data
        assignment = assessment_request.asset.assignment
        hash['assessment_request_id'] = assessment_request.id
        hash['html_url'] = course_assignment_submission_url(assignment.context_id, assignment.id, assessment_request.user_id)
        hash['title'] = I18n.t("stream_items_api.assessment_request_title", 'Peer Review for %{title}', title: assignment.title)
      else
        raise("Unexpected stream item type: #{stream_item.asset_type}")
      end
    end
  end

  def api_render_stream(opts)
    items = @current_user.shard.activate do
      scope = @current_user.visible_stream_item_instances(opts).preload(:stream_item)
      if opts.has_key?(:asset_type)
        is_cross_shard = @current_user.visible_stream_item_instances(opts).
          where("stream_item_id > ?", Shard::IDS_PER_SHARD).exists?
        if is_cross_shard
          # the old join doesn't work for cross-shard stream items, so we basically have to pre-calculate everything
          scope = scope.where(:stream_item_id => filtered_stream_item_ids(opts))
        else
          scope = scope.eager_load(:stream_item).where("stream_items.asset_type=?", opts[:asset_type])
          if opts[:asset_type] == 'Submission'
            scope = scope.joins("INNER JOIN #{Submission.quoted_table_name} ON submissions.id=asset_id")
            # just because there are comments doesn't mean the user can see them.
            # we still need to filter after the pagination :(
            scope = scope.where("submissions.submission_comments_count>0")
            scope = scope.where("submissions.user_id=?", opts[:submission_user_id]) if opts.has_key?(:submission_user_id)
          end
        end
      end
      Api.paginate(scope, self, self.send(opts[:paginate_url], @context), default_per_page: 21).to_a
    end
    items.select!(&:stream_item)
    stream_item_preloads(items.map(&:stream_item))
    json = items.map { |i| stream_item_json(i, i.stream_item, @current_user, session) }
    json.select! {|hash| hash['submission_comments'].present?} if opts[:asset_type] == 'Submission'
    render :json => json
  end

  def filtered_stream_item_ids(opts)
    all_stream_item_ids = @current_user.visible_stream_item_instances(opts).pluck(:stream_item_id)
    filtered_ids = []

    Shard.partition_by_shard(all_stream_item_ids) do |sliced_ids|
      si_scope = StreamItem.where(:id => sliced_ids).where(:asset_type => opts[:asset_type])
      if opts[:asset_type] == 'Submission'
        si_scope = si_scope.joins("INNER JOIN #{Submission.quoted_table_name} ON submissions.id=asset_id")
        # just because there are comments doesn't mean the user can see them.
        # we still need to filter after the pagination :(
        si_scope = si_scope.where("submissions.submission_comments_count>0")
        si_scope = si_scope.where("submissions.user_id=?", opts[:submission_user_id]) if opts.has_key?(:submission_user_id)
        filtered_ids += si_scope.pluck(:id).map{|id| Shard.relative_id_for(id, Shard.current, @current_user.shard)}
      end
    end
    filtered_ids
  end

  def api_render_stream_summary(contexts = nil)
    items = []

    @current_user.shard.activate do
      base_scope = @current_user.visible_stream_item_instances(:contexts => contexts).joins(:stream_item)

      full_counts = base_scope.except(:order).group('stream_items.asset_type', 'stream_items.notification_category',
        'stream_item_instances.workflow_state').count
        # as far as I can tell, the 'type' column previously extracted by stream_item_json is identical to asset_type
       # oh wait, except for Announcements -_-
      if full_counts.keys.any?{|k| k[0] == 'DiscussionTopic'}
        ann_counts = base_scope.where(:stream_items => {:asset_type => "DiscussionTopic"}).
          joins("INNER JOIN #{DiscussionTopic.quoted_table_name} ON discussion_topics.id=stream_items.asset_id").
          where("discussion_topics.type = ?", "Announcement").except(:order).group('stream_item_instances.workflow_state').count

        ann_counts.each do |wf_state, ann_count|
          full_counts[['Announcement', nil, wf_state]] = ann_count
          full_counts[['DiscussionTopic', nil, wf_state]] -= ann_count # subtract the announcement count from the "true" discussion topics
        end
      end

      total_counts = {}
      unread_counts = {}
      full_counts.each do |k, count|
        new_key = k.dup
        wf_state = new_key.pop
        if wf_state == 'unread'
          unread_counts[new_key] = count
        end
        total_counts[new_key] ||= 0
        total_counts[new_key] += count
      end

      # TODO: can remove after DataFixup::PopulateStreamItemNotificationCategory is run
      if total_counts.delete(['Message', nil]) # i.e. there are Message stream items without notification_category
        unread_counts.delete(['Message', nil])
        base_scope.where(:stream_items => {:asset_type => "Message", :notification_category => nil}).
          eager_load(:stream_item).each do |i|

          category = i.stream_item.get_notification_category
          key = ['Message', category]
          total_counts[key] ||= 0
          total_counts[key] += 1
          unless i.read?
            unread_counts[key] ||= 0
            unread_counts[key] += 1
          end
        end
      end

      cross_shard_totals, cross_shard_unreads = cross_shard_stream_item_counts(contexts)
      cross_shard_totals.each do |k, v|
        total_counts[k] ||= 0
        total_counts[k] += v
      end
      cross_shard_unreads.each do |k, v|
        unread_counts[k] ||= 0
        unread_counts[k] += v
      end

      total_counts.each do |key, count|
        type, category = key
        items << {:type => type, :notification_category => category,
          :count => count, :unread_count => unread_counts[key] || 0}
      end
      items.sort_by!{|i| i[:type]}
    end
    render :json => items
  end

  def cross_shard_stream_item_counts(contexts)
    total_counts = {}
    unread_counts = {}
    # handle cross-shard stream items -________-
    stream_item_ids = @current_user.visible_stream_item_instances(:contexts => contexts).
      where("stream_item_id > ?", Shard::IDS_PER_SHARD).pluck(:stream_item_id)
    if stream_item_ids.any?
      unread_stream_item_ids = @current_user.visible_stream_item_instances(:contexts => contexts).
        where("stream_item_id > ?", Shard::IDS_PER_SHARD).
        where(:workflow_state => "unread").pluck(:stream_item_id)

      total_counts = StreamItem.where(:id => stream_item_ids).except(:order).group(:asset_type, :notification_category).count
      if unread_stream_item_ids.any?
        unread_counts = StreamItem.where(:id => unread_stream_item_ids).except(:order).group(:asset_type, :notification_category).count
      end

      if total_counts.keys.any?{|k| k[0] == 'DiscussionTopic'}
        ann_scope = StreamItem.where(:stream_items => {:asset_type => "DiscussionTopic"}).
          joins(:discussion_topic).
          where("discussion_topics.type = ?", "Announcement")
        ann_total = ann_scope.where(:id => stream_item_ids).count

        if ann_total > 0
          total_counts[['Announcement', nil]] = ann_total
          total_counts[['DiscussionTopic', nil]] -= ann_total

          ann_unread = ann_scope.where(:id => unread_stream_item_ids).count
          if ann_unread > 0
            unread_counts[['Announcement', nil]] = ann_unread
            unread_counts[['DiscussionTopic', nil]] -= ann_unread
          end
        end
      end

      # TODO: can remove after DataFixup::PopulateStreamItemNotificationCategory is run
      if total_counts.delete(['Message', nil]) # i.e. there are Message stream items without notification_category
        unread_counts.delete(['Message', nil])
        StreamItem.where(:id => stream_item_ids).where(:asset_type => "Message", :notification_category => nil).find_each do |i|
          category = i.get_notification_category
          key = ['Message', category]
          total_counts[key] ||= 0
          total_counts[key] += 1
        end
        StreamItem.where(:id => unread_stream_item_ids).where(:asset_type => "Message", :notification_category => nil).find_each do |i|
          category = i.get_notification_category
          key = ['Message', category]
          unread_counts[key] ||= 0
          unread_counts[key] += 1
        end
      end
    end
    [total_counts, unread_counts]
  end
end
