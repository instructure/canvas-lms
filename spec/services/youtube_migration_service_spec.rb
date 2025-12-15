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

  describe "#queue_scan_course_for_embeds" do
    it "creates a new progress when none exists" do
      expect { described_class.queue_scan_course_for_embeds(course) }
        .to change { Progress.count }.by(1)

      progress = Progress.last
      expect(progress.tag).to eq("youtube_embed_scan")
      expect(progress.context).to eq(course)
    end

    it "uses n_strand for job processing" do
      expect_any_instance_of(Progress).to receive(:process_job) do |_progress, klass, method, opts|
        expect(klass).to eq(described_class)
        expect(method).to eq(:scan)
        expect(opts[:n_strand]).to eq("youtube_embed_scan_#{course.global_id}")
      end

      described_class.queue_scan_course_for_embeds(course)
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

    describe "when new_quizzes_scanning_youtube_links feature flag is enabled" do
      before do
        allow(Account.site_admin).to receive(:feature_enabled?).and_return(false)
        allow(Account.site_admin).to receive(:feature_enabled?).with(:new_quizzes_scanning_youtube_links).and_return(true)
        allow(Course).to receive(:find).with(course.id).and_return(course)
      end

      describe "if there are no new quizzes" do
        before do
          assignment_relation = double("assignment_relation")
          active_relation = double("active_relation")
          quiz_relation = double("quiz_relation")
          except_relation = double("except_relation")

          allow(course).to receive(:assignments).and_return(assignment_relation)
          allow(assignment_relation).to receive(:active).and_return(active_relation)
          allow(active_relation).to receive_messages(
            type_quiz_lti: quiz_relation,
            except: except_relation
          )
          allow(quiz_relation).to receive(:any?).and_return(false)
          allow(except_relation).to receive(:find_each).and_return([])
        end

        it "does not emit a live event" do
          allow(course).to receive_messages(global_id: "course_global_id_123", id: 1)
          expect(Canvas::LiveEvents).not_to receive(:scan_youtube_links)

          described_class.scan(progress)
        end
      end

      it "emits a live event with the right parameters" do
        assignment_relation = double("assignment_relation")
        active_relation = double("active_relation")
        quiz_relation = double("quiz_relation")
        except_relation = double("except_relation")
        last_assignment = double("last_assignment")
        external_tool_tag = double("external_tool_tag")

        allow(course).to receive(:assignments).and_return(assignment_relation)
        allow(assignment_relation).to receive(:active).and_return(active_relation)
        allow(active_relation).to receive_messages(
          type_quiz_lti: quiz_relation,
          except: except_relation
        )
        allow(quiz_relation).to receive_messages(
          any?: true,
          last: last_assignment
        )
        allow(last_assignment).to receive(:external_tool_tag).and_return(external_tool_tag)
        allow(external_tool_tag).to receive(:content_id).and_return("external_tool_123")
        allow(except_relation).to receive(:find_each).and_return([])
        allow(course).to receive_messages(global_id: "course_global_id_123", id: 1)

        expect(Canvas::LiveEvents).to receive(:scan_youtube_links) do |payload|
          expect(payload.scan_id).to eq(Progress.last.id)
          expect(payload.course_id).to eq(course.id)
          expect(payload.external_tool_id).to eq("external_tool_123")
        end

        progress.start!
        described_class.scan(progress)
      end
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

    it "transitions to waiting_for_external_tool when new_quizzes? returns true" do
      allow(described_class).to receive(:new_quizzes?).with(course).and_return(true)
      allow(described_class).to receive(:call_external_tool)
      progress.start!
      described_class.scan(progress)

      progress.reload
      expect(progress.workflow_state).to eq("waiting_for_external_tool")
      expect(progress.results).to be_present
      expect(progress.results[:completed_at]).to be_blank
    end

    it "completes immediately when new_quizzes? returns false" do
      allow(described_class).to receive(:new_quizzes?).with(course).and_return(false)
      progress.start!
      described_class.scan(progress)

      progress.reload
      expect(progress.results).to be_present
      expect(progress.results[:completed_at]).to be_present
    end
  end

  describe "#convert_embed" do
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

    it "uses n_strand for job processing" do
      expect_any_instance_of(Progress).to receive(:process_job) do |_progress, klass, method, opts, *_args|
        expect(klass).to eq(YoutubeMigrationService)
        expect(method).to eq(:perform_conversion)
        expect(opts[:n_strand]).to match(/youtube_embed_convert_/)
      end

      service.convert_embed(scan_progress.id, youtube_embed)
    end

    context "validation errors" do
      it "raises error when scan does not exist" do
        expect { service.convert_embed(999_999, youtube_embed) }
          .to raise_error(YoutubeMigrationService::EmbedNotFoundError, /Scan not found/)
      end

      it "raises error when embed does not exist in scan" do
        non_existent_embed = youtube_embed.merge(src: "https://www.youtube.com/embed/nonexistent")
        expect { service.convert_embed(scan_progress.id, non_existent_embed) }
          .to raise_error(YoutubeMigrationService::EmbedNotFoundError, /Embed not found in scan/)
      end

      it "raises error for unsupported resource type" do
        invalid_embed = youtube_embed.merge(resource_type: "UnsupportedResource")
        expect { service.convert_embed(scan_progress.id, invalid_embed) }
          .to raise_error(YoutubeMigrationService::UnsupportedResourceTypeError, /Unsupported resource type/)
      end

      it "raises error for invalid resource group key" do
        invalid_embed = youtube_embed.merge(resource_group_key: "invalid_key")
        expect { service.convert_embed(scan_progress.id, invalid_embed) }
          .to raise_error(YoutubeMigrationService::UnsupportedResourceTypeError, /Invalid resource group key/)
      end

      it "raises error when resource does not exist" do
        non_existent_embed = youtube_embed.merge(id: 999_999)
        scan_progress.update!(
          results: {
            resources: {
              "WikiPage|999_999" => {
                name: "Non-existent Page",
                embeds: [non_existent_embed],
                count: 1
              }
            },
            total_count: 1
          }
        )
        expect { service.convert_embed(scan_progress.id, non_existent_embed) }
          .to raise_error(YoutubeMigrationService::EmbedNotFoundError, /Resource not found/)
      end
    end
  end

  describe "validation methods" do
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

    describe "#validate_scan_exists!" do
      it "returns scan when it exists" do
        result = service.validate_scan_exists!(scan_progress.id)
        expect(result).to eq(scan_progress)
      end

      it "raises error when scan does not exist" do
        expect { service.validate_scan_exists!(999_999) }
          .to raise_error(YoutubeMigrationService::EmbedNotFoundError, /Scan not found/)
      end
    end

    describe "#validate_embed_exists_in_scan!" do
      it "passes when embed exists in scan" do
        expect { service.validate_embed_exists_in_scan!(scan_progress.id, youtube_embed) }
          .not_to raise_error
      end

      it "raises error when embed not in scan" do
        different_embed = youtube_embed.merge(src: "https://www.youtube.com/embed/different")
        expect { service.validate_embed_exists_in_scan!(scan_progress.id, different_embed) }
          .to raise_error(YoutubeMigrationService::EmbedNotFoundError, /Embed not found in scan/)
      end

      it "returns early when scan has no results" do
        empty_scan = Progress.create!(tag: "youtube_embed_scan", context: course, results: {})
        expect { service.validate_embed_exists_in_scan!(empty_scan.id, youtube_embed) }
          .not_to raise_error
      end
    end

    describe "#validate_supported_resource!" do
      it "passes for supported resource types" do
        YoutubeMigrationService::SUPPORTED_RESOURCES.each do |resource_type|
          expect { service.validate_supported_resource!(resource_type) }
            .not_to raise_error
        end
      end

      it "raises error for unsupported resource type" do
        expect { service.validate_supported_resource!("InvalidResource") }
          .to raise_error(YoutubeMigrationService::UnsupportedResourceTypeError, /Unsupported resource type/)
      end
    end

    describe "#validate_resource_group_key!" do
      it "passes for valid resource group key" do
        expect { service.validate_resource_group_key!("WikiPage|123") }
          .not_to raise_error
      end

      it "raises error for key without pipe separator" do
        expect { service.validate_resource_group_key!("InvalidKey") }
          .to raise_error(YoutubeMigrationService::UnsupportedResourceTypeError, /Invalid resource group key/)
      end

      it "raises error for key with empty parts" do
        expect { service.validate_resource_group_key!("|123") }
          .to raise_error(YoutubeMigrationService::UnsupportedResourceTypeError, /Invalid resource group key/)
        expect { service.validate_resource_group_key!("WikiPage|") }
          .to raise_error(YoutubeMigrationService::UnsupportedResourceTypeError, /Invalid resource group key/)
      end

      it "raises error for nil key" do
        expect { service.validate_resource_group_key!(nil) }
          .to raise_error(YoutubeMigrationService::UnsupportedResourceTypeError, /Invalid resource group key/)
      end
    end

    describe "#validate_resource_exists!" do
      it "passes when WikiPage exists" do
        expect { service.validate_resource_exists!("WikiPage", wiki_page.id) }
          .not_to raise_error
      end

      it "passes when Assignment exists" do
        assignment = assignment_model(course:)
        expect { service.validate_resource_exists!("Assignment", assignment.id) }
          .not_to raise_error
      end

      it "passes when DiscussionTopic exists" do
        topic = discussion_topic_model(context: course)
        expect { service.validate_resource_exists!("DiscussionTopic", topic.id) }
          .not_to raise_error
      end

      it "passes when Announcement exists" do
        announcement = announcement_model(context: course)
        expect { service.validate_resource_exists!("Announcement", announcement.id) }
          .not_to raise_error
      end

      it "passes when DiscussionEntry exists" do
        topic = discussion_topic_model(context: course)
        entry = topic.discussion_entries.create!(message: "Test", user: user_model)
        expect { service.validate_resource_exists!("DiscussionEntry", entry.id) }
          .not_to raise_error
      end

      it "passes when CalendarEvent exists" do
        event = course.calendar_events.create!(title: "Event", start_at: Time.zone.now)
        expect { service.validate_resource_exists!("CalendarEvent", event.id) }
          .not_to raise_error
      end

      it "passes when Quiz exists" do
        quiz = course.quizzes.create!(title: "Quiz")
        expect { service.validate_resource_exists!("Quizzes::Quiz", quiz.id) }
          .not_to raise_error
      end

      it "passes when QuizQuestion exists" do
        quiz = course.quizzes.create!(title: "Quiz")
        question = quiz.quiz_questions.create!(question_data: { question_text: "Question" })
        expect { service.validate_resource_exists!("Quizzes::QuizQuestion", question.id) }
          .not_to raise_error
      end

      it "passes when AssessmentQuestion exists" do
        bank = course.assessment_question_banks.create!(title: "Bank")
        question = bank.assessment_questions.create!(question_data: { question_text: "Question" })
        expect { service.validate_resource_exists!("AssessmentQuestion", question.id) }
          .not_to raise_error
      end

      it "passes for CourseSyllabus when course id matches" do
        expect { service.validate_resource_exists!("CourseSyllabus", course.id) }
          .not_to raise_error
      end

      it "raises error for CourseSyllabus when course id does not match" do
        expect { service.validate_resource_exists!("CourseSyllabus", 999_999) }
          .to raise_error(YoutubeMigrationService::ResourceNotFoundError, /Course not found/)
      end

      it "raises error when resource does not exist" do
        expect { service.validate_resource_exists!("WikiPage", 999_999) }
          .to raise_error(YoutubeMigrationService::ResourceNotFoundError, /Resource not found/)
      end

      it "raises error for unhandled resource type" do
        expect { service.validate_resource_exists!("UnhandledType", 123) }
          .to raise_error(YoutubeMigrationService::ResourceNotFoundError, /Cannot validate existence/)
      end

      shared_examples "passes for New Quizzes resource" do |type|
        it "returns true for #{type}" do
          expect { service.validate_resource_exists!(type, 123) }.not_to raise_error
          expect(service.validate_resource_exists!(type, 123)).to be(true)
        end
      end

      context "when resource_type is a New Quizzes resource" do
        YoutubeMigrationService::NEW_QUIZZES_RESOURCES.each do |type|
          include_examples "passes for New Quizzes resource", type
        end
      end
    end
  end

  describe "#perform_conversion" do
    before do
      studio_tool
    end

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

    it "successfully converts YouTube embed in announcement" do
      announcement = course.announcements.create!(
        title: "Test Announcement",
        message: '<p>Before</p><iframe src="https://www.youtube.com/embed/dQw4w9WgXcQ" width="560" height="315"></iframe><p>After</p>'
      )

      announcement_embed = youtube_embed.merge(
        id: announcement.id,
        resource_type: "Announcement",
        field: :message
      )

      scan_progress.results[:resources]["Announcement|#{announcement.id}"] = {
        name: announcement.title,
        embeds: [announcement_embed],
        count: 1
      }
      scan_progress.results[:total_count] += 1
      scan_progress.save!

      described_class.perform_conversion(convert_progress, course.id, scan_progress.id, announcement_embed)

      convert_progress.reload
      expect(convert_progress.results).to be_present
      expect(convert_progress.results[:success]).to be true

      announcement.reload
      expect(announcement.message).to include("lti-embed")
      expect(announcement.message).to include("Test Video Title")
      expect(announcement.message).not_to include("youtube.com")
      expect(announcement.message).to include("Before")
      expect(announcement.message).to include("After")
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

    it "finds YouTube embeds in assessment questions" do
      question_bank = assessment_question_bank_model(course:)
      assessment_question = assessment_question_model(
        bank: question_bank,
        question_data: {
          question_name: "YouTube Question",
          question_text: '<iframe src="https://www.youtube.com/embed/test123" width="560" height="315"></iframe>',
          correct_comments_html: '<iframe src="https://www.youtube.com/embed/comment456" width="560" height="315"></iframe>',
          question_type: "multiple_choice_question",
          answers: []
        }
      )

      resources = service.scan_course_for_embeds

      aq_key = "AssessmentQuestion|#{assessment_question.id}"
      expect(resources[aq_key]).to be_present
      expect(resources[aq_key][:name]).to eq("YouTube Question")
      expect(resources[aq_key][:count]).to eq(2)
      expect(resources[aq_key][:embeds].pluck(:src)).to include(
        "https://www.youtube.com/embed/test123",
        "https://www.youtube.com/embed/comment456"
      )
    end

    it "skips assessment questions with deleted question banks" do
      question_bank = assessment_question_bank_model(course:)
      assessment_question_model(
        bank: question_bank,
        question_data: {
          question_name: "Deleted Bank Question",
          question_text: '<iframe src="https://www.youtube.com/embed/deleted123" width="560" height="315"></iframe>',
          question_type: "multiple_choice_question",
          answers: []
        }
      )
      question_bank.destroy

      resources = service.scan_course_for_embeds
      expect(resources.keys).not_to include(/AssessmentQuestion/)
    end

    it "finds YouTube embeds in quiz questions" do
      quiz = quiz_model(course:, description: '<iframe src="https://www.youtube.com/embed/quizdesc" width="560" height="315"></iframe>')
      quiz.quiz_questions.create!(
        question_data: {
          question_name: "Quiz Question",
          question_text: '<iframe src="https://www.youtube.com/embed/quizq123" width="560" height="315"></iframe>',
          neutral_comments_html: '<iframe src="https://www.youtube.com/embed/neutral789" width="560" height="315"></iframe>',
          question_type: "text_only_question", # To make sure during create! there will be no assesment question creation
          answers: []
        }
      )

      resources = service.scan_course_for_embeds

      quiz_key = "Quizzes::Quiz|#{quiz.id}"
      expect(resources[quiz_key]).to be_present
      expect(resources[quiz_key][:count]).to eq(3) # 1 from description, 2 from question
      embeds_srcs = resources[quiz_key][:embeds].pluck(:src)
      expect(embeds_srcs).to include(
        "https://www.youtube.com/embed/quizdesc",
        "https://www.youtube.com/embed/quizq123",
        "https://www.youtube.com/embed/neutral789"
      )
    end

    it "skips quiz questions with assessment question association" do
      quiz = quiz_model(course:, description: "description")
      assessment_youtube_src = "https://www.youtube.com/embed/assessment123"

      question_bank = assessment_question_bank_model(course:)
      assessment_question = assessment_question_model(
        bank: question_bank,
        question_data: {
          question_name: "Assessment Question",
          question_text: "<iframe src=\"#{assessment_youtube_src}\" width=\"560\" height=\"315\"></iframe>",
          question_type: "multiple_choice_question",
          answers: []
        }
      )

      quiz.quiz_questions.create!(
        question_data: {
          question_name: "Linked Quiz Question",
          question_text: '<iframe src="https://www.youtube.com/embed/should_be_skipped" width="560" height="315"></iframe>',
          question_type: "multiple_choice_question",
          answers: []
        },
        assessment_question:
      )

      resources = service.scan_course_for_embeds

      quiz_key = "Quizzes::Quiz|#{quiz.id}"
      expect(resources[quiz_key]).to_not be_present

      aq_key = "AssessmentQuestion|#{assessment_question.id}"
      expect(resources[aq_key][:count]).to eq(1)
      aq_embeds_srcs = resources[aq_key][:embeds].pluck(:src)
      expect(aq_embeds_srcs).to include(assessment_youtube_src)
    end

    it "finds YouTube embeds in discussion entries" do
      topic = discussion_topic_model(
        context: course,
        message: '<iframe src="https://www.youtube.com/embed/topic123" width="560" height="315"></iframe>'
      )
      topic.discussion_entries.create!(
        message: '<iframe src="https://www.youtube.com/embed/entry456" width="560" height="315"></iframe>',
        user: @teacher
      )

      resources = service.scan_course_for_embeds

      topic_key = "DiscussionTopic|#{topic.id}"
      expect(resources[topic_key]).to be_present
      expect(resources[topic_key][:count]).to eq(2) # 1 from topic, 1 from entry
      embeds_srcs = resources[topic_key][:embeds].pluck(:src)
      expect(embeds_srcs).to include(
        "https://www.youtube.com/embed/topic123",
        "https://www.youtube.com/embed/entry456"
      )
    end

    it "finds YouTube embeds in announcements" do
      announcement = course.announcements.create!(
        title: "Important Announcement",
        message: '<p>Check out this video:</p><iframe src="https://www.youtube.com/embed/announcement123" width="560" height="315"></iframe><p>End of message</p>'
      )

      resources = service.scan_course_for_embeds

      announcement_key = "Announcement|#{announcement.id}"
      expect(resources[announcement_key]).to be_present
      expect(resources[announcement_key][:name]).to eq("Important Announcement")
      expect(resources[announcement_key][:count]).to eq(1)
      expect(resources[announcement_key][:embeds].first[:src]).to include("announcement123")
      expect(resources[announcement_key][:embeds].first[:resource_type]).to eq("Announcement")
      expect(resources[announcement_key][:embeds].first[:field]).to eq(:message)
    end

    it "finds YouTube embeds in announcements with discussion entries" do
      announcement = course.announcements.create!(
        title: "Announcement with Video",
        message: '<iframe src="https://www.youtube.com/embed/main_video" width="560" height="315"></iframe>'
      )
      announcement.discussion_entries.create!(
        message: '<iframe src="https://www.youtube.com/embed/reply_video" width="560" height="315"></iframe>',
        user: @teacher
      )

      resources = service.scan_course_for_embeds

      announcement_key = "Announcement|#{announcement.id}"
      expect(resources[announcement_key]).to be_present
      expect(resources[announcement_key][:count]).to eq(2) # 1 from announcement, 1 from entry
      embeds_srcs = resources[announcement_key][:embeds].pluck(:src)
      expect(embeds_srcs).to include(
        "https://www.youtube.com/embed/main_video",
        "https://www.youtube.com/embed/reply_video"
      )
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

    context "with AssessmentQuestion" do
      let(:question_bank) { assessment_question_bank_model(course:) }
      let(:assessment_question) do
        assessment_question_model(
          bank: question_bank,
          question_data: {
            question_name: "Test Question",
            question_text: original_html,
            correct_comments_html: original_html,
            question_type: "multiple_choice_question",
            answers: []
          }
        )
      end
      let(:embed) { youtube_embed.merge(id: assessment_question.id, resource_type: "AssessmentQuestion", field: :question_text) }

      it "updates the question_text field" do
        service.update_resource_content(embed, new_html)

        assessment_question.reload
        expect(assessment_question.question_data[:question_text]).to include("lti-embed")
        expect(assessment_question.question_data[:question_text]).not_to include("youtube.com")
        expect(assessment_question.question_data[:question_text]).to include("Before")
        expect(assessment_question.question_data[:question_text]).to include("After")
      end

      it "updates the correct_comments_html field" do
        embed_comments = embed.merge(field: :correct_comments_html)
        service.update_resource_content(embed_comments, new_html)

        assessment_question.reload
        expect(assessment_question.question_data[:correct_comments_html]).to include("lti-embed")
        expect(assessment_question.question_data[:correct_comments_html]).not_to include("youtube.com")
      end

      it "preserves other question data fields" do
        original_name = assessment_question.question_data[:question_name]
        service.update_resource_content(embed, new_html)

        assessment_question.reload
        expect(assessment_question.question_data[:question_name]).to eq(original_name)
        expect(assessment_question.question_data[:question_type]).to eq("multiple_choice_question")
      end
    end

    context "with Quizzes::QuizQuestion" do
      let(:quiz) { quiz_model(course:) }
      let(:quiz_question) do
        quiz.quiz_questions.create!(
          question_data: {
            question_name: "Quiz Question",
            question_text: original_html,
            incorrect_comments_html: original_html,
            question_type: "multiple_choice_question",
            answers: []
          }
        )
      end
      let(:embed) { youtube_embed.merge(id: quiz_question.id, resource_type: "Quizzes::QuizQuestion", field: :question_text) }

      it "updates the question_text field" do
        service.update_resource_content(embed, new_html)

        quiz_question.reload
        expect(quiz_question.question_data[:question_text]).to include("lti-embed")
        expect(quiz_question.question_data[:question_text]).not_to include("youtube.com")
        expect(quiz_question.question_data[:question_text]).to include("Before")
        expect(quiz_question.question_data[:question_text]).to include("After")
      end

      it "updates the incorrect_comments_html field" do
        embed_comments = embed.merge(field: :incorrect_comments_html)
        service.update_resource_content(embed_comments, new_html)

        quiz_question.reload
        expect(quiz_question.question_data[:incorrect_comments_html]).to include("lti-embed")
        expect(quiz_question.question_data[:incorrect_comments_html]).not_to include("youtube.com")
      end

      it "preserves other question data fields" do
        original_name = quiz_question.question_data[:question_name]
        service.update_resource_content(embed, new_html)

        quiz_question.reload
        expect(quiz_question.question_data[:question_name]).to eq(original_name)
        expect(quiz_question.question_data[:question_type]).to eq("multiple_choice_question")
      end
    end

    context "with Quizzes::Quiz" do
      let(:quiz) { quiz_model(course:, description: original_html) }
      let(:embed) { youtube_embed.merge(id: quiz.id, resource_type: "Quizzes::Quiz", field: :description) }

      it "updates the quiz description" do
        service.update_resource_content(embed, new_html)

        quiz.reload
        expect(quiz.description).to include("lti-embed")
        expect(quiz.description).not_to include("youtube.com")
      end

      it "raises error for unsupported quiz fields" do
        embed_invalid = embed.merge(field: :title)
        expect { service.update_resource_content(embed_invalid, new_html) }
          .to raise_error(/Quiz field title not supported/)
      end
    end

    context "with DiscussionEntry" do
      let(:discussion_topic) { discussion_topic_model(context: course) }
      let(:discussion_entry) do
        discussion_topic.discussion_entries.create!(
          message: original_html,
          user: @teacher
        )
      end
      let(:embed) { youtube_embed.merge(id: discussion_entry.id, resource_type: "DiscussionEntry", field: :message) }

      it "updates the entry message" do
        service.update_resource_content(embed, new_html)

        discussion_entry.reload
        expect(discussion_entry.message).to include("lti-embed")
        expect(discussion_entry.message).not_to include("youtube.com")
        expect(discussion_entry.message).to include("Before")
        expect(discussion_entry.message).to include("After")
      end
    end

    context "with DiscussionTopic" do
      let(:discussion_topic) { discussion_topic_model(context: course, message: original_html) }
      let(:embed) { youtube_embed.merge(id: discussion_topic.id, resource_type: "DiscussionTopic", field: :message) }

      it "updates the topic message" do
        service.update_resource_content(embed, new_html)

        discussion_topic.reload
        expect(discussion_topic.message).to include("lti-embed")
        expect(discussion_topic.message).not_to include("youtube.com")
      end
    end

    context "with Announcement" do
      let(:announcement) { course.announcements.create!(title: "Test Announcement", message: original_html) }
      let(:embed) { youtube_embed.merge(id: announcement.id, resource_type: "Announcement", field: :message) }

      it "updates the announcement message" do
        service.update_resource_content(embed, new_html)

        announcement.reload
        expect(announcement.message).to include("lti-embed")
        expect(announcement.message).not_to include("youtube.com")
        expect(announcement.message).to include("Before")
        expect(announcement.message).to include("After")
      end

      it "preserves the announcement title and other properties" do
        original_title = announcement.title
        original_workflow_state = announcement.workflow_state

        service.update_resource_content(embed, new_html)

        announcement.reload
        expect(announcement.title).to eq(original_title)
        expect(announcement.workflow_state).to eq(original_workflow_state)
        expect(announcement.type).to eq("Announcement")
      end
    end

    context "with CalendarEvent" do
      let(:calendar_event) { calendar_event_model(context: course, description: original_html) }
      let(:embed) { youtube_embed.merge(id: calendar_event.id, resource_type: "CalendarEvent", field: :description) }

      it "updates the event description" do
        service.update_resource_content(embed, new_html)

        calendar_event.reload
        expect(calendar_event.description).to include("lti-embed")
        expect(calendar_event.description).not_to include("youtube.com")
      end
    end

    context "with Course syllabus" do
      before { course.update!(syllabus_body: original_html) }

      let(:embed) { youtube_embed.merge(id: course.id, resource_type: "Course", field: :syllabus_body) }

      it "updates the syllabus body" do
        service.update_resource_content(embed, new_html)

        course.reload
        expect(course.syllabus_body).to include("lti-embed")
        expect(course.syllabus_body).not_to include("youtube.com")
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

  describe "#resource_group_key_for" do
    context "when resource_type is in NEW_QUIZZES_RESOURCES" do
      before do
        stub_const("NEW_QUIZZES_RESOURCES", ["QuizzesNext::Quiz"])
      end

      it "normalizes the type via prepare_new_quiz_resource_type and generates a key (embed hash form)" do
        embed = { resource_type: "QuizzesNext::Quiz", id: 42, resource_group_key: nil }

        expect(service)
          .to receive(:prepare_new_quiz_resource_type)
          .with("QuizzesNext::Quiz")
          .and_return("QuizzesNext::Quiz")

        expect(YoutubeMigrationService)
          .to receive(:generate_resource_key)
          .with("QuizzesNext::Quiz", 42)
          .and_return("QuizzesNext::Quiz|42")

        result = service.send(:resource_group_key_for, embed)
        expect(result).to eq("QuizzesNext::Quiz|42")
      end
    end

    context "when resource_type is NOT in NEW_QUIZZES_RESOURCES" do
      before do
        stub_const("NEW_QUIZZES_RESOURCES", [])
      end

      it "returns the existing resource_group_key as-is when present (including empty string)" do
        embed = { resource_type: "Assignment", id: 7, resource_group_key: "" }

        expect(YoutubeMigrationService).not_to receive(:generate_resource_key)

        result = service.send(:resource_group_key_for, embed)
        expect(result).to eq("")
      end

      it "falls back to generate_resource_key when resource_group_key is nil" do
        embed = { resource_type: "Assignment", id: 7, resource_group_key: nil }

        expect(YoutubeMigrationService)
          .to receive(:generate_resource_key)
          .with("Assignment", 7)
          .and_return("Assignment|7")

        result = service.send(:resource_group_key_for, embed)
        expect(result).to eq("Assignment|7")
      end
    end
  end

  describe "#mark_embed_as_converted" do
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

    it "marks the embed as converted in scan results" do
      service.mark_embed_as_converted(scan_progress, youtube_embed)

      scan_progress.reload
      resource = scan_progress.results[:resources]["WikiPage|#{wiki_page.id}"]

      expect(resource[:count]).to eq(2)
      expect(resource[:embeds].length).to eq(2)
      expect(resource[:converted_count]).to eq(1)

      # Find the converted embed
      converted_embed = resource[:embeds].find { |e| e[:src] == youtube_embed[:src] }
      expect(converted_embed[:converted]).to be true
      expect(converted_embed[:converted_at]).not_to be_nil

      # Other embed remains unchanged
      other_embed = resource[:embeds].find { |e| e[:src] == "https://www.youtube.com/embed/other" }
      expect(other_embed[:converted]).to be_nil

      expect(scan_progress.results[:total_converted]).to eq(1)
    end

    it "marks all embeds as converted and keeps resource" do
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

      service.mark_embed_as_converted(scan_progress, youtube_embed)

      scan_progress.reload
      resource = scan_progress.results[:resources]["WikiPage|#{wiki_page.id}"]

      expect(resource).not_to be_nil
      expect(resource[:count]).to eq(1)
      expect(resource[:converted_count]).to eq(1)
      expect(resource[:embeds].first[:converted]).to be true
      expect(scan_progress.results[:total_converted]).to eq(1)
    end

    it "decreases total count when embed is converted" do
      initial_total_count = scan_progress.results[:total_count]

      service.mark_embed_as_converted(scan_progress, youtube_embed)

      scan_progress.reload
      expect(scan_progress.results[:total_count]).to eq(initial_total_count - 1)
    end

    it "does not decrease total count when embed is already converted" do
      service.mark_embed_as_converted(scan_progress, youtube_embed)
      scan_progress.reload
      first_count = scan_progress.results[:total_count]
      service.mark_embed_as_converted(scan_progress, youtube_embed)
      scan_progress.reload

      expect(scan_progress.results[:total_count]).to eq(first_count)
    end

    it "raises error if embed not found" do
      nonexistent_embed = youtube_embed.merge(path: "//iframe[@src='https://www.youtube.com/embed/nonexistent']")

      expect { service.mark_embed_as_converted(scan_progress, nonexistent_embed) }
        .to raise_error(YoutubeMigrationService::EmbedNotFoundError)
    end
  end

  describe "#convert_all_embeds" do
    let(:scan_progress) do
      Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed",
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [youtube_embed, { src: "https://www.youtube.com/embed/other123", id: wiki_page.id, resource_type: "WikiPage", field: :body, path: "//iframe[@src='https://www.youtube.com/embed/other123']", width: nil, height: nil }],
              count: 2
            }
          },
          total_count: 2
        }
      )
    end

    it "creates a bulk conversion progress and queues background job" do
      service.convert_all_embeds(scan_progress.id)

      bulk_progress = Progress.where(tag: "youtube_embed_bulk_convert", context: course).last
      expect(bulk_progress).to be_present
      expect(bulk_progress.context).to eq(course)
      expect(bulk_progress.message).to eq("Converting 2 YouTube embeds")

      results = bulk_progress.results.with_indifferent_access
      expect(results["scan_progress_id"]).to eq(scan_progress.id)
      expect(results["total_embeds"]).to eq(2)
      expect(results["completed_embeds"]).to eq(0)
      expect(results["failed_embeds"]).to eq(0)
      expect(results["errors"]).to eq([])
    end

    it "handles scan progress with no embeds" do
      scan_progress.update!(results: { total_count: 0, resources: {} })

      result = service.convert_all_embeds(scan_progress.id)

      expect(result).to be_nil
      bulk_progress = Progress.where(tag: "youtube_embed_bulk_convert", context: course).last
      expect(bulk_progress).to be_nil
    end
  end

  describe "#convert_selected_embeds" do
    let(:embed1) do
      {
        src: "https://www.youtube.com/embed/video1",
        id: wiki_page.id,
        resource_type: "WikiPage",
        field: :body,
        path: "//iframe[@src='https://www.youtube.com/embed/video1']",
        width: nil,
        height: nil
      }
    end

    let(:embed2) do
      {
        src: "https://www.youtube.com/embed/video2",
        id: wiki_page.id,
        resource_type: "WikiPage",
        field: :body,
        path: "//iframe[@src='https://www.youtube.com/embed/video2']",
        width: nil,
        height: nil
      }
    end

    it "creates a bulk conversion progress for selected embeds" do
      scan_progress = Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed",
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [embed1, embed2],
              count: 2
            }
          },
          total_count: 2
        }
      )

      embeds_list = [embed1, embed2]
      service.convert_selected_embeds(embeds_list, scan_progress.id)

      bulk_progress = Progress.where(tag: "youtube_embed_bulk_convert", context: course).last
      expect(bulk_progress).to be_present
      expect(bulk_progress.context).to eq(course)
      expect(bulk_progress.message).to eq("Converting 2 YouTube embeds")

      results = bulk_progress.results.with_indifferent_access
      expect(results["scan_progress_id"]).to eq(scan_progress.id)
      expect(results["total_embeds"]).to eq(2)
      expect(results["completed_embeds"]).to eq(0)
      expect(results["failed_embeds"]).to eq(0)
      expect(results["errors"]).to eq([])
    end
  end

  describe "#perform_all_conversions" do
    before do
      studio_tool
    end

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

    let(:bulk_progress) do
      Progress.create!(
        tag: "youtube_embed_bulk_convert",
        context: course,
        results: {
          scan_progress_id: scan_progress.id,
          total_embeds: 1,
          completed_embeds: 0,
          failed_embeds: 0,
          errors: []
        }
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

    it "successfully converts all YouTube embeds to Studio embeds" do
      described_class.perform_all_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload
      expect(bulk_progress.results[:success]).to be true
      expect(bulk_progress.results[:completed_embeds]).to eq(1)
      expect(bulk_progress.results[:failed_embeds]).to eq(0)
      expect(bulk_progress.results[:errors]).to be_empty
      expect(bulk_progress.results[:progress_percentage]).to eq(100.0)

      wiki_page.reload
      expect(wiki_page.body).to include("lti-embed")
      expect(wiki_page.body).to include("Test Video Title")
      expect(wiki_page.body).not_to include("youtube.com")
    end

    it "handles Studio API errors gracefully and continues processing" do
      failing_page = wiki_page_model(
        course:,
        title: "Failing Page",
        body: '<iframe src="https://www.youtube.com/embed/failing" width="560" height="315"></iframe>'
      )

      scan_progress.update!(
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [youtube_embed],
              count: 1
            },
            "WikiPage|#{failing_page.id}" => {
              name: "Failing Page",
              embeds: [
                { src: "https://www.youtube.com/embed/failing", id: failing_page.id, resource_type: "WikiPage", field: :body, path: "//iframe[@src='https://www.youtube.com/embed/failing']", width: nil, height: nil }
              ],
              count: 1
            }
          },
          total_count: 2
        }
      )
      bulk_progress.update!(results: bulk_progress.results.merge(total_embeds: 2))

      stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
        .with(
          body: {
            url: "https://www.youtube.com/embed/failing",
            course_id: course.id,
            course_name: course.name
          }.to_json,
          headers: {
            "Authorization" => /Bearer .+/,
            "Content-Type" => "application/json"
          }
        )
        .to_return(status: 500, body: "Internal Server Error")

      expect(Canvas::Errors).to receive(:capture_exception)
        .with(:youtube_embed_bulk_convert, anything)
        .and_return(error_report: 12_345)

      described_class.perform_all_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload
      expect(bulk_progress.results[:success]).to be false
      expect(bulk_progress.results[:completed_embeds]).to eq(1)
      expect(bulk_progress.results[:failed_embeds]).to eq(1)
      expect(bulk_progress.results[:errors].length).to eq(1)
      expect(bulk_progress.results[:errors].first[:embed_src]).to eq("https://www.youtube.com/embed/failing")
      expect(bulk_progress.results[:errors].first[:error_report_id]).to eq(12_345)
      expect(bulk_progress.results[:progress_percentage]).to eq(100.0)
    end

    it "handles missing Studio tool" do
      studio_tool.destroy

      described_class.perform_all_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload
      expect(bulk_progress.results[:error]).to eq("Studio LTI tool not found for account")
      expect(bulk_progress.results[:completed_at]).to be_present
    end

    it "processes multiple resources with multiple embeds each" do
      assignment = assignment_model(course:, description: '<iframe src="https://www.youtube.com/embed/assignment123"></iframe>')
      assignment_embed = {
        src: "https://www.youtube.com/embed/assignment123",
        id: assignment.id,
        resource_type: "Assignment",
        field: :description,
        path: "//iframe[@src='https://www.youtube.com/embed/assignment123']",
        width: nil,
        height: nil
      }

      scan_progress.update!(
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [youtube_embed],
              count: 1
            },
            "Assignment|#{assignment.id}" => {
              name: "Test Assignment",
              embeds: [assignment_embed],
              count: 1
            }
          },
          total_count: 2
        }
      )
      bulk_progress.update!(results: bulk_progress.results.merge(total_embeds: 2))

      stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
        .with(body: hash_including(url: "https://www.youtube.com/embed/assignment123"))
        .to_return(
          status: 200,
          body: { "embed_url" => "https://arc.instructure.com/media/t_assignment", "title" => "Assignment Video", "id" => "media_assignment" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      described_class.perform_all_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload
      expect(bulk_progress.results[:success]).to be true
      expect(bulk_progress.results[:completed_embeds]).to eq(2)
      expect(bulk_progress.results[:failed_embeds]).to eq(0)
      expect(bulk_progress.results[:progress_percentage]).to eq(100.0)

      wiki_page.reload
      assignment.reload
      expect(wiki_page.body).to include("lti-embed")
      expect(assignment.description).to include("lti-embed")
    end

    it "handles general exceptions during bulk conversion" do
      allow_any_instance_of(described_class).to receive(:find_studio_tool)
        .and_raise(StandardError, "General error")

      expect(Canvas::Errors).to receive(:capture_exception)
        .with(:youtube_embed_bulk_convert, anything)
        .and_return(error_report: 54_321)

      described_class.perform_all_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload
      expect(bulk_progress.results[:error_report_id]).to eq(54_321)
      expect(bulk_progress.results[:completed_at]).to be_present
    end

    it "calculates progress percentage correctly" do
      page2 = wiki_page_model(course:, title: "Page 2", body: '<iframe src="https://www.youtube.com/embed/video2"></iframe>')
      page3 = wiki_page_model(course:, title: "Page 3", body: '<iframe src="https://www.youtube.com/embed/video3"></iframe>')
      page4 = wiki_page_model(course:, title: "Page 4", body: '<iframe src="https://www.youtube.com/embed/video4"></iframe>')

      scan_progress.update!(
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [youtube_embed],
              count: 1
            },
            "WikiPage|#{page2.id}" => {
              name: "Page 2",
              embeds: [{ src: "https://www.youtube.com/embed/video2", id: page2.id, resource_type: "WikiPage", field: :body, path: "//iframe[@src='https://www.youtube.com/embed/video2']", width: nil, height: nil }],
              count: 1
            },
            "WikiPage|#{page3.id}" => {
              name: "Page 3",
              embeds: [{ src: "https://www.youtube.com/embed/video3", id: page3.id, resource_type: "WikiPage", field: :body, path: "//iframe[@src='https://www.youtube.com/embed/video3']", width: nil, height: nil }],
              count: 1
            },
            "WikiPage|#{page4.id}" => {
              name: "Page 4",
              embeds: [{ src: "https://www.youtube.com/embed/video4", id: page4.id, resource_type: "WikiPage", field: :body, path: "//iframe[@src='https://www.youtube.com/embed/video4']", width: nil, height: nil }],
              count: 1
            }
          },
          total_count: 4
        }
      )
      bulk_progress.update!(results: bulk_progress.results.merge(total_embeds: 4))

      %w[video2 video3 video4].each do |video_id|
        stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
          .with(
            body: hash_including(url: "https://www.youtube.com/embed/#{video_id}"),
            headers: {
              "Authorization" => /Bearer .+/,
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: { "embed_url" => "https://arc.instructure.com/media/t_#{video_id}", "title" => "Video #{video_id}", "id" => "media_#{video_id}" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      described_class.perform_all_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload
      expect(bulk_progress.results[:progress_percentage]).to eq(100.0)
      expect(bulk_progress.results[:completed_embeds]).to eq(4)
      expect(bulk_progress.results[:failed_embeds]).to eq(0)
      expect(bulk_progress.results[:success]).to be true
    end

    it "demonstrates successful, failed, successful conversion sequence with error reporting" do
      page1 = wiki_page_model(course:, title: "Success Page 1", body: '<iframe src="https://www.youtube.com/embed/success1" width="560" height="315"></iframe>')
      page2 = wiki_page_model(course:, title: "Failing Page", body: '<iframe src="https://www.youtube.com/embed/failing" width="560" height="315"></iframe>')
      page3 = wiki_page_model(course:, title: "Success Page 2", body: '<iframe src="https://www.youtube.com/embed/success2" width="560" height="315"></iframe>')

      success1_embed = {
        src: "https://www.youtube.com/embed/success1",
        id: page1.id,
        resource_type: "WikiPage",
        field: :body,
        path: "//iframe[@src='https://www.youtube.com/embed/success1']",
        width: nil,
        height: nil
      }

      failing_embed = {
        src: "https://www.youtube.com/embed/failing",
        id: page2.id,
        resource_type: "WikiPage",
        field: :body,
        path: "//iframe[@src='https://www.youtube.com/embed/failing']",
        width: nil,
        height: nil
      }

      success2_embed = {
        src: "https://www.youtube.com/embed/success2",
        id: page3.id,
        resource_type: "WikiPage",
        field: :body,
        path: "//iframe[@src='https://www.youtube.com/embed/success2']",
        width: nil,
        height: nil
      }

      scan_progress.update!(
        results: {
          resources: {
            "WikiPage|#{page1.id}" => {
              name: "Success Page 1",
              embeds: [success1_embed],
              count: 1
            },
            "WikiPage|#{page2.id}" => {
              name: "Failing Page",
              embeds: [failing_embed],
              count: 1
            },
            "WikiPage|#{page3.id}" => {
              name: "Success Page 2",
              embeds: [success2_embed],
              count: 1
            }
          },
          total_count: 3
        }
      )
      bulk_progress.update!(results: bulk_progress.results.merge(total_embeds: 3))

      stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
        .with(
          body: {
            url: "https://www.youtube.com/embed/success1",
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
          body: { "embed_url" => "https://arc.instructure.com/media/t_success1", "title" => "Success Video 1", "id" => "media_success1" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
        .with(
          body: {
            url: "https://www.youtube.com/embed/failing",
            course_id: course.id,
            course_name: course.name
          }.to_json,
          headers: {
            "Authorization" => /Bearer .+/,
            "Content-Type" => "application/json"
          }
        )
        .to_return(status: 500, body: "Internal Server Error")

      stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
        .with(
          body: {
            url: "https://www.youtube.com/embed/success2",
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
          body: { "embed_url" => "https://arc.instructure.com/media/t_success2", "title" => "Success Video 2", "id" => "media_success2" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect(Canvas::Errors).to receive(:capture_exception)
        .with(:youtube_embed_bulk_convert, anything)
        .and_return(error_report: 99_999)

      described_class.perform_all_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload

      expect(bulk_progress.results[:completed_embeds]).to eq(2)
      expect(bulk_progress.results[:failed_embeds]).to eq(1)
      expect(bulk_progress.results[:success]).to be false
      expect(bulk_progress.results[:progress_percentage]).to eq(100.0)

      expect(bulk_progress.results[:errors].length).to eq(1)
      error_report = bulk_progress.results[:errors].first
      expect(error_report[:embed_src]).to eq("https://www.youtube.com/embed/failing")
      expect(error_report[:resource_type]).to eq("WikiPage")
      expect(error_report[:resource_id]).to eq(page2.id)
      expect(error_report[:error_report_id]).to eq(99_999)
      expect(error_report[:error_message]).to be_present

      page1.reload
      page3.reload
      expect(page1.body).to include("lti-embed")
      expect(page1.body).to include("Success Video 1")
      expect(page1.body).not_to include("youtube.com")
      expect(page3.body).to include("lti-embed")
      expect(page3.body).to include("Success Video 2")
      expect(page3.body).not_to include("youtube.com")

      page2.reload
      expect(page2.body).to include("youtube.com/embed/failing")
      expect(page2.body).not_to include("lti-embed")
    end
  end

  describe "#perform_selected_conversions" do
    before do
      studio_tool
    end

    let(:embed1) do
      {
        src: "https://www.youtube.com/embed/selected1",
        id: wiki_page.id,
        resource_type: "WikiPage",
        field: :body,
        path: "//iframe[@src='https://www.youtube.com/embed/selected1']",
        width: nil,
        height: nil
      }
    end

    let(:embed2) do
      {
        src: "https://www.youtube.com/embed/selected2",
        id: wiki_page.id,
        resource_type: "WikiPage",
        field: :body,
        path: "//iframe[@src='https://www.youtube.com/embed/selected2']",
        width: nil,
        height: nil
      }
    end

    let(:bulk_progress) do
      Progress.create!(
        tag: "youtube_embed_bulk_convert",
        context: course,
        results: {
          scan_progress_id: nil,
          total_embeds: 2,
          completed_embeds: 0,
          failed_embeds: 0,
          errors: []
        }
      )
    end

    before do
      wiki_page.update!(body: '<iframe src="https://www.youtube.com/embed/selected1"></iframe><iframe src="https://www.youtube.com/embed/selected2"></iframe>')

      [embed1, embed2].each do |embed|
        stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
          .with(
            body: {
              url: embed[:src],
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
            body: { "embed_url" => "https://arc.instructure.com/media/t_#{embed[:src].split("/").last}", "title" => "Selected Video", "id" => "media_selected" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end
    end

    it "successfully converts selected embeds without scan progress" do
      scan_progress = Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed",
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [embed1, embed2],
              count: 2
            }
          },
          total_count: 2
        }
      )

      described_class.perform_selected_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload
      expect(bulk_progress.results[:success]).to be true
      expect(bulk_progress.results[:completed_embeds]).to eq(2)
      expect(bulk_progress.results[:failed_embeds]).to eq(0)
      expect(bulk_progress.results[:errors]).to be_empty
      expect(bulk_progress.results[:progress_percentage]).to eq(100.0)

      wiki_page.reload
      expect(wiki_page.body).to include("lti-embed")
      expect(wiki_page.body).not_to include("youtube.com")
    end

    it "works with scan progress when provided" do
      scan_progress = Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed",
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [embed1, embed2],
              count: 2
            }
          },
          total_count: 2
        }
      )

      described_class.perform_selected_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload
      expect(bulk_progress.results[:completed_embeds]).to eq(2)

      scan_progress.reload
      expect(scan_progress.results[:resources]["WikiPage|#{wiki_page.id}"][:count]).to eq(2)
      expect(scan_progress.results[:total_count]).to eq(0)
    end

    it "handles empty embeds list gracefully" do
      scan_progress = Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed",
        results: {
          resources: {},
          total_count: 0
        }
      )

      bulk_progress.update!(results: bulk_progress.results.merge(total_embeds: 1))

      described_class.perform_selected_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload
      expect(bulk_progress.results[:success]).to be true
      expect(bulk_progress.results[:completed_embeds]).to eq(0)
      expect(bulk_progress.results[:failed_embeds]).to eq(0)
      expect(bulk_progress.results[:progress_percentage]).to eq(0.0)
    end

    it "handles Studio API errors gracefully and continues processing" do
      failing_embed = embed1.merge(src: "https://www.youtube.com/embed/failing")
      success_embed = embed2

      wiki_page.update!(body: '<iframe src="https://www.youtube.com/embed/failing"></iframe><iframe src="https://www.youtube.com/embed/selected2"></iframe>')

      scan_progress = Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed",
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [failing_embed, success_embed],
              count: 2
            }
          },
          total_count: 2
        }
      )

      stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
        .with(
          body: {
            url: "https://www.youtube.com/embed/failing",
            course_id: course.id,
            course_name: course.name
          }.to_json,
          headers: {
            "Authorization" => /Bearer .+/,
            "Content-Type" => "application/json"
          }
        )
        .to_return(status: 500, body: "Internal Server Error")

      expect(Canvas::Errors).to receive(:capture_exception)
        .with(:youtube_embed_bulk_convert, anything)
        .and_return(error_report: 77_777)

      described_class.perform_selected_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload
      expect(bulk_progress.results[:success]).to be false
      expect(bulk_progress.results[:completed_embeds]).to eq(1)
      expect(bulk_progress.results[:failed_embeds]).to eq(1)
      expect(bulk_progress.results[:errors].length).to eq(1)
      expect(bulk_progress.results[:errors].first[:embed_src]).to eq("https://www.youtube.com/embed/failing")
      expect(bulk_progress.results[:errors].first[:error_report_id]).to eq(77_777)
      expect(bulk_progress.results[:progress_percentage]).to eq(100.0)

      wiki_page.reload
      expect(wiki_page.body).to include("lti-embed")
      expect(wiki_page.body).to include("youtube.com/embed/failing")
    end

    it "handles missing Studio tool" do
      studio_tool.destroy

      scan_progress = Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed",
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [embed1],
              count: 1
            }
          },
          total_count: 1
        }
      )

      described_class.perform_selected_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload
      expect(bulk_progress.results[:error]).to eq("Studio LTI tool not found for account")
      expect(bulk_progress.results[:completed_at]).to be_present
    end

    it "handles general exceptions during selected conversions" do
      allow_any_instance_of(described_class).to receive(:find_studio_tool)
        .and_raise(StandardError, "General error")

      expect(Canvas::Errors).to receive(:capture_exception)
        .with(:youtube_embed_bulk_convert, anything)
        .and_return(error_report: 88_888)

      scan_progress = Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed",
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [embed1],
              count: 1
            }
          },
          total_count: 1
        }
      )

      described_class.perform_selected_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload
      expect(bulk_progress.results[:error_report_id]).to eq(88_888)
      expect(bulk_progress.results[:completed_at]).to be_present
    end

    it "processes multiple resource types successfully" do
      assignment = assignment_model(course:, description: '<iframe src="https://www.youtube.com/embed/assignment123"></iframe>')
      assignment_embed = {
        src: "https://www.youtube.com/embed/assignment123",
        id: assignment.id,
        resource_type: "Assignment",
        field: :description,
        path: "//iframe[@src='https://www.youtube.com/embed/assignment123']",
        width: nil,
        height: nil
      }

      scan_progress = Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed",
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [embed1],
              count: 1
            },
            "Assignment|#{assignment.id}" => {
              name: "Test Assignment",
              embeds: [assignment_embed],
              count: 1
            }
          },
          total_count: 2
        }
      )

      stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
        .with(body: hash_including(url: "https://www.youtube.com/embed/assignment123"))
        .to_return(
          status: 200,
          body: { "embed_url" => "https://arc.instructure.com/media/t_assignment", "title" => "Assignment Video", "id" => "media_assignment" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      described_class.perform_selected_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload
      expect(bulk_progress.results[:success]).to be true
      expect(bulk_progress.results[:completed_embeds]).to eq(2)
      expect(bulk_progress.results[:failed_embeds]).to eq(0)
      expect(bulk_progress.results[:progress_percentage]).to eq(100.0)

      wiki_page.reload
      assignment.reload
      expect(wiki_page.body).to include("lti-embed")
      expect(assignment.description).to include("lti-embed")
    end

    it "calculates progress percentage correctly with mixed results" do
      failing_embed = embed1.merge(src: "https://www.youtube.com/embed/failing")
      success_embed = embed2

      wiki_page.update!(body: '<iframe src="https://www.youtube.com/embed/failing"></iframe><iframe src="https://www.youtube.com/embed/selected2"></iframe>')

      scan_progress = Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed",
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [failing_embed, success_embed],
              count: 2
            }
          },
          total_count: 2
        }
      )

      stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
        .with(body: hash_including(url: "https://www.youtube.com/embed/failing"))
        .to_return(status: 500, body: "Internal Server Error")

      expect(Canvas::Errors).to receive(:capture_exception)
        .with(:youtube_embed_bulk_convert, anything)
        .and_return(error_report: 66_666)

      bulk_progress.update!(results: bulk_progress.results.merge(total_embeds: 2))

      described_class.perform_selected_conversions(bulk_progress, course.id, scan_progress.id)

      bulk_progress.reload
      expect(bulk_progress.results[:progress_percentage]).to eq(100.0)
      expect(bulk_progress.results[:completed_embeds]).to eq(1)
      expect(bulk_progress.results[:failed_embeds]).to eq(1)
      expect(bulk_progress.results[:success]).to be false
    end

    it "updates scan progress when provided for selected conversions" do
      scan_progress = Progress.create!(
        tag: "youtube_embed_scan",
        context: course,
        workflow_state: "completed",
        results: {
          resources: {
            "WikiPage|#{wiki_page.id}" => {
              name: "Test Page",
              embeds: [embed1.merge(converted: nil), embed2.merge(converted: nil)],
              count: 2
            }
          },
          total_count: 2
        }
      )

      described_class.perform_selected_conversions(bulk_progress, course.id, scan_progress.id)

      scan_progress.reload
      resource = scan_progress.results[:resources]["WikiPage|#{wiki_page.id}"]
      converted_embed1 = resource[:embeds].find { |e| e[:src] == embed1[:src] }
      converted_embed2 = resource[:embeds].find { |e| e[:src] == embed2[:src] }

      expect(converted_embed1[:converted]).to be true
      expect(converted_embed1[:converted_at]).not_to be_nil
      expect(converted_embed2[:converted]).to be true
      expect(converted_embed2[:converted_at]).not_to be_nil
      expect(resource[:converted_count]).to eq(2)
      expect(scan_progress.results[:total_converted]).to eq(2)
      expect(scan_progress.results[:total_count]).to eq(0)
    end
  end

  describe "#find_studio_tool" do
    before do
      studio_tool
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

    context "when Studio tool exist on one of the parent account" do
      it "finds tool from higher level in hierarchy" do
        mid_account = account_model(parent_account: root_account)
        leaf_account = account_model(parent_account: mid_account)
        leaf_course = course_model(account: leaf_account)

        studio_tool.destroy

        mid_account_tool = external_tool_model(
          context: mid_account,
          opts: {
            domain: "arc.instructure.com",
            url: "https://arc.instructure.com",
            consumer_key: "mid_account_tool_key",
            shared_secret: "mid_account_tool_secret",
            name: "mid_account_tool studio"
          }
        )

        result = described_class.new(leaf_course).find_studio_tool
        expect(result).to eq(mid_account_tool)
      end
    end

    context "when Studio tool exist on root account" do
      it "finds tool from higher level in hierarchy" do
        studio_tool.destroy

        root_account_tool = external_tool_model(
          context: root_account,
          opts: {
            domain: "arc.instructure.com",
            url: "https://arc.instructure.com",
            consumer_key: "root_account_tool_key",
            shared_secret: "root_account_tool_secret",
            name: "root_account_tool studio"
          }
        )

        result = described_class.new(course).find_studio_tool
        expect(result).to eq(root_account_tool)
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

    describe "#process_new_quizzes_scan_update" do
      let(:scan_progress) do
        Progress.create!(
          tag: "youtube_embed_scan",
          context: course,
          workflow_state: "waiting_for_external_tool",
          results: {
            resources: {
              "WikiPage|123" => {
                name: "Test Page",
                id: 123,
                type: "WikiPage",
                content_url: "/courses/#{course.id}/pages/test-page",
                count: 1,
                embeds: [
                  {
                    path: "//iframe[@src='https://www.youtube.com/embed/abc123']",
                    id: 123,
                    resource_type: "WikiPage",
                    field: "body",
                    src: "https://www.youtube.com/embed/abc123"
                  }
                ]
              }
            },
            total_count: 1,
            completed_at: 2.hours.ago.utc
          }
        )
      end

      let(:new_quizzes_scan_results) do
        {
          resources: [
            {
              name: "New Quiz",
              id: 456,
              type: "Quiz",
              content_url: "/courses/#{course.id}/quizzes/456",
              count: 2,
              embeds: [
                {
                  path: "//iframe[@src='https://www.youtube.com/embed/xyz789']",
                  id: 456,
                  resource_type: "Quiz",
                  field: "instructions",
                  src: "https://www.youtube.com/embed/xyz789"
                }
              ]
            }
          ],
          total_count: 2
        }
      end

      it "merges new quizzes results when status is completed" do
        service.process_new_quizzes_scan_update(
          scan_progress.id,
          new_quizzes_scan_status: "completed",
          new_quizzes_scan_results:
        )

        scan_progress.reload
        expect(scan_progress.workflow_state).to eq("completed")
        expect(scan_progress.results[:new_quizzes_scan_status]).to eq("completed")
        expect(scan_progress.results[:total_count]).to eq(3)
        expect(scan_progress.results[:resources].keys).to include("WikiPage|123", "Quiz|456")
        expect(scan_progress.results[:resources]["Quiz|456"][:name]).to eq("New Quiz")
        expect(scan_progress.results[:completed_at]).to be_present
      end

      it "handles failed status without merging results but still completes" do
        original_resources = scan_progress.results[:resources].dup

        service.process_new_quizzes_scan_update(
          scan_progress.id,
          new_quizzes_scan_status: "failed",
          new_quizzes_scan_results:
        )

        scan_progress.reload
        expect(scan_progress.workflow_state).to eq("completed")
        expect(scan_progress.results[:new_quizzes_scan_status]).to eq("failed")
        expect(scan_progress.results[:total_count]).to eq(1)
        expect(scan_progress.results[:resources]).to eq(original_resources)
        expect(scan_progress.results[:completed_at]).to be_present
      end

      it "handles processing errors gracefully and completes with failed status" do
        allow(YoutubeMigrationService).to receive(:generate_resource_key).and_raise(StandardError, "Test error")
        expect(Canvas::Errors).to receive(:capture).with(
          :youtube_migration_new_quizzes_scan_error,
          {
            course_id: course.id,
            scan_id: scan_progress.id,
            error: "Test error",
            message: "Error processing new quizzes scan update"
          }
        )

        service.process_new_quizzes_scan_update(
          scan_progress.id,
          new_quizzes_scan_status: "completed",
          new_quizzes_scan_results:
        )

        scan_progress.reload
        expect(scan_progress.workflow_state).to eq("completed")
        expect(scan_progress.results[:new_quizzes_scan_status]).to eq("failed")
        expect(scan_progress.results[:completed_at]).to be_present
      end

      it "handles nil new_quizzes_scan_results with default empty hash" do
        service.process_new_quizzes_scan_update(
          scan_progress.id,
          new_quizzes_scan_status: "completed"
        )

        scan_progress.reload
        expect(scan_progress.results[:new_quizzes_scan_status]).to eq("completed")
        expect(scan_progress.results[:total_count]).to eq(1)
      end

      it "raises error when scan is not found" do
        expect do
          service.process_new_quizzes_scan_update(
            99_999,
            new_quizzes_scan_status: "completed",
            new_quizzes_scan_results:
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "handles empty existing results gracefully" do
        empty_progress = Progress.create!(
          tag: "youtube_embed_scan",
          context: course,
          workflow_state: "waiting_for_external_tool"
        )

        service.process_new_quizzes_scan_update(
          empty_progress.id,
          new_quizzes_scan_status: "completed",
          new_quizzes_scan_results:
        )

        empty_progress.reload
        expect(empty_progress.workflow_state).to eq("completed")
        expect(empty_progress.results[:total_count]).to eq(2)
        expect(empty_progress.results[:resources]).to have_key("Quiz|456")
        expect(empty_progress.results[:resources]["Quiz|456"][:name]).to eq("New Quiz")
        expect(empty_progress.results[:resources]["Quiz|456"][:count]).to eq(2)
        expect(empty_progress.results[:new_quizzes_scan_status]).to eq("completed")
      end
    end

    describe "JWT token generation with user_uuid" do
      let(:user) { user_factory(active_all: true) }
      let(:user_uuid) { user.uuid }

      before do
        stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
          .to_return(
            status: 200,
            body: studio_api_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "includes user_uuid in JWT token payload when converting YouTube to Studio" do
        expect(CanvasSecurity::ServicesJwt).to receive(:generate) do |payload|
          expect(payload[:sub]).to eq(course.account.uuid)
          expect(payload[:user_uuid]).to eq(user_uuid)
          "mock.jwt.token"
        end

        service.convert_youtube_to_studio(youtube_embed, studio_tool, user_uuid:)
      end
    end

    describe "#reset_scan_status" do
      subject(:call) { service.reset_scan_status }

      let(:scan_tag) { "youtube_embed_scan" }

      context "when a scan is waiting_for_external_tool" do
        let!(:stuck_progress) do
          Progress.create!(
            tag: scan_tag,
            context: course,
            workflow_state: "waiting_for_external_tool",
            results: { total_count: 3 }
          )
        end

        it "marks scan as failed, completes it, and sets completed_at" do
          call
          stuck_progress.reload

          expect(stuck_progress.workflow_state).to eq("completed")
          expect(stuck_progress.results).to be_present
          expect(stuck_progress.results[:new_quizzes_scan_status]).to eq("failed")
          expect(stuck_progress.results[:completed_at]).to be_within(10.seconds).of(Time.now.utc)
        end

        it "preserves existing results keys" do
          call
          expect(stuck_progress.reload.results[:total_count]).to eq(3)
        end
      end

      context "when the scan's results are initially nil" do
        let!(:stuck_progress) do
          Progress.create!(
            tag: scan_tag,
            context: course,
            workflow_state: "waiting_for_external_tool",
            results: nil
          )
        end

        it "initializes results and sets failure + completed_at" do
          call
          stuck_progress.reload

          expect(stuck_progress.workflow_state).to eq("completed")
          expect(stuck_progress.results[:new_quizzes_scan_status]).to eq("failed")
          expect(stuck_progress.results[:completed_at]).to be_within(10.seconds).of(Time.now.utc)
        end
      end

      context "when there is no waiting scan" do
        it "does nothing and does not raise" do
          running = Progress.create!(
            tag: scan_tag,
            context: course,
            workflow_state: "running",
            results: { total_count: 1 }
          )

          expect { call }.not_to change { Progress.count }

          running.reload
          expect(running.workflow_state).to eq("running")
          expect(running.results[:new_quizzes_scan_status]).to be_nil
          expect(running.results[:completed_at]).to be_nil
        end
      end

      context "when multiple scans exist" do
        let!(:waiting) do
          Progress.create!(
            tag: scan_tag,
            context: course,
            workflow_state: "waiting_for_external_tool",
            results: { foo: "bar" }
          )
        end

        let!(:completed) do
          Progress.create!(
            tag: scan_tag,
            context: course,
            workflow_state: "completed",
            results: { baz: 1 }
          )
        end

        it "only completes the waiting scan and leaves others unchanged" do
          call

          expect(waiting.reload.workflow_state).to eq("completed")
          expect(waiting.results[:new_quizzes_scan_status]).to eq("failed")

          expect(completed.reload.workflow_state).to eq("completed")
          expect(completed.results).to eq(baz: 1)
        end
      end
    end
  end

  describe ".process_stuck_scans" do
    let(:new_quiz_course) { course_model }
    let(:progress) do
      Progress.create!(
        tag: YoutubeMigrationService::SCAN_TAG,
        context: new_quiz_course,
        workflow_state: "waiting_for_external_tool"
      )
    end

    before do
      Account.site_admin.enable_feature!(:new_quizzes_scanning_youtube_links)

      # Stub the assignment chain for new_quizzes? and call_external_tool
      external_tool_tag = double(content_id: 1)
      quiz_assignment = double(external_tool_tag:)
      quiz_lti_scope = double(any?: true, last: quiz_assignment)
      active_scope = double(type_quiz_lti: quiz_lti_scope)
      assignments = double(active: active_scope)

      allow_any_instance_of(Course).to receive(:assignments).and_return(assignments)
    end

    context "when progress is less than 1 minute old" do
      it "does not process the scan" do
        progress.update!(created_at: 30.minutes.ago)
        expect(described_class).not_to receive(:retry_scan)
        expect(described_class).not_to receive(:timeout_scan)
        described_class.process_stuck_scans
      end
    end

    context "when progress is between 1-3 minutes old" do
      it "retries the scan by re-emitting Live Event" do
        progress.update!(created_at: 2.hours.ago)
        expect(Canvas::LiveEvents).to receive(:scan_youtube_links)
        described_class.process_stuck_scans

        progress.reload
        expect(progress.workflow_state).to eq("waiting_for_external_tool")
        expect(progress.results[:retry_count]).to eq(1)
        expect(progress.results[:last_retry_at]).to be_present
      end
    end

    context "when progress is 3+ minutes old" do
      it "times out the scan and marks as completed" do
        progress.update!(created_at: 4.hours.ago)
        described_class.process_stuck_scans

        progress.reload
        expect(progress.workflow_state).to eq("completed")
        expect(progress.results[:new_quizzes_scan_status]).to eq("timeout")
        expect(progress.results[:error]).to include("Timed out")
        expect(progress.results[:timeout_at]).to be_present
      end
    end

    context "when feature flag is disabled" do
      it "does not process any scans" do
        Account.site_admin.disable_feature!(:new_quizzes_scanning_youtube_links)
        progress.update!(created_at: 2.hours.ago)
        expect(described_class).not_to receive(:retry_scan)
        described_class.process_stuck_scans
      end
    end

    context "with multiple stuck scans" do
      let(:progress2) do
        Progress.create!(
          tag: YoutubeMigrationService::SCAN_TAG,
          context: new_quiz_course,
          workflow_state: "waiting_for_external_tool",
          created_at: 2.hours.ago
        )
      end
      let(:progress3) do
        Progress.create!(
          tag: YoutubeMigrationService::SCAN_TAG,
          context: new_quiz_course,
          workflow_state: "waiting_for_external_tool",
          created_at: 4.hours.ago
        )
      end

      it "processes all stuck scans appropriately" do
        progress.update!(created_at: 2.hours.ago)
        progress2
        progress3

        expect(Canvas::LiveEvents).to receive(:scan_youtube_links).twice

        described_class.process_stuck_scans

        progress.reload
        progress2.reload
        progress3.reload

        expect(progress.workflow_state).to eq("waiting_for_external_tool")
        expect(progress.results[:retry_count]).to eq(1)

        expect(progress2.workflow_state).to eq("waiting_for_external_tool")
        expect(progress2.results[:retry_count]).to eq(1)

        expect(progress3.workflow_state).to eq("completed")
        expect(progress3.results[:new_quizzes_scan_status]).to eq("timeout")
      end
    end
  end

  describe "skip_attachment_association_update flag" do
    before do
      studio_tool
      stub_request(:post, "https://arc.instructure.com/api/internal/youtube_embed")
        .to_return(
          status: 200,
          body: studio_api_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    let(:original_html) do
      '<iframe src="https://www.youtube.com/embed/dQw4w9WgXcQ" width="560" height="315"></iframe>'
    end

    let(:new_html) do
      '<iframe class="lti-embed" src="/courses/123/external_tools/retrieve"></iframe>'
    end

    shared_examples "skips attachment association creation" do |resource_type, model_factory, field|
      it "sets skip_attachment_association_update flag for #{resource_type}" do
        resource = send(model_factory)
        embed = youtube_embed.merge(id: resource.id, resource_type:, field:)

        expect_any_instance_of(resource.class).to receive(:skip_attachment_association_update=).with(true).and_call_original

        service.update_resource_content(embed, new_html)

        resource.reload
        expect(resource.send(field)).to include("lti-embed")
        expect(resource.send(field)).not_to include("youtube.com")
      end

      it "prevents AttachmentAssociation creation during update" do
        resource = send(model_factory)
        embed = youtube_embed.merge(id: resource.id, resource_type:, field:)

        expect { service.update_resource_content(embed, new_html) }.not_to change { AttachmentAssociation.count }

        resource.reload
        expect(resource.send(field)).to include("lti-embed")
      end
    end

    context "with WikiPage" do
      let(:wiki_page_with_embed) do
        wiki_page_model(course:, body: original_html)
      end

      include_examples "skips attachment association creation", "WikiPage", :wiki_page_with_embed, :body
    end

    context "with Assignment" do
      let(:assignment_with_embed) do
        assignment_model(course:, description: original_html)
      end

      include_examples "skips attachment association creation", "Assignment", :assignment_with_embed, :description
    end

    context "with DiscussionTopic" do
      let(:discussion_topic_with_embed) do
        discussion_topic_model(context: course, message: original_html)
      end

      include_examples "skips attachment association creation", "DiscussionTopic", :discussion_topic_with_embed, :message
    end

    context "with Announcement" do
      let(:announcement_with_embed) do
        course.announcements.create!(title: "Test", message: original_html)
      end

      include_examples "skips attachment association creation", "Announcement", :announcement_with_embed, :message
    end

    context "with DiscussionEntry" do
      let(:discussion_entry_with_embed) do
        topic = discussion_topic_model(context: course)
        topic.discussion_entries.create!(message: original_html, user: @teacher)
      end

      include_examples "skips attachment association creation", "DiscussionEntry", :discussion_entry_with_embed, :message
    end

    context "with CalendarEvent" do
      let(:calendar_event_with_embed) do
        calendar_event_model(context: course, description: original_html)
      end

      include_examples "skips attachment association creation", "CalendarEvent", :calendar_event_with_embed, :description
    end

    context "with Quizzes::Quiz" do
      let(:quiz_with_embed) do
        quiz_model(course:, description: original_html)
      end

      include_examples "skips attachment association creation", "Quizzes::Quiz", :quiz_with_embed, :description
    end

    context "with Course syllabus" do
      let(:course_with_syllabus) do
        course.update!(syllabus_body: original_html)
        course
      end

      include_examples "skips attachment association creation", "Course", :course_with_syllabus, :syllabus_body
    end
  end
end
