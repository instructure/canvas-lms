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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe SubmissionList do
  it "should initialize with a course" do
    course_model
    lambda{@sl = SubmissionList.new(@course)}.should_not raise_error
    @sl.should be_is_a(SubmissionList)
    @sl.course.should eql(@course)
  
    lambda{@sl = SubmissionList.new(@course)}.should_not raise_error
    @sl.course.should eql(@course)
    
    lambda{@sl = SubmissionList.new(-1)}.should raise_error(ArgumentError, "Must provide a course.")
  end
  
  it "should provide a dictionary in 'list'" do
    course_model
    SubmissionList.new(@course).list.should be_is_a(Dictionary)
  end
  
  it "should create keys in the data when versions of submissions existed" do
    interesting_submission_list
    @sl.list.keys.should eql([Date.parse(Time.now.utc.to_s)])
  end

  it "should take the time zone into account when dividing grading history into days" do
    course_with_teacher(:active_all => true)
    course_with_student(:course => @course, :active_all => true)

    @assignment1 = @course.assignments.create!(:title => 'one', :points_possible => 10)
    @assignment2 = @course.assignments.create!(:title => 'two', :points_possible => 10)
    @assignment3 = @course.assignments.create!(:title => 'three', :points_possible => 10)

    Time.zone = 'Alaska'
    Time.stubs(:now).returns(Time.utc(2011, 12, 31, 23, 0))   # 12/31 14:00 local time
    @assignment1.grade_student(@student, {:grade => 10, :grader => @teacher})
    Time.stubs(:now).returns(Time.utc(2012, 1, 1, 1, 0))      # 12/31 16:00 local time
    @assignment2.grade_student(@student, {:grade => 10, :grader => @teacher})
    Time.stubs(:now).returns(Time.utc(2012, 1, 1, 10, 0))     #  1/01 01:00 local time
    @assignment3.grade_student(@student, {:grade => 10, :grader => @teacher})
    Time.unstub(:now)

    @days = SubmissionList.new(@course).days
    @days.size.should == 2
    @days[0].date.should == Date.new(2012, 1, 1)
    @days[0].graders[0].assignments.size.should == 1
    @days[1].date.should == Date.new(2011, 12, 31)
    @days[1].graders[0].assignments.size.should == 2
  end

  context "named loops" do
    
    before do
      interesting_submission_data
    end
    
    it "should be able to loop on days" do
      available_keys = [:graders, :date]
      SubmissionList.days(@course).each do |day|
        day.should be_is_a(OpenStruct)
        day.send(:table).keys.size.should eql(available_keys.size)
        available_keys.each {|k| day.send(:table).should be_include(k)}
        day.graders.should be_is_a(Array)
        day.date.should be_is_a(Date)
      end
    end
    
    it "should be able to loop on graders" do
      available_keys = [:grader_id, :assignments, :name]
      SubmissionList.days(@course).each do |day|
        day.graders.each do |grader|
          grader.should be_is_a(OpenStruct)
          grader.send(:table).keys.size.should eql(available_keys.size)
          available_keys.each {|k| grader.send(:table).keys.should be_include(k)}
          grader.grader_id.should be_is_a(Numeric)
          grader.assignments.should be_is_a(Array)
          grader.name.should be_is_a(String)
          grader.assignments[0].submissions[0].grader.should eql(grader.name)
          grader.assignments[0].submissions[0].grader_id.should eql(grader.grader_id)
        end
      end
    end

    it "should only keep one diff per grader per day" do
      SubmissionList.days(@course).each do |day|
        day.graders.each do |grader|
          grader.assignments.each do |assignment|
            assignment.submissions.length.should eql assignment.submissions.map(&:student_name).uniq.length
          end
        end
      end
    end
    
    it "should be able to loop on assignments" do
      available_keys = [:submission_count, :name, :submissions, :assignment_id]
      SubmissionList.days(@course).each do |day|
        day.graders.each do |grader|
          grader.assignments.each do |assignment|
            assignment.should be_is_a(OpenStruct)
            assignment.send(:table).keys.size.should eql(available_keys.size)
            available_keys.each {|k| assignment.send(:table).keys.should be_include(k)}
            assignment.submission_count.should eql(assignment.submissions.size)
            assignment.name.should be_is_a(String)
            assignment.name.should eql(assignment.submissions[0].assignment_name)
            assignment.submissions.should be_is_a(Array)
            assignment.assignment_id.should eql(assignment.submissions[0].assignment_id)
          end
        end
      end
    end
    
    it "should be able to loop on submissions" do
      available_keys = [
        :assignment_id, :assignment_name, :attachment_id, :attachment_ids,
        :body, :course_id, :created_at, :current_grade, :current_graded_at,
        :current_grader, :grade_matches_current_submission, :graded_at,
        :graded_on, :grader, :grader_id, :group_id, :id, :new_grade,
        :new_graded_at, :new_grader, :previous_grade, :previous_graded_at,
        :previous_grader, :process_attempts, :processed, :published_grade,
        :published_score, :safe_grader_id, :score, :student_entered_score,
        :student_user_id, :submission_id, :student_name, :submission_type,
        :updated_at, :url, :user_id, :workflow_state
      ]
      
      SubmissionList.days(@course).each do |day|
        day.graders.each do |grader|
          grader.assignments.each do |assignment|
            assignment.submissions.each do |submission|
              submission.should be_is_a(OpenStruct)
              submission.send(:table).keys.size.should eql(available_keys.size)
              available_keys.each {|k| submission.send(:table).keys.should be_include(k)}
            end
          end
        end
      end
    end
  
  end

  context "real data inspection" do
    before do
      course_model
      sl = SubmissionList.new(@course)
      @sort_block_for_filtering = sl.send(:sort_block_for_filtering)
      @sort_block_for_displaying = sl.send(:sort_block_for_displaying)
      @full_hash_list = YAML.load_file(
        File.expand_path(
          File.join(
            File.dirname(__FILE__),
            "..", 
            "fixtures", 
            "submission_list_full_hash_list.yml"
          )
        )
      )
      # def sort_block_for_filtering
      #   lambda{|a, b|
      #     tier_1 = a[:id] <=> b[:id]
      #     tier_2 = a[:updated_at] <=> b[:updated_at]
      #     tier_1 == 0 ? tier_2 : tier_1
      #   }
      # end
      # 
      # def sort_block_for_displaying
      #   lambda{|a, b|
      # 
      #     first_tier = if b[:graded_at] and a[:graded_at]
      #       b[:graded_at] <=> a[:graded_at]
      #     elsif b[:graded_at]
      #       1
      #     elsif a[:graded_at]
      #       -1
      #     else
      #       0
      #     end
      # 
      #     second_tier = a[:safe_grader_id] <=> b[:safe_grader_id]
      #     third_tier = a[:assignment_id] <=> b[:assignment_id]
      # 
      #     case first_tier
      #     when -1
      #       -1
      #     when 1
      #       1
      #     when 0
      #       case second_tier
      #       when -1
      #         -1
      #       when 1
      #         1
      #       when 0
      #         third_tier
      #       end
      #     end
      #   }
      # end
      
      
    end
    
    it "should be able to use a desctructive sort" do
      fhl = @full_hash_list.dup
      fhl.sort!(&@sort_block_for_displaying)
      fhl.should_not eql(@full_hash_list)
    end
    
    it "should order by id, then updated_at" do
    end
    
  end
end

def interesting_submission_list(opts={})
  interesting_submission_data(opts)
  @course.reload
  @sl = SubmissionList.new(@course)
end

def interesting_submission_data(opts={})
  opts[:grader] ||= {}
  opts[:user] ||= {}
  opts[:course] ||= {}
  opts[:assignment] ||= {}
  opts[:submission] ||= {}
  
  @grader = user_model({:name => 'some_grader'}.merge(opts[:grader]))
  @grader2 = user_model({:name => 'another_grader'}.merge(opts[:grader]))
  @student = factory_with_protected_attributes(User, {:name => "some student", :workflow_state => "registered"}.merge(opts[:user]))
  @course = factory_with_protected_attributes(Course, {:name => "some course", :workflow_state => "available"}.merge(opts[:course]))
  [@grader, @grader2].each do |grader|
    e = @course.enroll_teacher(grader)
    e.accept
  end
  @course.enroll_student(@student)
  @assignment = @course.assignments.new({
    :title => "some assignment", 
    :points_possible => 10
  }.merge(opts[:assignment]))
  @assignment.workflow_state = "published"
  @assignment.save!
  @assignment.grade_student(@student, {:grade => 1.5, :grader => @grader}.merge(opts[:submission]))
  @assignment.grade_student(@student, {:grade => 3, :grader => @grader}.merge(opts[:submission]))
  @assignment.grade_student(@student, {:grade => 5, :grader => @grader2}.merge(opts[:submission]))
  @student = user_model(:name => 'another student')
  @course.enroll_student(@student)
  @assignment.reload
  @assignment.grade_student(@student, {:grade => 8, :grader => @grader}.merge(opts[:submission]))
  @student = user_model(:name => 'smart student')
  @course.enroll_student(@student)
  @assignment.reload
  @assignment.grade_student(@student, {:grade => 10, :grader => @grader}.merge(opts[:submission]))
  @assignment = @course.assignments.create({
    :title => "another assignment", 
    :points_possible => 10
  })
  @assignment.workflow_state = "published"
  @assignment.save!
  @assignment.grade_student(@student, {:grade => 10, :grader => @grader}.merge(opts[:submission]))
end
