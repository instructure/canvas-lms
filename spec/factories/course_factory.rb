#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Factories
  def course_factory(opts={})
    account = opts[:account] || Account.default
    account.shard.activate do
      @course = Course.create!(:sis_source_id => opts[:sis_source_id], :name => opts[:course_name], :account => account, :is_public => !!opts[:is_public])
      @course.offer! if opts[:active_course] || opts[:active_all]
      if opts[:active_all]
        u = User.create!
        u.register!
        u.enable_feature!(:new_user_tutorial_on_off) if opts[:new_user]
        e = @course.enroll_teacher(u)
        e.workflow_state = 'active'
        e.save!
        @teacher = u
      end
      create_grading_periods_for(@course, opts) if opts[:grading_periods]
    end
    @course
  end

  def course_model(opts={})
    allow_reusable = opts.delete :reusable
    @course = factory_with_protected_attributes(Course, course_valid_attributes.merge(opts))
    @teacher = user_model
    e = @course.enroll_teacher(@teacher)
    e.accept
    @user = @teacher
    @course
  end

  def course_valid_attributes
    {
      :name => 'value for name',
      :group_weighting_scheme => 'value for group_weighting_scheme',
      :start_at => Time.now,
      :conclude_at => Time.now + 100,
      :is_public => true,
      :allow_student_wiki_edits => true,
    }
  end

  def course_with_user(enrollment_type, opts={})
    @course = opts[:course] || course_factory(opts)
    @user = opts[:user] || @course.shard.activate { user_factory(opts) }
    @enrollment = @course.enroll_user(@user, enrollment_type, opts)
    @user.save!
    @enrollment.course = @course # set the reverse association
    if opts[:active_enrollment] || opts[:active_all]
      @enrollment.workflow_state = 'active'
      @enrollment.save!
    end
    @course.reload
    @enrollment
  end

  def course_with_student(opts={})
    course_with_user('StudentEnrollment', opts)
    @student = @user
    @enrollment
  end

  def course_with_ta(opts={})
    course_with_user("TaEnrollment", opts)
    @ta = @user
    @enrollment
  end

  def course_with_student_logged_in(opts={})
    course_with_student(opts)
    user_session(@user)
  end

  def course_with_teacher(opts={})
    course_with_user('TeacherEnrollment', opts)
    @teacher = @user
    @enrollment
  end

  def course_with_designer(opts={})
    course_with_user('DesignerEnrollment', opts)
    @designer = @user
    @enrollment
  end

  def course_with_teacher_logged_in(opts={})
    course_with_teacher(opts)
    user_session(@user)
  end

  def course_with_observer(opts={})
    course_with_user('ObserverEnrollment', opts)
    @observer = @user
    @enrollment
  end

  def course_with_observer_logged_in(opts={})
    course_with_observer(opts)
    user_session(@user)
  end

  def course_with_student_submissions(opts={})
    course_with_teacher_logged_in(opts)
    student_in_course
    @course.claim! if opts[:unpublished]
    submission_count = opts[:submissions] || 1
    submission_count.times do |s|
      assignment = @course.assignments.create!(:title => "test #{s} assignment")
      submission = assignment.submissions.find_by!(user: @student)
      submission.update_attributes!(score: '5') if opts[:submission_points]
    end
  end

  # quickly create a course, bypassing all that AR crap
  def create_course(options = {})
    create_courses(1, options.merge({return_type: :record}))[0]
  end

  # create a bunch of courses at once, optionally enrolling a user in them
  # records can either be the number of records to create, or an array of
  # hashes of attributes you want to insert
  def create_courses(records, options = {})
    account = options[:account] || Account.default
    records = records.times.map{ |i| { name: "Course #{i}" } } if records.is_a?(Integer)
    records = records.map { |record| course_valid_attributes.merge(account_id: account.id, root_account_id: account.id, workflow_state: 'available', enrollment_term_id: account.default_enrollment_term.id).merge(record) }
    course_data = create_records(Course, records, options[:return_type])
    course_ids = options[:return_type] == :record ?
      course_data.map(&:id) :
      course_data

    if options[:account_associations]
      create_records(CourseAccountAssociation, course_ids.map{ |id| {account_id: account.id, course_id: id, depth: 0}})
    end
    if user = options[:enroll_user]
      section_ids = create_records(CourseSection, course_ids.map{ |id| {course_id: id, root_account_id: account.id, name: "Default Section", default_section: true}})
      type = options[:enrollment_type] || "TeacherEnrollment"
      role_id = Role.get_built_in_role(type).id
      result = create_records(Enrollment, course_ids.each_with_index.map{ |id, i| {course_id: id, user_id: user.id, type: type, course_section_id: section_ids[i], root_account_id: account.id, workflow_state: 'active', :role_id => role_id}})
      create_enrollment_states(result, {state: "active"})
      result
    end
    course_data
  end

  def course_with_student_and_submitted_homework
    course_with_teacher_logged_in(active_all: true)
    @teacher = @user
    student_in_course(active_all: true)
    @assignment = @course.assignments.create!({
      title: "some assignment",
      submission_types: "online_url,online_upload"
    })
    @submission = @assignment.submit_homework(@user, {
      submission_type: "online_url",
      url: "http://www.google.com"
    })
  end
end
