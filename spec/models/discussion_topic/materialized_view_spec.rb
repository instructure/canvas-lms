#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe DiscussionTopic::MaterializedView do
  def map_to_ids_and_replies(list)
    list.map { |l| l = l.slice('id', 'replies'); l['replies'] = map_to_ids_and_replies(l['replies'] || []); l }
  end

  before :once do
    topic_with_nested_replies
    @view = DiscussionTopic::MaterializedView.where(discussion_topic_id: @topic).first
  end

  describe ".materialized_view_for" do
    it "should build the intial empty view synchronously" do
      expect(DiscussionTopic::MaterializedView.materialized_view_for(@topic)).to eq ["[]", [], [], []]
    end

    it "should return nil and schedule a job if no view" do
      DiscussionTopic::MaterializedView.for(@topic).destroy
      expect(DiscussionTopic::MaterializedView.materialized_view_for(@topic)).to eq nil
      expect(Delayed::Job.strand_size("materialized_discussion:#{@topic.id}")).to eq 1
    end

    it "should return the view if it exists but is out of date" do
      @view.update_materialized_view_without_send_later
      expect(DiscussionTopic::MaterializedView.materialized_view_for(@topic)).to be_present
      reply = @topic.reply_from(:user => @user, :text => "new message!")
      Delayed::Job.find_available(100).each(&:destroy)
      json, participants, entries = DiscussionTopic::MaterializedView.materialized_view_for(@topic)
      expect(json).to be_present
      expect(entries).not_to be_include(reply.id)
      # since the view was out of date, it's returned but a job is queued
      expect(Delayed::Job.strand_size("materialized_discussion:#{@topic.id}")).to eq 1
      # after updating, the view should include the new entry
      @view.update_materialized_view_without_send_later
      json, participants, entries = DiscussionTopic::MaterializedView.materialized_view_for(@topic)
      expect(json).to be_present
      expect(entries).to be_include(reply.id)
    end
  end

  it "should build a materialized view of the structure, participants and entry ids" do
    view = DiscussionTopic::MaterializedView.where(discussion_topic_id: @topic).first
    view.update_materialized_view_without_send_later
    structure, participant_ids, entry_ids = @topic.materialized_view
    expect(view.materialized_view_json).to eq [structure, participant_ids, entry_ids, []]
    expect(participant_ids.sort).to eq [@student.id, @teacher.id].sort
    expect(entry_ids.sort).to eq @topic.discussion_entries.map(&:id).sort
    json = JSON.parse(structure)
    expect(json.size).to eq 2
    expect(json.map { |e| e['id'] }).to eq [@root1.id.to_s, @root2.id.to_s]
    expect(json.map { |e| e['parent_id'] }).to eq [nil, nil]
    deleted = json[0]['replies'][0]
    expect(deleted['deleted']).to eq true
    expect(deleted['user_id']).to be_nil
    expect(deleted['message']).to be_nil
    expect(json[0]['replies'][1]['replies'][0]['attachment']['url']).to eq "http://localhost/files/#{@attachment.id}/download?download_frd=1&verifier=#{@attachment.uuid}"
    # verify the api_user_content functionality in a non-request context
    html_message = json[0]['replies'][1]['message']
    html = Nokogiri::HTML::DocumentFragment.parse(html_message)
    expect(html.at_css('a')['href']).to eq "http://localhost/courses/#{@course.id}/files/#{@reply2_attachment.id}/download?verifier=#{@reply2_attachment.uuid}"
    expect(html.at_css('video')['src']).to eq "http://localhost/courses/#{@course.id}/media_download?entryId=0_abcde&media_type=video&redirect=1"

    # the deleted entry will be marked deleted and have no summary
    simple_json = map_to_ids_and_replies(json)
    expect(simple_json).to eq [
      {
      'id' => @root1.id.to_s,
      'replies' => [
        { 'id' => @reply1.id.to_s, 'replies' => [ { 'id' => @reply_reply2.id.to_s, 'replies' => [] } ], },
        { 'id' => @reply2.id.to_s, 'replies' => [ { 'id' => @reply_reply1.id.to_s, 'replies' => [] } ], },
    ],
    },
    {
      'id' => @root2.id.to_s,
      'replies' => [
        { 'id' => @reply3.id.to_s, 'replies' => [], },
    ],
    },
    ]
  end
end
