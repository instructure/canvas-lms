# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

RSpec.shared_examples "it has a single accessibility context" do
  let(:error_message) { "Exactly one context must be present" }

  context "validations" do
    context "when none of the context associations are set" do
      it "adds an error" do
        subject.valid?

        expect(subject.errors[:base]).to include(error_message)
      end
    end

    context "when multiple context associations are set" do
      it "adds an error" do
        subject.wiki_page = wiki_page_model
        subject.assignment = assignment_model
        subject.valid?

        expect(subject.errors[:base]).to include(error_message)
      end
    end

    context "when only one context association is set" do
      it "does not add an error for wiki_page" do
        subject.wiki_page = wiki_page_model
        subject.valid?

        expect(subject.errors[:base]).not_to include(error_message)
      end

      it "does not add an error for assignment" do
        subject.assignment = assignment_model
        subject.valid?

        expect(subject.errors[:base]).not_to include(error_message)
      end

      it "does not add an error for attachment" do
        subject.attachment = attachment_model
        subject.valid?

        expect(subject.errors[:base]).not_to include(error_message)
      end
    end
  end

  context "context methods" do
    describe "#context" do
      context "with wiki_page" do
        let(:wiki_page) { wiki_page_model }

        it "returns the wiki_page" do
          subject.wiki_page = wiki_page
          expect(subject.context).to eq(wiki_page)
        end
      end

      context "with assignment" do
        let(:assignment) { assignment_model }

        it "returns the assignment" do
          subject.assignment = assignment
          expect(subject.context).to eq(assignment)
        end
      end

      context "with attachment" do
        let(:attachment) { attachment_model }

        it "returns the attachment" do
          subject.attachment = attachment
          expect(subject.context).to eq(attachment)
        end
      end
    end

    describe "#context=" do
      context "with wiki_page" do
        let(:wiki_page) { wiki_page_model }

        it "sets the wiki_page" do
          subject.context = wiki_page
          expect(subject.wiki_page).to eq(wiki_page)
        end
      end

      context "with assignment" do
        let(:assignment) { assignment_model }

        it "sets the assignment" do
          subject.context = assignment
          expect(subject.assignment).to eq(assignment)
        end
      end

      context "with attachment" do
        let(:attachment) { attachment_model }

        it "sets the attachment" do
          subject.context = attachment
          expect(subject.attachment).to eq(attachment)
        end
      end

      context "when context is not supported" do
        let(:invalid_context) { instance_double(PluginSetting, id: 1) }

        it "raises an error" do
          expect { subject.context = invalid_context }.to(
            raise_error(ArgumentError, "Unsupported context type: RSpec::Mocks::InstanceVerifyingDouble")
          )
        end
      end
    end

    describe "#context_id_and_type" do
      context "when the context is a wiki_page" do
        let(:wiki_page) { wiki_page_model }

        it "returns the wiki_page ID and type" do
          subject.wiki_page = wiki_page
          expect(subject.context_id_and_type).to eq([wiki_page.id, "WikiPage"])
        end
      end

      context "when the context is an assignment" do
        let(:assignment) { assignment_model }

        it "returns the assignment ID and type" do
          subject.assignment = assignment
          expect(subject.context_id_and_type).to eq([assignment.id, "Assignment"])
        end
      end

      context "when the context is an attachment" do
        let(:attachment) { attachment_model }

        it "returns the attachment ID and type" do
          subject.attachment = attachment
          expect(subject.context_id_and_type).to eq([attachment.id, "Attachment"])
        end
      end

      context "when no context is present" do
        it "returns [nil, nil]" do
          expect(subject.context_id_and_type).to eq([nil, nil])
        end
      end
    end

    describe "#context_url" do
      let(:course_id) { 1 }

      before { allow(subject).to receive(:course_id).and_return(course_id) }

      context "when the context is a wiki_page" do
        let(:wiki_page) { wiki_page_model }

        it "returns the correct wiki_page URL" do
          subject.wiki_page = wiki_page
          expect(subject.context_url).to eq("/courses/#{subject.course_id}/pages/#{wiki_page.id}")
        end
      end

      context "when the context is an assignment" do
        let(:assignment) { assignment_model }

        it "returns the correct assignment URL" do
          subject.assignment = assignment
          expect(subject.context_url).to eq("/courses/#{subject.course_id}/assignments/#{assignment.id}")
        end
      end

      context "when the context is an attachment" do
        let(:attachment) { attachment_model }

        it "returns the correct attachment URL" do
          subject.attachment = attachment
          expect(subject.context_url).to eq("/courses/#{subject.course_id}/files?preview=#{attachment.id}")
        end
      end

      context "when no context is present" do
        it "returns nil" do
          expect(subject.context_url).to be_nil
        end
      end
    end
  end
end
