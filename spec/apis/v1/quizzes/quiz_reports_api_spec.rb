#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../models/quizzes/quiz_statistics/item_analysis/common')

describe Quizzes::QuizReportsController, type: :request do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  describe "GET /courses/:course_id/quizzes/:quiz_id/reports [index]" do
    def api_index(params={}, options={})
      method = options[:raw] ? :raw_api_call : :api_call
      headers = options[:jsonapi] ? { 'Accept' => 'application/vnd.api+json' } : {}
      send method, :get,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/reports", {
          controller: "quizzes/quiz_reports",
          action: "index",
          format: "json",
          course_id: @course.id.to_s,
          quiz_id: @quiz.id.to_s
        }, params, headers
    end

    it 'denies unprivileged access' do
      student_in_course(:active_all => true)
      @quiz = @course.quizzes.create({ title: 'Test Quiz' })
      api_index({}, { raw: true })
      assert_status(401)
    end

    context 'with privileged access' do
      before :once do
        teacher_in_course(:active_all => true)
        @quiz = @course.quizzes.create({ title: 'Test Quiz' })
      end

      it 'returns all reports, generated or not' do
        stats = @quiz.current_statistics_for "student_analysis"
        stats.save!

        json = api_index
        expect(json.length).to eq 2
        expect(json.map { |report| report['report_type'] }.sort).
          to eq %w[ item_analysis student_analysis ]
      end

      describe 'the `includes_all_versions` flag' do
        it 'enables it' do
          json = api_index({ includes_all_versions: true })

          student_analysis = json.detect do |report|
            report['report_type'] == 'student_analysis'
          end

          expect(student_analysis['includes_all_versions']).to eq true
        end

        it 'defaults to false' do
          json = api_index

          student_analysis = json.detect do |report|
            report['report_type'] == 'student_analysis'
          end

          expect(student_analysis['includes_all_versions']).to eq false
        end
      end

      context 'JSON-API' do
        it 'returns all reports, generated or not' do
          stats = @quiz.current_statistics_for "student_analysis"
          stats.save!

          json = api_index({}, { jsonapi: true })

          expect(json['quiz_reports']).to be_present
          expect(json['quiz_reports'].length).to eq 2
          expect(json['quiz_reports'].map { |report| report['report_type'] }.sort).
            to eq %w[ item_analysis student_analysis ]
        end
      end
    end
  end

  describe "POST /courses/:course_id/quizzes/:quiz_id/reports" do
    def api_create(params={}, options={})
      method = options[:raw] ? :raw_api_call : :api_call
      headers = options[:jsonapi] ? { 'Accept' => 'application/vnd.api+json' } : {}
      send method, :post,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/reports", {
          controller: "quizzes/quiz_reports",
          action: "create",
          format: "json",
          course_id: @course.id.to_s,
          quiz_id: @quiz.id.to_s
        }, params, headers
    end

    before :once do
      teacher_in_course(:active_all => true)
      @me = @user
      simple_quiz_with_submissions %w{T T T}, %w{T T T}, %w{T F F}, %w{T F T}, :user => @user, :course => @course
      @user = @me
    end

    it "should create a new report" do
      expect(Quizzes::QuizStatistics.count).to eq 0
      json = api_create({:quiz_report => {:report_type => "item_analysis"}})
      expect(Quizzes::QuizStatistics.count).to eq 1
      expect(json['id']).to eq Quizzes::QuizStatistics.first.id
    end

    it "should reuse an existing report" do
      @quiz.statistics_csv('item_analysis')
      expect(Quizzes::QuizStatistics.count).to eq 1
      json = api_create({:quiz_report => {:report_type => "item_analysis"}})
      expect(Quizzes::QuizStatistics.count).to eq 1
      expect(json['id']).to eq Quizzes::QuizStatistics.first.id
    end

    context 'JSON-API' do
      it "should create a new report" do
        expect(Quizzes::QuizStatistics.count).to eq 0

        json = api_create({
          quiz_reports: [{
            report_type: "item_analysis"
          }]
        }, { jsonapi: true })

        expect(Quizzes::QuizStatistics.count).to eq 1

        expect(json['quiz_reports']).to be_present
        expect(json['quiz_reports'][0]['id']).to eq "#{Quizzes::QuizStatistics.first.id}"
      end
    end
  end

  describe "GET /courses/:course_id/quizzes/:quiz_id/reports/:id [show]" do
    def api_show(params={}, options={})
      method = options[:raw] ? :raw_api_call : :api_call
      headers = options[:jsonapi] ? {'Accept' => 'application/vnd.api+json'} : {}
      send method, :get,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/reports/#{@report.id}", {
          controller: "quizzes/quiz_reports",
          action: "show",
          format: "json",
          course_id: @course.id.to_s,
          quiz_id: @quiz.id.to_s,
          id: @report.id.to_s
        }, params, headers
    end

    it 'denies unprivileged access' do
      student_in_course(:active_all => true)
      @quiz = @course.quizzes.create({ title: 'Test Quiz' })
      @report = @quiz.current_statistics_for('student_analysis')
      api_show({}, raw: true)
      assert_status(401)
    end

    context 'with privileged access' do
      before :once do
        teacher_in_course(:active_all => true)
        @quiz = @course.quizzes.create({ title: 'Test Quiz' })
        @report = @quiz.current_statistics_for('student_analysis')
      end

      it 'shows the report' do
        json = api_show
        expect(json['id']).to eq @report.id
        expect(json['report_type']).to eq 'student_analysis'
      end

      it 'embeds its attachment automatically in JSON format' do
        @report.generate_csv
        @report.reload

        json = api_show
        expect(json['file']).to be_present
        expect(json['file']['id']).to eq @report.csv_attachment.id
      end

      context 'JSON-API' do
        it 'renders' do
          json = api_show({}, { jsonapi: true })
          expect(json['quiz_reports']).to be_present
          expect(json['quiz_reports'][0]['id']).to eq "#{@report.id}"
          expect(json['quiz_reports'][0]['report_type']).to eq 'student_analysis'
        end

        it 'embeds its attachment with ?include=file' do
          @report.generate_csv
          @report.reload

          json = api_show({:include=>['file']}, { jsonapi: true })
          expect(json['quiz_reports'][0]['file']).to be_present
          expect(json['quiz_reports'][0]['file']['id']).to eq @report.csv_attachment.id
        end

        it 'embeds its progress with ?include=progress' do
          @report.start_progress
          @report.reload

          json = api_show({:include=>['progress']}, { jsonapi: true })
          expect(json['quiz_reports'][0]['file']).not_to be_present
          expect(json['quiz_reports'][0]['progress']).to be_present
          expect(json['quiz_reports'][0]['progress']['id']).to eq @report.progress.id
        end
      end
    end # context 'with privileged access'
  end # API show
end
