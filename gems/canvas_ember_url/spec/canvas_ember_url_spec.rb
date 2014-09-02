#
# Copyright (C) 2011 Instructure, Inc.
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

require 'spec_helper'

describe CanvasEmberUrl::UrlMappings do

  context "quizzes" do
    let(:course_quizzes) { "http://localhost:3000/courses/1/quizzes" }
    let(:mappings) do
      CanvasEmberUrl::UrlMappings.new(:course_quizzes => course_quizzes)
    end

    describe "#course_quizzes_url" do
      it "should build the base url passed in" do
        mappings.course_quizzes_url.should == course_quizzes
      end
    end

    describe "#course_quiz_url" do
      it "should build the base url passed in" do
        mappings.course_quiz_url(1).should == "#{course_quizzes}#/1"
      end

      it "should build the base url with headless param present" do
        mappings.course_quiz_url(1, headless: 1).should == "#{course_quizzes}?headless=1#/1"
      end

      it "should build the base url with headless param empty" do
        mappings.course_quiz_url(1, headless: nil).should == "#{course_quizzes}#/1"
      end
    end

    describe "#course_quiz_preview_url" do
      it "should build the base url passed in" do
        mappings.course_quiz_preview_url(1).should == "#{course_quizzes}#/1/preview"
      end
    end

    describe "#course_quiz_moderate_url" do
      it "should build the base url passed in" do
        mappings.course_quiz_moderate_url(1).should == "#{course_quizzes}#/1/moderate"
      end
    end

    describe "#course_quiz_statistics_url" do
      it "should build the base url passed in" do
        mappings.course_quiz_statistics_url(1).should == "#{course_quizzes}#/1/statistics"
      end
    end
  end
end
