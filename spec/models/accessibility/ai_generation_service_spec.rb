# frozen_string_literal: true

#
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

describe Accessibility::AiGenerationService do
  let(:account) { Account.default }
  let(:course) { course_model(account:) }
  let(:user) { user_model }
  let(:attachment) { attachment_model(context: user, size: 1.megabyte, content_type: "image/png") }
  let(:domain_root_account) { account }
  let(:params) do
    {
      content_type: "Page",
      content_id: wiki_page.id,
      path: "./div/p/img",
      context: course,
      current_user: user,
      domain_root_account:
    }
  end

  def create_wiki_page_with_body(body_content)
    page = course.wiki_pages.build(title: "Test", body: body_content)
    page.updating_user = user
    page.save!
    page
  end

  before do
    stub_const("CedarClient", Class.new do
      def self.generate_alt_text(*)
        Struct.new(:image, keyword_init: true).new(image: { "altText" => "Generated alt text" })
      end
    end)
  end

  describe "#generate_alt_text" do
    let(:wiki_page) do
      page = course.wiki_pages.build(title: "Test Page", body: "<div><p><img src=\"/files/#{attachment.id}\" /></p></div>")
      page.updating_user = user
      page.save!
      page
    end

    it "instantiates the service and calls generate_alt_text" do
      allow(Attachment).to receive(:find_by).and_call_original
      allow(Attachment).to receive(:find_by).with(id: attachment.id.to_s).and_return(attachment)
      allow(attachment).to receive_messages(grants_right?: true, open: StringIO.new("fake image data"))

      service = described_class.new(**params)
      expect(service).to receive(:generate_alt_text).and_call_original

      service.generate_alt_text
    end

    it "returns the result from generate_alt_text" do
      allow(Attachment).to receive(:find_by).and_call_original
      allow(Attachment).to receive(:find_by).with(id: attachment.id.to_s).and_return(attachment)
      allow(attachment).to receive_messages(grants_right?: true, open: StringIO.new("fake image data"))

      service = described_class.new(**params)
      result = service.generate_alt_text
      expect(result).to eq("Generated alt text")
    end

    context "when all parameters are valid" do
      let(:wiki_page) do
        page = course.wiki_pages.build(title: "Test Page", body: "<div><p><img src=\"/files/#{attachment.id}\" /></p></div>")
        page.updating_user = user
        page.save!
        page
      end

      before do
        allow(Attachment).to receive(:find_by).and_call_original
        allow(Attachment).to receive(:find_by).with(id: attachment.id.to_s).and_return(attachment)
        allow(attachment).to receive_messages(grants_right?: true, open: StringIO.new("fake image data"))
      end

      it "successfully generates alt text" do
        result = described_class.new(**params).generate_alt_text
        expect(result).to eq("Generated alt text")
      end

      it "calls CedarClient with correct parameters" do
        expect(CedarClient).to receive(:generate_alt_text).with(
          image: { base64_source: kind_of(String), type: "Base64" },
          feature_slug: "alttext",
          root_account_uuid: account.uuid,
          current_user: user,
          max_length: 200,
          target_language: kind_of(String)
        ).and_call_original

        described_class.new(**params).generate_alt_text
      end

      it "encodes the attachment to base64" do
        expect(Base64).to receive(:strict_encode64).with("fake image data").and_call_original
        described_class.new(**params).generate_alt_text
      end
    end

    context "when parameters are missing or invalid" do
      let(:wiki_page) do
        page = course.wiki_pages.build(title: "Test Page", body: "<div><p><img src=\"/files/#{attachment.id}\" /></p></div>")
        page.updating_user = user
        page.save!
        page
      end

      it "raises InvalidParameterError when content_type is missing" do
        params[:content_type] = nil
        expect { described_class.new(**params).generate_alt_text }.to raise_error(Accessibility::AiGenerationService::InvalidParameterError)
      end

      it "raises InvalidParameterError when content_id is missing" do
        params[:content_id] = nil
        expect { described_class.new(**params).generate_alt_text }.to raise_error(Accessibility::AiGenerationService::InvalidParameterError)
      end

      it "raises InvalidParameterError when path is missing" do
        params[:path] = nil
        expect { described_class.new(**params).generate_alt_text }.to raise_error(Accessibility::AiGenerationService::InvalidParameterError)
      end

      it "raises InvalidParameterError when content_id is not an integer" do
        params[:content_id] = "not_an_integer"
        expect { described_class.new(**params).generate_alt_text }.to raise_error(Accessibility::AiGenerationService::InvalidParameterError)
      end

      it "raises InvalidParameterError for unsupported content_type" do
        params[:content_type] = "UnsupportedType"
        expect { described_class.new(**params).generate_alt_text }.to raise_error(Accessibility::AiGenerationService::InvalidParameterError)
      end

      it "raises InvalidParameterError when resource does not exist" do
        params[:content_id] = 999_999
        expect { described_class.new(**params).generate_alt_text }.to raise_error(Accessibility::AiGenerationService::InvalidParameterError)
      end
    end

    context "with Assignment resource" do
      let(:assignment) do
        assignment = course.assignments.build(description: "<div><p><img src=\"/files/#{attachment.id}\" /></p></div>")
        assignment.updating_user = user
        assignment.save!
        assignment
      end

      it "successfully generates alt text for assignment" do
        allow(Attachment).to receive(:find_by).and_call_original
        allow(Attachment).to receive(:find_by).with(id: attachment.id.to_s).and_return(attachment)
        allow(attachment).to receive_messages(grants_right?: true, open: StringIO.new("fake image data"))

        assignment_params = {
          content_type: "Assignment",
          content_id: assignment.id,
          path: "./div/p/img",
          context: course,
          current_user: user,
          domain_root_account:
        }
        result = described_class.new(**assignment_params).generate_alt_text
        expect(result).to eq("Generated alt text")
      end
    end

    context "attachment ID extraction with regex" do
      context "with relative paths (should match)" do
        it "extracts ID from /files/123" do
          wiki_page = create_wiki_page_with_body("<img src=\"/files/#{attachment.id}\" />")
          allow(Attachment).to receive(:find_by).and_call_original
          allow(Attachment).to receive(:find_by).with(id: attachment.id.to_s).and_return(attachment)
          allow(attachment).to receive_messages(grants_right?: true, open: StringIO.new("fake image data"))

          result = described_class.new(
            content_type: "Page",
            content_id: wiki_page.id,
            path: "./img",
            context: course,
            current_user: user,
            domain_root_account:
          ).generate_alt_text
          expect(result).to eq("Generated alt text")
        end

        it "extracts ID from /courses/3/files/174/preview" do
          wiki_page = create_wiki_page_with_body("<img src=\"/courses/3/files/#{attachment.id}/preview\" />")
          allow(Attachment).to receive(:find_by).and_call_original
          allow(Attachment).to receive(:find_by).with(id: attachment.id.to_s).and_return(attachment)
          allow(attachment).to receive_messages(grants_right?: true, open: StringIO.new("fake image data"))

          result = described_class.new(
            content_type: "Page",
            content_id: wiki_page.id,
            path: "./img",
            context: course,
            current_user: user,
            domain_root_account:
          ).generate_alt_text
          expect(result).to eq("Generated alt text")
        end

        it "extracts ID from /courses/1/files/456/download" do
          wiki_page = create_wiki_page_with_body("<img src=\"/courses/1/files/#{attachment.id}/download\" />")
          allow(Attachment).to receive(:find_by).and_call_original
          allow(Attachment).to receive(:find_by).with(id: attachment.id.to_s).and_return(attachment)
          allow(attachment).to receive_messages(grants_right?: true, open: StringIO.new("fake image data"))

          result = described_class.new(
            content_type: "Page",
            content_id: wiki_page.id,
            path: "./img",
            context: course,
            current_user: user,
            domain_root_account:
          ).generate_alt_text
          expect(result).to eq("Generated alt text")
        end
      end

      context "with full URLs (should NOT match)" do
        it "raises InvalidParameterError for https://example.com/files/123" do
          wiki_page = create_wiki_page_with_body("<img src=\"https://example.com/files/123\" />")

          expect do
            described_class.new(
              content_type: "Page",
              content_id: wiki_page.id,
              path: "./img",
              context: course,
              current_user: user,
              domain_root_account:
            ).generate_alt_text
          end.to raise_error(Accessibility::AiGenerationService::InvalidParameterError)
        end

        it "raises InvalidParameterError for http://canvas.com/files/456" do
          wiki_page = create_wiki_page_with_body("<img src=\"http://canvas.com/files/456\" />")

          expect do
            described_class.new(
              content_type: "Page",
              content_id: wiki_page.id,
              path: "./img",
              context: course,
              current_user: user,
              domain_root_account:
            ).generate_alt_text
          end.to raise_error(Accessibility::AiGenerationService::InvalidParameterError)
        end
      end

      it "raises InvalidParameterError when src attribute is missing" do
        wiki_page = create_wiki_page_with_body("<img />")

        expect do
          described_class.new(
            content_type: "Page",
            content_id: wiki_page.id,
            path: "./img",
            context: course,
            current_user: user,
            domain_root_account:
          ).generate_alt_text
        end.to raise_error(Accessibility::AiGenerationService::InvalidParameterError)
      end

      it "raises InvalidParameterError when element at path is not an img" do
        wiki_page = create_wiki_page_with_body("<div>not an image</div>")

        expect do
          described_class.new(
            content_type: "Page",
            content_id: wiki_page.id,
            path: "./div",
            context: course,
            current_user: user,
            domain_root_account:
          ).generate_alt_text
        end.to raise_error(Accessibility::AiGenerationService::InvalidParameterError)
      end
    end

    context "attachment validation" do
      let(:wiki_page) do
        page = course.wiki_pages.build(title: "Test Page", body: "<img src=\"/files/#{attachment.id}\" />")
        page.updating_user = user
        page.save!
        page
      end

      before do
        params[:content_id] = wiki_page.id
        params[:path] = "./img"
      end

      it "raises InvalidParameterError when attachment does not exist" do
        wiki_page_with_invalid_id = create_wiki_page_with_body("<img src=\"/files/999999\" />")
        params[:content_id] = wiki_page_with_invalid_id.id

        expect { described_class.new(**params).generate_alt_text }.to raise_error(Accessibility::AiGenerationService::InvalidParameterError)
      end

      it "raises InvalidParameterError when user lacks read permission" do
        allow(Attachment).to receive(:find_by).and_call_original
        allow(Attachment).to receive(:find_by).with(id: attachment.id.to_s).and_return(attachment)
        allow(attachment).to receive(:grants_right?).with(user, :read).and_return(false)

        expect { described_class.new(**params).generate_alt_text }.to raise_error(Accessibility::AiGenerationService::InvalidParameterError)
      end

      it "raises InvalidParameterError when file size exceeds limit" do
        large_attachment = attachment_model(context: user, size: 11.megabytes, content_type: "image/png")
        wiki_page_large = create_wiki_page_with_body("<img src=\"/files/#{large_attachment.id}\" />")
        params[:content_id] = wiki_page_large.id
        allow(large_attachment).to receive(:grants_right?).and_return(true)

        expect { described_class.new(**params).generate_alt_text }.to raise_error(Accessibility::AiGenerationService::InvalidParameterError)
      end

      it "raises InvalidParameterError when content type is unsupported" do
        pdf_attachment = attachment_model(context: user, size: 1.megabyte, content_type: "application/pdf")
        wiki_page_pdf = create_wiki_page_with_body("<img src=\"/files/#{pdf_attachment.id}\" />")
        params[:content_id] = wiki_page_pdf.id
        allow(pdf_attachment).to receive(:grants_right?).and_return(true)

        expect { described_class.new(**params).generate_alt_text }.to raise_error(Accessibility::AiGenerationService::InvalidParameterError)
      end
    end

    context "locale inference" do
      let(:wiki_page) do
        page = course.wiki_pages.build(title: "Test Page", body: "<img src=\"/files/#{attachment.id}\" />")
        page.updating_user = user
        page.save!
        page
      end

      before do
        params[:content_id] = wiki_page.id
        params[:path] = "./img"
        allow(Attachment).to receive(:find_by).with(id: attachment.id.to_s).and_return(attachment)
        allow(attachment).to receive_messages(grants_right?: true, open: StringIO.new("fake image data"))
      end

      it "uses infer_locale to determine target language" do
        service = described_class.new(**params)
        expect(service).to receive(:infer_locale).with(
          context: course,
          user:,
          root_account: domain_root_account
        ).and_return("en")

        service.generate_alt_text
      end

      it "passes target_language to CedarClient" do
        allow_any_instance_of(described_class).to receive(:infer_locale).and_return("es")

        expect(CedarClient).to receive(:generate_alt_text).with(
          hash_including(target_language: "es")
        ).and_call_original

        described_class.new(**params).generate_alt_text
      end
    end
  end
end
