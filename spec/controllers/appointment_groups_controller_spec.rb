#
# Copyright (C) 2016 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AppointmentGroupsController do
  before :once do
    @course2 = course_factory(active_all: true)
    course_factory(active_all: true)
    student_in_course(active_all: true)
    @group_student = @student
    student_in_course(active_all: true)
    teacher_in_course(active_all: true)
    @next_year = Time.now.year + 1
    @ag = AppointmentGroup.create!(:title => "blah", :contexts => [@course, @course2],
                                   :new_appointments => [
                                     ["#{@next_year}-01-01 12:00:00", "#{@next_year}-01-01 13:00:00"],
                                     ["#{@next_year}-02-01 12:00:00", "#{@next_year}-02-01 13:00:00"],
                                   ])
    @ag.publish!

    @ag_with_reservation = AppointmentGroup.create!(:title => "blah", :contexts => [@course, @course2],
                                                    :new_appointments => [
                                                      ["#{@next_year}-01-01 14:00:00", "#{@next_year}-01-01 15:00:00"],
                                                      ["#{@next_year}-02-01 14:00:00", "#{@next_year}-02-01 15:00:00"],
                                                    ])
    @ag_with_reservation.publish!
    @participant = @ag_with_reservation.participant_for(@student)
    @reservation = @ag_with_reservation.appointments.last.reserve_for(@participant, @student)

    @group_users = [@group_student, @student]

    @group1 = group(:name => "group1", :group_context => @course)
    @group1.participating_users << @group_users
    @group1.save!
    @gc = @group1.group_category
    @group_ag = AppointmentGroup.create!(:title => "test", :contexts => [@course, @course2],
                                         :participants_per_appointment => 2,
                                         :new_appointments => [
                                           ["#{@next_year}-01-01 17:00:00", "#{@next_year}-01-01 18:00:00"],
                                           ["#{@next_year}-02-01 17:00:00", "#{@next_year}-02-01 18:00:00"],
                                         ])

    @group_ag.appointment_group_sub_contexts.create! :sub_context => @gc, :sub_context_code => @gc.asset_string
    @group_ag.appointments.first.reserve_for(@group1, @group_student)
    @group_ag.publish!
  end

  before :each do
    user_session @student
  end

  context "old scheduler" do
    describe "GET 'index'" do
      it 'redirects to the scheduler tab index' do
        get 'index'
        check_redirect(response, 'view_name' => 'scheduler')
      end
    end

    describe "GET 'show'" do
      it 'redirects to a specific appointment group in the scheduler' do
        get 'show', :id => @ag.to_param
        check_redirect(response, 'view_name' => 'scheduler', 'appointment_group_id' => @ag.id)
      end
    end
  end

  context "new scheduler" do
    before :once do
      @course.root_account.enable_feature! 'better_scheduler'
    end

    describe "GET 'index'" do
      it "redirects to the agenda, starting at the first appointment group's start_at" do
        get 'index'
        check_redirect(response, 'view_name' => 'agenda', 'view_start' => "#{@next_year}-01-01" )
      end
    end

    describe "GET 'show'" do
      it "without appointment - redirects to the agenda on date of appt. in find_appointment mode" do
        get 'show', :id => @ag.to_param
        check_redirect(response, 'view_name' => 'agenda', 'view_start' => "#{@next_year}-01-01",
                       'find_appointment' => @course.asset_string)
      end

      it "redirects to a specific event on the month view" do
        get 'show', :id => @ag.to_param, :event_id => @ag.appointments.last.to_param
        check_redirect(response, 'view_name' => 'month', 'view_start' => "#{@next_year}-02-01")
      end

      it "with appt it redirects to the agenda, starting at the date of appt. group" do
        get 'show', :id => @ag_with_reservation.to_param
        check_redirect(response, 'view_name' => 'agenda', 'view_start' => "#{@next_year}-01-01")
      end
      it "with appt it redirects to a specific event in month view" do
        get 'show', :id => @ag_with_reservation.to_param, :event_id => @reservation.to_param
        check_redirect(response, {'view_name' => 'month', 'view_start' => "#{@next_year}-02-01"},
                       "event_id=#{@reservation.id}")
      end
      it "with appt it redirects to a specific parent event in month view if requester did not create the event." do
        user_session @teacher
        get 'show', :id => @ag_with_reservation.to_param, :event_id => @reservation.to_param
        check_redirect(response, {'view_name' => 'month', 'view_start' => "#{@next_year}-02-01"},
                       "event_id=#{@reservation.parent_event.id}")
      end
      it "with group appt it redirects to the agenda, starting at the date of appt. group, no find appt. mode." do
        get 'show', :id => @group_ag.to_param
        check_redirect(response, 'view_name' => 'agenda', 'view_start' => "#{@next_year}-01-01")
      end


    end
  end

  private

  def check_redirect(response, hash, query = nil)
    expect(response).to be_redirect
    uri = URI.parse(response.location)
    expect(uri.path).to eq '/calendar2'
    json = JSON.parse([uri.fragment].pack('H*'))
    expect(json).to eq hash
    if query
      expect(uri.query).to eq query
    end
  end
end
