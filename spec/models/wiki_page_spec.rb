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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe WikiPage do
  
  # it "should send page created notifications" do
    # course_with_teacher(:active_all => true)
    # Notification.create(:name => "New Wiki Page")
    # p = @course.wiki.wiki_pages.create(:title => "some page")
    # p.messages_sent.should_not be_nil
    # p.messages_sent.should_not be_empty
    # p.messages_sent["New Wiki Page"].should_not be_nil
    # p.messages_sent["New Wiki Page"].should_not be_empty
    # p.messages_sent["New Wiki Page"][0].user.should eql(@user)
  # end
  
  it "should send page updated notifications" do
    course_with_teacher(:active_all => true)
    n = Notification.create(:name => "Updated Wiki Page", :category => "TestImmediately")
    NotificationPolicy.create(:notification => n, :communication_channel => @user.communication_channel, :user => @user, :frequency => "immediately")
    p = @course.wiki.wiki_pages.create(:title => "some page")
    p.created_at = 3.days.ago
    p.notify_of_update = true
    p.save!
    p.created_at.should <= 3.days.ago
    p.update_attributes(:body => "Awgawg")
    p.messages_sent.should_not be_nil
    p.messages_sent.should_not be_empty
    p.messages_sent["Updated Wiki Page"].should_not be_nil
    p.messages_sent["Updated Wiki Page"].should_not be_empty
    p.messages_sent["Updated Wiki Page"].map(&:user).should be_include(@user) #[0].user.should eql(@user)
  end
  
  context "atom" do
    
    it "should use the wiki namespace context name in the title" do
      
    end

    # context = opts[:context]
    # namespace = self.wiki.wiki_namespaces.find_by_context_id(context && context.id) || self.wiki.wiki_namespaces.find(:first)
    # prefix = namespace.context_prefix || ""
    # Atom::Entry.new do |entry|
    #   entry.title     = "Wiki Page#{", " + namespace.context.name}: #{self.title}"
    #   entry.updated   = self.updated_at
    #   entry.published = self.created_at
    #   entry.id        = "tag:instructure.com,#{self.created_at.strftime("%Y-%m-%d")}:/wiki_pages/#{self.feed_code}_#{self.updated_at.strftime("%Y-%m-%d")}"
    #   entry.links    << Atom::Link.new(:rel => 'alternate', 
    #                                 :href => "http://#{HostUrl.context_host(namespace.context)}/#{prefix}/wiki/#{self.url}")
    #   entry.content   = Atom::Content::Html.new(self.body)
    
    
  # end
    
  end
  
  context "clone_for" do
    it "should clone for another context" do
      course_with_teacher(:active_all => true)
      p = @course.wiki.wiki_pages.create(:title => "some page")
      p.save!
      course
      new_p = p.clone_for(@course)
      new_p.title.should eql(p.title)
      new_p.should_not eql(p)
      new_p.wiki.should_not eql(p.wiki)
    end
  end
end
