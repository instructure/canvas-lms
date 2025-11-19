# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe AttachmentHelper do
  include ApplicationHelper
  include AttachmentHelper

  before :once do
    course_with_student
    @att = attachment_model(context: @user)
  end

  it "returns a valid canvadoc session url" do
    @current_user = @student
    allow(@att).to receive(:canvadocable?).and_return(true)
    attrs = doc_preview_attributes(@att)
    expect(attrs).to match(/canvadoc_session/)
    expect(attrs).to match(/#{@current_user.id}/)
    expect(attrs).to match(/#{@att.id}/)
  end

  it "includes attachment name for iframe's aria-label" do
    @current_user = @student
    attrs = doc_preview_attributes(@att)
    expect(attrs).to match(/data-attachment_name="#{@att.name}"/)
  end

  it "includes anonymous_instructor_annotations in canvadoc url" do
    @current_user = @teacher
    allow(@att).to receive(:canvadocable?).and_return(true)
    attrs = doc_preview_attributes(@att, { anonymous_instructor_annotations: true })
    expect(attrs).to match "anonymous_instructor_annotations%22:true"
  end

  it "includes enrollment_type in canvadoc url when annotations are enabled" do
    @current_user = @teacher
    allow(@att).to receive(:canvadocable?).and_return(true)
    attrs = doc_preview_attributes(@att, { enable_annotations: true, enrollment_type: "teacher" })
    expect(attrs).to match "enrollment_type%22:%22teacher"
  end

  it "includes submission id in canvadoc url" do
    id = 23
    @current_user = @teacher
    allow(@att).to receive(:canvadocable?).and_return(true)
    attrs = doc_preview_attributes(@att, { enable_annotations: true, enrollment_type: "teacher", submission_id: id })
    expect(attrs).to match "%22submission_id%22:#{id}"
  end

  describe "set_cache_header" do
    it "does not allow caching of instfs redirects" do
      allow(@att).to receive(:instfs_hosted?).and_return(true)
      expect(self).not_to receive(:cancel_cache_buster)
      set_cache_header(@att, false)
      expect(response.headers).not_to have_key("Cache-Control")
    end
  end

  describe "#access_via_location?" do
    let(:attachment) { @att }
    let(:user) { @student }
    let(:access_type) { :read }

    context "when location parameter is not present" do
      it "returns false" do
        expect(access_via_location?(attachment, user, access_type)).to be false
      end
    end

    context "when location parameter is present but access_type is not :read or :download" do
      before do
        allow(self).to receive(:params).and_return({ location: "some_location" })
      end

      it "returns false for :update access type" do
        expect(access_via_location?(attachment, user, :update)).to be false
      end

      it "returns false for :delete access type" do
        expect(access_via_location?(attachment, user, :delete)).to be false
      end
    end

    context "when location parameter is present and access_type is :read" do
      let(:access_type) { :read }

      context "with avatar_ location" do
        let(:avatar_user) { user_factory }
        let(:avatar_user_id) { Shard.short_id_for(avatar_user.global_id) }

        before do
          allow(self).to receive(:params).and_return({ location: "avatar_#{avatar_user_id}" })
        end

        it "returns true when user allows avatar access" do
          allow(User).to receive(:find_by).and_return(avatar_user)
          allow(avatar_user).to receive(:allow_avatar_access?).with(attachment).and_return(true)
          expect(access_via_location?(attachment, user, access_type)).to be true
        end

        it "returns false when user does not allow avatar access" do
          allow(User).to receive(:find_by).and_return(avatar_user)
          allow(avatar_user).to receive(:allow_avatar_access?).with(attachment).and_return(false)
          expect(access_via_location?(attachment, user, access_type)).to be false
        end

        it "returns false when user is not found" do
          allow(self).to receive(:params).and_return({ location: "avatar_1~999999" })
          expect(access_via_location?(attachment, user, access_type)).to be false
        end

        it "handles nil user gracefully" do
          allow(User).to receive(:find_by).and_return(nil)
          expect(access_via_location?(attachment, user, access_type)).to be false
        end
      end

      context "with non-avatar location" do
        let(:location) { "some_other_location" }
        let(:session) { {} }

        before do
          allow(self).to receive_messages(params: { location: }, session:)
        end

        it "returns true when AttachmentAssociation.verify_access returns true" do
          allow(AttachmentAssociation).to receive(:verify_access)
            .with(location, attachment, user, session)
            .and_return(true)
          expect(access_via_location?(attachment, user, access_type)).to be true
        end

        it "returns false when AttachmentAssociation.verify_access returns false" do
          allow(AttachmentAssociation).to receive(:verify_access)
            .with(location, attachment, user, session)
            .and_return(false)
          expect(access_via_location?(attachment, user, access_type)).to be false
        end
      end
    end

    context "when location parameter is present and access_type is :download" do
      let(:access_type) { :download }

      context "with avatar_ location" do
        let(:avatar_user) { user_factory }

        before do
          allow(self).to receive(:params).and_return({ location: "avatar_#{avatar_user.id}" })
        end

        it "returns true when user allows avatar access" do
          allow(User).to receive(:find_by).with(id: avatar_user.id.to_s).and_return(avatar_user)
          allow(avatar_user).to receive(:allow_avatar_access?).with(attachment).and_return(true)
          expect(access_via_location?(attachment, user, access_type)).to be true
        end

        it "returns false when user does not allow avatar access" do
          allow(avatar_user).to receive(:allow_avatar_access?).with(attachment).and_return(false)
          expect(access_via_location?(attachment, user, access_type)).to be false
        end
      end

      context "with non-avatar location" do
        let(:location) { "submission_123" }
        let(:session) { { user_id: user.id } }

        before do
          allow(self).to receive_messages(params: { location: }, session:)
        end

        it "delegates to AttachmentAssociation.verify_access with correct parameters" do
          expect(AttachmentAssociation).to receive(:verify_access)
            .with(location, attachment, user, session)
            .and_return(true)
          expect(access_via_location?(attachment, user, access_type)).to be true
        end
      end
    end

    context "edge cases" do
      let(:access_type) { :read }

      it "handles avatar location with non-numeric user id" do
        allow(self).to receive(:params).and_return({ location: "avatar_abc" })
        expect(access_via_location?(attachment, user, access_type)).to be false
      end

      it "handles avatar location with empty user id" do
        allow(self).to receive(:params).and_return({ location: "avatar_" })
        expect(access_via_location?(attachment, user, access_type)).to be false
      end
    end
  end

  describe "#doc_preview_json" do
    subject { doc_preview_json(attachment, locked_for_user:) }

    let(:attachment) { @att }
    let(:locked_for_user) { false }

    shared_examples_for "scenarios when the file is not locked for the user" do
      let(:preview_json) { raise "set in examples" }

      it "adds the canvadoc session url" do
        expect(preview_json.keys).to include(:canvadoc_session_url)
      end
    end

    context "when 'locked_for_user' is true" do
      let(:locked_for_user) { false }

      it_behaves_like "scenarios when the file is not locked for the user" do
        let(:preview_json) { subject }
      end
    end

    context "when 'locked_for_user' is not given" do
      it_behaves_like "scenarios when the file is not locked for the user" do
        let(:preview_json) { doc_preview_json(attachment) }
      end
    end

    context "when 'locked_for_user' is false" do
      let(:locked_for_user) { true }

      it "does not add the canvadoc session url" do
        expect(subject.keys).not_to include(:canvadoc_session_url)
      end
    end
  end
end
