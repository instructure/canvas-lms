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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe DiscussionTopicsController, :type => :integration do
  before(:each) do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
  end

  it "should return discussion topic list" do
    @topic = @course.discussion_topics.create!(:title => "Topic 1", :message => "<p>content here</p>", :podcast_enabled => true)
    att = Attachment.create!(:filename => 'content.txt', :display_name => "content.txt", :uploaded_data => StringIO.new('attachment content'), :folder => Folder.unfiled_folder(@course), :context => @course)
    @topic.attachment = att
    @topic.save

    sub = @course.discussion_topics.create!(:title => "Sub topic", :message => "<p>i'm subversive</p>")
    sub.root_topic_id = @topic.id
    sub.save

    json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s})
    
      # get rid of random characters in podcast url
    json.last["podcast_url"].gsub!(/_[^.]*/, '_randomness')
    json.last == {"podcast_url"=>"/feeds/topics/1/enrollment_randomness.rss",
                  "require_initial_post"=>nil,
                  "title"=>"Topic 1",
                  "discussion_subentry_count"=>0,
                  "assignment_id"=>nil,
                  "delayed_post_at"=>nil,
                  "id"=>@topic.id,
                  "user_name"=>"User Name",
                  "last_reply_at"=>@topic.last_reply_at.as_json,
                  "permissions"=>{"delete"=>true,
                                   "reply"=>true,
                                   "read"=>true,
                                   "attach"=>true,
                                   "create"=>true,
                                   "update"=>true},
                  "message"=>"<p>content here</p>",
                  "posted_at"=>@topic.posted_at.as_json,
                  "root_topic_id"=>nil,
                  "attachments"=>[{"content-type"=>"unknown/unknown",
                                   "url"=>"http://www.example.com/courses/#{@course.id}/files/#{att.id}/download",
                                   "filename"=>"content.txt",
                                   "display_name"=>"content.txt"}],
                  "topic_children"=>[sub.id]}
  end

  it "should paginate and return proper pagination headers for courses" do
    7.times { |i| @course.discussion_topics.create!(:title => i.to_s, :message => i.to_s) }
    @course.discussion_topics.count.should == 7
    json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=3",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s, :per_page => '3'})

    json.length.should == 3
    response.headers['Link'].should eql(%{</api/v1/courses/#{@course.id}/discussion_topics?page=2&per_page=3>; rel="next",</api/v1/courses/#{@course.id}/discussion_topics?page=1&per_page=3>; rel="first",</api/v1/courses/#{@course.id}/discussion_topics?page=3&per_page=3>; rel="last"})

      # get the last page
    json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics?page=3&per_page=3",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s, :page => '3', :per_page => '3'})
    json.length.should == 1
    response.headers['Link'].should eql(%{</api/v1/courses/#{@course.id}/discussion_topics?page=2&per_page=3>; rel="prev",</api/v1/courses/#{@course.id}/discussion_topics?page=1&per_page=3>; rel="first",</api/v1/courses/#{@course.id}/discussion_topics?page=3&per_page=3>; rel="last"})
  end
  
  it "should work with groups" do
    group_category = @course.group_categories.create(:name => 'watup')
    group = Group.create!(:name=>"group1", :group_category=>group_category, :context => @course)
    gtopic = group.discussion_topics.create!(:title => "Group Topic 1", :message => "<p>content here</p>")

    att = Attachment.create!(:filename => 'content.txt', :display_name => "content.txt", :uploaded_data => StringIO.new('attachment content'), :folder => Folder.unfiled_folder(group), :context => group)
    gtopic.attachment = att
    gtopic.save

    json = api_call(:get, "/api/v1/groups/#{group.id}/discussion_topics.json",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :group_id => group.id.to_s})
    json.first.should == {"podcast_url"=>nil,
                          "require_initial_post"=>nil,
                          "title"=>"Group Topic 1",
                          "discussion_subentry_count"=>0,
                          "assignment_id"=>nil,
                          "delayed_post_at"=>nil,
                          "id"=>gtopic.id,
                          "user_name"=>"User Name",
                          "last_reply_at"=>gtopic.last_reply_at.as_json,
                          "permissions"=>
                                  {"delete"=>true,
                                   "reply"=>true,
                                   "read"=>true,
                                   "attach"=>true,
                                   "create"=>true,
                                   "update"=>true},
                          "message"=>"<p>content here</p>",
                          "attachments"=>
                                  [{"content-type"=>"unknown/unknown",
                                    "url"=>"http://www.example.com/files/#{att.id}/download?verifier=#{att.uuid}",
                                    "filename"=>"content.txt",
                                    "display_name"=>"content.txt"}],
                          "posted_at"=>gtopic.posted_at.as_json,
                          "root_topic_id"=>nil,
                          "topic_children"=>[]}
  end

  it "should paginate and return proper pagination headers for groups" do
    group_category = @course.group_categories.create(:name => "watup")
    group = Group.create!(:name=>"group1", :group_category=>group_category, :context => @course)
    7.times { |i| group.discussion_topics.create!(:title => i.to_s, :message => i.to_s) }
    group.discussion_topics.count.should == 7
    json = api_call(:get, "/api/v1/groups/#{group.id}/discussion_topics.json?per_page=3",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :group_id => group.id.to_s, :per_page => '3'})

    json.length.should == 3
    response.headers['Link'].should eql(%{</api/v1/groups/#{group.id}/discussion_topics?page=2&per_page=3>; rel="next",</api/v1/groups/#{group.id}/discussion_topics?page=1&per_page=3>; rel="first",</api/v1/groups/#{group.id}/discussion_topics?page=3&per_page=3>; rel="last"})

      # get the last page
    json = api_call(:get, "/api/v1/groups/#{group.id}/discussion_topics.json?page=3&per_page=3",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :group_id => group.id.to_s, :page => '3', :per_page => '3'})
    json.length.should == 1
    response.headers['Link'].should eql(%{</api/v1/groups/#{group.id}/discussion_topics?page=2&per_page=3>; rel="prev",</api/v1/groups/#{group.id}/discussion_topics?page=1&per_page=3>; rel="first",</api/v1/groups/#{group.id}/discussion_topics?page=3&per_page=3>; rel="last"})
  end

end
