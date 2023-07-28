# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe CollaborationsHelper do
  let(:user) { double("user") }
  let(:course) { Course.new(name: "my course").tap { |t| allow(t).to receive_messages(id: 1) } }
  let(:collab) { double("single collaboration").tap { |t| allow(t).to receive_messages(id: 1) } }

  describe "collaboration" do
    it "renders the collaborations" do
      expect(helper).to receive(:render).with("collaborations/collaboration", include(collaboration: collab, user:))
      helper.collaboration(collab, user, false)
    end

    it "renders the google auth for google drive collaborations if the user does not have google docs authorized" do
      allow(collab).to receive(:is_a?).with(GoogleDocsCollaboration).and_return(true)
      expect(helper).to receive(:render).with("collaborations/auth_google_drive", collaboration: collab)
      helper.collaboration(collab, user, false)
    end

    it "constructs the data attributes" do
      expect(helper).to receive(:render).with("collaborations/collaboration", include(
                                                                                data_attributes: include({ id: 1 })
                                                                              ))
      helper.collaboration(collab, user, false)
    end

    it "has the data-update-launch-url attribute if it is a ExternalToolCollaboration" do
      assign(:context, course)
      launch_url = "http://example.com/test"
      allow(collab).to receive_messages(is_a?: false, update_url: launch_url)
      allow(collab).to receive(:is_a?).with(ExternalToolCollaboration).and_return true
      expect(helper).to receive(:render).with("collaborations/collaboration",
                                              include(
                                                data_attributes: include(
                                                  update_launch_url: include(CGI.escape(launch_url)),
                                                  id: collab.id
                                                )
                                              ))
      helper.collaboration(collab, user, false)
    end
  end

  describe "#edit_button" do
    it "returns the edit button if the user has permissions" do
      allow(collab).to receive(:grants_any_right?).and_return(true)
      expect(helper).to receive(:render).with("collaborations/edit_button", collaboration: collab)
      helper.edit_button(collab, user)
    end

    it "doesn't return the edit button for an ExternalToolCollaboration that don't have an edit url" do
      allow(collab).to receive(:is_a?).with(ExternalToolCollaboration).and_return(true)
      allow(collab).to receive_messages(update_url: nil, grants_any_right?: true)
      expect(helper).not_to receive(:render)
      helper.edit_button(collab, user)
    end
  end

  describe "#delete_button" do
    it "returns the delete button if the user has permissions" do
      allow(collab).to receive(:grants_any_right?).and_return(true)
      expect(helper).to receive(:render).with("collaborations/delete_button", collaboration: collab)
      helper.delete_button(collab, user)
    end
  end

  describe "#collaboration_links" do
    it "returns collaboration links if the user has permissions" do
      allow(collab).to receive(:grants_any_right?).and_return(true)
      expect(helper).to receive(:render).with("collaborations/collaboration_links", collaboration: collab, user:)
      helper.collaboration_links(collab, user)
    end

    it "doesn't return collaboration links if the user doesn't have permission" do
      allow(collab).to receive(:grants_any_right?).and_return(false)
      expect(helper).not_to receive(:render).with("collaborations/collaboration_links", collaboration: collab, user:)
      helper.collaboration_links(collab, user)
    end
  end
end
