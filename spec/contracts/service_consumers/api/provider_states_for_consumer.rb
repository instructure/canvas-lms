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

Dir[File.dirname(__FILE__) + "/provider_states_for_consumer/*.rb"].each {|f| require f }
require 'spec/factories/course_factory'
require 'spec/factories/user_factory'

PactConfig::Consumers::ALL.each do |consumer|

  Pact.provider_states_for consumer do
    set_up do
      Pact::Canvas.base_state = Pact::Canvas::BaseState.seed!
    end

    # The following states are provided by the set_up block above, thus the no_op
    # because no additional setup is required.

    # Account_ID: 1 | Name: Siteadmin Account
      # ID: 1 | Name: SiteAdmin1

    # Account_ID: 2 | Name: Default Account
      # ID: 2 | Name: Admin1
      # ID: 3 | Name: Teacher1
      # ID: 4 | Name: TeacherAssistant1
      # ID: 5 | Name: Student1
      # ID: 6 | Name: Observer1
      # Course_ID: 1 | Name: 'Contract Tests Course'
        # Enrolled:
          # Student1
          # Teacher1
          # TeacherAssistant1
          # Observer1
    provider_state('an account') { no_op }
    provider_state('a course') { no_op }
    provider_state('a student enrolled in a course') { no_op }
    provider_state('a teacher enrolled in a course') { no_op }
    provider_state('a teacher assistant enrolled in a course') { no_op }
    provider_state('an observer enrolled in a course') { no_op }
    provider_state('an account admin') { no_op }
    provider_state('a site admin') { no_op }
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
      :site_admins,
      :site_admin_account,
      :students,
      :teachers,
      :teacher_assistants
    )

    def self.seed!(opts: {})
      self.new(opts)
    end

    private

    def initialize(opts)
      @site_admin_account = opts[:site_admin_account] || Account.site_admin
      @account = opts[:account] || Account.default
      @course = opts[:course] || seed_course
      seed_users(opts)
      enable_features
    end

    def enable_features
     @account.enable_feature!(:student_planner)
    end

    def seed_course
      course = course_factory(account: @account, active_course: true, course_name: 'Contract Tests Course')

      # overriding these because the random uuid and lti_context_id won't work
      # with contract tests until we are able to use Pact provider_params
      course.lti_context_id = '9b4ef1eea0eb4c3498983e09a6ef88f1'
      course.uuid = 'eylMsUDGR6aQDPCO5kOE6AGyH6ePPZLfV7CN1dV2'
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
    end

    def seed_site_admins(count: 1)
      site_admins = []
      count.times do |i|
        index = i + 1
        site_admin_name = "SiteAdmin#{index}"
        site_admin_email = "#{site_admin_name}@instructure.com"
        site_admin = account_admin_user(account: @site_admin_account, email: site_admin_email, name: site_admin_name)
        site_admin.pseudonyms.create!(unique_id: site_admin_email, password: 'password', password_confirmation: 'password')
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
        admin.pseudonyms.create!(unique_id: admin_email, password: 'password', password_confirmation: 'password', sis_user_id: "SIS_#{admin_name}")
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
        teacher.pseudonyms.create!(unique_id: teacher_email, password: 'password', password_confirmation: 'password', sis_user_id: "SIS_#{teacher_name}")
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
        ta.pseudonyms.create!(unique_id: ta_email, password: 'password', password_confirmation: 'password', sis_user_id: "SIS_#{ta_name}")
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
        student.pseudonyms.create!(unique_id: student_email, password: 'password', password_confirmation: 'password', sis_user_id: "SIS_#{student_name}")
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
        observer.pseudonyms.create!(unique_id: observer_email, password: 'password', password_confirmation: 'password', sis_user_id: "SIS_#{observer_name}")
        observer.email = observer_email
        observer.accept_terms
        enroll_observer(observer: observer)
        observers << observer
      end
      observers
    end

    def enroll_observer(observer:, student_to_observe: nil)
      student = student_to_observe || @students.first
      @course.enroll_user(
        observer,
        'ObserverEnrollment',
        enrollment_state: 'active',
        associated_user_id: student.id
      )
    end
  end
end
