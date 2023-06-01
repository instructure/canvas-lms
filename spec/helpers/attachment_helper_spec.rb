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

  it "returns a valid crocodoc session url" do
    @current_user = @student
    allow(@att).to receive(:crocodoc_available?).and_return(true)
    attrs = doc_preview_attributes(@att)
    expect(attrs).to match(/crocodoc_session/)
    expect(attrs).to match(/#{@current_user.id}/)
    expect(attrs).to match(/#{@att.id}/)
  end

  it "returns a valid canvadoc session url" do
    @current_user = @student
    allow(@att).to receive(:canvadocable?).and_return(true)
    attrs = doc_preview_attributes(@att)
    expect(attrs).to match(/canvadoc_session/)
    expect(attrs).to match(/#{@current_user.id}/)
    expect(attrs).to match(/#{@att.id}/)
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

  describe "#doc_preview_json" do
    subject { doc_preview_json(attachment, locked_for_user:) }

    let(:attachment) { @att }
    let(:locked_for_user) { false }

    shared_examples_for "scenarios when the file is not locked for the user" do
      let(:preview_json) { raise "set in examples" }

      it "adds the crocodoc session url" do
        expect(preview_json.keys).to include(:crocodoc_session_url)
      end

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

      it "does not add the crocodoc session url" do
        expect(subject.keys).not_to include(:crocodoc_session_url)
      end

      it "does not add the canvadoc session url" do
        expect(subject.keys).not_to include(:canvadoc_session_url)
      end
    end
  end
end
