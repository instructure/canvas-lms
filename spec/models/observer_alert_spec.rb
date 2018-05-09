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

require_relative '../sharding_spec_helper'

describe ObserverAlert do
  it 'can link to a threshold and observation link' do
    assignment = assignment_model()
    assignment.save!
    observer = user_factory()
    student = user_factory()
    link = UserObservationLink.new(:student => student, :observer => observer,
                            :root_account => @account)
    link.save!
    threshold = ObserverAlertThreshold.new(:user_observation_link => link, :alert_type => 'missing')
    threshold.save!

    alert = ObserverAlert.new(:user_observation_link => link, :observer_alert_threshold => threshold,
                      :context => assignment, :alert_type => 'missing', :action_date => Time.zone.now,
                      :title => 'Assignment missing')
    alert.save!

    saved_alert = ObserverAlert.find(alert.id)
    expect(saved_alert).not_to be_nil
    expect(saved_alert.user_observation_link).not_to be_nil
    expect(saved_alert.observer_alert_threshold).not_to be_nil
  end

  describe 'course_announcement' do
    before :once do
      @course = course_factory()
      @student = student_in_course(:active_all => true, :course => @course).user
      @observer = course_with_observer(:course => @course, :associated_user_id => @student.id, :active_all => true).user
      @link = UserObservationLink.create!(student: @student, observer: @observer, root_account: @account)
      ObserverAlertThreshold.create!(user_observation_link: @link, alert_type: 'course_announcement')

      # user without a threshold
      @observer2 = course_with_observer(:course => @course, :associated_user_id => @student.id, :active_all => true).user
      @link2 = UserObservationLink.create!(student: @student, observer: @observer2, root_account: @account)
    end

    it 'creates an alert when a user has a threshold for course announcements' do
      a = announcement_model(:context => @course)
      alert = ObserverAlert.where(user_observation_link: @link).first
      expect(alert).not_to be_nil
      expect(alert.context).to eq a
      expect(alert.title).to include('Announcement posted: ')

      alert2 = ObserverAlert.where(user_observation_link: @link2).first
      expect(alert2).to be_nil
    end

    it 'creates an alert when the delayed announcement becomes active' do
      a = announcement_model(:context => @course, :delayed_post_at => Time.zone.now, :workflow_state => :post_delayed)
      alert = ObserverAlert.where(user_observation_link: @link, context: a).first
      expect(alert).to be_nil

      a.workflow_state = 'active'
      a.save!

      alert = ObserverAlert.where(user_observation_link: @link, context: a).first
      expect(alert).not_to be_nil
    end
  end

  describe 'institution_announcement' do
    before :once do
      @no_link_account = account_model
      @account = account_model
      @student = student_in_course(:active_all => true, :course => @course).user
      @observer = course_with_observer(:course => @course, :associated_user_id => @student.id, :active_all => true).user
      @link = UserObservationLink.create!(student: @student, observer: @observer, root_account: @account)
      ObserverAlertThreshold.create!(user_observation_link: @link, alert_type: 'institution_announcement')

      # user without a threshold
      @observer2 = course_with_observer(:course => @course, :associated_user_id => @student.id, :active_all => true).user
      @link2 = UserObservationLink.create!(student: @student, observer: @observer2, root_account: @account)
    end

    it 'doesnt create an alert if the notificaiton is not for the root account' do
      sub_account = account_model(root_account: @account, parent_account: @account)
      notification = sub_account_notification(account: sub_account)
      alert = ObserverAlert.where(context: notification).first
      expect(alert).to be_nil
    end

    it 'doesnt create an alert if the start_at time is in the future' do
      notification = account_notification(start_at: 1.day.from_now, account: @account)
      alert = ObserverAlert.where(context: notification).first
      expect(alert).to be_nil
    end

    it 'doesnt create an alert if the roles dont include student or observer' do
      role_ids = ["TeacherEnrollment", "AccountAdmin"].map{|name| Role.get_built_in_role(name).id}
      notification = account_notification(account: @account, role_ids: role_ids)
      alert = ObserverAlert.where(context: notification).first
      expect(alert).to be_nil
    end

    it 'doesnt create an alert if there are no links' do
      notification = account_notification(account: @no_link_account)
      alert = ObserverAlert.where(context: notification).first
      expect(alert).to be_nil
    end

    it 'creates an alert for each threshold set' do
      notification = account_notification(account: @account)
      alert = ObserverAlert.where(context: notification)
      expect(alert.count).to eq 1

      expect(alert.first.context).to eq notification
    end

    it 'creates an alert if student role is selected but not observer' do
      role_ids = ["StudentEnrollment", "AccountAdmin"].map{|name| Role.get_built_in_role(name).id}
      notification = account_notification(account: @account, role_ids: role_ids)
      alert = ObserverAlert.where(context: notification).first
      expect(alert.context).to eq notification
    end

    it 'creates an alert if observer role is selected but not student' do
      role_ids = ["ObserverEnrollment", "AccountAdmin"].map{|name| Role.get_built_in_role(name).id}
      notification = account_notification(account: @account, role_ids: role_ids)
      alert = ObserverAlert.where(context: notification).first
      expect(alert.context).to eq notification
    end
  end
end
