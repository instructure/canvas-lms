
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GradebookHistoryApiController do
  def json_body
    JSON.parse(response.body.split(';').last)
  end

  def date_key(submission)
    submission.graded_at.to_date.as_json
  end


  before do
    course_with_teacher_logged_in(:active_all => true)

    student = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)
    student_in_course(:user => student, :active_all => 1)
    student2 = user_with_pseudonym(:username => 'student2@example.com', :active_all => 1)
    student_in_course(:user => student2, :active_all => 1)
    student3 = user_with_pseudonym(:username => 'student3@example.com', :active_all => 1)
    student_in_course(:user => student3, :active_all => 1)

    @grader = user_with_pseudonym(:name => 'Grader', :username => 'grader@example.com', :active_all => 1)
    @super_grader = user_with_pseudonym(:name => 'SuperGrader', :username => 'super_grader@example.com', :active_all => 1)
    @other_grader = user_with_pseudonym(:name => 'OtherGrader', :username => 'other_grader@example.com', :active_all => 1)

    @assignment1 = @course.assignments.create!(:title => "some assignment")
    @assignment2 = @course.assignments.create!(:title => "another assignment")

    @submission1 = @assignment1.submit_homework(student)
    @submission2 = @assignment1.submit_homework(student2)
    @submission3 = @assignment1.submit_homework(student3)
    @submission4 = @assignment2.submit_homework(student)

    @submission1.update_attributes!(:graded_at => Time.now, :grader_id => @grader.id, :score => 100)
    @submission2.update_attributes!(:graded_at => Time.now, :grader_id => @super_grader.id, :score => 90)
    @submission3.update_attributes!(:graded_at => (Time.now - 24.hours), :grader_id => @other_grader.id, :score => 80)
    @submission4.update_attributes!(:graded_at => (Time.now - 24.hours), :grader_id => @other_grader.id, :score => 70)
  end

  describe 'GET days' do

    def graders_hash_for(submission)
      json_body.select{|d| d['date'] == date_key(submission) }.first['graders']
    end

    describe 'default params' do

      before { get 'days', :course_id => @course.id, :format => 'json' }

      it 'provides an array of the dates where there are submissions' do
        json_body.map{ |d| d['date'] }.sort.should == [date_key(@submission1), date_key(@submission3)].sort
      end

      it 'nests all the graders for a day inside the date entry' do
        graders_hash_for(@submission1).map{|g| g['name'] }.sort.should == ['Grader', 'SuperGrader']
        graders_hash_for(@submission3).map{|g| g['name'] }.should == ['OtherGrader']
      end

      it 'includes a list of assignment names for each grader' do
        grader_hash = graders_hash_for(@submission3).select{|h| h['id'] == @other_grader.id }.first
        grader_hash['assignments'].map{|a| a['name'] }.sort.should == ['some assignment', 'another assignment'].sort
      end
    end

    it 'paginates' do
      old_grader = User.create!
      two_days_ago = 48.hours.ago
      25.times do |i|
        student = user_with_pseudonym(:username => "student-history-#{i}@example.com", :active_all => 1)
        student_in_course(:user => student, :active_all => 1)
        submission = @assignment1.submit_homework(student)
        submission.update_attributes!(:graded_at => two_days_ago, :grader_id => old_grader.id)
      end

      get 'days', :course_id => @course.id, :format => 'json', :page => 2
      json_body.map{|d| d['date'] }.should == [two_days_ago.to_date.as_json]
    end
  end

  describe 'GET day_details' do
    before { get 'day_details', :course_id => @course.id, :format => 'json', :date => @submission1.graded_at.strftime('%Y-%m-%d') }

    it 'has the graders as the top level piece of data' do
      json_body.map{|g| g['id'] }.sort.should == [@grader.id, @super_grader.id].sort
    end

    it 'lists assignment names under the graders' do
      json_body.select{|g| g['id'] == @grader.id }.first['assignments'].first['name'].should == @assignment1.title
    end
  end

  describe 'GET assignment' do
    let(:date) { @submission1.graded_at.strftime('%Y-%m-%d') }
    let(:params) { { :course_id => @course.id, :date => date, :grader_id => @grader.id, :assignment_id => @assignment1.id } }

    before { get( 'submissions', { :format => 'json' }.merge(params) ) }

    it 'lists submissions' do
      json_body.first['submission_id'].should == @submission1.id
      json_body.first['versions'].first['score'].should == 100
    end
  end
end
