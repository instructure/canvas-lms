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

shared_examples_for "QuizReportSerializer Associations" do
  it "embeds its attachment as :file when present" do
    statistics.generate_csv
    statistics.reload

    serializer = Quizzes::QuizReportSerializer.new(statistics, {
                                                     controller:,
                                                     scope: user,
                                                     session:,
                                                     includes: ["file"]
                                                   })

    json = serializer.as_json[:quiz_report].stringify_keys
    expect(json).to have_key "file"
    expect(json["file"]["id"]).to be_present
  end

  it "embeds its progress when present" do
    statistics.generate_csv_in_background

    serializer = Quizzes::QuizReportSerializer.new(statistics, {
                                                     controller:,
                                                     scope: user,
                                                     session:,
                                                     includes: ["progress"]
                                                   })

    json = serializer.as_json[:quiz_report].stringify_keys
    expect(json).to have_key "progress"
    expect(json["progress"][:id]).to be_present
  end
end

describe Quizzes::QuizReportSerializer do
  subject do
    Quizzes::QuizReportSerializer.new(statistics, {
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
  let :quiz do
    context.quizzes.build(title: "banana split").tap do |quiz|
      quiz.id = 2
      quiz.save!
    end
  end

  let :statistics do
    quiz.current_statistics_for("student_analysis")
  end

  let(:user) { User.new }
  let(:session) { double }
  let(:host_name) { "example.com" }

  let :controller do
    ActiveModel::FakeController.new({}).tap do |controller|
      allow(controller).to receive_messages(session:, context:)
    end
  end

  let :json do
    @json ||= subject.as_json[:quiz_report].stringify_keys
  end

  context "format independent" do
    %w[
      report_type
      readable_type
      includes_all_versions
      anonymous
      created_at
      updated_at
    ].each do |attr|
      it "serializes #{attr}" do
        expect(json[attr]).to eq statistics.send(attr)
      end
    end

    it "exposes whether the report is generatable" do
      expect(json["generatable"]).to eq statistics.report.generatable?
    end

    it "links to itself" do
      expect(json["url"]).to eq(
        "http://example.com/api/v1/courses/1/quizzes/2/reports/#{statistics.id}"
      )
    end
  end

  context "JSON-API" do
    before do
      expect(controller).to receive(:accepts_jsonapi?).at_least(:once).and_return true
    end

    it "serializes id" do
      expect(json["id"]).to eq statistics.id.to_s
    end

    context "associations" do
      include_examples "QuizReportSerializer Associations"

      it "links to the quiz" do
        expect(json["links"]).to be_present
        expect(json["links"]["quiz"]).to eq "http://example.com/api/v1/courses/1/quizzes/2"
      end
    end
  end

  context "legacy JSON" do
    before do
      expect(controller).to receive(:accepts_jsonapi?).at_least(:once).and_return false
    end

    it "serializes id" do
      expect(json["id"]).to eq statistics.id
    end

    it "includes quiz_id" do
      expect(json["quiz_id"]).to eq quiz.id
    end

    it "includes the progress_url" do
      statistics.generate_csv_in_background

      expect(json["progress_url"]).to eq(
        "http://example.com/api/v1/progress/#{statistics.progress.id}"
      )
    end

    context "associations" do
      include_examples "QuizReportSerializer Associations"
    end
  end
end
