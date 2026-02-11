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

describe Accessibility::ResourceScanController do
  let(:course) { course_model }

  before do
    allow_any_instance_of(described_class).to receive(:require_user).and_return(true)
    allow_any_instance_of(described_class).to receive(:check_authorized_action).and_return(true)

    # Create three scans with differing attributes so every sort field has
    # distinguishable values.
    accessibility_resource_scan_model(
      course:,
      context: assignment_model(course:),
      workflow_state: "queued",
      resource_name: "Queued Resource",
      resource_workflow_state: :published,
      issue_count: 1,
      resource_updated_at: 3.days.ago
    )

    accessibility_resource_scan_model(
      course:,
      context: attachment_model(course:),
      workflow_state: "in_progress",
      resource_name: "In Progress Resource",
      resource_workflow_state: :unpublished,
      issue_count: 2,
      resource_updated_at: 2.days.ago.beginning_of_day
    )

    accessibility_resource_scan_model(
      course:,
      context: wiki_page_model(course:),
      workflow_state: "completed",
      resource_name: "Completed Resource",
      resource_workflow_state: :published,
      issue_count: 3,
      resource_updated_at: 3.days.ago
    )
  end

  context "when a11y_checker feature flag disabled" do
    it "renders forbidden" do
      allow_any_instance_of(described_class).to receive(:check_authorized_action).and_call_original
      allow(course).to receive(:a11y_checker_enabled?).and_return(false)

      expect(controller).to receive(:render).with(status: :forbidden)
      controller.send(:check_authorized_action)
    end
  end

  describe "GET #index" do
    context "with discussion topics" do
      before do
        accessibility_resource_scan_model(
          course:,
          context: discussion_topic_model(context: course),
          workflow_state: "completed",
          resource_name: "Discussion Topic Resource",
          resource_workflow_state: :published,
          issue_count: 1,
          resource_updated_at: 1.day.ago
        )
      end

      it "includes discussion topic scans" do
        get :index, params: { course_id: course.id }, format: :json
        expect(response).to have_http_status(:ok)

        json = response.parsed_body
        resource_types = json.pluck("resource_type")
        expect(resource_types).to include("DiscussionTopic")
      end

      it "sorts discussion topics by resource_type" do
        get :index, params: { course_id: course.id, sort: "resource_type", direction: "asc" }, format: :json
        expect(response).to have_http_status(:ok)

        json = response.parsed_body
        discussion_scan = json.find { |scan| scan["resource_type"] == "DiscussionTopic" }
        expect(discussion_scan).to be_present
      end
    end

    context "with syllabus" do
      before do
        accessibility_resource_scan_model(
          course:,
          is_syllabus: true,
          workflow_state: "completed",
          resource_name: "Course Syllabus",
          resource_workflow_state: :published,
          issue_count: 2,
          resource_updated_at: 2.days.ago
        )
      end

      it "includes syllabus scans" do
        get :index, params: { course_id: course.id }, format: :json
        expect(response).to have_http_status(:ok)

        json = response.parsed_body
        syllabus_scan = json.find { |scan| scan["resource_type"] == "Syllabus" }
        expect(syllabus_scan).to be_present
        expect(syllabus_scan["resource_name"]).to eq("Course Syllabus")
      end

      it "sorts syllabus by resource_type" do
        get :index, params: { course_id: course.id, sort: "resource_type", direction: "asc" }, format: :json
        expect(response).to have_http_status(:ok)

        json = response.parsed_body
        # Syllabus should come after 's' but before 'w' (wiki_page)
        resource_types = json.pluck("resource_type")
        syllabus_index = resource_types.index("Syllabus")
        expect(syllabus_index).not_to be_nil
      end
    end

    %w[resource_name resource_type resource_workflow_state resource_updated_at issue_count].each do |sort_param|
      it "sorts by #{sort_param} ascending and descending" do
        # Ascending order
        get :index, params: { course_id: course.id, sort: sort_param, direction: "asc" }, format: :json
        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.length).to eq(3)

        asc_values = json.pluck(sort_param)

        # Descending order
        get :index, params: { course_id: course.id, sort: sort_param, direction: "desc" }, format: :json
        expect(response).to have_http_status(:ok)
        desc_json = response.parsed_body
        expect(desc_json.length).to eq(3)

        desc_values = desc_json.pluck(sort_param)

        expect(desc_values).to eq(asc_values.reverse)
      end
    end

    context "when sorting by issue_count with closed issues as tie-breaker" do
      let(:wiki_page1) { wiki_page_model(course:) }
      let(:wiki_page2) { wiki_page_model(course:) }
      let(:wiki_page3) { wiki_page_model(course:) }

      let!(:scan1) do
        accessibility_resource_scan_model(
          course:,
          context: wiki_page1,
          workflow_state: "completed",
          resource_name: "Scan with 5 active, 10 closed",
          issue_count: 5
        )
      end

      let!(:scan2) do
        accessibility_resource_scan_model(
          course:,
          context: wiki_page2,
          workflow_state: "completed",
          resource_name: "Scan with 5 active, 3 closed",
          issue_count: 5
        )
      end

      let!(:scan3) do
        accessibility_resource_scan_model(
          course:,
          context: wiki_page3,
          workflow_state: "completed",
          resource_name: "Scan with 2 active, 20 closed",
          issue_count: 2
        )
      end

      before do
        Account.site_admin.enable_feature!(:a11y_checker_close_issues)
        Account.site_admin.enable_feature!(:a11y_checker_ga2_features)

        10.times do
          accessibility_issue_model(
            course:,
            accessibility_resource_scan: scan1,
            rule_type: Accessibility::Rules::HeadingsStartAtH2Rule.id,
            workflow_state: "closed"
          )
        end

        # Create 3 closed issues for scan2
        3.times do
          accessibility_issue_model(
            course:,
            accessibility_resource_scan: scan2,
            rule_type: Accessibility::Rules::HeadingsStartAtH2Rule.id,
            workflow_state: "closed"
          )
        end

        # Create 20 closed issues for scan3
        20.times do
          accessibility_issue_model(
            course:,
            accessibility_resource_scan: scan3,
            rule_type: Accessibility::Rules::HeadingsStartAtH2Rule.id,
            workflow_state: "closed"
          )
        end
      end

      it "sorts by issue_count DESC, then closed_issue_count DESC when feature flag enabled" do
        get :index, params: { course_id: course.id, sort: "issue_count", direction: "desc" }, format: :json
        expect(response).to have_http_status(:ok)

        json = response.parsed_body
        # Filter to just our test scans
        test_scans = json.select { |s| [scan1.id, scan2.id, scan3.id].include?(s["id"]) }

        # Expected order:
        # 1. scan1 (5 active, 10 closed)
        # 2. scan2 (5 active, 3 closed) - same active count as scan1, but fewer closed
        # 3. scan3 (2 active, 20 closed) - fewer active issues
        expect(test_scans[0]["id"]).to eq(scan1.id)
        expect(test_scans[1]["id"]).to eq(scan2.id)
        expect(test_scans[2]["id"]).to eq(scan3.id)
      end

      it "sorts by issue_count ASC, then closed_issue_count ASC when feature flag enabled" do
        get :index, params: { course_id: course.id, sort: "issue_count", direction: "asc" }, format: :json
        expect(response).to have_http_status(:ok)

        json = response.parsed_body
        # Filter to just our test scans
        test_scans = json.select { |s| [scan1.id, scan2.id, scan3.id].include?(s["id"]) }

        # Expected order (ascending):
        # 1. scan3 (2 active, 20 closed)
        # 2. scan2 (5 active, 3 closed) - more active than scan3, fewer closed than scan1
        # 3. scan1 (5 active, 10 closed) - same active count as scan2, but more closed
        expect(test_scans[0]["id"]).to eq(scan3.id)
        expect(test_scans[1]["id"]).to eq(scan2.id)
        expect(test_scans[2]["id"]).to eq(scan1.id)
      end

      it "sorts by issue_count only when feature flag disabled" do
        Account.site_admin.disable_feature!(:a11y_checker_close_issues)

        get :index, params: { course_id: course.id, sort: "issue_count", direction: "desc" }, format: :json
        expect(response).to have_http_status(:ok)

        json = response.parsed_body
        test_scans = json.select { |s| [scan1.id, scan2.id, scan3.id].include?(s["id"]) }

        # Expected order when not considering closed count:
        # scan1 and scan2 both have 5 active issues, so order between them may vary
        # scan3 has 2 active issues, so it should be last
        expect(test_scans.length).to eq(3)
        first_two_ids = [test_scans[0]["id"], test_scans[1]["id"]]
        expect(first_two_ids).to contain_exactly(scan1.id, scan2.id)
        expect(test_scans[2]["id"]).to eq(scan3.id)
      end

      it "includes closed_issue_count in response" do
        get :index, params: { course_id: course.id }, format: :json
        expect(response).to have_http_status(:ok)

        json = response.parsed_body
        scan1_json = json.find { |s| s["id"] == scan1.id }
        scan2_json = json.find { |s| s["id"] == scan2.id }
        scan3_json = json.find { |s| s["id"] == scan3.id }

        expect(scan1_json["closed_issue_count"]).to eq(10)
        expect(scan2_json["closed_issue_count"]).to eq(3)
        expect(scan3_json["closed_issue_count"]).to eq(20)
      end
    end

    it "only includes issue_count and issues for completed scans" do
      get :index, params: { course_id: course.id }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body

      queued_json = json.find { |scan| scan["resource_name"] == "Queued Resource" }
      expect(queued_json).not_to have_key("issue_count")
      expect(queued_json).not_to have_key("issues")

      in_progress_json = json.find { |scan| scan["resource_name"] == "In Progress Resource" }
      expect(in_progress_json).not_to have_key("issue_count")
      expect(in_progress_json).not_to have_key("issues")

      completed_json = json.find { |scan| scan["resource_name"] == "Completed Resource" }
      expect(completed_json["issue_count"]).to eq(3)
      expect(completed_json).to have_key("issues")
    end

    context "with issues" do
      let(:wiki_page) do
        wiki_page_model(course:)
      end
      let(:scan_with_issues) do
        accessibility_resource_scan_model(
          course:,
          context: wiki_page,
          workflow_state: "completed",
          resource_updated_at: "2025-07-19T02:18:00Z",
          resource_name: "Tutorial",
          resource_workflow_state: "published",
          issue_count: 1
        )
      end
      let!(:issue) do
        accessibility_issue_model(
          course:,
          accessibility_resource_scan: scan_with_issues,
          rule_type: Accessibility::Rules::HeadingsStartAtH2Rule.id,
          node_path: "./div/h1",
          metadata: {
            element: "h1",
            form: {
              type: "radio_input_group"
            },
          }
        )
      end

      it "sets the issue attributes" do
        get :index, params: { course_id: course.id }, format: :json
        expect(response).to have_http_status(:ok)

        json = response.parsed_body
        scan_with_issues_json = json.find { |scan| scan["id"] == scan_with_issues.id }

        expected_json = {
          "id" => scan_with_issues.id,
          "course_id" => course.id,
          "resource_id" => scan_with_issues.wiki_page_id,
          "resource_type" => "WikiPage",
          "resource_name" => "Tutorial",
          "resource_workflow_state" => "published",
          "resource_updated_at" => "2025-07-19T02:18:00Z",
          "resource_url" => "/courses/#{course.id}/pages/#{wiki_page.id}",
          "workflow_state" => "completed",
          "error_message" => "",
          "closed_at" => nil,
          "closed_issue_count" => 0,
          "issue_count" => 1,
          "issues" => [
            {
              "id" => issue.id,
              "rule_id" => "headings-start-at-h2",
              "element" => "h1",
              "display_name" => "Heading levels should start at level 2",
              "message" => "This text is styled as a Heading 1, but there should only be one H1 on a web page — the page title. Use Heading 2 or lower (H2, H3, etc.) for your content headings instead.",
              "why" => ["Sighted users scan web pages quickly by looking for large or bolded headings. Similarly, screen reader users rely on properly structured headings to scan the content and jump directly to key sections. Using correct heading levels in a logical order (like H2, H3, etc.) ensures your course is clear, organized, and accessible to everyone.", "Each page on Canvas already has a main title (H1), so your content should start with an H2 to keep the structure clear."],
              "path" => "./div/h1",
              "issue_url" => "https://www.w3.org/TR/WCAG20-TECHS/G141.html",
              "form" => { "type" => "radio_input_group" }
            }
          ]
        }

        expect(scan_with_issues_json).to eq(expected_json)
      end

      context "with resolved or dismissed issues" do
        let!(:resolved_issue) do
          accessibility_issue_model(
            course:,
            context: wiki_page,
            accessibility_resource_scan: scan_with_issues,
            rule_type: Accessibility::Rules::HeadingsStartAtH2Rule.id,
            workflow_state: "resolved"
          )
        end
        let!(:dismissed_issue) do
          accessibility_issue_model(
            course:,
            context: wiki_page,
            accessibility_resource_scan: scan_with_issues,
            rule_type: Accessibility::Rules::HeadingsStartAtH2Rule.id,
            workflow_state: "dismissed"
          )
        end

        it "does not retrieve resolved or dismissed issues" do
          get :index, params: { course_id: course.id }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          scan_with_issues_json = json.find { |scan| scan["id"] == scan_with_issues.id }
          issue_ids = scan_with_issues_json["issues"].pluck("id")

          expect(issue_ids).not_to include(resolved_issue.id)
          expect(issue_ids).not_to include(dismissed_issue.id)
        end
      end

      context "with filters" do
        it "filters by rule types" do
          get :index, params: { course_id: course.id, filters: { ruleTypes: ["headings-start-at-h2"] } }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(1)
          expect(json.first["id"]).to eq(scan_with_issues.id)
        end

        it "filters by resource types" do
          get :index, params: { course_id: course.id, filters: { artifactTypes: ["assignment"] } }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(1)
          expect(json.all? { |scan| scan["resource_type"] == "Assignment" }).to be true
        end

        context "with syllabus filter" do
          before do
            accessibility_resource_scan_model(
              course:,
              is_syllabus: true,
              workflow_state: "completed",
              resource_name: "Course Syllabus",
              resource_workflow_state: :published,
              issue_count: 0
            )
          end

          it "filters by syllabus resource type" do
            get :index, params: { course_id: course.id, filters: { artifactTypes: ["syllabus"] } }, format: :json
            expect(response).to have_http_status(:ok)

            json = response.parsed_body
            expect(json.length).to eq(1)
            expect(json.first["resource_type"]).to eq("Syllabus")
          end
        end

        context "with discussion topics" do
          before do
            accessibility_resource_scan_model(
              course:,
              context: discussion_topic_model(context: course),
              workflow_state: "completed",
              resource_name: "Discussion",
              resource_workflow_state: :published,
              issue_count: 0
            )
          end

          it "filters by discussion_topic resource type" do
            get :index, params: { course_id: course.id, filters: { artifactTypes: ["discussion_topic"] } }, format: :json
            expect(response).to have_http_status(:ok)

            json = response.parsed_body
            expect(json.length).to eq(1)
            expect(json.first["resource_type"]).to eq("DiscussionTopic")
          end
        end

        it "filters by workflow states" do
          get :index, params: { course_id: course.id, filters: { workflowStates: ["published"] } }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(3)
          expect(json.all? { |scan| scan["resource_workflow_state"] == "published" }).to be true
        end

        it "filters by date range" do
          get :index, params: { course_id: course.id, filters: { fromDate: 2.days.ago.beginning_of_day, toDate: 1.day.ago } }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(1)
          expect(json.first["resource_name"]).to eq("In Progress Resource")
        end

        it "applies multiple filters together" do
          get :index, params: { course_id: course.id, filters: { artifactTypes: ["wiki_page"], workflowStates: ["published"] } }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(2)
          expect(json.first["resource_name"]).to eq("Completed Resource")
        end

        context "when combining filters with sorting" do
          let(:wiki_page1) { wiki_page_model(course:) }
          let(:wiki_page2) { wiki_page_model(course:) }
          let(:wiki_page3) { wiki_page_model(course:) }

          let!(:scan_high_count) do
            accessibility_resource_scan_model(
              course:,
              context: wiki_page1,
              workflow_state: "completed",
              resource_name: "High Issue Count Page",
              resource_workflow_state: "published",
              issue_count: 10
            )
          end

          let!(:scan_medium_count) do
            accessibility_resource_scan_model(
              course:,
              context: wiki_page2,
              workflow_state: "completed",
              resource_name: "Medium Issue Count Page",
              resource_workflow_state: "published",
              issue_count: 5
            )
          end

          let!(:scan_low_count) do
            accessibility_resource_scan_model(
              course:,
              context: wiki_page3,
              workflow_state: "completed",
              resource_name: "Low Issue Count Page",
              resource_workflow_state: "published",
              issue_count: 2
            )
          end

          before do
            3.times do
              accessibility_issue_model(
                course:,
                accessibility_resource_scan: scan_high_count,
                rule_type: "img-alt"
              )
            end

            2.times do
              accessibility_issue_model(
                course:,
                accessibility_resource_scan: scan_medium_count,
                rule_type: "img-alt"
              )
            end

            accessibility_issue_model(
              course:,
              accessibility_resource_scan: scan_low_count,
              rule_type: "img-alt"
            )

            2.times do
              accessibility_issue_model(
                course:,
                accessibility_resource_scan: scan_high_count,
                rule_type: "img-alt-filename"
              )
            end

            accessibility_issue_model(
              course:,
              accessibility_resource_scan: scan_medium_count,
              rule_type: "img-alt-filename"
            )

            accessibility_issue_model(
              course:,
              accessibility_resource_scan: scan_high_count,
              rule_type: "img-alt-length"
            )
          end

          it "filters by multiple rule types and sorts by issue_count descending" do
            get :index,
                params: {
                  course_id: course.id,
                  filters: {
                    ruleTypes: %w[img-alt img-alt-filename img-alt-length],
                    artifactTypes: %w[wiki_page]
                  },
                  sort: "issue_count",
                  direction: "desc"
                },
                format: :json

            expect(response).to have_http_status(:ok)

            json = response.parsed_body
            test_scans = json.select { |s| [scan_high_count.id, scan_medium_count.id, scan_low_count.id].include?(s["id"]) }

            expect(test_scans.length).to eq(3)

            expect(test_scans[0]["id"]).to eq(scan_high_count.id)
            expect(test_scans[1]["id"]).to eq(scan_medium_count.id)
            expect(test_scans[2]["id"]).to eq(scan_low_count.id)
          end

          it "filters by multiple rule types and sorts by issue_count ascending" do
            get :index,
                params: {
                  course_id: course.id,
                  filters: {
                    ruleTypes: %w[img-alt img-alt-filename],
                    artifactTypes: %w[wiki_page]
                  },
                  sort: "issue_count",
                  direction: "asc"
                },
                format: :json

            expect(response).to have_http_status(:ok)

            json = response.parsed_body
            test_scans = json.select { |s| [scan_high_count.id, scan_medium_count.id, scan_low_count.id].include?(s["id"]) }

            expect(test_scans.length).to eq(3)

            expect(test_scans[0]["id"]).to eq(scan_low_count.id)
            expect(test_scans[1]["id"]).to eq(scan_medium_count.id)
            expect(test_scans[2]["id"]).to eq(scan_high_count.id)
          end

          it "filters by single rule type with artifact type and sorts by resource_type" do
            get :index,
                params: {
                  course_id: course.id,
                  filters: {
                    ruleTypes: %w[img-alt],
                    artifactTypes: %w[wiki_page]
                  },
                  sort: "resource_type",
                  direction: "asc"
                },
                format: :json

            expect(response).to have_http_status(:ok)

            json = response.parsed_body
            test_scans = json.select { |s| [scan_high_count.id, scan_medium_count.id, scan_low_count.id].include?(s["id"]) }

            expect(test_scans.length).to eq(3)
            expect(test_scans.all? { |s| s["resource_type"] == "WikiPage" }).to be true
          end

          it "combines rule type filter, artifact type filter, and resource_name sort" do
            get :index,
                params: {
                  course_id: course.id,
                  filters: {
                    ruleTypes: %w[img-alt-filename],
                    artifactTypes: %w[wiki_page]
                  },
                  sort: "resource_name",
                  direction: "asc"
                },
                format: :json

            expect(response).to have_http_status(:ok)

            json = response.parsed_body
            test_scans = json.select { |s| [scan_high_count.id, scan_medium_count.id].include?(s["id"]) }

            expect(test_scans.length).to eq(2)
            expect(test_scans.pluck("resource_name")).to eq(["High Issue Count Page", "Medium Issue Count Page"])
          end
        end

        it "returns all scans if filters are empty" do
          get :index, params: { course_id: course.id, filters: {} }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(4)
        end

        it "filters by search term" do
          get :index, params: { course_id: course.id, search: "Tut" }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(1)
          expect(json.first["resource_name"]).to eq("Tutorial")
        end

        it "filters by search term case insensitively" do
          get :index, params: { course_id: course.id, search: "tutorial" }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(1)
          expect(json.first["resource_name"]).to eq("Tutorial")
        end

        it "returns no results for non-matching search term" do
          get :index, params: { course_id: course.id, search: "Nonexistent" }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json).to be_empty
        end
      end
    end
  end

  describe "GET #poll" do
    let(:queued_scan) do
      accessibility_resource_scan_model(
        course:,
        context: assignment_model(course:),
        workflow_state: "queued",
        resource_name: "Queued Scan"
      )
    end

    let(:in_progress_scan) do
      accessibility_resource_scan_model(
        course:,
        context: wiki_page_model(course:),
        workflow_state: "in_progress",
        resource_name: "In Progress Scan"
      )
    end

    let(:completed_scan) do
      accessibility_resource_scan_model(
        course:,
        context: wiki_page_model(course:),
        workflow_state: "completed",
        resource_name: "Completed Scan",
        issue_count: 2
      )
    end

    let(:failed_scan) do
      accessibility_resource_scan_model(
        course:,
        context: attachment_model(course:),
        workflow_state: "failed",
        resource_name: "Failed Scan",
        error_message: "Scan failed"
      )
    end

    it "returns empty array when no scan_ids provided" do
      get :poll, params: { course_id: course.id }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["scans"]).to eq([])
    end

    it "returns empty array when scan_ids is empty string" do
      get :poll, params: { course_id: course.id, scan_ids: "" }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["scans"]).to eq([])
    end

    it "returns requested scans by scan_ids" do
      scan1_id = queued_scan.id
      scan2_id = in_progress_scan.id

      get :poll, params: { course_id: course.id, scan_ids: "#{scan1_id},#{scan2_id}" }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["scans"].length).to eq(2)

      scan_ids = json["scans"].pluck("id")
      expect(scan_ids).to contain_exactly(scan1_id, scan2_id)
    end

    it "only includes scans from the specified course" do
      other_course = course_model
      other_scan = accessibility_resource_scan_model(
        course: other_course,
        context: assignment_model(course: other_course),
        workflow_state: "queued"
      )

      scan_id = queued_scan.id

      get :poll, params: { course_id: course.id, scan_ids: "#{scan_id},#{other_scan.id}" }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["scans"].length).to eq(1)
      expect(json["scans"][0]["id"]).to eq(scan_id)
    end

    it "does not include issue_count and issues for queued scans" do
      scan_id = queued_scan.id

      get :poll, params: { course_id: course.id, scan_ids: scan_id.to_s }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      scan_json = json["scans"][0]

      expect(scan_json).not_to have_key("issue_count")
      expect(scan_json).not_to have_key("issues")
    end

    it "does not include issue_count and issues for in_progress scans" do
      scan_id = in_progress_scan.id

      get :poll, params: { course_id: course.id, scan_ids: scan_id.to_s }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      scan_json = json["scans"][0]

      expect(scan_json).not_to have_key("issue_count")
      expect(scan_json).not_to have_key("issues")
    end

    it "includes issue_count and issues for completed scans" do
      scan_id = completed_scan.id
      accessibility_issue_model(
        course:,
        accessibility_resource_scan: completed_scan,
        rule_type: Accessibility::Rules::HeadingsStartAtH2Rule.id
      )

      get :poll, params: { course_id: course.id, scan_ids: scan_id.to_s }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      scan_json = json["scans"][0]

      expect(scan_json["issue_count"]).to eq(2)
      expect(scan_json).to have_key("issues")
      expect(scan_json["issues"]).to be_an(Array)
    end

    it "does not include issue_count and issues for failed scans" do
      scan_id = failed_scan.id

      get :poll, params: { course_id: course.id, scan_ids: scan_id.to_s }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      scan_json = json["scans"][0]

      expect(scan_json).not_to have_key("issue_count")
      expect(scan_json).not_to have_key("issues")
      expect(scan_json["error_message"]).to eq("Scan failed")
    end

    it "handles mixed scan states correctly" do
      queued_id = queued_scan.id
      in_progress_id = in_progress_scan.id
      completed_id = completed_scan.id
      failed_id = failed_scan.id

      scan_ids = "#{queued_id},#{in_progress_id},#{completed_id},#{failed_id}"

      get :poll, params: { course_id: course.id, scan_ids: }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["scans"].length).to eq(4)

      queued_json = json["scans"].find { |s| s["id"] == queued_id }
      expect(queued_json).not_to have_key("issue_count")

      in_progress_json = json["scans"].find { |s| s["id"] == in_progress_id }
      expect(in_progress_json).not_to have_key("issue_count")

      completed_json = json["scans"].find { |s| s["id"] == completed_id }
      expect(completed_json["issue_count"]).to eq(2)
      expect(completed_json).to have_key("issues")

      failed_json = json["scans"].find { |s| s["id"] == failed_id }
      expect(failed_json).not_to have_key("issue_count")
      expect(failed_json).not_to have_key("issues")
      expect(failed_json["error_message"]).to eq("Scan failed")
    end

    it "returns correct JSON structure for each scan" do
      scan_id = completed_scan.id

      get :poll, params: { course_id: course.id, scan_ids: scan_id.to_s }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      scan_json = json["scans"][0]

      expect(scan_json).to have_key("id")
      expect(scan_json).to have_key("resource_id")
      expect(scan_json).to have_key("resource_type")
      expect(scan_json).to have_key("resource_name")
      expect(scan_json).to have_key("resource_workflow_state")
      expect(scan_json).to have_key("resource_updated_at")
      expect(scan_json).to have_key("resource_url")
      expect(scan_json).to have_key("workflow_state")
      expect(scan_json).to have_key("error_message")
    end

    it "handles non-existent scan IDs gracefully" do
      non_existent_id = 999_999

      get :poll, params: { course_id: course.id, scan_ids: non_existent_id.to_s }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["scans"]).to be_empty
    end

    it "accepts up to the maximum number of scan IDs" do
      # Create 10 scans (the default limit)
      scans = (1..10).map do |_i|
        accessibility_resource_scan_model(
          course:,
          context: assignment_model(course:),
          workflow_state: "queued"
        )
      end

      scan_ids = scans.map(&:id).join(",")

      get :poll, params: { course_id: course.id, scan_ids: }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["scans"].length).to eq(10)
    end

    it "rejects more than the maximum number of scan IDs" do
      # Create 11 scans (exceeds the default limit of 10)
      scans = (1..11).map do |_i|
        accessibility_resource_scan_model(
          course:,
          context: assignment_model(course:),
          workflow_state: "queued"
        )
      end

      scan_ids = scans.map(&:id).join(",")

      get :poll, params: { course_id: course.id, scan_ids: }, format: :json
      expect(response).to have_http_status(:bad_request)

      json = response.parsed_body
      expect(json["error"]).to include("Too many scan IDs")
      expect(json["error"]).to include("Maximum allowed: 10")
    end

    it "respects custom limit from settings" do
      Setting.set("accessibility_resource_scan_poll_max_ids", "5")

      # Create 6 scans (exceeds the custom limit of 5)
      scans = (1..6).map do |_i|
        accessibility_resource_scan_model(
          course:,
          context: assignment_model(course:),
          workflow_state: "queued"
        )
      end

      scan_ids = scans.map(&:id).join(",")

      get :poll, params: { course_id: course.id, scan_ids: }, format: :json
      expect(response).to have_http_status(:bad_request)

      json = response.parsed_body
      expect(json["error"]).to include("Maximum allowed: 5")

      # Clean up setting
      Setting.remove("accessibility_resource_scan_poll_max_ids")
    end
  end

  describe "PATCH #close_issues" do
    let(:user) { user_model }
    let(:wiki_page) { wiki_page_model(course:) }
    let(:scan) do
      accessibility_resource_scan_model(
        course:,
        context: wiki_page,
        workflow_state: "completed"
      )
    end

    before do
      allow_any_instance_of(described_class).to receive(:require_user) do
        controller.instance_variable_set(:@current_user, user)
        true
      end
      allow_any_instance_of(described_class).to receive(:check_authorized_action) do
        controller.instance_variable_set(:@context, course)
        true
      end
      allow_any_instance_of(described_class).to receive(:check_close_issues_feature_flag).and_return(true)
    end

    context "when a11y_checker_close_issues feature flag disabled" do
      it "renders forbidden" do
        expect(Accessibility::BulkCloseIssuesService).not_to receive(:call)

        allow_any_instance_of(described_class).to receive(:check_close_issues_feature_flag).and_call_original
        # allow(course).to receive(:a11y_checker_enabled?).and_return(false)

        patch :close_issues, params: { course_id: course.id, id: scan.id, close: true }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "returns 200 and calls service with correct params" do
      expect(Accessibility::BulkCloseIssuesService).to receive(:call).with(
        scan:,
        user_id: user.id,
        close: true
      )

      patch :close_issues, params: { course_id: course.id, id: scan.id, close: true }, format: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 when scan does not exist" do
      patch :close_issues, params: { course_id: course.id, id: 999_999, close: true }, format: :json
      expect(response).to have_http_status(:not_found)

      json = response.parsed_body
      expect(json["error"]).to eq("Scan not found")
    end

    it "returns 404 when scan belongs to different course" do
      other_course = course_model
      other_scan = accessibility_resource_scan_model(
        course: other_course,
        context: wiki_page_model(course: other_course),
        workflow_state: "completed"
      )

      patch :close_issues, params: { course_id: course.id, id: other_scan.id, close: true }, format: :json
      expect(response).to have_http_status(:not_found)

      json = response.parsed_body
      expect(json["error"]).to eq("Scan not found")
    end

    it "returns 422 when service raises exception" do
      allow(Accessibility::BulkCloseIssuesService).to receive(:call).and_raise(StandardError, "Something went wrong")

      patch :close_issues, params: { course_id: course.id, id: scan.id, close: true }, format: :json
      expect(response).to have_http_status(:unprocessable_content)

      json = response.parsed_body
      expect(json["error"]).to eq("Something went wrong")
    end

    it "returns scan attributes in response" do
      allow(Accessibility::BulkCloseIssuesService).to receive(:call)

      patch :close_issues, params: { course_id: course.id, id: scan.id, close: true }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json).to have_key("id")
      expect(json).to have_key("resource_id")
      expect(json).to have_key("workflow_state")
      expect(json).to have_key("closed_at")
    end
  end
end
