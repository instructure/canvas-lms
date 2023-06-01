# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe "Quizzes2 Exporter" do
  context "assignment creation" do
    before :once do
      @course = Account.default.courses.create!
      @tool = Account.default.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @quiz = @course.quizzes.create!(
        title: "quiz1",
        quiz_type: "assignment",
        points_possible: 2.0,
        due_at: 2.days.ago,
        unlock_at: 7.days.ago,
        lock_at: 7.days.from_now
      )
      @ce = @course.content_exports.create!(
        export_type: ContentExport::QUIZZES2,
        selected_content: @quiz.id
      )
      @quizzes2 = Exporters::Quizzes2Exporter.new(@ce)
    end

    it "creates a Quizzes2 assignment group if it doesn't exist" do
      expect(@course.assignment_groups.where(name: Exporters::Quizzes2Exporter::GROUP_NAME).exists?).to be false
      @quizzes2.export
      expect(@course.assignment_groups.where(name: Exporters::Quizzes2Exporter::GROUP_NAME).exists?).to be true
    end

    it "creates a Quizzes2 assignment group if it was previously deleted" do
      old_group = @course.assignment_groups.create(name: Exporters::Quizzes2Exporter::GROUP_NAME)
      old_group.destroy
      @quizzes2.export
      expect(@course.assignment_groups.where(name: Exporters::Quizzes2Exporter::GROUP_NAME).exists?).to be true
    end

    it "does not create a new Quizzes2 assignment group if one exists" do
      @course.assignment_groups.create(name: Exporters::Quizzes2Exporter::GROUP_NAME)
      @quizzes2.export
      expect(@course.assignment_groups.where(name: Exporters::Quizzes2Exporter::GROUP_NAME).count).to eq 1
    end

    it "creates a Quizzes2 assignment" do
      @course.enable_feature!(:post_grades)
      @quiz.assignment.update!(post_to_sis: true)
      @quizzes2.export
      assignment = @course.assignments.where.not(id: @quiz.assignment.id).first
      expect(assignment.title).to eq @quiz.title
      expect(assignment.points_possible).to eq @quiz.points_possible
      expect(assignment.due_at).to eq @quiz.due_at
      expect(assignment.unlock_at).to eq @quiz.unlock_at
      expect(assignment.lock_at).to eq @quiz.lock_at
      expect(assignment.post_to_sis).to eq @quiz.assignment.post_to_sis
      expect(assignment.submission_types).to eq "external_tool"
      expect(assignment.external_tool_tag.url).to eq @tool.url
      expect(assignment.assignment_group.name).to eq Exporters::Quizzes2Exporter::GROUP_NAME
    end

    it "doesn't fail when exporting an ungraded quiz and SIS grade export is enabled" do
      @course.enable_feature!(:post_grades)
      survey_quiz = @course.quizzes.create!(title: "blah", quiz_type: "survey")
      ce = @course.content_exports.create!(
        export_type: ContentExport::QUIZZES2,
        selected_content: survey_quiz.id
      )
      exporter = Exporters::Quizzes2Exporter.new(ce)
      expect { exporter.export }.to change { @course.assignments.count }.by(1)
    end

    it "builds assignment payload" do
      @quizzes2.export
      assignment = @course.assignments.where.not(id: @quiz.assignment.id).first
      expect(@quizzes2.build_assignment_payload).to eq(
        {
          assignment: {
            resource_link_id: assignment.lti_resource_link_id,
            assignment_id: assignment.global_id,
            title: @quiz.title,
            context_title: @quiz.context.name,
            course_uuid: @quiz.course.uuid,
            points_possible: assignment.points_possible
          }
        }
      )
    end

    context "when newquizzes_on_quiz_page is enabled" do
      before do
        @course.root_account.enable_feature!(:newquizzes_on_quiz_page)
      end

      it "sets correct workflow_state" do
        @quizzes2.export
        assignment = @course.assignments.where.not(id: @quiz.assignment.id).first
        expect(assignment.workflow_state).to eq "migrating"
        expect(assignment.migrate_from_id).to be(@quiz.id)
      end

      context "when failed assignment is provided" do
        let(:failed_assignment) do
          @course.assignments.create!(
            position: 777,
            assignment_group:
          )
        end

        let(:assignment_group) do
          @course.assignment_groups.create!(name: "group_123")
        end

        it "creates assignment with expected group and position" do
          @quizzes2.export(failed_assignment_id: failed_assignment.id)
          assignment = @course.assignments.where.not(id: @quiz.assignment.id).first
          expect(assignment.position).to be(777)
          expect(assignment.assignment_group.id).to be(assignment_group.id)
        end
      end
    end
  end
end
