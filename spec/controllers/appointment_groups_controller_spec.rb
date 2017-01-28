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
    @next_year = Time.now.year + 1
    @ag = AppointmentGroup.create!(:title => "blah", :contexts => [@course, @course2],
                                   :new_appointments => [
                                     ["#{@next_year}-01-01 12:00:00", "#{@next_year}-01-01 13:00:00"],
                                     ["#{@next_year}-02-01 12:00:00", "#{@next_year}-02-01 13:00:00"],
                                   ])
    @ag.publish!
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
      it "redirects to the agenda, starting at the given appointment group's start_at" do
        get 'show', :id => @ag.to_param
        check_redirect(response, 'view_name' => 'agenda', 'view_start' => "#{@next_year}-01-01")
      end

      it "redirects to a specific event on the agenda" do
        get 'show', :id => @ag.to_param, :event_id => @ag.appointments.last.to_param
        check_redirect(response, 'view_name' => 'agenda', 'view_start' => "#{@next_year}-02-01")
      end

      it "enters find-appointment mode if requested" do
        get 'show', :id => @ag.to_param, :find_appointment => true
        check_redirect(response, 'view_name' => 'agenda', 'view_start' => "#{@next_year}-01-01",
                       'find_appointment' => @course.asset_string)
      end
    end
  end

  private

  def check_redirect(response, hash)
    expect(response).to be_redirect
    uri = URI.parse(response.location)
    expect(uri.path).to eq '/calendar2'
    json = JSON.parse([uri.fragment].pack('H*'))
    expect(json).to eq hash
  end
end
