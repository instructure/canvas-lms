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
#

require_relative "../apis/api_spec_helper"

describe WikiPagesApiController, type: :request do
  include Api

  before :once do
    course_with_teacher(active_all: true)
  end

  def update_wiki_page(user, page, wiki_params = {}, expected_status: 200)
    url = "/api/v1/courses/#{@course.id}/pages/#{page.url}"
    path = {
      controller: "wiki_pages_api",
      action: "update",
      format: "json",
      course_id: @course.id.to_s,
      url_or_id: page.url
    }
    params = { wiki_page: wiki_params }
    api_call_as_user(user, :put, url, path, params, {}, { expected_status: })
  end

  def revert_wiki_page(user, page, revision_id, expected_status: 200)
    url = "/api/v1/courses/#{@course.id}/pages/#{page.url}/revisions/#{revision_id}"
    path = {
      controller: "wiki_pages_api",
      action: "revert",
      format: "json",
      course_id: @course.id.to_s,
      url_or_id: page.url,
      revision_id:
    }
    api_call_as_user(user, :post, url, path, {}, {}, { expected_status: })
  end

  def revisions_of_wiki_page(user, page)
    url = "/api/v1/courses/#{@course.id}/pages/#{page.url}/revisions"
    path = {
      controller: "wiki_pages_api",
      action: "revisions",
      format: "json",
      course_id: @course.id.to_s,
      url_or_id: page.url
    }
    api_call_as_user(user, :get, url, path, {}, {}, { expected_status: 200 })
  end

  def create_wiki_page(user, wiki_params = {}, expected_status: 200)
    url = "/api/v1/courses/#{@course.id}/pages"
    path = {
      controller: "wiki_pages_api",
      action: "create",
      format: "json",
      course_id: @course.id.to_s
    }
    params = { wiki_page: wiki_params }
    api_call_as_user(user, :post, url, path, params, {}, { expected_status: })
  end

  def get_wiki_pages(user, include_params = [], expected_status: 200)
    url = "/api/v1/courses/#{@course.id}/pages"
    path = {
      controller: "wiki_pages_api",
      action: "index",
      format: "json",
      course_id: @course.id.to_s
    }
    params = { include: include_params }
    api_call_as_user(user, :get, url, path, params, {}, { expected_status: })
  end

  describe "index" do
    before do
      @wiki_page = create_wiki_page(@teacher, { title: "Pläcëhöldër", body: "Test" }, expected_status: 200)
    end

    context "block_content_editor feature is disabled" do
      before do
        @course.account.enable_feature!(:block_content_editor)
        @course.disable_feature!(:block_content_editor_eap)
      end

      it "returns a list of wiki pages" do
        response = get_wiki_pages(@teacher, ["body"])
        expect(response).to be_an(Array)
        expect(response.pluck("id")).to include(@wiki_page["id"])
      end
    end

    context "block_content_editor feature is enabled" do
      before do
        @course.account.enable_feature!(:block_content_editor)
        @course.enable_feature!(:block_content_editor_eap)
      end

      it "returns a list of wiki pages" do
        response = get_wiki_pages(@teacher, ["body"])
        expect(response).to be_an(Array)
        expect(response.pluck("id")).to include(@wiki_page["id"])
      end
    end
  end

  describe "n_plus_one_index_wiki_page_api feature flag" do
    before :once do
      student_in_course(active_all: true)

      5.times do |i|
        page = @course.wiki_pages.create!(title: "Test Page #{i}")
        page.assignment_overrides.create!(set_type: "CourseSection", set_id: @course.default_section.id)
        mod = @course.context_modules.first || @course.context_modules.create!(name: "Module")
        mod.add_item(type: "wiki_page", id: page.id)
      end
    end

    def count_queries_for_pages_api(flag_enabled:)
      flag_enabled ? Account.site_admin.enable_feature!(:n_plus_one_index_wiki_page_api) : Account.site_admin.disable_feature!(:n_plus_one_index_wiki_page_api)

      query_count = 0
      ActiveSupport::Notifications.subscribed(
        ->(*, payload) { query_count += 1 if payload[:sql] && !payload[:cached] },
        "sql.active_record"
      ) do
        json = api_call_as_user(@student, :get, "/api/v1/courses/#{@course.id}/pages", controller: "wiki_pages_api", action: "index", format: "json", course_id: @course.to_param)
        expect(json).to be_an(Array)
      end
      query_count
    end

    it "reduces N+1 queries compared to flag disabled" do
      query_count_off = count_queries_for_pages_api(flag_enabled: false)
      query_count_on = count_queries_for_pages_api(flag_enabled: true)

      expect(query_count_on).to be < query_count_off, "Query count should be less, but its not: #{query_count_on} < #{query_count_off}"
    end
  end

  describe "attachment associations" do
    before do
      @aa_test_data = AttachmentAssociationsSpecHelper.new(@course.account, @course)
    end

    it "POST #create creates AAs" do
      wiki_response = create_wiki_page(@teacher, { title: "Pläcëhöldër", body: @aa_test_data.base_html }, expected_status: 200)
      @wiki_page = WikiPage.find(wiki_response["page_id"])
      id_occurences, att_occurences = @aa_test_data.count_aa_records("WikiPage", wiki_response["page_id"])

      expect(id_occurences.keys).to match_array [wiki_response["page_id"]]
      expect(id_occurences.values).to all eq 1
      expect(att_occurences.keys).to match_array [@aa_test_data.attachment1.id]
      expect(att_occurences.values).to all eq 1
    end

    it "updates with new attachments" do
      wiki_response = create_wiki_page(@teacher, { title: "Pläcëhöldër", body: @aa_test_data.base_html }, expected_status: 200)
      @wiki_page = WikiPage.find(wiki_response["page_id"])
      update_wiki_page(@teacher, @wiki_page, { body: @aa_test_data.added_html })

      id_occurences, att_occurences = @aa_test_data.count_aa_records("WikiPage", wiki_response["page_id"])

      expect(id_occurences.keys).to match_array [wiki_response["page_id"]]
      expect(id_occurences.values).to all eq 2
      expect(att_occurences.keys).to match_array [@aa_test_data.attachment1.id, @aa_test_data.attachment2.id]
      expect(att_occurences.values).to all eq 1
    end

    it "updates with removed attachments should keep the associations" do
      wiki_response = create_wiki_page(@teacher, { title: "Pläcëhöldër", body: @aa_test_data.base_html }, expected_status: 200)
      @wiki_page = WikiPage.find(wiki_response["page_id"])
      update_wiki_page(@teacher, @wiki_page, { body: @aa_test_data.removed_html })
      id_occurences, att_occurences = @aa_test_data.count_aa_records("WikiPage", wiki_response["page_id"])

      expect(id_occurences.keys).to match_array [wiki_response["page_id"]]
      expect(id_occurences.values).to all eq 1
      expect(att_occurences.keys).to match_array [@aa_test_data.attachment1.id]
      expect(att_occurences.values).to all eq 1
    end

    it "reverts as expected" do
      wiki_response = create_wiki_page(@teacher, { title: "Pläcëhöldër", body: @aa_test_data.base_html }, expected_status: 200)
      @wiki_page = WikiPage.find(wiki_response["page_id"])
      update_wiki_page(@teacher, @wiki_page, { body: @aa_test_data.added_html })
      revisions = revisions_of_wiki_page(@teacher, @wiki_page)
      expect do
        revert_wiki_page(@teacher, @wiki_page, revisions.last["revision_id"])
      end.not_to raise_error
    end
  end

  describe "PUT #update with context_module touching" do
    before :once do
      wiki_page_model(title: "WikiPage Title")
      @wiki_page = @page

      @context_module = ContextModule.create!(
        context: @course,
        name: "Sample Module"
      )

      @context_module.add_item(
        id: @wiki_page.id,
        type: "wiki_page"
      )
    end

    context "when the wiki page is part of a context module" do
      before do
        @wiki_page.reload
        @context_module.reload
      end

      it "has exactly one ContentTag referencing the context module" do
        expect(@wiki_page.context_module_tags.size).to eq 1
        expect(@wiki_page.context_module_tags.first.context_module).to eq @context_module
      end

      it "touches each associated context_module on successful update" do
        original_updated_at = @context_module.updated_at

        update_wiki_page(@teacher, @wiki_page, { title: "Updated Wiki Title" })

        expect(@context_module.reload.updated_at).to be > original_updated_at
      end
    end

    context "when the wiki page has no context modules" do
      before do
        @wiki_page.reload
        @context_module.destroy!
      end

      it "does not raise an error" do
        expect do
          update_wiki_page(@teacher, @wiki_page, { title: "Another Title" })
        end.not_to raise_error
      end
    end
  end

  describe "POST #ai_generate_alt_text" do
    def ai_generate_alt_text_request(user, params = {})
      url = "/api/v1/courses/#{@course.id}/pages_ai/alt_text"
      path = {
        controller: "wiki_pages_api",
        action: "ai_generate_alt_text",
        format: "json",
        course_id: @course.id.to_s
      }
      api_call_as_user(user, :post, url, path, params)
    end

    context "when block content editor is disabled" do
      let!(:attachment) do
        attachment = @course.attachments.create!(
          filename: "test_image.jpg",
          uploaded_data: StringIO.new("fake image data")
        )
        attachment.update!(content_type: "image/jpeg")
        attachment
      end

      before do
        @course.account.enable_feature!(:block_content_editor)
        @course.disable_feature!(:block_content_editor_eap)
        allow(CedarClient).to receive(:enabled?).and_return(true)
      end

      it "returns forbidden even for teachers" do
        ai_generate_alt_text_request(@teacher, { attachment_id: attachment.id })
        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to eq("The feature is not available")
      end

      it "returns forbidden for students" do
        student_in_course(active_all: true)
        ai_generate_alt_text_request(@student, { attachment_id: attachment.id })
        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["errors"][0]["message"]).to eq("user not authorized to perform that action")
      end
    end

    context "when block content editor is enabled" do
      before do
        @course.account.enable_feature!(:block_content_editor)
        @course.enable_feature!(:block_content_editor_eap)
      end

      context "when site admin AI alt text feature is disabled" do
        let!(:attachment) do
          attachment = @course.attachments.create!(
            filename: "test_image.jpg",
            uploaded_data: StringIO.new("fake image data")
          )
          attachment.update!(content_type: "image/jpeg")
          attachment
        end

        before do
          Account.site_admin.disable_feature!(:block_content_editor_ai_alt_text)
          allow(CedarClient).to receive(:enabled?).and_return(true)
        end

        it "returns forbidden even for teachers" do
          ai_generate_alt_text_request(@teacher, { attachment_id: attachment.id })
          expect(response).to have_http_status(:forbidden)
          expect(response.parsed_body["error"]).to eq("The feature is not available")
        end

        it "returns forbidden for students" do
          student_in_course(active_all: true)
          ai_generate_alt_text_request(@student, { attachment_id: attachment.id })
          expect(response).to have_http_status(:forbidden)
          expect(response.parsed_body["errors"][0]["message"]).to eq("user not authorized to perform that action")
        end
      end

      context "when site admin AI alt text feature is enabled" do
        before do
          Account.site_admin.enable_feature!(:block_content_editor_ai_alt_text)
        end

        context "when CedarClient is disabled" do
          before do
            allow(CedarClient).to receive(:enabled?).and_return(false)
          end

          it "returns forbidden for teachers when CedarClient is not available" do
            ai_generate_alt_text_request(@teacher)
            expect(response).to have_http_status(:forbidden)
            expect(response.parsed_body["error"]).to eq("AI client is not available")
          end

          it "returns forbidden for students when CedarClient is not available" do
            student_in_course(active_all: true)
            ai_generate_alt_text_request(@student)
            expect(response).to have_http_status(:forbidden)
            expect(response.parsed_body["errors"][0]["message"]).to eq("user not authorized to perform that action")
          end
        end

        context "when CedarClient is enabled" do
          before do
            stub_const("CedarClient", Class.new do
              def enabled?
                true
              end

              def self.generate_alt_text(*)
                Struct.new(:image, keyword_init: true).new(image: { "altText" => "AI generated text." })
              end
            end)
            allow(CedarClient).to receive(:enabled?).and_return(true)
          end

          context "with invalid parameters" do
            # Tests ordered to match the actual validation sequence in the controller

            it "returns 400 when attachment_id parameter is missing" do
              ai_generate_alt_text_request(@teacher, {})
              expect(response).to have_http_status(:bad_request)
              expect(response.parsed_body).to eq({})
            end

            it "returns 400 when attachment_id is blank" do
              ai_generate_alt_text_request(@teacher, { attachment_id: "" })
              expect(response).to have_http_status(:bad_request)
              expect(response.parsed_body).to eq({})
            end

            it "returns 404 when attachment is not found" do
              non_existent_attachment_id = 99_999
              ai_generate_alt_text_request(@teacher, { attachment_id: non_existent_attachment_id })
              expect(response).to have_http_status(:not_found)
            end

            it "returns forbidden when user lacks read access to attachment" do
              # Create attachment in another course that teacher doesn't have access to
              other_course = course_factory
              unauthorized_attachment = other_course.attachments.create!(
                filename: "unauthorized_image.jpg",
                uploaded_data: StringIO.new("fake image data")
              )
              unauthorized_attachment.update!(content_type: "image/jpeg")

              ai_generate_alt_text_request(@teacher, { attachment_id: unauthorized_attachment.id })
              expect(response).to have_http_status(:forbidden)
            end

            it "returns 400 when image exceeds size limit" do
              large_attachment = @course.attachments.create!(
                filename: "large_image.jpg",
                uploaded_data: StringIO.new("x" * 4.megabytes)
              )
              large_attachment.update!(content_type: "image/jpeg")

              ai_generate_alt_text_request(@teacher, { attachment_id: large_attachment.id })
              expect(response).to have_http_status(:bad_request)
              expect(response.parsed_body["error"]).to eq("Image too large")
            end

            it "returns 400 when image type is not supported" do
              unsupported_attachment = @course.attachments.create!(
                filename: "document.pdf",
                uploaded_data: StringIO.new("fake pdf content")
              )
              unsupported_attachment.update!(content_type: "application/pdf")

              ai_generate_alt_text_request(@teacher, { attachment_id: unsupported_attachment.id })
              expect(response).to have_http_status(:bad_request)
              expect(response.parsed_body["error"]).to eq("Unsupported image type")
            end
          end

          context "with valid parameters" do
            let!(:attachment) do
              attachment = @course.attachments.create!(
                filename: "test_image.jpg",
                uploaded_data: StringIO.new("fake image data")
              )
              attachment.update!(content_type: "image/jpeg")
              attachment
            end

            it "returns unauthorized when user lacks granular manage course content permissions" do
              student_in_course(active_all: true)
              ai_generate_alt_text_request(@student, { attachment_id: attachment.id })
              expect(response).to have_http_status(:forbidden)
              expect(response.parsed_body["errors"][0]["message"]).to eq("user not authorized to perform that action")
            end

            it "calls CedarClient.generate_alt_text with correct parameters when lang is provided" do
              params = { lang: "en-us", attachment_id: attachment.id }

              expect(CedarClient).to receive(:generate_alt_text).with({
                                                                        image: { base64_source: kind_of(String), type: "Base64" },
                                                                        feature_slug: "alttext",
                                                                        root_account_uuid: @course.root_account.uuid,
                                                                        current_user: @teacher,
                                                                        max_length: 120,
                                                                        target_language: "en"
                                                                      })

              ai_generate_alt_text_request(@teacher, params)
            end

            it "returns the generation result in the response" do
              params = { attachment_id: attachment.id }

              ai_generate_alt_text_request(@teacher, params)
              expect(response).to have_http_status(:ok)

              response_body = response.parsed_body
              expect(response_body).to have_key("image")
              expect(response_body["image"]).to have_key("altText")
              expect(response_body["image"]["altText"]).to eq("AI generated text.")
            end
          end
        end
      end
    end
  end

  describe "POST accessibility_scan" do
    before :once do
      course_with_teacher(active_all: true)
      @student = student_in_course(active_all: true).user
      @wiki_page = @course.wiki_pages.create!(
        title: "Test Page",
        body: "<h1>Title</h1><p>Content</p>"
      )
    end

    def accessibility_scan_request(user, page_url, expected_status: 200)
      url = "/api/v1/courses/#{@course.id}/pages/#{page_url}/accessibility/scan"
      path = {
        controller: "wiki_pages_api",
        action: "accessibility_scan",
        format: "json",
        course_id: @course.id.to_s,
        url_or_id: page_url
      }
      api_call_as_user(user, :post, url, path, {}, {}, { expected_status: })
    end

    context "when a11y_checker feature is enabled" do
      before do
        @course.account.enable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)
      end

      it "requires manage course content permissions" do
        accessibility_scan_request(@student, @wiki_page.url, expected_status: 403)
      end

      it "runs a synchronous accessibility scan and returns scan results" do
        json = accessibility_scan_request(@teacher, @wiki_page.url)

        expect(json["id"]).to be_present
        expect(json["resource_type"]).to eq("WikiPage")
        expect(json["resource_name"]).to eq("Test Page")
        expect(json["workflow_state"]).to eq("completed")
        expect(json["issue_count"]).to be >= 0
        expect(json["issues"]).to be_an(Array)
      end

      it "returns 404 for non-existent page" do
        accessibility_scan_request(@teacher, "nonexistent-page", expected_status: 404)
      end

      it "calls ResourceScannerService with the wiki page" do
        service_double = instance_double(Accessibility::ResourceScannerService)
        scan_double = instance_double(AccessibilityResourceScan,
                                      id: 1,
                                      context: @wiki_page,
                                      resource_name: "Test Page",
                                      resource_workflow_state: "active",
                                      resource_updated_at: Time.zone.now,
                                      context_url: "/courses/#{@course.id}/pages/#{@wiki_page.id}",
                                      resource_scan_path: nil,
                                      workflow_state: "completed",
                                      error_message: nil,
                                      issue_count: 0,
                                      accessibility_issues: double(select: []))

        expect(Accessibility::ResourceScannerService).to receive(:new)
          .with(resource: @wiki_page)
          .and_return(service_double)
        expect(service_double).to receive(:call_sync).and_return(scan_double)

        accessibility_scan_request(@teacher, @wiki_page.url)
      end
    end

    context "when a11y_checker feature is disabled" do
      before do
        @course.account.disable_feature!(:a11y_checker)
        @course.disable_feature!(:a11y_checker_eap)
      end

      it "returns forbidden even for teachers" do
        accessibility_scan_request(@teacher, @wiki_page.url, expected_status: 403)
      end

      it "returns forbidden for students" do
        accessibility_scan_request(@student, @wiki_page.url, expected_status: 403)
      end
    end
  end

  describe "POST accessibility_queue_scan" do
    before :once do
      course_with_teacher(active_all: true)
      @student = student_in_course(active_all: true).user
      @wiki_page = @course.wiki_pages.create!(
        title: "Test Page",
        body: "<h1>Title</h1><p>Content</p>"
      )
    end

    def accessibility_queue_scan_request(user, page_url, expected_status: 200)
      url = "/api/v1/courses/#{@course.id}/pages/#{page_url}/accessibility/queue_scan"
      path = {
        controller: "wiki_pages_api",
        action: "accessibility_queue_scan",
        format: "json",
        course_id: @course.id.to_s,
        url_or_id: page_url
      }
      api_call_as_user(user, :post, url, path, {}, {}, { expected_status: })
    end

    context "when a11y_checker feature is enabled" do
      before do
        @course.account.enable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)
      end

      it "requires manage course content permissions" do
        accessibility_queue_scan_request(@student, @wiki_page.url, expected_status: 403)
      end

      it "queues an asynchronous accessibility scan and returns scan object with queued state" do
        json = accessibility_queue_scan_request(@teacher, @wiki_page.url)

        expect(json["id"]).to be_present
        expect(json["resource_id"]).to eq(@wiki_page.id)
        expect(json["resource_type"]).to eq("WikiPage")
        expect(json["resource_name"]).to eq("Test Page")
        expect(json["workflow_state"]).to eq("queued")
      end

      it "returns 404 for non-existent page" do
        accessibility_queue_scan_request(@teacher, "nonexistent-page", expected_status: 404)
      end

      it "calls ResourceScannerService with the wiki page using async call method" do
        service = Accessibility::ResourceScannerService.new(resource: @wiki_page)

        expect(Accessibility::ResourceScannerService).to receive(:new)
          .with(resource: @wiki_page)
          .and_return(service)
        # Stub delay to prevent actual job queueing but allow scan creation
        expect(service).to receive(:delay).and_return(service)
        expect(service).to receive(:scan_resource)

        accessibility_queue_scan_request(@teacher, @wiki_page.url)
      end

      it "does not queue duplicate scans if one is already queued" do
        # Create an existing queued scan
        existing_scan = AccessibilityResourceScan.create!(
          context: @wiki_page,
          course_id: @course.id,
          workflow_state: "queued",
          resource_name: @wiki_page.title,
          resource_workflow_state: "published",
          resource_updated_at: @wiki_page.updated_at
        )

        # Should not create a new delayed job
        expect(Delayed::Job).not_to receive(:enqueue)

        json = accessibility_queue_scan_request(@teacher, @wiki_page.url)

        # Should return the existing scan
        expect(json["id"]).to eq(existing_scan.id)
        expect(json["workflow_state"]).to eq("queued")
      end
    end

    context "when a11y_checker feature is disabled" do
      before do
        @course.account.disable_feature!(:a11y_checker)
        @course.disable_feature!(:a11y_checker_eap)
      end

      it "returns forbidden even for teachers" do
        accessibility_queue_scan_request(@teacher, @wiki_page.url, expected_status: 403)
      end

      it "returns forbidden for students" do
        accessibility_queue_scan_request(@student, @wiki_page.url, expected_status: 403)
      end
    end
  end
end
