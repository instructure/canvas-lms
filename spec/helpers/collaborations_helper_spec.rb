#
# Copyright (C) 2016 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CollaborationsHelper do

  let(:user) { mock('user') }
  let(:course) { Course.new(name: "my course").tap {|t| t.stubs(id: 1)} }
  let(:collab) { mock('single collaboration').tap {|t| t.stubs(id: 1) } }

  describe "collaboration" do
    it 'renders the collaborations' do
      helper.expects(:render).with('collaborations/collaboration', has_entries(collaboration: collab, user: user))
      helper.collaboration(collab, user, false)
    end

    it 'renders the google auth for google drive collaborations if the user does not have google docs authorized' do
      collab.stubs(:is_a?).with(GoogleDocsCollaboration).returns(true)
      helper.expects(:render).with('collaborations/auth_google_drive', collaboration: collab)
      helper.collaboration(collab, user, false)
    end

    it 'constructs the data attributes' do
      helper.expects(:render).with('collaborations/collaboration', has_entries(
                                                                     data_attributes: has_entries({id: 1})
      ))
      helper.collaboration(collab, user, false)
    end

    it 'has the data-update-launch-url attribute if it is a ExternalToolCollaboration' do
      assign(:context, course)
      launch_url = 'http://example.com/test'
      collab.stubs(:is_a?).returns false
      collab.stubs(:is_a?).with(ExternalToolCollaboration).returns true
      collab.stubs(:update_url).returns(launch_url)
      helper.expects(:render).with('collaborations/collaboration',
                                has_entries(
                                  data_attributes: has_entries(
                                    update_launch_url: includes(CGI.escape(launch_url)),
                                    id: collab.id
                                  )
                                )
                                  )
      helper.collaboration(collab, user, false)
    end

  end

  describe "#edit_button" do
    it 'returns the edit button if the user has permissions' do
      collab.stubs(:grants_any_right?).returns(true)
      helper.expects(:render).with('collaborations/edit_button', collaboration: collab)
      helper.edit_button(collab, user)
    end

    it "doesn't return the edit button for an ExternalToolCollaboration that don't have an edit url" do
      collab.stubs(:is_a?).with(ExternalToolCollaboration).returns(true)
      collab.stubs(:update_url).returns(nil)
      collab.stubs(:grants_any_right?).returns(true)
      helper.expects(:render).never
      helper.edit_button(collab, user)
    end

  end

  describe "#delete_button" do
    it 'returns the delete button if the user has permissions' do
      collab.stubs(:grants_any_right?).returns(true)
      helper.expects(:render).with('collaborations/delete_button', collaboration: collab)
      helper.delete_button(collab, user)
    end
  end

  describe "#collaboration_links" do

    it 'returns collaboration links if the user has permissions' do
      collab.stubs(:grants_any_right?).returns(true)
      helper.expects(:render).with('collaborations/collaboration_links', collaboration: collab, user: user)
      helper.collaboration_links(collab, user)
    end

    it "doesn't return collaboration links if the user doesn't have permission" do
      collab.stubs(:grants_any_right?).returns(false)
      helper.expects(:render).with('collaborations/collaboration_links', collaboration: collab, user: user).never
      helper.collaboration_links(collab, user)
    end

  end


end
