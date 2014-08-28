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
    @view = DiscussionTopic::MaterializedView.find_by_discussion_topic_id(@topic.id)
  end

  describe ".materialized_view_for" do
    it "should build the intial empty view synchronously" do
      DiscussionTopic::MaterializedView.materialized_view_for(@topic).should == ["[]", [], [], []]
    end

    it "should return nil and schedule a job if no view" do
      DiscussionTopic::MaterializedView.for(@topic).destroy
      DiscussionTopic::MaterializedView.materialized_view_for(@topic).should == nil
      Delayed::Job.strand_size("materialized_discussion:#{@topic.id}").should == 1
    end

    it "should return the view if it exists but is out of date" do
      @view.update_materialized_view_without_send_later
      DiscussionTopic::MaterializedView.materialized_view_for(@topic).should be_present
      reply = @topic.reply_from(:user => @user, :text => "new message!")
      Delayed::Job.find_available(100).each(&:destroy)
      json, participants, entries = DiscussionTopic::MaterializedView.materialized_view_for(@topic)
      json.should be_present
      entries.should_not be_include(reply.id)
      # since the view was out of date, it's returned but a job is queued
      Delayed::Job.strand_size("materialized_discussion:#{@topic.id}").should == 1
      # after updating, the view should include the new entry
      @view.update_materialized_view_without_send_later
      json, participants, entries = DiscussionTopic::MaterializedView.materialized_view_for(@topic)
      json.should be_present
      entries.should be_include(reply.id)
    end
  end

  it "should build a materialized view of the structure, participants and entry ids" do
    view = DiscussionTopic::MaterializedView.find_by_discussion_topic_id(@topic.id)
    view.update_materialized_view_without_send_later
    structure, participant_ids, entry_ids = @topic.materialized_view
    view.materialized_view_json.should == [structure, participant_ids, entry_ids, []]
    participant_ids.sort.should == [@student.id, @teacher.id].sort
    entry_ids.sort.should == @topic.discussion_entries.map(&:id).sort
    json = JSON.parse(structure)
    json.size.should == 2
    json.map { |e| e['id'] }.should == [@root1.id.to_s, @root2.id.to_s]
    json.map { |e| e['parent_id'] }.should == [nil, nil]
    deleted = json[0]['replies'][0]
    deleted['deleted'].should == true
    deleted['user_id'].should be_nil
    deleted['message'].should be_nil
    json[0]['replies'][1]['replies'][0]['attachment']['url'].should == "http://localhost/files/#{@attachment.id}/download?download_frd=1&verifier=#{@attachment.uuid}"
    # verify the api_user_content functionality in a non-request context
    html_message = json[0]['replies'][1]['message']
    html = Nokogiri::HTML::DocumentFragment.parse(html_message)
    html.at_css('a')['href'].should == "http://localhost/courses/#{@course.id}/files/#{@reply2_attachment.id}/download?verifier=#{@reply2_attachment.uuid}"
    html.at_css('video')['src'].should == "http://localhost/courses/#{@course.id}/media_download?entryId=0_abcde&media_type=video&redirect=1"

    # the deleted entry will be marked deleted and have no summary
    simple_json = map_to_ids_and_replies(json)
    simple_json.should == [
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
