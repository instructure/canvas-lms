require 'spec_helper'

describe Assignment::SpeedGrader do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true, user_name: "some user")
  end

  context "create and publish a course with 2 students" do
    let_once(:student_A) do
      course_with_student(course: @course, user_name: "Student A")
      @student
    end
    let_once(:student_B) do
      course_with_student(course: @course, user_name: "Student B")
      @student
    end
    let_once(:teacher) do
      course_with_teacher(course: @course, user_name: "an teacher")
      @teacher
    end

    context "add students to the group" do
      let(:category) { @course.group_categories.create! name: "Assignment Groups" }
      let(:assignment) do
        @course.assignments.create!(
                                    group_category_id: category.id,
                                    grade_group_students_individually: false,
                                    submission_types: %w(text_entry)
                                    )
      end
      let(:homework_params) do
        {
          submission_type: 'online_text_entry',
          body: 'blah',
          comment: 'a group comment during submission from student A',
          group_comment: true
        }.freeze
      end
      let(:comment_two_to_group_params) do
        {
          comment: 'a group comment from student A',
          user_id:  student_A.id,
          group_comment: true
        }.freeze
      end
      let(:comment_three_to_group_params) do
        {
          comment: 'a group comment from student B',
          user_id:  student_B.id,
          group_comment: true
        }.freeze
      end
      let(:comment_four_private_params) do
        {
          comment: 'a private comment from student A',
          user_id:  student_A.id,
        }.freeze
      end
      let(:comment_five_private_params) do
        {
          comment: 'a private comment from student B',
          user_id:  student_B.id,
        }.freeze
      end
      let(:comment_six_to_group_params) do
        {
          comment: 'a group comment from teacher',
          user_id:  teacher.id,
          group_comment: true
        }.freeze
      end
      let(:comment_seven_private_params) do
        {
          comment: 'a private comment from teacher',
          user_id:  teacher.id,
        }.freeze
      end

      before do
        group = category.groups.create!(name: 'a group', context: @course)
        group.add_user(student_A)
        group.add_user(student_B)
        assignment.submit_homework(student_A, homework_params.dup)
        assignment.update_submission(student_A, comment_two_to_group_params.dup)
        assignment.update_submission(student_A, comment_three_to_group_params.dup)
        assignment.update_submission(student_A, comment_four_private_params.dup)
        assignment.update_submission(student_A, comment_five_private_params.dup)
        assignment.update_submission(student_A, comment_six_to_group_params.dup)
        assignment.update_submission(student_A, comment_seven_private_params.dup)
      end

      it "only shows group comments" do
        json = Assignment::SpeedGrader.new(assignment, teacher).json
        comments = json.fetch(:submissions).first.fetch(:submission_comments).map do |comment|
          comment.slice(:author_id, :comment)
        end
        expect(comments).to include({
          "author_id" => student_A.id,
          "comment" => homework_params.fetch(:comment)
        },{
          "author_id" => comment_two_to_group_params.fetch(:user_id),
          "comment" => comment_two_to_group_params.fetch(:comment)
        },{
          "author_id" => comment_three_to_group_params.fetch(:user_id),
          "comment" => comment_three_to_group_params.fetch(:comment)
        },{
          "author_id" => comment_six_to_group_params.fetch(:user_id),
          "comment" => comment_six_to_group_params.fetch(:comment)
        })
        expect(comments).not_to include({
          "author_id" => comment_four_private_params.fetch(:user_id),
          "comment" => comment_four_private_params.fetch(:comment)
        },{
          "author_id" => comment_five_private_params.fetch(:user_id),
          "comment" => comment_five_private_params.fetch(:comment)
        },{
          "author_id" => comment_seven_private_params.fetch(:user_id),
          "comment" => comment_seven_private_params.fetch(:comment)
      })
      end
    end
  end

  it "includes comments' created_at" do
    setup_assignment_with_homework
    @submission = @assignment.submissions.first
    @comment = @submission.add_comment(:comment => 'comment')
    json = Assignment::SpeedGrader.new(@assignment, @user).json
    expect(json[:submissions].first[:submission_comments].first[:created_at].to_i).to eql @comment.created_at.to_i
  end

  it "excludes provisional comments" do
    setup_assignment_with_homework
    @submission = @assignment.submissions.first
    @comment = @submission.add_comment(:comment => 'comment', :provisional => true)
    json = Assignment::SpeedGrader.new(@assignment, @user).json
    expect(json[:submissions].first[:submission_comments]).to be_empty
  end

  context "students and active course sections" do
    before(:once) do
      @course = course(:active_course => true)
      @teacher, @student1, @student2 = (1..3).map{User.create}
      @assignment = Assignment.create!(title: "title", context: @course, only_visible_to_overrides: true)
      @course.enroll_teacher(@teacher)
      @course.enroll_student(@student2, :enrollment_state => 'active')
      @section1 = @course.course_sections.create!(name: "test section 1")
      @section2 = @course.course_sections.create!(name: "test section 2")
      student_in_section(@section1, user: @student1)
      create_section_override_for_assignment(@assignment, {course_section: @section1})
    end

    it "includes only students and sections with overrides for differentiated assignments" do
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json

      expect(json[:context][:students].map{|s| s[:id]}.include?(@student1.id)).to be_truthy
      expect(json[:context][:students].map{|s| s[:id]}.include?(@student2.id)).to be_falsey
      expect(json[:context][:active_course_sections].map{|cs| cs[:id]}.include?(@section1.id)).to be_truthy
      expect(json[:context][:active_course_sections].map{|cs| cs[:id]}.include?(@section2.id)).to be_falsey
    end

    it "includes all students when is only_visible_to_overrides false" do
      @assignment.only_visible_to_overrides = false
      @assignment.save!
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json

      expect(json[:context][:students].map{|s| s[:id]}.include?(@student1.id)).to be_truthy
      expect(json[:context][:students].map{|s| s[:id]}.include?(@student2.id)).to be_truthy
      expect(json[:context][:active_course_sections].map{|cs| cs[:id]}.include?(@section1.id)).to be_truthy
      expect(json[:context][:active_course_sections].map{|cs| cs[:id]}.include?(@section2.id)).to be_truthy
    end
  end

  it "returns submission lateness" do
    # Set up
    section_1 = @course.course_sections.create!(:name => 'Section one')
    section_2 = @course.course_sections.create!(:name => 'Section two')

    assignment = @course.assignments.create!(:title => 'Overridden assignment', :due_at => Time.now - 5.days)

    student_1 = user_with_pseudonym(:active_all => true, :username => 'student1@example.com')
    student_2 = user_with_pseudonym(:active_all => true, :username => 'student2@example.com')

    @course.enroll_student(student_1, :section => section_1).accept!
    @course.enroll_student(student_2, :section => section_2).accept!

    o1 = assignment.assignment_overrides.build
    o1.due_at = Time.now - 2.days
    o1.due_at_overridden = true
    o1.set = section_1
    o1.save!

    o2 = assignment.assignment_overrides.build
    o2.due_at = Time.now + 2.days
    o2.due_at_overridden = true
    o2.set = section_2
    o2.save!

    submission_1 = assignment.submit_homework(student_1, :submission_type => 'online_text_entry', :body => 'blah')
    submission_2 = assignment.submit_homework(student_2, :submission_type => 'online_text_entry', :body => 'blah')

    # Test
    json = Assignment::SpeedGrader.new(assignment, @teacher).json
    json[:submissions].each do |submission|
      user = [student_1, student_2].detect { |s| s.id == submission[:user_id] }
      expect(submission[:late]).to eq user.submissions.first.late?
    end
  end

  it "includes inline view pingback url for files" do
    assignment = @course.assignments.create! :submission_types => ['online_upload']
    attachment = @student.attachments.create! :uploaded_data => dummy_io, :filename => 'doc.doc', :display_name => 'doc.doc', :context => @student
    submission = assignment.submit_homework @student, :submission_type => :online_upload, :attachments => [attachment]
    json = Assignment::SpeedGrader.new(assignment, @teacher).json
    attachment_json = json['submissions'][0]['submission_history'][0]['submission']['versioned_attachments'][0]['attachment']
    expect(attachment_json['view_inline_ping_url']).to match %r{/users/#{@student.id}/files/#{attachment.id}/inline_view\z}
  end

  context "group assignments" do
    before :once do
      course_with_teacher(active_all: true)
      @gc = @course.group_categories.create! name: "Assignment Groups"
      @groups = 2.times.map { |i| @gc.groups.create! name: "Group #{i}", context: @course }
      students = create_users_in_course(@course, 6, return_type: :record)
      students.each_with_index { |s, i| @groups[i % @groups.size].add_user(s) }
      @assignment = @course.assignments.create!(
        group_category_id: @gc.id,
        grade_group_students_individually: false,
        submission_types: %w(text_entry)
      )
    end

    it "is not in group mode for non-group assignments" do
      setup_assignment_with_homework
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json
      expect(json["GROUP_GRADING_MODE"]).not_to be_truthy
    end

    it 'returns "groups" instead of students' do
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json
      @groups.each do |group|
        j = json["context"]["students"].find { |g| g["name"] == group.name }
        expect(group.users.map(&:id)).to include j["id"]
      end
      expect(json["GROUP_GRADING_MODE"]).to be_truthy
    end

    it 'chooses the student with turnitin data to represent' do
      turnitin_submissions = @groups.map do |group|
        rep = group.users.shuffle.first
        turnitin_submission, *others = @assignment.grade_student(rep, grade: 10)
        turnitin_submission.update_attribute :turnitin_data, {blah: 1}
        turnitin_submission
      end

      @assignment.update_attribute :turnitin_enabled, true
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json

      expect(json["submissions"].map { |s|
        s["id"]
      }.sort).to eq turnitin_submissions.map(&:id).sort
    end

    it 'prefers people with submissions' do
      g1, _ = @groups
      @assignment.grade_student(g1.users.first, score: 10)
      g1rep = g1.users.shuffle.first
      s = @assignment.submission_for_student(g1rep)
      s.update_attribute :submission_type, 'online_upload'
      expect(@assignment.representatives(@teacher)).to include g1rep
    end

    it "prefers people who aren't excused when submission exists" do
      g1, _ = @groups
      g1rep, *others = g1.users.to_a.shuffle
      @assignment.submit_homework(g1rep, {
        submission_type: 'online_text_entry',
        body: 'hi'
      })
      others.each { |u| @assignment.grade_student(u, excuse: true) }
      expect(@assignment.representatives(@teacher)).to include g1rep
    end

    it "includes users who aren't in a group" do
      student_in_course active_all: true
      expect(@assignment.representatives(@teacher).last).to eq @student
    end

    it "doesn't include deleted groups" do
      student_in_course active_all: true
      deleted_group = @gc.groups.create! name: "DELETE ME", context: @course
      deleted_group.add_user(@student)
      rep_names = @assignment.representatives(@teacher).map(&:name)
      expect(rep_names).to include "DELETE ME"

      deleted_group.destroy
      rep_names = @assignment.representatives(@teacher).map(&:name)
      expect(rep_names).not_to include "DELETE ME"
    end

    it 'prefers active users over other workflow states' do
      group = @groups.first
      enrollments = group.all_real_student_enrollments
      enrollments[0].deactivate
      enrollments[1].conclude

      reps = @assignment.representatives(@teacher, includes: [:inactive, :completed])
      user = reps.select { |u| u.name == group.name }.first
      expect(user.id).to eql(enrollments[2].user_id)
    end

    it 'prefers inactive users when no active users are present' do
      group = @groups.first
      enrollments = group.all_real_student_enrollments
      enrollments[0].conclude
      enrollments[1].deactivate
      enrollments[2].conclude

      reps = @assignment.representatives(@teacher, includes: [:inactive, :completed])
      user = reps.select { |u| u.name == group.name }.first
      expect(user.id).to eql(enrollments[1].user_id)
    end

    it 'includes concluded students when included' do
      group = @groups.first
      enrollments = group.all_real_student_enrollments
      enrollments.each(&:conclude)

      reps = @assignment.representatives(@teacher, includes: [:completed])
      user = reps.select { |u| u.name == group.name }.first
      expect(user.id).to eql(enrollments[0].user_id)
    end

    it 'does not include concluded students when included' do
      group = @groups.first
      enrollments = group.all_real_student_enrollments
      enrollments.each(&:conclude)

      reps = @assignment.representatives(@teacher, includes: [])
      user = reps.select { |u| u.name == group.name }.first
      expect(user).to be_nil
    end

    it 'includes inactive students when included' do
      group = @groups.first
      enrollments = group.all_real_student_enrollments
      enrollments.each(&:deactivate)

      reps = @assignment.representatives(@teacher, includes: [:inactive])
      user = reps.select { |u| u.name == group.name }.first
      expect(user.id).to eql(enrollments[0].user_id)
    end

    it 'does not include inactive students when included' do
      group = @groups.first
      enrollments = group.all_real_student_enrollments
      enrollments.each(&:deactivate)

      reps = @assignment.representatives(@teacher, includes: [])
      user = reps.select { |u| u.name == group.name }.first
      expect(user).to be_nil
    end
  end

  context "quizzes" do
    it "works for quizzes without quiz_submissions" do
      quiz = @course.quizzes.create! :title => "Final",
                                     :quiz_type => "assignment"
      quiz.did_edit
      quiz.offer

      assignment = quiz.assignment
      assignment.grade_student(@student, grade: 1)
      json = Assignment::SpeedGrader.new(assignment, @teacher).json
      expect(json[:submissions].all? { |s|
        s.has_key? 'submission_history'
      }).to be_truthy
    end

    context "with quiz_submissions" do
      before :once do
        quiz_with_graded_submission [], :course => @course, :user => @student
      end

      it "doesn't include quiz_submissions when there are too many attempts" do
        Setting.set('too_many_quiz_submission_versions', 3)
        3.times {
          @quiz_submission.versions.create!
        }
        json = Assignment::SpeedGrader.new(@quiz.assignment, @teacher).json
        json[:submissions].all? { |s| expect(s["submission_history"].size).to eq 1 }
      end

      it "returns quiz lateness correctly" do
        @quiz.time_limit = 10
        @quiz.save!

        json = Assignment::SpeedGrader.new(@assignment, @teacher).json
        expect(json[:submissions].first['submission_history'].first[:submission]['late']).to be_falsey

        @quiz.due_at = 1.day.ago
        @quiz.save!

        json = Assignment::SpeedGrader.new(@assignment, @teacher).json
        expect(json[:submissions].first['submission_history'].first[:submission]['late']).to be_truthy
      end

      it "returns quiz history for records before and after namespace change" do
        @quiz.save!

        json = Assignment::SpeedGrader.new(@assignment, @teacher).json
        expect(json[:submissions].first['submission_history'].size).to eq 1

        Version.where("versionable_type = 'QuizSubmission'").update_all("versionable_type = 'Quizzes::QuizSubmission'")
        json = Assignment::SpeedGrader.new(@assignment.reload, @teacher).json
        expect(json[:submissions].first['submission_history'].size).to eq 1
      end
    end
  end

  describe "with moderated grading" do
    before(:once) do
      course_with_ta(:course => @course, :active_all => true)
      assignment_model(:course => @course, :submission_types => 'online_text_entry')
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)

      @submission = @assignment.submit_homework(@student, :submission_type => 'online_text_entry', :body => 'ahem')
      @assignment.update_submission(@student, :comment => 'real comment', :score => 1, :commenter => @student)

      selection = @assignment.moderated_grading_selections.create!(:student => @student)

      @submission.add_comment(:author => @teacher, :comment => 'provisional comment', :provisional => true)
      teacher_pg = @submission.provisional_grade(@teacher)
      teacher_pg.update_attribute(:score, 2)
      @association.assess(
        :user => @student, :assessor => @teacher, :artifact => teacher_pg,
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => 2,
            :comments => 'a comment',
          }
        })

      selection.provisional_grade = teacher_pg
      selection.save!

      @submission.add_comment(:author => @ta, :comment => 'other provisional comment', :provisional => true)
      ta_pg = @submission.provisional_grade(@ta)
      ta_pg.update_attribute(:score, 3)
      @association.assess(
        :user => @student, :assessor => @ta, :artifact => ta_pg,
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => 3,
            :comments => 'a comment',
          }
        })

      @other_student = user(:active_all => true)
      student_in_course(:course => @course, :user => @other_student, :active_all => true)
    end

    it "returns submission comments with null provisional grade" do
      course_with_ta :course => @course, :active_all => true
      json = Assignment::SpeedGrader.new(@assignment, @ta, :grading_role => :provisional_grader).json
      expect(json['submissions'][0]['submission_comments'].map { |comment| comment['comment'] }).to match_array ['real comment']
    end

    describe "for provisional grader" do
      before(:once) do
        @json = Assignment::SpeedGrader.new(@assignment, @ta, :grading_role => :provisional_grader).json
      end

      it "includes only the grader's provisional grades" do
        expect(@json['submissions'][0]['score']).to eq 3
        expect(@json['submissions'][0]['provisional_grades']).to be_nil
      end

      it "includes only the grader's provisional comments (and the real ones)" do
        expect(@json['submissions'][0]['submission_comments'].map { |comment| comment['comment'] }).to match_array ['other provisional comment', 'real comment']
      end

      it "only includes the grader's provisional rubric assessments" do
        ras = @json['context']['students'][0]['rubric_assessments']
        expect(ras.count).to eq 1
        expect(ras[0]['assessor_id']).to eq @ta.id
      end

      it "determines whether the student needs a provisional grade" do
        expect(@json['context']['students'][0]['needs_provisional_grade']).to be_falsey
        expect(@json['context']['students'][1]['needs_provisional_grade']).to be_truthy # other student
      end
    end

    describe "for moderator" do
      before(:once) do
        @json = Assignment::SpeedGrader.new(@assignment, @teacher, :grading_role => :moderator).json
      end

      it "includes the moderator's provisional grades and comments" do
        expect(@json['submissions'][0]['score']).to eq 2
        expect(@json['submissions'][0]['submission_comments'].map { |comment| comment['comment'] }).to match_array ['provisional comment', 'real comment']
      end

      it "includes the moderator's provisional rubric assessments" do
        ras = @json['context']['students'][0]['rubric_assessments']
        expect(ras.count).to eq 1
        expect(ras[0]['assessor_id']).to eq @teacher.id
      end

      it "lists all provisional grades" do
        pgs = @json['submissions'][0]['provisional_grades']
        expect(pgs.size).to eq 2
        expect(pgs.map { |pg| [pg['score'], pg['scorer_id'], pg['submission_comments'].map{|c| c['comment']}.sort] }).to match_array(
          [
            [2.0, @teacher.id, ["provisional comment", "real comment"]],
            [3.0, @ta.id, ["other provisional comment", "real comment"]]
          ]
        )
      end

      it "includes all the other provisional rubric assessments in their respective grades" do
        ta_pras = @json['submissions'][0]['provisional_grades'][1]['rubric_assessments']
        expect(ta_pras.count).to eq 1
        expect(ta_pras[0]['assessor_id']).to eq @ta.id
      end

      it "includes whether the provisional grade is selected" do
        expect(@json['submissions'][0]['provisional_grades'][0]['selected']).to be_truthy
        expect(@json['submissions'][0]['provisional_grades'][1]['selected']).to be_falsey
      end
    end
  end

  context "honoring gradebook preferences" do
    let_once(:test_course) do
      test_course = course(active_course: true)
      test_course.enroll_teacher(teacher, enrollment_state: 'active')
      test_course.enroll_student(active_student, enrollment_state: 'active')
      test_course.enroll_student(inactive_student, enrollment_state: 'inactive')
      test_course.enroll_student(concluded_student, enrollment_state: 'completed')
      test_course
    end

    let_once(:teacher) { User.create }
    let_once(:active_student) { User.create }
    let_once(:inactive_student) { User.create }
    let_once(:concluded_student) { User.create }

    let(:gradebook_settings) do
      { test_course.id =>
        {
          'show_inactive_enrollments' => 'false',
          'show_concluded_enrollments' => 'false'
        }
      }
    end

    let_once(:assignment) do
      Assignment.create!(title: "title", context: test_course)
    end

    it "returns active students and enrollments when inactive and concluded settings are false" do
      teacher.preferences[:gradebook_settings] = gradebook_settings
      json = Assignment::SpeedGrader.new(assignment, teacher).json

      students = json['context']['students'].map { |s| s['id'] }
      expect(students).to include(active_student.id)
    end

    it "returns active and inactive students and enrollments when inactive enromments is true" do
      gradebook_settings[test_course.id]['show_inactive_enrollments'] = 'true'
      teacher.preferences[:gradebook_settings] = gradebook_settings
      json = Assignment::SpeedGrader.new(assignment, teacher).json

      students = json['context']['students'].map { |s| s['id'] }
      expect(students).to include(active_student.id, inactive_student.id)
    end

    it "returns active and concluded students and enrollments when concluded is true" do
      gradebook_settings[test_course.id]['show_concluded_enrollments'] = 'true'
      teacher.preferences[:gradebook_settings] = gradebook_settings
      json = Assignment::SpeedGrader.new(assignment, teacher).json

      students = json['context']['students'].map { |s| s['id'] }
      expect(students).to include(active_student.id, concluded_student.id)
    end

    it "returns active, inactive, and concluded students and enrollments when both settings are true" do
      gradebook_settings[test_course.id]['show_inactive_enrollments'] = 'true'
      gradebook_settings[test_course.id]['show_concluded_enrollments'] = 'true'
      teacher.preferences[:gradebook_settings] = gradebook_settings
      json = Assignment::SpeedGrader.new(assignment, teacher).json

      students = json['context']['students'].map { |s| s['id'] }
      expect(students).to include(active_student.id, inactive_student.id, concluded_student.id)
    end
  end

  def setup_assignment_with_homework
    setup_assignment_without_submission
    res = @assignment.submit_homework(@user, {:submission_type => 'online_text_entry', :body => 'blah'})
    expect(res).not_to be_nil
    expect(res).to be_is_a(Submission)
    @assignment.reload
  end

  def setup_assignment_without_submission
    assignment_model(:course => @course)
    @assignment.reload
  end
end
