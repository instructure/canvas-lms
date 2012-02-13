#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe AppointmentGroupsController, :type => :integration do
  before do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym(:active_user => true))
    @me = @user
  end

  expected_fields = [
    'appointments_count', 'context_code', 'created_at', 'description',
    'end_at', 'id', 'location_address', 'location_name',
    'max_appointments_per_participant', 'min_appointments_per_participant',
    'participant_type', 'participant_visibility',
    'participants_per_appointment', 'requiring_action', 'start_at',
    'sub_context_code', 'title', 'updated_at', 'url', 'workflow_state'
  ]

  it 'should return manageable appointment groups' do
    ag1 = @course.appointment_groups.create(:title => "something")
    cat = @course.group_categories.create
    ag2 = @course.appointment_groups.create(:title => "another", :sub_context_code => cat.asset_string)
    ag3 = Course.create.appointment_groups.create(:title => "inaccessible")
    ag4 = @course.appointment_groups.create(:title => "past", :new_appointments => [["#{Time.now.year - 1}-01-01 12:00:00", "#{Time.now.year - 1}-01-01 13:00:00"]])

    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'manageable'})
    json.size.should eql 2
    json.first.keys.sort.should eql expected_fields
    json.first.slice('id', 'title', 'participant_type').should eql({'id' => ag1.id, 'title' => 'something', 'participant_type' => 'User'})
    json.last.slice('id', 'title', 'participant_type').should eql({'id' => ag2.id, 'title' => 'another', 'participant_type' => 'Group'})
  end

  it "should return past manageable appointment groups, if requested" do
    ag = @course.appointment_groups.create(:title => "past", :new_appointments => [["#{Time.now.year - 1}-01-01 12:00:00", "#{Time.now.year - 1}-01-01 13:00:00"]])
    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&include_past_appointments=1", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'manageable', :include_past_appointments => '1'})
    json.size.should eql 1
  end

  it 'should return reservable appointment groups' do
    ag1 = @course.appointment_groups.create(:title => "can't reserve")
    ag1.publish!
    ag2 = Course.create.appointment_groups.create(:title => "me neither")
    ag2.publish!

    student_in_course :course => course(:active_all => true), :user => @me
    ag3 = @course.appointment_groups.create(:title => "enrollment not active")
    ag3.publish!

    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    ag4 = @course.appointment_groups.create(:title => "unpublished")
    ag5 = @course.appointment_groups.create(:title => "no times")
    ag5.publish!

    ag6 = @course.appointment_groups.create(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]])
    ag6.publish!
    cat = @course.group_categories.create
    mygroup = cat.groups.create(:context => @course)
    mygroup.users << @me
    @me.reload
    ag7 = @course.appointment_groups.create(:title => "double yay", :sub_context_code => cat.asset_string, :new_appointments => [["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]])
    ag7.publish!
    ag8 = @course.appointment_groups.create(:title => "past", :new_appointments => [["#{Time.now.year - 1}-01-01 12:00:00", "#{Time.now.year - 1}-01-01 13:00:00"]])
    ag8.publish!

    json = api_call(:get, "/api/v1/appointment_groups?scope=reservable", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'reservable'})
    json.size.should eql 2
    json.first.keys.sort.should eql expected_fields
    json.first.slice('id', 'title', 'participant_type').should eql({'id' => ag6.id, 'title' => 'yay', 'participant_type' => 'User'})
    json.last.slice('id', 'title', 'participant_type').should eql({'id' => ag7.id, 'title' => 'double yay', 'participant_type' => 'Group'})
  end

  it "should return past reservable appointment groups, if requested" do
    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    ag = @course.appointment_groups.create(:title => "past", :new_appointments => [["#{Time.now.year - 1}-01-01 12:00:00", "#{Time.now.year - 1}-01-01 13:00:00"]])
    ag.publish!
    json = api_call(:get, "/api/v1/appointment_groups?scope=reservable&include_past_appointments=1", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'reservable', :include_past_appointments => '1'})
    json.size.should eql 1
  end

  it 'should paginate appointment groups' do
    ids = 25.times.map { |i| @course.appointment_groups.create(:title => "#{i}").id }
    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&per_page=10", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json',
                      :scope => 'manageable', :per_page => '10'})
    json.size.should eql 10
    response.headers['Link'].should match(%r{</api/v1/appointment_groups\?.*page=2.*>; rel="next",</api/v1/appointment_groups\?.*page=1.*>; rel="first",</api/v1/appointment_groups\?.*page=3.*>; rel="last"})

    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&per_page=10&page=3", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json',
                      :scope => 'manageable', :per_page => '10', :page => '3'})
    json.size.should eql 5
    response.headers['Link'].should match(%r{</api/v1/appointment_groups\?.*page=2.*>; rel="prev",</api/v1/appointment_groups\?.*page=1.*>; rel="first",</api/v1/appointment_groups\?.*page=3.*>; rel="last"})
  end

  it 'should include appointments and child_events, if requested' do
    ag = @course.appointment_groups.create(:title => "something", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]])
    student = student_in_course(:course => @course, :active_all => true).user
    ag.appointments.first.reserve_for student, @me
    @user = @me

    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&include[]=appointments", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'manageable', :include => ['appointments']})
    json.size.should eql 1
    json.first.keys.sort.should eql((expected_fields + ['appointments']).sort)

    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&include[]=appointments&include[]=child_events", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'manageable', :include => ['appointments', 'child_events']})
    json.size.should eql 1
    json.first.keys.sort.should eql((expected_fields + ['appointments']).sort)
    ajson = json.first['appointments']
    ajson.first.keys.should include('child_events')
    cjson = ajson.first['child_events']
    cjson.first.keys.should include('user')
    cjson.first['user']['id'].should eql student.id
  end

  it 'should get a manageable appointment group' do
    ag = @course.appointment_groups.create(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])

    json = api_call(:get, "/api/v1/appointment_groups/#{ag.id}", {
                      :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => ag.id.to_s})
    json.keys.sort.should eql((expected_fields + ['appointments']).sort)
    json['id'].should eql ag.id
    json['requiring_action'].should be_false
    json['appointments'].size.should eql 1
    json['appointments'].first.keys.should include('child_events_count')
    json['appointments'].first.keys.should_not include('child_events')
  end

  it 'should include child_events, if requested' do
    ag = @course.appointment_groups.create(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
    student = student_in_course(:course => @course, :active_all => true).user
    ag.appointments.first.reserve_for student, @me
    @user = @me

    json = api_call(:get, "/api/v1/appointment_groups/#{ag.id}?include[]=child_events", {
                      :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => ag.id.to_s, :include => ['child_events']})
    json.keys.sort.should eql((expected_fields + ['appointments']).sort)
    json['id'].should eql ag.id
    json['requiring_action'].should be_false
    ajson = json['appointments']
    ajson.first.keys.should include('child_events')
    cjson = ajson.first['child_events']
    cjson.first.keys.should include('user')
    cjson.first['user']['id'].should eql student.id
  end

  it 'should get a reservable appointment group' do
    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    @user = @me
    ag = @course.appointment_groups.create(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]])
    ag.publish!

    json = api_call(:get, "/api/v1/appointment_groups/#{ag.id}", {
                      :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => ag.id.to_s})
    json.keys.sort.should eql((expected_fields + ['appointments']).sort)
    json['id'].should eql ag.id
    json['requiring_action'].should be_false
  end

  it 'should require action until the min has been met' do
    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    @user = @me
    ag = @course.appointment_groups.create(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :min_appointments_per_participant => 1)
    ag.publish!
    appt = ag.appointments.first

    json = api_call(:get, "/api/v1/appointment_groups/#{ag.id}", {
                      :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => ag.id.to_s})
    json.keys.sort.should eql((expected_fields + ['appointments']).sort)
    json['id'].should eql ag.id
    json['requiring_action'].should be_true

    appt.reserve_for(@me, @me)

    json = api_call(:get, "/api/v1/appointment_groups/#{ag.id}", {
                      :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => ag.id.to_s})
    json.keys.sort.should eql((expected_fields + ['appointments']).sort)
    json['id'].should eql ag.id
    json['requiring_action'].should be_false
  end

  it 'should enforce create permissions' do
    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    @user = @me
    raw_api_call(:post, "/api/v1/appointment_groups",
                      {:controller => 'appointment_groups', :action => 'create', :format => 'json'},
                      {:appointment_group => {:context_code => @course.asset_string, :title => "ohai"} })
    JSON.parse(response.body)['status'].should == 'unauthorized'
  end

  it 'should create a new appointment group' do
    json = api_call(:post, "/api/v1/appointment_groups",
                      {:controller => 'appointment_groups', :action => 'create', :format => 'json'},
                      {:appointment_group => {:context_code => @course.asset_string, :title => "ohai", :new_appointments => {'0' => ["2012-01-01 12:00:00", "2012-01-01 13:00:00"]}} })
    json.keys.sort.should eql((expected_fields + ['new_appointments']).sort)
    json['start_at'].should eql "2012-01-01T12:00:00Z"
    json['end_at'].should eql "2012-01-01T13:00:00Z"
    json['new_appointments'].size.should eql 1
    json['workflow_state'].should eql 'pending'
  end

  it 'should create a new appointment group with a sub_context' do
    json = api_call(:post, "/api/v1/appointment_groups",
                      {:controller => 'appointment_groups', :action => 'create', :format => 'json'},
                      {:appointment_group => {:context_code => @course.asset_string, :sub_context_code => @course.default_section.asset_string, :title => "ohai"} })
    json.keys.sort.should eql expected_fields
    json['workflow_state'].should eql 'pending'
    json['sub_context_code'].should eql @course.default_section.asset_string
  end

  it 'should enforce update permissions' do
    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    @user = @me
    ag = @course.appointment_groups.create(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
    raw_api_call(:put, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'update', :format => 'json', :id => ag.id.to_s},
                      {:appointment_group => {:title => "lol"} })
    JSON.parse(response.body)['status'].should == 'unauthorized'
  end

  it 'should update an appointment group' do
    ag = @course.appointment_groups.create(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
    json = api_call(:put, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'update', :format => 'json', :id => ag.id.to_s},
                      {:appointment_group => {:title => "lol"} })
    json.keys.sort.should eql expected_fields
    json['title'].should eql 'lol'
  end

  it 'should ignore updates to readonly fields' do
    ag = @course.appointment_groups.create(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
    json = api_call(:put, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'update', :format => 'json', :id => ag.id.to_s},
                      {:appointment_group => {:title => "lol", :sub_context_code => @course.default_section.asset_string} })
    json.keys.sort.should eql expected_fields
    json['title'].should eql 'lol'
    json['sub_context_code'].should be_nil
  end

  it 'should publish an appointment group in an update through the api' do
    ag = @course.appointment_groups.create(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
    ag.workflow_state.should == 'pending'
    json = api_call(:put, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'update', :format => 'json', :id => ag.id.to_s},
                      {:appointment_group => {:publish => '1'} })
    ag.reload
    ag.workflow_state.should == 'active'
  end

  it 'should publish an appointment group when creating through the api when requested' do
    json = api_call(:post, "/api/v1/appointment_groups",
                      {:controller => 'appointment_groups', :action => 'create', :format => 'json'},
                      {:appointment_group => {:context_code => @course.asset_string, :title => "ohai", :new_appointments => {'0' => ["2012-01-01 12:00:00", "2012-01-01 13:00:00"]}, :publish => '1'} })
    json['workflow_state'].should eql 'active'
    AppointmentGroup.find(json['id']).workflow_state.should eql 'active'
  end

  it 'should enforce delete permissions' do
    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    @user = @me
    ag = @course.appointment_groups.create(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
    raw_api_call(:delete, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'destroy', :format => 'json', :id => ag.id.to_s})
    JSON.parse(response.body)['status'].should == 'unauthorized'
  end

  it 'should delete an appointment group' do
    ag = @course.appointment_groups.create(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
    json = api_call(:delete, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'destroy', :format => 'json', :id => ag.id.to_s})
    json.keys.sort.should eql expected_fields
    json['workflow_state'].should eql 'deleted'
    ag.reload.should be_deleted
  end

  types = {
    'users' => proc {
      @ag = @course.appointment_groups.create(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"], ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]])
      @ag.publish!
      student1 = student_in_course(:course => @course, :active_all => true).user
      @ag.appointments.first.reserve_for student1, @me
      student2 = student_in_course(:course => @course, :active_all => true).user
    },
    'groups' => proc {
      cat = @course.group_categories.create
      @ag = @course.appointment_groups.create(:title => "yay", :sub_context_code => cat.asset_string, :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"], ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]])
      @ag.publish!
      group1 = cat.groups.create(:context => @course)
      group1.users << student_in_course(:course => @course, :active_all => true).user
      @ag.appointments.first.reserve_for group1, @me
      group2 = cat.groups.create(:context => @course)
      group2.users << student_in_course(:course => @course, :active_all => true).user
    }
  }
  types.each do |type, block|
    context "#{type.singularize}-level appointment groups" do
      before &block

      it "should return all #{type}" do
        json = api_call(:get, "/api/v1/appointment_groups/#{@ag.id}/#{type}", {
                          :controller => 'appointment_groups', :id => @ag.id.to_s, :action => type,
                          :format => 'json'})
        json.size.should eql 2
        json.map{ |j| j['id'] }.should eql @ag.possible_participants.map(&:id)
      end

      it "should paginate #{type}" do
        json = api_call(:get, "/api/v1/appointment_groups/#{@ag.id}/#{type}?per_page=1", {
                          :controller => 'appointment_groups', :id => @ag.id.to_s, :action => type,
                          :format => 'json', :per_page => '1'})
        json.size.should eql 1
        response.headers['Link'].should match(%r{</api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=2.*>; rel="next",</api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=1.*>; rel="first",</api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=2.*>; rel="last"})

        json = api_call(:get, "/api/v1/appointment_groups/#{@ag.id}/#{type}?per_page=1&page=2", {
                          :controller => 'appointment_groups', :id => @ag.id.to_s, :action => type,
                          :format => 'json', :per_page => '1', :page => '2'})
        json.size.should eql 1
        response.headers['Link'].should match(%r{</api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=1.*>; rel="prev",</api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=1.*>; rel="first",</api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=2.*>; rel="last"})
      end

      it "should return registered #{type}" do
        json = api_call(:get, "/api/v1/appointment_groups/#{@ag.id}/#{type}?registration_status=registered", {
                          :controller => 'appointment_groups', :id => @ag.id.to_s, :action => type,
                          :registration_status => 'registered', :format => 'json'})
        json.size.should eql 1
        json.map{ |j| j['id'] }.should eql @ag.possible_participants('registered').map(&:id)
      end

      it "should return unregistered #{type}" do
        json = api_call(:get, "/api/v1/appointment_groups/#{@ag.id}/#{type}?registration_status=unregistered", {
                          :controller => 'appointment_groups', :id => @ag.id.to_s, :action => type,
                          :registration_status => 'unregistered', :format => 'json'})
        json.size.should eql 1
        json.map{ |j| j['id'] }.should eql @ag.possible_participants('unregistered').map(&:id)
      end

      it "should not return non-#{type.singularize} participants" do
        (types.keys - [type]).each do |other_type|
          json = api_call(:get, "/api/v1/appointment_groups/#{@ag.id}/#{other_type}", {
                            :controller => 'appointment_groups', :id => @ag.id.to_s, :action => other_type, :format => 'json'})
          json.should be_empty
        end
      end
    end
  end
end
