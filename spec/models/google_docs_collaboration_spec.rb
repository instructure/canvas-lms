#
# Copyright (C) 2014 Instructure, Inc.
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

require 'spec_helper'

describe GoogleDocsCollaboration do
  def stub_service
    google_drive_connection = stub(retrieve_access_token: "asdf123", acl_add: nil, acl_remove: nil)
    GoogleDrive::Connection.stubs(:new).returns(google_drive_connection)
    file = stub(data: stub(id: 1, to_json: "{id: 1}", alternateLink: "http://google.com"))
    google_drive_connection.stubs(:create_doc).with("title").returns(file)
  end

  describe "#initialize_document" do
    let(:user) { User.new }
    it "creates a google doc" do
      google_docs_collaboration = GoogleDocsCollaboration.new
      google_docs_collaboration.title = "title"
      google_docs_collaboration.user = user
      stub_service
      Rails.cache.expects(:fetch).returns(["token", "secret"])
      google_docs_collaboration.initialize_document
    end
  end

  describe 'collaborators' do
    before :once do
      PluginSetting.create!(:name => "google_drive", :settings => {})
      @other_user = user_with_pseudonym(:active_all => true)
      @student = user_with_pseudonym(:active_all => true)
      course_factory(:active_all => true)
      @course.enroll_student(@student)

      @teacher.user_services.create! service: 'google_drive', service_domain: 'drive.google.com',
                                     service_user_id: 'teh_teacher@gmail.com', token: 'blah', secret: 'bleh'
      @student.user_services.create! service: 'google_drive', service_domain: 'drive.google.com',
                                     service_user_id: 'teh_student@gmail.com', token: 'bleh', secret: 'blah'
      @other_user.user_services.create! service: 'google_drive', service_domain: 'drive.google.com',
                                        service_user_id: 'distractor@gmail.com', token: 'bleh', secret: 'bleh'

      stub_service
      @collaboration = GoogleDocsCollaboration.new(:title => 'title', :user => @teacher)
      @collaboration.context = @course
      @collaboration.save!
    end

    it "adds collaborators" do
      stub_service
      @collaboration.update_members([@teacher, @student])
      collaborators = @collaboration.reload.collaborators.to_a
      expect(collaborators.map(&:user_id)).to match_array([@student.id, @teacher.id])
      expect(collaborators.map(&:authorized_service_user_id)).to match_array(['teh_teacher@gmail.com', 'teh_student@gmail.com'])
    end

    it "doesn't add users outside the course" do
      stub_service
      @collaboration.update_members([@other_user])
      @collaboration.reload
      expect(@collaboration.collaborators.pluck(:user_id)).not_to include @other_user.id
    end
  end
end
