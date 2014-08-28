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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../views_helper')

describe "/quizzes/quizzes/statistics" do
  it "should render with non-nil submission statistics" do
    course_with_student
    view_context
    assigns[:quiz] = q = @course.quizzes.create!(:quiz_type => 'assignment').tap{|q| q.should be_graded }
    assigns[:submitted_users] = []
    assigns[:statistics] = { :submission_score_high => 20,
                             :submission_count => 3,
                             :submission_score_low => 15,
                             :multiple_attempts_included => true,
                             :last_submission_at => Time.now.utc,
                             :submission_duration_average => 0,
                             :submission_score_stdev => 2.05480466765634,
                             :submission_user_ids => [4, 3, 2],
                             :questions => [],
                             :submission_correct_count_average => 3,
                             :submission_incorrect_count_average => 2,
                             :submission_score_average => 17.3333333333333,
                             :unique_submission_count => 3}

    render "quizzes/quizzes/statistics"
    response.should_not be_nil
    content_for(:right_side).should_not be_nil
    kv = {}
    page = Nokogiri::HTML(content_for(:right_side))
    page.css('#statistics_summary').first.children.each do |row|
      next if row.name != 'tr'
      row = row.children.find_all{|col| col.name == 'td'}
      next if row.size != 2
      kv[row[0].text] = row[1].text
    end
    kv.should == {
      "Low Score:" => "15",
      "Average Time:" => "less than a minute",
      "Average Incorrect:" => "2",
      "Standard Deviation:" => "2.05",
      "High Score:" => "20",
      "Mean Score:" => "17.33",
      "Average Correct:" => "3"
    }
  end

  it "should render with nil submission statistics" do
    course_with_student
    view_context
    assigns[:quiz] = @course.quizzes.create!
    assigns[:statistics] = { :submission_duration_average => 0,
                             :questions => [] }
    assigns[:submitted_users] = []
    render "quizzes/quizzes/statistics"
    response.should_not be_nil
    content_for(:right_side).should_not be_nil
    kv = {}
    page = Nokogiri::HTML(content_for(:right_side))
    page.css('#statistics_summary').first.children.each do |row|
      next if row.name != 'tr'
      row = row.children.find_all{|col| col.name == 'td'}
      next if row.size != 2
      kv[row[0].text] = row[1].text
    end
    kv.should == {
      "Low Score:" => "_",
      "Average Time:" => "less than a minute",
      "Average Incorrect:" => "_",
      "Standard Deviation:" => "_",
      "High Score:" => "_",
      "Mean Score:" => "_",
      "Average Correct:" => "_"
    }
  end
end
