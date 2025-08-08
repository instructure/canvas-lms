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

require "spec_helper"
require "webmock/rspec"

RSpec.describe YoutubeMigrationService do
  let(:root_account) { account_model }
  let(:course) { course_model(account: root_account) }
  let(:service) { described_class.new(course) }

  let(:youtube_embed) do
    {
      src: "https://www.youtube.com/embed/dQw4w9WgXcQ",
      id: wiki_page.id,
      resource_type: "WikiPage",
      field: :body,
      path: "//iframe[@src='https://www.youtube.com/embed/dQw4w9WgXcQ']",
      width: nil,
      height: nil
    }
  end

  let(:studio_tool) do
    external_tool_model(
      context: root_account,
      opts: {
        domain: "arc.instructure.com",
        url: "https://arc.instructure.com",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        name: "Studio"
      }
    )
  end

  let(:studio_api_response) do
    {
      "embed_url" => "https://arc.instructure.com/media/t_abcd1234",
      "title" => "Test Video Title",
      "id" => "media_12345"
    }
  end

  let!(:wiki_page) do
    wiki_page_model(
      course:,
      title: "Test Page",
      body: '<iframe src="https://www.youtube.com/embed/dQw4w9WgXcQ" width="560" height="315"></iframe>'
    )
  end

  before do
    allow(Lti::ContextToolFinder).to receive(:all_tools_for)
      .with(root_account)
      .and_return(double(active: double(find_by: studio_tool)))
  end

  describe "#queue_scan_course_for_embeds" do
    it "creates a new progress when none exists" do
      expect { described_class.queue_scan_course_for_embeds(course) }
        .to change { Progress.count }.by(1)

      progress = Progress.last
      expect(progress.tag).to eq("youtube_embed_scan")
      expect(progress.context).to eq(course)
    end

    it "returns existing progress if one is already running" do
      existing_progress = Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "running"
      )

      result = described_class.queue_scan_course_for_embeds(course)
      expect(result).to eq(existing_progress)
      expect(Progress.count).to eq(1)
    end

    it "creates new progress if previous one is completed" do
      Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed"
      )

      expect { described_class.queue_scan_course_for_embeds(course) }
        .to change { Progress.count }.by(1)
    end
  end

  describe "#scan" do
    let(:progress) { Progress.create!(tag: "youtube_embed_scan", context: course) }

    it "scans course and sets results on progress" do
      described_class.scan(progress)

      progress.reload
      expect(progress.results).to be_present
      expect(progress.results[:total_count]).to eq(1)
      expect(progress.results[:resources]).to be_present
    end

    it "handles scan errors gracefully" do
      allow_any_instance_of(described_class).to receive(:scan_course_for_embeds)
        .and_raise(StandardError, "Scan failed")

      expect(Canvas::Errors).to receive(:capture_exception)
        .with(:youtube_embed_scan, anything)
        .and_return(error_report: 12_345)

      described_class.scan(progress)

      progress.reload
      expect(progress.results).to be_present
      expect(progress.results[:error_report_id]).to eq(12_345)
    end
  end

  describe "#convert_embed" do
    let(:scan_progress) do
      Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed"
      )
    end

    it "creates a conversion progress and queues background job" do
      service.convert_embed(scan_progress.id, youtube_embed)

      convert_progress = Progress.where(tag: "youtube_embed_convert", context: course).last
      expect(convert_progress).to be_present
      expect(convert_progress.context).to eq(course)

      results = convert_progress.results.with_indifferent_access
      stored_embed = results["original_embed"]
      expect(stored_embed).to be_present
      expect(stored_embed["src"]).to eq(youtube_embed[:src])
      expect(stored_embed["id"]).to eq(youtube_embed[:id])
      expect(stored_embed["resource_type"]).to eq(youtube_embed[:resource_type])
    end

    context "with feature flag for high priority" do
      it "uses high priority when feature flag is enabled" do
        Account.site_admin.enable_feature!(:youtube_migration_high_priority)

        expect_any_instance_of(Progress).to receive(:process_job) do |_instance, klass, method, opts, *_args|
          expect(klass).to eq(YoutubeMigrationService)
          expect(method).to eq(:perform_conversion)
          expect(opts[:priority]).to eq(Delayed::HIGH_PRIORITY)
        end

        service.convert_embed(scan_progress.id, youtube_embed)
      end

      it "uses low priority when feature flag is disabled" do
        Account.site_admin.disable_feature!(:youtube_migration_high_priority)

        expect_any_instance_of(Progress).to receive(:process_job) do |_instance, klass, method, opts, *_args|
          expect(klass).to eq(YoutubeMigrationService)
          expect(method).to eq(:perform_conversion)
          expect(opts[:priority]).to eq(Delayed::LOW_PRIORITY)
        end

        service.convert_embed(scan_progress.id, youtube_embed)
      end
    end
  end

  describe "#perform_conversion" do
    let(:scan_progress) do
      Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed",
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [youtube_embed],
              count: 1
            }
          },
          total_count: 1
        }
      )
    end

    let(:convert_progress) do
      Progress.create!(
        tag: "youtube_embed_convert",
        context: course,
        results: { original_embed: youtube_embed }
      )
    end

    before do
      stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
        .with(
          body: {
            url: youtube_embed[:src],
            course_id: course.id,
            course_name: course.name
          }.to_json,
          headers: {
            "Authorization" => /Bearer .+/,
            "Content-Type" => "application/json"
          }
        )
        .to_return(
          status: 200,
          body: studio_api_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "successfully converts YouTube embed to Studio embed" do
      described_class.perform_conversion(convert_progress, course.id, scan_progress.id, youtube_embed)

      convert_progress.reload
      expect(convert_progress.results).to be_present
      expect(convert_progress.results[:success]).to be true
      expect(convert_progress.results[:studio_tool_id]).to eq(studio_tool.id)

      wiki_page.reload
      expect(wiki_page.body).to include("lti-embed")
      expect(wiki_page.body).to include("Test Video Title")
      expect(wiki_page.body).not_to include("youtube.com")
    end

    it "handles Studio API errors" do
      stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
        .to_return(status: 500, body: "Internal Server Error")

      expect(Canvas::Errors).to receive(:capture_exception)
        .with(:youtube_embed_convert, anything)
        .and_return(error_report: 54_321)

      described_class.perform_conversion(convert_progress, course.id, scan_progress.id, youtube_embed)

      convert_progress.reload
      expect(convert_progress.results).to be_present
      expect(convert_progress.results[:error_report_id]).to eq(54_321)
    end

    it "handles missing Studio tool" do
      studio_tool.destroy

      described_class.perform_conversion(convert_progress, course.id, scan_progress.id, youtube_embed)

      convert_progress.reload
      expect(convert_progress.results).to be_present
      expect(convert_progress.results[:error]).to eq("Studio LTI tool not found for account")
    end
  end

  describe "#scan_course_for_embeds" do
    let!(:assignment) do
      assignment_model(
        course:,
        title: "Assignment with YouTube",
        description: '<iframe src="https://www.youtube.com/embed/abc123" width="560" height="315"></iframe>'
      )
    end

    it "finds YouTube embeds in wiki pages" do
      resources = service.scan_course_for_embeds

      wiki_key = "WikiPage|#{wiki_page.id}"
      expect(resources[wiki_key]).to be_present
      expect(resources[wiki_key][:name]).to eq("Test Page")
      expect(resources[wiki_key][:count]).to eq(1)
      expect(resources[wiki_key][:embeds].first[:src]).to include("dQw4w9WgXcQ")
    end

    it "finds YouTube embeds in assignments" do
      resources = service.scan_course_for_embeds

      assignment_key = "Assignment|#{assignment.id}"
      expect(resources[assignment_key]).to be_present
      expect(resources[assignment_key][:name]).to eq("Assignment with YouTube")
      expect(resources[assignment_key][:count]).to eq(1)
      expect(resources[assignment_key][:embeds].first[:src]).to include("abc123")
    end

    it "skips resources without YouTube embeds" do
      wiki_page.update(body: "<p>No embeds here</p>")
      assignment.update(description: "<p>No embeds here either</p>")

      resources = service.scan_course_for_embeds
      expect(resources.keys.length).to eq(0)
    end
  end

  describe "#convert_youtube_to_studio" do
    before do
      stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
        .to_return(
          status: 200,
          body: studio_api_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "calls Studio API and generates iframe HTML" do
      result = service.convert_youtube_to_studio(youtube_embed, studio_tool)

      expect(result).to include("lti-embed")
      expect(result).to include("Test Video Title")
      expect(result).to include("/courses/#{course.id}/external_tools/retrieve")
      expect(result).to include("allowfullscreen")
    end

    it "uses original iframe dimensions when available" do
      embed_with_dimensions = youtube_embed.merge(width: "640", height: "480")
      result = service.convert_youtube_to_studio(embed_with_dimensions, studio_tool)

      expect(result).to include('width="640"')
      expect(result).to include('height="480"')
      expect(result).to include('style="width: 640px; height: 480px;"')
    end

    it "uses default dimensions when original dimensions are not available" do
      result = service.convert_youtube_to_studio(youtube_embed, studio_tool)

      expect(result).to include('width="560"')
      expect(result).to include('height="315"')
      expect(result).to include('style="width: 560px; height: 315px;"')
    end

    it "handles Studio API failures" do
      stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
        .to_return(status: 500, body: "Server Error")

      expect { service.convert_youtube_to_studio(youtube_embed, studio_tool) }
        .to raise_error(/Studio API request failed/)
    end
  end

  describe "#update_resource_content" do
    let(:original_html) { '<p>Before</p><iframe src="https://www.youtube.com/embed/dQw4w9WgXcQ" width="560" height="315"></iframe><p>After</p>' }
    let(:new_html) { '<iframe class="lti-embed" src="/courses/123/external_tools/retrieve?url=studio" title="Studio Video"></iframe>' }

    context "with WikiPage" do
      let(:wiki_page) { wiki_page_model(course:, body: original_html) }
      let(:embed) { youtube_embed.merge(id: wiki_page.id) }

      it "updates the page body" do
        service.update_resource_content(embed, new_html)

        wiki_page.reload
        expect(wiki_page.body).to include("lti-embed")
        expect(wiki_page.body).not_to include("youtube.com")
        expect(wiki_page.body).to include("Before")
        expect(wiki_page.body).to include("After")
      end
    end

    context "with Assignment" do
      let(:assignment) { assignment_model(course:, description: original_html) }
      let(:embed) { youtube_embed.merge(id: assignment.id, resource_type: "Assignment") }

      it "updates the assignment description" do
        service.update_resource_content(embed, new_html)

        assignment.reload
        expect(assignment.description).to include("lti-embed")
        expect(assignment.description).not_to include("youtube.com")
      end
    end

    context "with unsupported resource type" do
      let(:embed) { youtube_embed.merge(resource_type: "UnsupportedType") }

      it "raises an error" do
        expect { service.update_resource_content(embed, new_html) }
          .to raise_error(/Unsupported resource type/)
      end
    end
  end

  describe "#delete_embed_from_scan" do
    let(:scan_progress) do
      embed_data = {
        path: youtube_embed[:path],
        field: youtube_embed[:field],
        resource_type: youtube_embed[:resource_type],
        resource_group_key: youtube_embed[:resource_group_key],
        src: youtube_embed[:src],
        id: youtube_embed[:id]
      }
      Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed",
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [embed_data, { path: "//iframe[@src='https://www.youtube.com/embed/other']", field: :body, resource_type: "WikiPage", resource_group_key: nil, src: "https://www.youtube.com/embed/other", id: 123, width: nil, height: nil }],
              count: 2
            }
          },
          total_count: 2
        }
      )
    end

    it "removes the embed from scan results" do
      service.delete_embed_from_scan(scan_progress, youtube_embed)

      scan_progress.reload
      resource = scan_progress.results[:resources]["WikiPage|#{wiki_page.id}"]

      expect(resource[:count]).to eq(1)
      expect(resource[:embeds].length).to eq(1)
      expect(resource[:embeds].first[:src]).to eq("https://www.youtube.com/embed/other")
      expect(scan_progress.results[:total_count]).to eq(1)
    end

    it "removes entire resource if no embeds remain" do
      # Set up scan with only one embed
      embed_data = {
        path: youtube_embed[:path],
        field: youtube_embed[:field],
        resource_type: youtube_embed[:resource_type],
        resource_group_key: youtube_embed[:resource_group_key],
        src: youtube_embed[:src],
        id: youtube_embed[:id]
      }
      scan_progress.update!(
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [embed_data],
              count: 1
            }
          },
          total_count: 1
        }
      )

      service.delete_embed_from_scan(scan_progress, youtube_embed)

      scan_progress.reload
      expect(scan_progress.results[:resources]).to be_empty
      expect(scan_progress.results[:total_count]).to eq(0)
    end

    it "raises error if embed not found" do
      nonexistent_embed = youtube_embed.merge(path: "//iframe[@src='https://www.youtube.com/embed/nonexistent']")

      expect { service.delete_embed_from_scan(scan_progress, nonexistent_embed) }
        .to raise_error(YoutubeMigrationService::EmbedNotFoundError)
    end
  end

  describe "#find_studio_tool" do
    let(:course_studio_tool) do
      external_tool_model(
        context: sub_account,
        opts: {
          domain: "arc.instructure.com",
          url: "https://arc.instructure.com",
          consumer_key: "course_key",
          shared_secret: "course_secret",
          name: "Course Studio"
        }
      )
    end

    context "when Studio tool exists in root account" do
      it "finds Studio tool by domain" do
        result = service.find_studio_tool
        expect(result).to eq(studio_tool)
      end

      it "returns nil if Studio tool not found" do
        studio_tool.destroy

        result = service.find_studio_tool
        expect(result).to be_nil
      end

      it "does not return disabled tools" do
        studio_tool.update(workflow_state: "disabled")

        result = service.find_studio_tool
        expect(result).to be_nil
      end
    end

    context "when Studio tool exists in course account" do
      let(:sub_account) { account_model(parent_account: root_account) }
      let(:sub_course) { course_model(account: sub_account) }
      let(:sub_service) { described_class.new(sub_course) }

      before do
        # Remove root account tool to test course account tool
        studio_tool.destroy
        course_studio_tool
      end

      it "finds Studio tool in course account" do
        result = sub_service.find_studio_tool
        expect(result).to eq(course_studio_tool)
      end

      it "does not return disabled course account tools" do
        course_studio_tool.update(workflow_state: "disabled")

        result = sub_service.find_studio_tool
        expect(result).to be_nil
      end
    end

    context "when Studio tools exist in both root account and course account" do
      let(:sub_account) { account_model(parent_account: root_account) }
      let(:sub_course) { course_model(account: sub_account) }
      let(:sub_service) { described_class.new(sub_course) }

      before do
        course_studio_tool
      end

      it "prioritizes root account tool over course account tool" do
        result = sub_service.find_studio_tool
        expect(result).to eq(studio_tool)
        expect(result).not_to eq(course_studio_tool)
      end

      it "falls back to course account tool if root account tool is disabled" do
        studio_tool.update(workflow_state: "disabled")

        result = sub_service.find_studio_tool
        expect(result).to eq(course_studio_tool)
      end
    end

    context "when tools exist but have different domains" do
      before do
        studio_tool.update(domain: "other.instructure.com")
      end

      it "returns nil for tools with wrong domain" do
        result = service.find_studio_tool
        expect(result).to be_nil
      end
    end

    context "when no external tools exist" do
      before do
        studio_tool.destroy
      end

      it "returns nil when no tools exist" do
        result = service.find_studio_tool
        expect(result).to be_nil
      end
    end
  end

  describe "class methods" do
    describe ".last_youtube_embed_scan_progress_by_course" do
      it "returns the most recent scan progress" do
        Progress.create!(tag: "youtube_embed_scan", context: course, created_at: 1.day.ago)
        new_progress = Progress.create!(tag: "youtube_embed_scan", context: course, created_at: 1.hour.ago)

        result = described_class.last_youtube_embed_scan_progress_by_course(course)
        expect(result).to eq(new_progress)
      end
    end

    describe ".find_scan" do
      let(:progress) { Progress.create!(tag: "youtube_embed_scan", context: course) }

      it "finds scan by course and id" do
        result = described_class.find_scan(course, progress.id)
        expect(result).to eq(progress)
      end

      it "raises error if scan not found" do
        expect { described_class.find_scan(course, 99_999) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe ".generate_resource_key" do
      it "generates consistent resource key" do
        key = described_class.generate_resource_key("WikiPage", 123)
        expect(key).to eq("WikiPage|123")
      end
    end
  end
end
