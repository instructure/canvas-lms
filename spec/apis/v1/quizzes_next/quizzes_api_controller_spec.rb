# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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
require_relative "../../api_spec_helper"
require_relative "../../locked_examples"
require_relative "../../../file_upload_helper"

describe QuizzesNext::QuizzesApiController, type: :request do
  describe "GET /courses/:course_id/all_quizzes (index)" do
    let(:quizzes) { (0..3).map { |i| @course.quizzes.create! title: "quiz_#{i}" } }
    let(:assignments) do
      (0..2).map do |i|
        @course.assignments.create! title: "assignment_#{i}", workflow_state: "unpublished"
      end
    end
    let(:new_quizzes) do
      (3..5).map do |i|
        quiz = @course.assignments.create! title: "assignment_#{i}", workflow_state: "unpublished"
        quiz.quiz_lti!
        quiz.save!
        quiz
      end
    end

    let(:tool) do
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
    end

    before(:once) { teacher_in_course(active_all: true) }

    before do
      quizzes
      assignments
      tool
      new_quizzes
    end

    context "as a teacher" do
      subject do
        api_call(
          :get,
          "/api/v1/courses/#{@course.id}/all_quizzes",
          controller: "quizzes_next/quizzes_api",
          action: "index",
          format: "json",
          course_id: @course.id.to_s
        )
      end

      it "returns list of old quizzes" do
        quiz_collection = subject.collect.reject { |quiz| quiz["quiz_type"] == "quizzes.next" }
        expect(quiz_collection.pluck("id")).to eq quizzes.map(&:id)
      end

      it "returns list of assignments (new quizzes)" do
        quiz_collection = subject.collect.select { |quiz| quiz["quiz_type"] == "quizzes.next" }
        expect(quiz_collection.pluck("id")).to eq new_quizzes.map(&:id)
      end

      describe "search_term query param" do
        let(:search_term) { "waldo" }
        let(:quizzes_with_search_term) { (0..2).map { |i| @course.quizzes.create! title: "#{search_term}_#{i}" } }
        let(:assignments_with_search_term) do
          (3..5).map do |i|
            @course.assignments.create! title: "#{search_term}_#{i}"
          end
        end
        let(:quizzes_without_search_term) { (0..2).map { |i| @course.quizzes.create! title: "quiz_#{i}" } }
        let(:quizzes) { quizzes_with_search_term + quizzes_without_search_term + assignments_with_search_term }

        before do
          assignments_with_search_term.each do |quiz|
            quiz.quiz_lti!
            quiz.save!
          end
        end

        it "searches for quizzes by title" do
          response = api_call(
            :get,
            "/api/v1/courses/#{@course.id}/all_quizzes?search_term=#{search_term}",
            controller: "quizzes_next/quizzes_api",
            action: "index",
            format: "json",
            course_id: @course.id.to_s,
            search_term:
          )

          response_quizzes = response.reject { |quiz| quiz["quiz_type"] == "quizzes.next" }.pluck("title")
          expect(response_quizzes.sort).to eq(quizzes_with_search_term.map(&:title).sort)

          response_quizzes = response.select { |quiz| quiz["quiz_type"] == "quizzes.next" }.pluck("title")
          expect(response_quizzes.sort).to eq(assignments_with_search_term.map(&:title).sort)
        end
      end

      context "quizzes with the same title" do
        let(:quiz_count) { 10 }
        let(:quizzes) { (0..quiz_count).map { @course.quizzes.create! title: "the same title" } }
        let(:assignments) do
          (0..quiz_count).map do
            @course.assignments.create! title: "the same title"
          end
        end

        before do
          assignments.each do |quiz|
            quiz.quiz_lti!
            quiz.save!
          end
        end

        it "orders quizzes deterministically for pagination" do
          found_quiz_ids = []
          (quiz_count * 2).times do |i|
            page_num = i + 1
            response = api_call(
              :get,
              "/api/v1/courses/#{@course.id}/all_quizzes?page=#{page_num}&per_page=1",
              controller: "quizzes_next/quizzes_api",
              action: "index",
              format: "json",
              course_id: @course.id.to_s,
              per_page: 1,
              page: page_num
            )

            id = response.first["id"]
            id_already_found = found_quiz_ids.include?(id)
            expect(id_already_found).to be_falsey
            found_quiz_ids << id
          end
        end
      end

      context "when there are multiple data pages" do
        subject do
          api_call(
            :get,
            "/api/v1/courses/#{@course.id}/all_quizzes?per_page=2",
            controller: "quizzes_next/quizzes_api",
            action: "index",
            format: "json",
            course_id: @course.id.to_s,
            per_page: 2
          )
        end

        it "include a response header Link" do
          subject
          link_header = response.headers["Link"]
          expect(link_header).to eq(
            "<http://www.example.com/api/v1/courses/#{@course.id}/all_quizzes?page=1&per_page=2>; rel=\"current\"," \
            "<http://www.example.com/api/v1/courses/#{@course.id}/all_quizzes?page=2&per_page=2>; rel=\"next\"," \
            "<http://www.example.com/api/v1/courses/#{@course.id}/all_quizzes?page=1&per_page=2>; rel=\"first\"," \
            "<http://www.example.com/api/v1/courses/#{@course.id}/all_quizzes?page=4&per_page=2>; rel=\"last\""
          )
        end

        it "also caches link header" do
          enable_cache do
            subject
            link_header = response.headers["Link"]
            cache_key = Rails.cache.instance_variable_get(:@data).keys.grep(/quizzes\.next/).first.dup.split(":", 2).last
            cached_content = Rails.cache.read(cache_key)
            expect(cached_content[:link]).to eq(link_header)
          end
        end
      end
    end

    context "as a student" do
      before(:once) { student_in_course(active_all: true) }

      context "quiz tab is disabled" do
        before do
          @course.tab_configuration = [{ id: Course::TAB_QUIZZES, hidden: true }]
          @course.save!
        end

        it "returns unauthorized" do
          raw_api_call(
            :get,
            "/api/v1/courses/#{@course.id}/all_quizzes",
            controller: "quizzes_next/quizzes_api",
            action: "index",
            format: "json",
            course_id: @course.id.to_s
          )
          assert_status(404)
        end
      end

      context "a published quiz" do
        subject do
          api_call(
            :get,
            "/api/v1/courses/#{@course.id}/all_quizzes",
            controller: "quizzes_next/quizzes_api",
            action: "index",
            format: "json",
            course_id: @course.id.to_s
          )
        end

        let(:published_quiz) { quizzes.first }
        let(:published_new_quiz) { new_quizzes.first }

        before do
          published_quiz.publish!
          published_new_quiz.update_attribute(:workflow_state, "published")
        end

        it "only returns published quizzes" do
          quiz_ids = subject.pluck("id")
          expect(quiz_ids).to eq([published_quiz.id, published_new_quiz.id])
        end
      end
    end
  end
end
