require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe GradebookHistoryApiController, type: :request do
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

      submission1 = bare_submission_model(assignment1, student, :graded_at => Time.now.in_time_zone, :grader_id => grader.id, :score => 100)
      submission2 = bare_submission_model(assignment1, student2, :graded_at => Time.now.in_time_zone, :grader_id => super_grader.id, :score => 90)
      submission3 = bare_submission_model(assignment1, student3, :graded_at => (Time.now - 24.hours).in_time_zone, :grader_id => other_grader.id, :score => 80)
      submission4 = bare_submission_model(assignment2, student, :graded_at => (Time.now - 24.hours).in_time_zone, :grader_id => other_grader.id, :score => 70)

      json = api_call_as_user(@teacher, :get,
          "/api/v1/courses/#{@course.id}/gradebook_history/days.json",
          {
            :controller => 'gradebook_history_api',
            :action => 'days',
            :format => 'json',
            :course_id => @course.id.to_s
          })

      expect(json.first.keys.sort).to eq ['date', 'graders']
    end
  end

  describe 'GET /courses/:course_id/gradebook_history/:date' do
    it 'routes the request correctly and returns decent data' do
      course_with_teacher(:active_all => true)

      student = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)
      student_in_course(:user => student, :active_all => 1)

      grader = user_with_pseudonym(:name => 'Grader', :username => 'grader@example.com', :active_all => 1)

      assignment = @course.assignments.create!(:title => "some assignment")

      submission = bare_submission_model(assignment, student, :graded_at => Time.now.in_time_zone, :grader_id => grader.id, :score => 100)

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

      expect(json.first["name"]).to eq "Grader"
    end

  end

  describe 'GET /courses/:course_id/gradebook_history/:date/graders/:grader_id/assignments/:assignment_id/submissions' do
    let(:date) { Time.now.in_time_zone }
    let(:date_string) { date.strftime('%Y-%m-%d') }

    before :once do
      course_with_teacher(:active_all => true)
      @student = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)
      student_in_course(:user => @student, :active_all => 1)
      @assignment = @course.assignments.create!(:title => "some assignment")
      @submission = bare_submission_model(@assignment, @student)
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

      expect(json.first['submission_id']).to eq @submission.id
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

      expect(json.first['submission_id']).to eq @submission.id
    end
  end

  describe 'GET /courses/:course_id/gradebook_history/feed' do
    before :once do
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

    def create_versions
      @submission1.with_versioning(:explicit => true) {
        @submission1.update_attributes!(:graded_at => Time.zone.now, :grader_id => @grader.id, :score => 100) }
      @submission2.with_versioning(:explicit => true) {
        @submission2.update_attributes!(:graded_at => Time.zone.now, :grader_id => @super_grader.id, :score => 90) }
      @submission3.with_versioning(:explicit => true) {
        @submission3.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 80) }
      @submission4.with_versioning(:explicit => true) {
        @submission4.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 70) }
    end

    it 'should return all applicable versions' do
      create_versions

      expect(api_call_as_user(@teacher, :get, "/api/v1/courses/#{@course.id}/gradebook_history/feed.json", {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s
      }).size).to eq 8
    end

    it 'should paginate the versions' do
      create_versions

      expect(api_call_as_user(@teacher, :get, "/api/v1/courses/#{@course.id}/gradebook_history/feed.json?per_page=5", {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s,
        :per_page => '5'
      }).size).to eq 5

      links = Api.parse_pagination_links(response.headers['Link'])
      next_link = links.index_by{ |link| link[:rel] }["next"]

      expect(api_call_as_user(@teacher, :get, next_link[:uri].to_s, {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s,
        :context_id => @course.id.to_s,
        :context_type => 'Course',
        :page => '2',
        :per_page => '5'
      }).size).to eq 3
    end

    it 'should order the most recent versions first' do
      @submission3.with_versioning(:explicit => true) {
        @submission3.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 80)
      }

      json = api_call_as_user(@teacher, :get, "/api/v1/courses/#{@course.id}/gradebook_history/feed.json", {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s
      }).first

      expect(json["id"]).to eq @submission3.id
      expect(json["grade"]).to eq @submission3.grade
      expect(json["grader_id"]).to eq @other_grader.id
    end

    it 'should optionally restrict by assignment_id' do
      @submission4.with_versioning(:explicit => true) {
        @submission4.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 70)
      }

      json = api_call_as_user(@teacher, :get, "/api/v1/courses/#{@course.id}/gradebook_history/feed.json?assignment_id=#{@assignment2.id}", {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s,
        :assignment_id => @assignment2.id.to_s
      })

      expect(json.size).to eq 2
      json.each{ |entry| expect(entry["assignment_id"]).to eq @assignment2.id }
    end

    it 'should optionally restrict by user_id' do
      @submission4.with_versioning(:explicit => true) {
        @submission4.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 70)
      }

      json = api_call_as_user(@teacher, :get, "/api/v1/courses/#{@course.id}/gradebook_history/feed.json?user_id=#{@student1.id}", {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s,
        :user_id => @student1.id.to_s
      })

      expect(json.size).to eq 3
      json.each{ |entry| expect(entry["user_id"]).to eq @student1.id }
    end

    it 'should optionally reverse ordering to oldest version first' do
      @submission3.with_versioning(:explicit => true) {
        @submission3.update_attributes!(:graded_at => 24.hours.ago, :grader_id => @other_grader.id, :score => 80)
      }

      json = api_call_as_user(@teacher, :get, "/api/v1/courses/#{@course.id}/gradebook_history/feed.json?ascending=1", {
        :controller => 'gradebook_history_api',
        :action => 'feed',
        :format => 'json',
        :course_id => @course.id.to_s,
        :ascending => '1'
      }).first

      expect(json["id"]).to eq @submission1.id
      expect(json["grade"]).to be_nil
      expect(json["grader_id"]).to be_nil
    end
  end
end
