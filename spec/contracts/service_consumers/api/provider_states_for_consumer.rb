# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

Dir[File.dirname(__FILE__) + "/provider_states_for_consumer/*.rb"].each { |f| require f }
require_relative "../../../factories/course_factory"
require_relative "../../../factories/user_factory"

PactConfig::Consumers::ALL.each do |consumer|
  Pact.provider_states_for consumer do
    set_up do
      Pact::Canvas.base_state = Pact::Canvas::BaseState.seed!
    end

    # The following states are provided by the set_up block above, thus the no_op
    # because no additional setup is required.

    # Account_ID: 1 | Name: Siteadmin Account
    #   ID: 1 | Name: SiteAdmin1

    # Account_ID: 2 | Name: Default Account
    #   ID: 2 | Name: Admin1
    #   ID: 3 | Name: Teacher1
    #   ID: 4 | Name: TeacherAssistant1
    #   ID: 5 | Name: Student1
    #   ID: 6 | Name: Observer1
    #   ID: 7 | Name: Parent1
    #     Course_ID: 1 | Name: 'Contract Tests Course'
    #       Enrolled:
    #         Student1
    #         Teacher1
    #         TeacherAssistant1
    #         Observer1
    provider_state("an account") { no_op }
    provider_state("a course") { no_op }
    provider_state("a student enrolled in a course") { no_op }
    provider_state("a teacher enrolled in a course") { no_op }
    provider_state("a teacher assistant enrolled in a course") { no_op }
    provider_state("an observer enrolled in a course") { no_op }
    provider_state("an account admin") { no_op }
    provider_state("a site admin") { no_op }
    provider_state("a parent") { no_op } # Parents aren't enrolled in courses; they are "super observers"
  end
end

module Pact::Canvas
  def self.base_state=(base_state)
    @base_state = base_state
  end

  def self.base_state
    @base_state
  end

  class BaseState
    include Factories

    attr_reader(
      :account,
      :account_admins,
      :course,
      :observers,
      :parents,
      :site_admins,
      :site_admin_account,
      :students,
      :teachers,
      :teacher_assistants,
      :mobile_courses,
      :mobile_teacher,
      :mobile_student
    )

    def self.seed!(opts: {})
      new(opts)
    end

    private

    def initialize(opts)
      @site_admin_account = opts[:site_admin_account] || Account.site_admin
      @account = opts[:account] || Account.default
      @course = opts[:course] || seed_course
      seed_users(opts)
      @mobile_courses = seed_mobile
      enable_default_developer_key!
    end

    def seed_course
      course = course_factory(account: @account, active_course: true, course_name: "Contract Tests Course")

      # overriding these because the random uuid and lti_context_id won't work
      # with contract tests until we are able to use Pact provider_params
      course.lti_context_id = "9b4ef1eea0eb4c3498983e09a6ef88f1"
      course.uuid = "eylMsUDGR6aQDPCO5kOE6AGyH6ePPZLfV7CN1dV2"
      course.start_at ||= Time.now
      course.save!
      course
    end

    def seed_users(opts)
      @site_admins = opts[:site_admins] || seed_site_admins
      @account_admins = opts[:account_admins] || seed_account_admins
      @teachers = opts[:teachers] || seed_teachers
      @teacher_assistants = opts[:teacher_assistants] || seed_teacher_assistants
      @students = opts[:students] || seed_students
      @observers = opts[:observers] || seed_observers
      @parents = opts[:parents] || seed_parents
    end

    def seed_site_admins(count: 1)
      site_admins = []
      count.times do |i|
        index = i + 1
        site_admin_name = "SiteAdmin#{index}"
        site_admin_email = "#{site_admin_name}@instructure.com"
        site_admin = account_admin_user(account: @site_admin_account, email: site_admin_email, name: site_admin_name)
        site_admin.pseudonyms.create!(unique_id: site_admin_email, password: "password", password_confirmation: "password")
        site_admin.email = site_admin_email
        site_admin.accept_terms
        site_admins << site_admin
      end
      site_admins
    end

    def seed_account_admins(count: 1)
      account_admins = []
      count.times do |i|
        index = i + 1
        admin_name = "Admin#{index}"
        admin_email = "#{admin_name}@instructure.com"
        admin = account_admin_user(account: @account, email: admin_email, name: admin_name)
        admin.pseudonyms.create!(unique_id: admin_email, password: "password", password_confirmation: "password", sis_user_id: "SIS_#{admin_name}")
        admin.email = admin_email
        admin.accept_terms
        account_admins << admin
      end
      account_admins
    end

    def seed_teachers(count: 1)
      teachers = []
      count.times do |i|
        index = i + 1
        teacher_name = "Teacher#{index}"
        teacher_email = "#{teacher_name}@instructure.com"
        teacher = user_factory(active_all: true, course: @course, name: teacher_name)
        teacher.pseudonyms.create!(unique_id: teacher_email, password: "password", password_confirmation: "password", sis_user_id: "SIS_#{teacher_name}")
        teacher.email = teacher_email
        teacher.accept_terms
        course.enroll_teacher(teacher).accept!
        teachers << teacher
      end
      teachers
    end

    def seed_teacher_assistants(count: 1)
      teacher_assistants = []
      count.times do |i|
        index = i + 1
        ta_name = "TeacherAssistant#{index}"
        ta_email = "#{ta_name}@instructure.com"
        ta = user_factory(active_all: true, course: @course, name: ta_name)
        ta.pseudonyms.create!(unique_id: ta_email, password: "password", password_confirmation: "password", sis_user_id: "SIS_#{ta_name}")
        ta.email = ta_email
        ta.accept_terms
        course.enroll_ta(ta).accept!
        teacher_assistants << ta
      end
      teacher_assistants
    end

    def seed_students(count: 1)
      students = []
      count.times do |i|
        index = i + 1
        student_name = "Student#{index}"
        student_email = "#{student_name}@instructure.com"
        student = user_factory(active_all: true, course: @course, name: student_name)
        student.pseudonyms.create!(unique_id: student_email, password: "password", password_confirmation: "password", sis_user_id: "SIS_#{student_name}")
        student.email = student_email
        student.accept_terms
        course.enroll_student(student).accept!
        students << student
      end
      students
    end

    def seed_observers(count: 1)
      observers = []
      count.times do |i|
        index = i + 1
        observer_name = "Observer#{index}"
        observer_email = "#{observer_name}@instructure.com"
        observer = user_factory(active_all: true, course: @course, name: observer_name)
        observer.pseudonyms.create!(unique_id: observer_email, password: "password", password_confirmation: "password", sis_user_id: "SIS_#{observer_name}")
        observer.email = observer_email
        observer.accept_terms
        enroll_observer(observer:)
        observers << observer
      end
      observers
    end

    def enroll_observer(observer:, student_to_observe: nil)
      student = student_to_observe || @students.first
      @course.enroll_user(
        observer,
        "ObserverEnrollment",
        enrollment_state: "active",
        associated_user_id: student.id
      )
    end

    def seed_parents(count: 1)
      parents = []
      count.times do |i|
        index = i + 1
        parent_name = "Parent#{index}"
        parent_email = "#{parent_name}@instructure.com"
        parent = user_factory(active_user: true, name: parent_name)
        parent.pseudonyms.create!(unique_id: parent_email, password: "password", password_confirmation: "password", sis_user_id: "SIS_#{parent_name}")
        parent.email = parent_email
        parent.save!

        # Parent1 observes Student1, Parent2 observes Student2, etc.
        UserObservationLink.create!(student: @students[i], observer: parent, root_account_id: @account)

        parents << parent
      end
      parents
    end

    # Set up a playground for mobile usage
    #
    # Student id 8, "Mobile Student"
    # Teacher id 9, "Mobile Teacher"
    # Courses with ids 2 and 3, "Mobile Course 1" and "Mobile Course 2".  The latter is favorited.
    def seed_mobile
      # Let's make a mobile student
      mstudent_name = "Mobile Student"
      mstudent_email = "MobileStudent@instructure.com"
      mstudent = user_factory(active_all: true, name: mstudent_name)
      mstudent.pseudonyms.create!(unique_id: mstudent_email, password: "password", password_confirmation: "password", sis_user_id: "SIS_#{mstudent_name}")
      mstudent.email = mstudent_email
      mstudent.accept_terms
      mstudent.profile.bio = "My Bio" # Add bio
      mstudent.profile.save
      mstudent.update(locale: "en", pronouns: "They/Them") # populate locale, pronouns

      # And a mobile teacher
      mteacher_name = "Mobile Teacher"
      mteacher_email = "MobileTeacher@instructure.com"
      mteacher = user_factory(active_all: true, name: mteacher_name)
      mteacher.pseudonyms.create!(unique_id: mteacher_email, password: "password", password_confirmation: "password", sis_user_id: "SIS_#{mteacher_name}")
      mteacher.email = mteacher_email
      mteacher.accept_terms
      mteacher.update(pronouns: "She/Her")

      # The logic below will stomp @course and perhaps a few other things.
      # We'll save them so that we can restore them later to their original value.
      original_course = @course

      mcourses = []
      # Now let's make 2 courses
      2.times do |i|
        index = i + 1
        mcourse = course_factory(account: @account, active_course: true, course_name: "Mobile Course #{index}", is_public: true)

        # overriding these because the random uuid and lti_context_id won't work
        # with contract tests until we are able to use Pact provider_params
        # JHoag: I don't know if our mobile tests need this or not.  Just trying to follow a pattern.
        #        I had to add the "-<index>" because these need to be unique
        mcourse.lti_context_id = "9b4ef1eea0eb4c3498983e09a6ef88f1-#{index}"
        mcourse.uuid = "eylMsUDGR6aQDPCO5kOE6AGyH6ePPZLfV7CN1dV2-#{index}"
        mcourse.start_at ||= Time.now
        mcourse.save!

        # Enroll our student and teacher in each course
        mcourse.enroll_student(mstudent).accept!
        mcourse.enroll_teacher(mteacher).accept!
        mcourse.save!

        # Create grading periods for each course
        create_grading_periods_for(mcourse, grading_periods: [:current, :future])
        mcourse.save

        # Update our enrollments with last_activity_at, start_at and end_at
        enrollment = mcourse.enrollments.detect { |e| e.user_id == 8 }
        enrollment.update(last_activity_at: 1.minute.ago)
        enrollment.save
        mcourse.enrollment_term.update!(start_at: 1.month.ago, end_at: 1.month.from_now)

        # Update our course to with license and conclude_at (which maps to end_at), enable grading
        mcourse.update!(grading_standard_enabled: true, license: "private", conclude_at: 1.month.from_now)

        # All courses created after the initial favorite will be favorited, I think.  (course_spec.rb, L1607)
        # So just favorite the last one.
        if i == 1
          # puts "Favoriting #{mcourse.id}"
          mstudent.favorites.create!(context_type: "Course", context: mcourse)
          mstudent.favorites.first.save
          mstudent.save!
        end

        # Add start_at,  end_at to our course section
        mcourse.course_sections.first.update(start_at: 1.month.ago, end_at: 1.month.from_now)
        mcourses << mcourse
      end

      # Restore initial value of @course,  possibly others
      @course = original_course

      # Record our mobile student and teacher
      @mobile_student = mstudent
      @mobile_teacher = mteacher

      # Return our mobile courses
      mcourses
    end
  end
end
