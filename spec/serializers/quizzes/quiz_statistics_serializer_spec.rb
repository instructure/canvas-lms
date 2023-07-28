# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe Quizzes::QuizStatisticsSerializer do
  subject do
    Quizzes::QuizStatisticsSerializer.new(statistics, {
                                            controller:,
                                            scope: user,
                                            session:
                                          })
  end

  let :context do
    Course.new.tap do |course|
      course.id = 1
      course.save!
    end
  end

  let :assignment do
    context.assignments.create!(title: "quiz assignment")
  end

  let :quiz do
    context.quizzes.build(title: "banana split").tap do |quiz|
      quiz.id = 1
      quiz.assignment = assignment
      quiz.workflow_state = "available"
      quiz.save!
    end
  end

  let :statistics do
    analyses = [
      quiz.current_statistics_for("student_analysis"),
      quiz.current_statistics_for("item_analysis")
    ]

    analyses.each do |analysis|
      analysis.quiz = quiz
    end

    Quizzes::QuizStatisticsSerializer::Input.new(quiz, {}, *analyses)
  end

  let(:user) { User.new }
  let(:session) { double }
  let(:host_name) { "example.com" }

  let :controller do
    options = {
      accepts_jsonapi: true,
      stringify_json_ids: false
    }

    ActiveModel::FakeController.new(options).tap do |controller|
      allow(controller).to receive_messages(session:, context:)
    end
  end

  before do
    @json = subject.as_json[:quiz_statistics].stringify_keys
  end

  %w[
    question_statistics
    submission_statistics
    multiple_attempts_exist
    includes_all_versions
    generated_at
  ].each do |attr|
    it "serializes #{attr}" do
      expect(@json).to have_key(attr)
    end
  end

  it "serializes generated_at to point to the earliest report date" do
    oldest = 5.days.ago

    allow(statistics.student_analysis).to receive_messages(created_at: oldest)
    allow(statistics.item_analysis).to receive_messages(created_at: oldest + 1.day)

    @json = subject.as_json[:quiz_statistics].stringify_keys
    expect(@json["generated_at"]).to eq oldest
  end

  it "de-scopifies submission statistic keys" do
    keys = %w[
      correct_count_average
      duration_average
      incorrect_count_average
      score_average
      score_high
      score_low
      score_stdev
      unique_count
    ]

    expect(@json["submission_statistics"].keys.map(&:to_s).sort & keys).to eq keys
  end

  it "serializes url" do
    expect(@json["url"]).to eq "http://example.com/api/v1/courses/1/quizzes/1/statistics"
  end

  it "serializes quiz url" do
    expect(@json["links"]).to be_present
    expect(@json["links"]["quiz"]).to eq "http://example.com/api/v1/courses/1/quizzes/1"
  end

  it "serializes speed_grader url" do
    allow(quiz.assignment).to receive(:can_view_speed_grader?).and_return true
    expect(subject.as_json[:quiz_statistics][:speed_grader_url]).to eq(
      controller.send(:speed_grader_course_gradebook_url, quiz.context, assignment_id: quiz.assignment.id)
    )
  end

  it "does not serialize speed_grader url if user cannot view speed grader" do
    allow(quiz.assignment).to receive(:can_view_speed_grader?).and_return false
    expect(subject.as_json[:quiz_statistics][:speed_grader_url]).to be_nil
  end

  it "stringifies question_statistics ids" do
    allow(subject).to receive_messages(student_analysis_report: {
                                         questions: [["question", { id: 5 }]]
                                       })

    json = subject.as_json[:quiz_statistics]
    expect(json[:question_statistics]).to be_present
    expect(json[:question_statistics][0][:id]).to eq "5"
  end

  it "munges item_analysis with question_statistics" do
    allow(subject).to receive_messages(student_analysis_report: {
                                         questions: [["question", { id: 5 }]]
                                       })

    allow(subject).to receive_messages(item_analysis_report: [
                                         { question_id: 5, foo: "bar" }
                                       ])

    json = subject.as_json[:quiz_statistics]
    expect(json[:question_statistics]).to be_present
    expect(json[:question_statistics][0][:foo]).to eq "bar"
  end
end
