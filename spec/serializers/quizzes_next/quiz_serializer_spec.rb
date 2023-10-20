# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe QuizzesNext::QuizSerializer do
  subject { quiz_serializer.as_json }

  let(:original_context) do
    Account.default.courses.create
  end

  let(:original_assignment) do
    group = original_context.assignment_groups.create(name: "some group 1")
    original_context.assignments.create(
      title: "some assignment 1",
      assignment_group: group,
      due_at: 1.week.from_now,
      workflow_state: "published"
    )
  end

  let(:context) do
    Account.default.courses.create
  end

  let(:assignment) do
    group = context.assignment_groups.create(name: "some group")
    context.assignments.create(
      title: "some assignment",
      assignment_group: group,
      due_at: 1.week.from_now,
      workflow_state: "published",
      duplicate_of: original_assignment,
      settings: {
        lockdown_browser: {
          require_lockdown_browser: true,
          require_lockdown_browser_for_results: false,
          require_lockdown_browser_monitor: true,
          lockdown_browser_monitor_data: "some text data",
          access_code: "magic code"
        }
      }
    )
  end
  let(:user) { User.create }
  let(:session) { double(:[] => nil) }
  let(:controller) do
    ActiveModel::FakeController.new(accepts_jsonapi: false, stringify_json_ids: false)
  end
  let(:quiz_serializer) do
    QuizzesNext::QuizSerializer.new(assignment, {
                                      controller:,
                                      scope: user,
                                      session:,
                                      root: false
                                    })
  end

  before do
    allow(controller).to receive_messages(session:, context:)
    allow(assignment).to receive(:grants_right?).at_least(:once).and_return true
    allow(context).to receive(:grants_right?).at_least(:once).and_return true
    allow(context).to receive(:grants_any_right?).at_least(:once).and_return true
  end

  %i[
    id
    title
    description
    due_at
    lock_at
    unlock_at
    points_possible
    assignment_group_id
    migration_id
    only_visible_to_overrides
    post_to_sis
    allowed_attempts
    workflow_state
  ].each do |attribute|
    it "serializes #{attribute}" do
      expect(subject[attribute]).to eq assignment.send(attribute)
    end
  end

  describe "#quiz_type" do
    it "serializes quiz_type" do
      expect(subject[:quiz_type]).to eq("quizzes.next")
    end
  end

  describe "#published" do
    it "serializes published" do
      expect(subject[:published]).to be(true)
    end
  end

  describe "#course_id" do
    it "serializes course_id" do
      expect(subject[:course_id]).to eq(context.id)
    end
  end

  describe "#assignment_id" do
    it "serializes assignment_id" do
      expect(subject[:assignment_id]).to eq(assignment.id)
    end
  end

  describe "#original_course_id" do
    it "serializes original_course_id" do
      expect(subject[:original_course_id]).to eq(original_context.id)
    end
  end

  describe "#original_assignment_id" do
    it "serializes original_assignment_id" do
      expect(subject[:original_assignment_id]).to eq(original_assignment.id)
    end
  end

  describe "#original_assignment_name" do
    it "serializes original_assignment_name" do
      expect(subject[:original_assignment_name]).to eq("some assignment 1")
    end
  end

  describe "#require_lockdown_browser" do
    it "serializes require_lockdown_browser" do
      expect(subject[:require_lockdown_browser]).to be_truthy
    end
  end

  describe "#require_lockdown_browser_for_results" do
    it "serializes require_lockdown_browser_for_results" do
      expect(subject[:require_lockdown_browser_for_results]).to be_falsy
    end
  end

  describe "#require_lockdown_browser_monitor" do
    it "serializes require_lockdown_browser_monitor" do
      expect(subject[:require_lockdown_browser_monitor]).to be_truthy
    end
  end

  describe "#lockdown_browser_monitor_data" do
    it "serializes lockdown_browser_monitor_data" do
      expect(subject[:lockdown_browser_monitor_data]).to eq "some text data"
    end
  end

  describe "#access_code" do
    it "serializes access_code" do
      expect(subject[:access_code]).to eq "magic code"
    end
  end

  context "when the assignment is a migrated quiz" do
    let(:quiz) do
      Quizzes::Quiz.create(title: "Quiz Name", context:)
    end

    let(:assignment) do
      group = context.assignment_groups.create(name: "some group")
      context.assignments.create(
        title: "some assignment",
        assignment_group: group,
        due_at: 1.week.from_now,
        workflow_state: "published",
        migrate_from_id: quiz.id
      )
    end

    it "serializes original_assignment_id" do
      expect(subject[:original_quiz_id]).to eq(quiz.id)
    end
  end

  describe "enabled_course_paces" do
    it "when enabled, quiz is 'in_paced_course'" do
      context.enable_course_paces = true
      result = quiz_serializer.as_json
      expect(result[:in_paced_course]).to be(true)
    end

    it "when enabled, but feature is off quiz is not 'in_paced_course'" do
      context.account.disable_feature!(:course_paces)
      context.enable_course_paces = true
      result = quiz_serializer.as_json
      expect(result[:in_paced_course]).to be(false)
    end

    it "when disabled, quiz is not 'in_paced_course'" do
      context.enable_course_paces = false
      result = quiz_serializer.as_json
      expect(result[:in_paced_course]).to be(false)
    end
  end

  describe "permissions" do
    it "serializes permissions" do
      expect(subject[:permissions]).to include({
                                                 read: true,
                                                 create: true,
                                                 update: true,
                                                 delete: true
                                               })
    end
  end
end
