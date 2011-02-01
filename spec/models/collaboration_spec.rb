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

describe Collaboration do
  
  context "collaboration_class" do
    it "should list default collaboration types" do
      Collaboration.instance_variable_set('@collab_types', Collaboration::DEFAULT_COLLABORATION_TYPES)
      Collaboration.collaboration_types.should eql(Collaboration::DEFAULT_COLLABORATION_TYPES)
      Collaboration.instance_variable_set('@collab_types', {})
      Collaboration.collaboration_types.should eql({})
    end
    it "should allow google docs collaborations" do
      Collaboration.instance_variable_set('@collab_types', Collaboration::DEFAULT_COLLABORATION_TYPES)
      GoogleDocs.instance_variable_set('@config', {})
      Collaboration.collaboration_class('GoogleDocs').should eql(GoogleDocsCollaboration)
    end
    it "should allow etherpad collaborations" do
      Collaboration.instance_variable_set('@collab_types', Collaboration::DEFAULT_COLLABORATION_TYPES)
      EtherpadCollaboration.instance_variable_set('@config', {})
      Collaboration.collaboration_class('Etherpad').should eql(EtherpadCollaboration)
    end
    it "should not allow invalid collaborations" do
      Collaboration.instance_variable_set('@collab_types', Collaboration::DEFAULT_COLLABORATION_TYPES)
      Collaboration.collaboration_class('Bacon').should eql(nil)
    end
  end
  
  context "parsed data" do
    before do
      google_docs_collaboration_model
    end
    it "should be able to parse the data stored as an Atom entry" do
      ae = @collaboration.parse_data
      ae.should be_is_a(Atom::Entry)
      ae.title.should eql('Biology 100 Collaboration')
    end
    
    it "should be able to get the title from the data" do
      @collaboration.title.should eql('Biology 100 Collaboration')
    end
    
    it "should have Google Docs as a default service name" do
      @collaboration.service_name.should eql('Google Docs')
    end
  end
  
end
