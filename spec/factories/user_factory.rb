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
  def user_model(opts={})
    email = opts.delete(:email)
    @user = factory_with_protected_attributes(User, valid_user_attributes.merge(opts))
    @user.email = email if email # set e-mail after record creation
    @user
  end

  def tie_user_to_account(user, opts={})
    user.account_users.create(:account => opts[:account] || Account.default, :role => opts[:role] || admin_role)
  end

  def valid_user_attributes
    {
      :name => 'value for name',
    }
  end

  def account_admin_user_with_role_changes(opts={})
    account_with_role_changes(opts)
    account_admin_user(opts)
  end

  def account_admin_user(opts={})
    opts = { active_user: true }.merge(opts)
    account = opts[:account] || Account.default
    create_grading_periods_for(account, opts) if opts[:grading_periods]
    @user = opts[:user] || account.shard.activate { user_factory(opts) }
    @admin = @user

    account.account_users.create!(:user => @user, :role => opts[:role])
    @user
  end

  def site_admin_user(opts={})
    account_admin_user(opts.merge(account: Account.site_admin))
  end

  def user_factory(opts={})
    @user = User.create!(opts.slice(:name, :short_name))
    if opts[:active_user] || opts[:active_all]
      @user.accept_terms
      @user.register!
    end
    @user.update_attribute :workflow_state, opts[:user_state] if opts[:user_state]
    @cc = communication_channel(@user, opts) if opts[:active_cc]
    @user
  end

  def user_with_pseudonym(opts={})
    user_factory(opts) unless opts[:user]
    user = opts[:user] || @user
    @pseudonym = pseudonym(user, opts)
    user
  end

  def user_with_communication_channel(opts={})
    user_factory(opts) unless opts[:user]
    user = opts[:user] || @user
    @cc = communication_channel(user, opts)
    user
  end

  def user_with_managed_pseudonym(opts={})
    user_factory(opts) unless opts[:user]
    user = opts[:user] || @user
    managed_pseudonym(user, opts)
    user
  end

  def student_in_course(opts={})
    opts[:course] = @course if @course && !opts[:course]
    course_with_student(opts)
  end

  def ta_in_course(opts={})
    opts[:course] = @course if @course && !opts[:course]
    course_with_ta(opts)
  end

  def student_in_section(section, opts={})
    student = opts.fetch(:user) { user_factory }
    enrollment = section.course.enroll_user(student, 'StudentEnrollment', :section => section, :force_update => true)
    student.save!
    enrollment.workflow_state = 'active'
    enrollment.save!
    student
  end

  def ta_in_section(section, opts={})
    ta = opts.fetch(:user) { user_factory }
    enrollment = section.course.enroll_user(ta, 'TaEnrollment', :section => section, :force_update => true)
    ta.save!
    enrollment.limit_privileges_to_course_section = true unless opts[:full_course_permissions]
    enrollment.workflow_state = 'active'
    enrollment.save!
    ta
  end

  def teacher_in_section(section, opts={})
    teacher = opts.fetch(:user) { user_factory }
    limit_privileges_to_course_section = opts[:limit_privileges_to_course_section] || false
    enrollment = section.course.enroll_user(teacher, 'TeacherEnrollment', :section => section,
      :force_update => true, :limit_privileges_to_course_section => limit_privileges_to_course_section)
    teacher.save!
    enrollment.workflow_state = 'active'
    enrollment.save!
    teacher
  end

  def teacher_in_course(opts={})
    opts[:course] = @course if @course && !opts[:course]
    course_with_teacher(opts)
  end

  def n_students_in_course(n, opts={})
    course = opts[:course] || course_model
    create_users_in_course(course, n, return_type: :record)
  end

  def create_users(records, options = {})
    @__create_user_count ||= 0
    name_prefix = options[:name_prefix] || "user"
    records = records.times.map{ |i| { name: "#{name_prefix} #{@__create_user_count + i + 1}" } } if records.is_a?(Integer)
    records = records.map { |record| valid_user_attributes.merge(workflow_state: "registered").merge(record) }
    @__create_user_count += records.size
    create_records(User, records, options[:return_type])
  end

  # create a bunch of users at once, and enroll them all in the same course
  def create_users_in_course(course, records, options = {})
    user_data = create_users(records, options)
    create_enrollments(course, user_data, options)

    user_data
  end
end
