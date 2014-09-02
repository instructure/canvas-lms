#
# Copyright (C) 2011-2012 Instructure, Inc.
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

describe Collaboration do
  context "collaboration_class" do
    it "should by default not have any collaborations" do
      Collaboration.any_collaborations_configured?.should be_false
      Collaboration.collaboration_types.should == []
    end

    it "should allow google docs collaborations" do
      Collaboration.collaboration_class('GoogleDocs').should eql(nil)
      plugin_setting = PluginSetting.new(:name => "google_docs", :settings => {})
      plugin_setting.save!
      Collaboration.collaboration_class('GoogleDocs').should eql(GoogleDocsCollaboration)
      plugin_setting.disabled = true
      plugin_setting.save!
      Collaboration.collaboration_class('GoogleDocs').should eql(nil)
    end

    it "should allow etherpad collaborations" do
      Collaboration.collaboration_class('Etherpad').should eql(nil)
      plugin_setting = PluginSetting.new(:name => "etherpad", :settings => {})
      plugin_setting.save!
      Collaboration.collaboration_class('Etherpad').should eql(EtherpadCollaboration)
      plugin_setting.disabled = true
      plugin_setting.save!
      Collaboration.collaboration_class('Etherpad').should eql(nil)
    end

    it "should not allow invalid collaborations" do
      Collaboration.collaboration_class('Bacon').should eql(nil)
    end
  end

  context "parsed data" do
    before :once do
      google_docs_collaboration_model
    end

    it "should be able to parse the data stored as an Atom entry" do
      ae = @collaboration.parse_data
      ae.should be_is_a(Atom::Entry)
      ae.title.should eql('Biology 100 Collaboration')
    end

    it "should be able to get the title from the data" do
      @collaboration.title = nil
      @collaboration.title.should eql('Biology 100 Collaboration')
    end

    it "should have Google Docs as a default service name" do
      @collaboration.service_name.should eql('Google Docs')
    end
  end

  context "a collaboration with collaborators" do
    before :each do
      PluginSetting.create!(:name => "etherpad", :settings => {})
      @users  = (1..4).map { user_with_pseudonym(:active_all => true) }
      @groups = [group_model]
      @groups.first.add_user(@users.last, 'active')
      @collaboration = Collaboration.new(:title => 'Test collaboration',
                                         :user  => @users.first)
      @collaboration.type = 'EtherpadCollaboration'
      @collaboration.save!
    end

    it "should add new collaborators" do
      @collaboration.update_members(@users[0..-2], @groups.map(&:id))
      @collaboration.reload.collaborators.map(&:user_id).uniq.count.should == 4
      @collaboration.collaborators.map(&:group_id).uniq.count.should == 2
    end

    it "should update existing collaborators" do
      @collaboration.update_members(@users[0..-1], @groups.map(&:id))
      @collaboration.update_members(@users[0..-2])
      @collaboration.reload
      @collaboration.collaborators.map(&:user_id).uniq.count.should == 3
      @collaboration.collaborators.map(&:group_id).uniq.count.should == 1
      @collaboration.collaborators.reload.map(&:user_id).should_not include @users.last.id
    end
  end

  describe EtherpadCollaboration do
    it "should not re-initialize the url" do
      collab = EtherpadCollaboration.new
      collab.url = "http://example.com/legacy-uri"
      collab.initialize_document
      collab.url.should == "http://example.com/legacy-uri"
    end
  end
end
