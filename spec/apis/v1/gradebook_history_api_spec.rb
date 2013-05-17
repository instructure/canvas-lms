require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe GradebookHistoryApiController, :type => :integration do
  include Api

  describe 'GET /courses/:course_id/gradebook_history/days' do
    it 'returns the array of days' do
      course_with_teacher(:active_all => true)

      student = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)
      student_in_course(:user => student, :active_all => 1)
      student2 = user_with_pseudonym(:username => 'student2@example.com', :active_all => 1)
      student_in_course(:user => student2, :active_all => 1)
      student3 = user_with_pseudonym(:username => 'student3@example.com', :active_all => 1)
      student_in_course(:user => student3, :active_all => 1)

      grader = user_with_pseudonym(:name => 'Grader', :username => 'grader@example.com', :active_all => 1)
      super_grader = user_with_pseudonym(:name => 'SuperGrader', :username => 'super_grader@example.com', :active_all => 1)
      other_grader = user_with_pseudonym(:name => 'OtherGrader', :username => 'other_grader@example.com', :active_all => 1)

      assignment1 = @course.assignments.create!(:title => "some assignment")
      assignment2 = @course.assignments.create!(:title => "another assignment")

      submission1 = assignment1.submit_homework(student)
      submission2 = assignment1.submit_homework(student2)
      submission3 = assignment1.submit_homework(student3)
      submission4 = assignment2.submit_homework(student)

      submission1.update_attributes!(:graded_at => Time.now.in_time_zone, :grader_id => grader.id, :score => 100)
      submission2.update_attributes!(:graded_at => Time.now.in_time_zone, :grader_id => super_grader.id, :score => 90)
      submission3.update_attributes!(:graded_at => (Time.now - 24.hours).in_time_zone, :grader_id => other_grader.id, :score => 80)
      submission4.update_attributes!(:graded_at => (Time.now - 24.hours).in_time_zone, :grader_id => other_grader.id, :score => 70)

      json = api_call_as_user(@teacher, :get,
          "/api/v1/courses/#{@course.id}/gradebook_history/days.json",
          {
            :controller => 'gradebook_history_api',
            :action => 'days',
            :format => 'json',
            :course_id => @course.id.to_s
          })

      json.first.keys.sort.should == ['date', 'graders']
    end
  end

  describe 'GET /courses/:course_id/gradebook_history/:date' do
    it 'routes the request correctly and returns decent data' do
      course_with_teacher(:active_all => true)

      student = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)
      student_in_course(:user => student, :active_all => 1)

      grader = user_with_pseudonym(:name => 'Grader', :username => 'grader@example.com', :active_all => 1)

      assignment = @course.assignments.create!(:title => "some assignment")

      submission = assignment.submit_homework(student)

      submission.update_attributes!(:graded_at => Time.now.in_time_zone, :grader_id => grader.id, :score => 100)

      date = Time.now.in_time_zone.strftime('%Y-%m-%d')
      json = api_call_as_user(@teacher, :get,
            "/api/v1/courses/#{@course.id}/gradebook_history/#{date}.json",
            {
              :controller => 'gradebook_history_api',
              :action => 'day_details',
              :format => 'json',
              :course_id => @course.id.to_s,
              :date=>date
            })

      json.first["name"].should == "Grader"
    end

  end

  describe 'GET /courses/:course_id/gradebook_history/:date/graders/:grader_id/assignments/:assignment_id/submissions' do
    let(:date) { Time.now.in_time_zone }
    let(:date_string) { date.strftime('%Y-%m-%d') }

    before do
      course_with_teacher(:active_all => true)
      @student = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)
      student_in_course(:user => @student, :active_all => 1)
      @assignment = @course.assignments.create!(:title => "some assignment")
      @submission = @assignment.submit_homework(@student)
    end

    it 'routes properly and returns reasonable data' do
      grader = user_with_pseudonym(:name => 'Grader', :username => 'grader@example.com', :active_all => 1)
      @submission.update_attributes!(:graded_at => date, :grader_id => grader.id, :score => 100)

      json = api_call_as_user(@teacher, :get,
            "/api/v1/courses/#{@course.id}/gradebook_history/#{date_string}/graders/#{grader.id}/assignments/#{@assignment.id}/submissions.json",
            {
              :controller => 'gradebook_history_api',
              :action => 'submissions',
              :format => 'json',
              :course_id => @course.id.to_s,
              :date => date_string,
              :grader_id => grader.id.to_s,
              :assignment_id => @assignment.id.to_s
            })

      json.first['submission_id'].should == @submission.id
    end

    it 'can find autograded data' do
      @submission.update_attributes!(:graded_at => date, :grader_id => -50, :score => 100)

      json = api_call_as_user(@teacher, :get,
            "/api/v1/courses/#{@course.id}/gradebook_history/#{date_string}/graders/0/assignments/#{@assignment.id}/submissions.json",
            {
              :controller => 'gradebook_history_api',
              :action => 'submissions',
              :format => 'json',
              :course_id => @course.id.to_s,
              :date => date_string,
              :grader_id => '0',
              :assignment_id => @assignment.id.to_s
            })

      json.first['submission_id'].should == @submission.id
    end
  end

  describe 'GET /courses/:course_id/gradebook_history/feed' do
    before do
      course_with_teacher(:active_all => true)

      @student1 = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)
      student_in_course(:user => @student1, :active_all => 1)
      @student2 = user_with_pseudonym(:username => 'student2@example.com', :active_all => 1)
      student_in_course(:user => @student2, :active_all => 1)
      @student3 = user_with_pseudonym(:username => 'student3@example.com', :active_all => 1)
      student_in_course(:user => @student3, :active_all => 1)

      @grader = user_with_pseudonym(:name => 'Grader', :username => 'grader@example.com', :active_all => 1)
      @super_grader = user_with_pseudonym(:name => 'SuperGrader', :username => 'super_grader@example.com', :active_all => 1)
      @other_grader = user_with_pseudonym(:name => 'OtherGrader', :username => 'other_grader@example.com', :active_all => 1)

      @assignment1 = @course.assignments.create!(:title => "some assignment")
      @assignment2 = @course.assignments.create!(:title => "another assignment")

      @submission1 = @assignment1.submit_homework(@student1)
      @submission2 = @assignment1.submit_homework(@student2)
      @submission3 = @assignment1.submit_homework(@student3)
      @submission4 = @assignment2.submit_homework(@student1)
    end

    it 'should return submission version API objects' do
      @submission4.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 70)

      json = api_call_as_user(@teacher, :get, "/api/v1/courses/#{@course.id}/gradebook_history/feed.json", {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s
      }).first

      json.keys.sort.should == ["assignment_id", "assignment_name", "attempt", "body", "current_grade", "current_graded_at", "current_grader", "grade", "grade_matches_current_submission", "graded_at", "grader", "grader_id", "id", "late", "preview_url", "score", "submission_type", "submitted_at", "url", "user_id", "user_name", "workflow_state"]
    end

    it 'should return all applicable versions' do
      @submission1.update_attributes!(:graded_at => Time.zone.now, :grader_id => @grader.id, :score => 100)
      @submission2.update_attributes!(:graded_at => Time.zone.now, :grader_id => @super_grader.id, :score => 90)
      @submission3.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 80)
      @submission4.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 70)

      api_call_as_user(@teacher, :get, "/api/v1/courses/#{@course.id}/gradebook_history/feed.json", {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s
      }).size.should == 8
    end

    it 'should paginate the versions' do
      @submission1.update_attributes!(:graded_at => Time.zone.now, :grader_id => @grader.id, :score => 100)
      @submission2.update_attributes!(:graded_at => Time.zone.now, :grader_id => @super_grader.id, :score => 90)
      @submission3.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 80)
      @submission4.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 70)

      api_call_as_user(@teacher, :get, "/api/v1/courses/#{@course.id}/gradebook_history/feed.json?per_page=5", {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s,
        :per_page => '5'
      }).size.should == 5

      links = Api.parse_pagination_links(response.headers['Link'])
      next_link = links.index_by{ |link| link[:rel] }["next"]

      api_call_as_user(@teacher, :get, next_link[:uri].to_s, {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s,
        :context_id => @course.id.to_s,
        :context_type => 'Course',
        :page => '2',
        :per_page => '5'
      }).size.should == 3
    end

    it 'should order the most recent versions first' do
      @submission3.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 80)

      json = api_call_as_user(@teacher, :get, "/api/v1/courses/#{@course.id}/gradebook_history/feed.json", {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s
      }).first

      json["id"].should == @submission3.id
      json["grade"].should == @submission3.grade
      json["grader_id"].should == @other_grader.id
    end

    it 'should optionally restrict by assignment_id' do
      @submission4.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 70)

      json = api_call_as_user(@teacher, :get, "/api/v1/courses/#{@course.id}/gradebook_history/feed.json?assignment_id=#{@assignment2.id}", {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s,
        :assignment_id => @assignment2.id.to_s
      })

      json.size.should == 2
      json.each{ |entry| entry["assignment_id"].should == @assignment2.id }
    end

    it 'should optionally restrict by user_id' do
      @submission4.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 70)

      json = api_call_as_user(@teacher, :get, "/api/v1/courses/#{@course.id}/gradebook_history/feed.json?user_id=#{@student1.id}", {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s,
        :user_id => @student1.id.to_s
      })

      json.size.should == 3
      json.each{ |entry| entry["user_id"].should == @student1.id }
    end

    it 'should optionally reverse ordering to oldest version first' do
      @submission3.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 80)

      json = api_call_as_user(@teacher, :get, "/api/v1/courses/#{@course.id}/gradebook_history/feed.json?ascending=1", {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s,
        :ascending => '1'
      }).first

      json["id"].should == @submission1.id
      json["grade"].should be_nil
      json["grader_id"].should be_nil
    end
  end
end
