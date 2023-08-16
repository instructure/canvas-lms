# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe Collaboration do
  context "collaboration_class" do
    describe ".any_collaborations_configured?" do
      let(:context) { course_factory }

      it "bies default not have any collaborations" do
        expect(Collaboration.any_collaborations_configured?(context)).to be_falsey
        expect(Collaboration.collaboration_types).to eq []
      end

      it "returns true if an external tool with a collaboration placment exists" do
        tool = context.context_external_tools.new(
          name: "bob",
          consumer_key: "bob",
          shared_secret: "bob",
          tool_id: "some_tool",
          privacy_level: "public"
        )
        tool.url = "http://www.example.com/basic_lti"
        tool.collaboration = {
          url: "http://#{HostUrl.default_host}/selection_test",
          selection_width: 400,
          selection_height: 400
        }
        tool.save!
        expect(Collaboration.any_collaborations_configured?(context)).to be true
      end

      it "uses Lti::ContextToolFinder.all_tools_scope_union to find tools" do
        expect(Lti::ContextToolFinder).to receive(:all_tools_scope_union).and_return(double(exists?: true))
        expect(Collaboration.any_collaborations_configured?(context)).to be true
      end
    end

    it "allows google docs collaborations" do
      expect(Collaboration.collaboration_class("GoogleDocs")).to be_nil
      plugin_setting = PluginSetting.new(name: "google_drive", settings: {})
      plugin_setting.save!
      expect(Collaboration.collaboration_class("GoogleDocs")).to eql(GoogleDocsCollaboration)
      plugin_setting.disabled = true
      plugin_setting.save!
      expect(Collaboration.collaboration_class("GoogleDocs")).to be_nil
    end

    it "allows etherpad collaborations" do
      expect(Collaboration.collaboration_class("Etherpad")).to be_nil
      plugin_setting = PluginSetting.new(name: "etherpad", settings: {})
      plugin_setting.save!
      expect(Collaboration.collaboration_class("Etherpad")).to eql(EtherpadCollaboration)
      plugin_setting.disabled = true
      plugin_setting.save!
      expect(Collaboration.collaboration_class("Etherpad")).to be_nil
    end

    it "does not allow invalid collaborations" do
      expect(Collaboration.collaboration_class("Bacon")).to be_nil
    end
  end

  context "parsed data" do
    before :once do
      google_docs_collaboration_model
    end

    it "has Google Docs as a default service name" do
      expect(@collaboration.service_name).to eql("Google Docs")
    end
  end

  context "a collaboration with collaborators" do
    before :once do
      PluginSetting.create!(name: "etherpad", settings: {})
      @other_user = user_with_pseudonym(active_all: true)
      @users = (1..4).map { user_with_pseudonym(active_all: true) }
      course_factory(active_all: true)
      @users.each { |u| @course.enroll_student(u) }
      @groups = [group_model(context: @course)]
      @groups.first.add_user(@users.last, "active")
      @collaboration = @course.collaborations.new(title: "Test collaboration",
                                                  user: @users.first)
      @collaboration.type = "EtherpadCollaboration"
      @collaboration.save!
    end

    it "adds new collaborators" do
      @collaboration.update_members(@users[0..-2], @groups.map(&:id))
      expect(@collaboration.reload.collaborators.map(&:user_id).uniq.count).to eq 4
      expect(@collaboration.collaborators.map(&:group_id).uniq.count).to eq 2
    end

    it "updates existing collaborators" do
      @collaboration.update_members(@users[0..], @groups.map(&:id))
      @collaboration.update_members(@users[0..-2])
      @collaboration.reload
      expect(@collaboration.collaborators.map(&:user_id).uniq.count).to eq 3
      expect(@collaboration.collaborators.map(&:group_id).uniq.count).to eq 1
      expect(@collaboration.collaborators.reload.map(&:user_id)).not_to include @users.last.id
    end

    it "does not add a group multiple times" do
      @collaboration.update_members([@users[0]], @groups)
      @collaboration.update_members([@users[0]], @groups)
      @collaboration.reload

      expect(@collaboration.collaborators.filter_map(&:group_id)).to eq @groups.map(&:id)
    end

    it "doesn't add users outside the course" do
      @collaboration.update_members([@other_user])
      @collaboration.reload
      expect(@collaboration.collaborators.pluck(:user_id)).not_to include @other_user.id
    end

    it "doesn't add groups outside the course" do
      other_group = @course.account.groups.create! name: "eh"
      @collaboration.update_members([], [other_group])
      @collaboration.reload
      expect(@collaboration.collaborators.pluck(:group_id)).not_to include other_group.id
    end

    it "allows course admins (and group members) to be added to a group collaboration" do
      @users.each { |u| u.student_enrollments.first.accept! }
      gc = @groups.first.collaborations.create! title: "derp", user: @teacher
      gc.update_members([@teacher, @users.first, @users.last])
      users = gc.reload.collaborators.pluck(:user_id)
      expect(users).to match_array([@teacher.id, @users.last.id])
    end
  end

  describe EtherpadCollaboration do
    it "does not re-initialize the url" do
      collab = EtherpadCollaboration.new
      collab.url = "http://example.com/legacy-uri"
      collab.initialize_document
      expect(collab.url).to eq "http://example.com/legacy-uri"
    end
  end
end
