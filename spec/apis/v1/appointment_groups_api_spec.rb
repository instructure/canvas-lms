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

describe AppointmentGroupsController, type: :request do
  before :once do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym(:active_user => true))
    @course1 = @course
    course_with_teacher(:active_all => true, :user => @user)
    @course2 = @course
    @me = @user
    @student1 = student_in_course(:course => @course, :active_all => true).user
    @student2 = student_in_course(:course => @course, :active_all => true).user
    @user = @me
  end

  expected_fields = [
    'appointments_count', 'context_codes', 'created_at', 'description',
    'end_at', 'html_url', 'id', 'location_address', 'location_name',
    'max_appointments_per_participant', 'min_appointments_per_participant',
    'participant_type', 'participant_visibility',
    'participants_per_appointment', 'requiring_action', 'start_at',
    'sub_context_codes', 'title', 'updated_at', 'url', 'workflow_state'
  ]

  it 'should return manageable appointment groups' do
    ag1 = AppointmentGroup.create!(:title => "something", :contexts => [@course1])
    cat = @course1.group_categories.create(name: "foo")
    ag2 = AppointmentGroup.create!(:title => "another", :contexts => [@course1], :sub_context_codes => [cat.asset_string])
    ag3 = AppointmentGroup.create!(:title => "inaccessible", :contexts => [Course.create!])
    ag4 = AppointmentGroup.create!(:title => "past", :contexts => [@course1, @course2], :new_appointments => [["#{Time.now.year - 1}-01-01 12:00:00", "#{Time.now.year - 1}-01-01 13:00:00"]])

    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable", {
                    :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'manageable'})
    json.size.should eql 2
    json.first.keys.sort.should eql expected_fields
    json.first.slice('id', 'title', 'participant_type').should eql({'id' => ag1.id, 'title' => 'something', 'participant_type' => 'User'})
    json.last.slice('id', 'title', 'participant_type').should eql({'id' => ag2.id, 'title' => 'another', 'participant_type' => 'Group'})
  end

  it "should return past manageable appointment groups, if requested" do
    ag = AppointmentGroup.create!(:title => "past", :new_appointments => [["#{Time.now.year - 1}-01-01 12:00:00", "#{Time.now.year - 1}-01-01 13:00:00"]], :contexts => [@course])
    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&include_past_appointments=1", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'manageable', :include_past_appointments => '1'})
    json.size.should eql 1
  end

  it "should restrict manageable appointment groups by context_codes" do
    ag1 = AppointmentGroup.create!(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :contexts => [@course1])
    ag2 = AppointmentGroup.create!(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :contexts => [@course2])

    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable", {
        :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'manageable'})
    json.size.should eql 2

    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&context_codes[]=course_#{@course2.id}", {
        :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'manageable', :context_codes => ["course_#{@course2.id}"]})
    json.size.should eql 1
  end

  it 'should return reservable appointment groups' do
    ag1 = AppointmentGroup.create!(:title => "can't reserve", :contexts => [@course])
    ag1.publish!
    ag2 = AppointmentGroup.create!(:title => "me neither", :contexts => [Course.create!])
    ag2.publish!

    student_in_course :course => course(:active_all => true), :user => @me
    ag3 = AppointmentGroup.create!(:title => "enrollment not active", :contexts => [@course])
    ag3.publish!

    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    ag4 = AppointmentGroup.create!(:title => "unpublished", :contexts => [@course])
    ag5 = AppointmentGroup.create!(:title => "no times", :contexts => [@course])
    ag5.publish!

    ag6 = AppointmentGroup.create!(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :contexts => [@course])
    ag6.publish!
    cat = @course.group_categories.create(name: "foo")
    mygroup = cat.groups.create(:context => @course)
    mygroup.users << @me
    @me.reload
    ag7 = AppointmentGroup.create!(:title => "double yay", :sub_context_codes => [cat.asset_string], :new_appointments => [["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]], :contexts => [@course])
    ag7.publish!
    ag8 = AppointmentGroup.create!(:title => "past", :new_appointments => [["#{Time.now.year - 1}-01-01 12:00:00", "#{Time.now.year - 1}-01-01 13:00:00"]], :contexts => [@course])
    ag8.publish!

    c1s2 = @course1.course_sections.create!
    c2s2 = @course2.course_sections.create!
    user_in_c1s2 = student_in_section(c1s2)
    user_in_c2s2 = student_in_section(c2s2)
    @user = @me

    ag9 = AppointmentGroup.create! :title => "multiple contexts / sub contexts",
                                   :contexts => [@course1, @course2],
                                   :sub_context_codes => [c1s2.asset_string, c2s2.asset_string],
                                   :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]]
    ag9.publish!

    json = api_call(:get, "/api/v1/appointment_groups?scope=reservable", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'reservable'})
    json.size.should eql 2
    json.first.keys.sort.should eql expected_fields
    json.first.slice('id', 'title', 'participant_type').should eql({'id' => ag6.id, 'title' => 'yay', 'participant_type' => 'User'})
    json.last.slice('id', 'title', 'participant_type').should eql({'id' => ag7.id, 'title' => 'double yay', 'participant_type' => 'Group'})

    [user_in_c1s2, user_in_c2s2].each do |user|
      @user = user
      json = api_call(:get, "/api/v1/appointment_groups?scope=reservable", {
                        :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'reservable'})
      json.size.should eql 1
      json.first['id'].should eql ag9.id
    end
  end

  it "should restrict reservable appointment groups by context_codes" do
    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    ag1 = AppointmentGroup.create!(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :contexts => [@course])
    ag1.publish!

    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    ag2 = AppointmentGroup.create!(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :contexts => [@course])
    ag2.publish!

    json = api_call(:get, "/api/v1/appointment_groups?scope=reservable", {
        :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'reservable'})
    json.size.should eql 2

    json = api_call(:get, "/api/v1/appointment_groups?scope=reservable&context_codes[]=course_#{@course.id}", {
        :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'reservable', :context_codes => ["course_#{@course.id}"]})
    json.size.should eql 1
  end

  it "should return past reservable appointment groups, if requested" do
    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    ag = AppointmentGroup.create!(:title => "past", :new_appointments => [["#{Time.now.year - 1}-01-01 12:00:00", "#{Time.now.year - 1}-01-01 13:00:00"]], :contexts => [@course])
    ag.publish!
    json = api_call(:get, "/api/v1/appointment_groups?scope=reservable&include_past_appointments=1", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'reservable', :include_past_appointments => '1'})
    json.size.should eql 1
  end

  it 'should paginate appointment groups' do
    ids = 5.times.map { |i| AppointmentGroup.create!(:title => "#{i}".object_id, :contexts => [@course]) }
    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&per_page=2", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json',
                      :scope => 'manageable', :per_page => '2'})
    json.size.should eql 2
    response.headers['Link'].should match(%r{<http://www.example.com/api/v1/appointment_groups\?.*page=2.*>; rel="next",<http://www.example.com/api/v1/appointment_groups\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/appointment_groups\?.*page=3.*>; rel="last"})

    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&per_page=2&page=3", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json',
                      :scope => 'manageable', :per_page => '2', :page => '3'})
    json.size.should eql 1
    response.headers['Link'].should match(%r{<http://www.example.com/api/v1/appointment_groups\?.*page=2.*>; rel="prev",<http://www.example.com/api/v1/appointment_groups\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/appointment_groups\?.*page=3.*>; rel="last"})
  end

  it 'should include appointments and child_events, if requested' do
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :contexts => [@course])
    ag.appointments.first.reserve_for @student1, @me

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
    cjson.first['user']['id'].should eql @student1.id
  end

  it 'should get a manageable appointment group' do
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])

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
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
    ag.appointments.first.reserve_for @student1, @me

    json = api_call(:get, "/api/v1/appointment_groups/#{ag.id}?include[]=child_events", {
                      :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => ag.id.to_s, :include => ['child_events']})
    json.keys.sort.should eql((expected_fields + ['appointments']).sort)
    json['id'].should eql ag.id
    json['requiring_action'].should be_false
    ajson = json['appointments']
    ajson.first.keys.should include('child_events')
    cjson = ajson.first['child_events']
    cjson.first.keys.should include('user')
    cjson.first['user']['id'].should eql @student1.id
  end

  it 'should get a reservable appointment group' do
    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    ag = AppointmentGroup.create!(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :contexts => [@course])
    ag.publish!

    json = api_call(:get, "/api/v1/appointment_groups/#{ag.id}", {
                      :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => ag.id.to_s})
    json.keys.sort.should eql((expected_fields + ['appointments']).sort)
    json['id'].should eql ag.id
    json['requiring_action'].should be_false
  end

  it 'should require action until the min has been met' do
    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    ag = AppointmentGroup.create!(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :min_appointments_per_participant => 1, :contexts => [@course])
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
    raw_api_call(:post, "/api/v1/appointment_groups",
                      {:controller => 'appointment_groups', :action => 'create', :format => 'json'},
                      {:appointment_group => {:context_codes => [@course.asset_string], :title => "ohai"} })
    JSON.parse(response.body)['status'].should == 'unauthorized'
  end

  it 'should create a new appointment group' do
    json = api_call(:post, "/api/v1/appointment_groups",
                      {:controller => 'appointment_groups', :action => 'create', :format => 'json'},
                      {:appointment_group => {:context_codes => [@course.asset_string], :title => "ohai", :new_appointments => {'0' => ["2012-01-01 12:00:00", "2012-01-01 13:00:00"]}} })
    json.keys.sort.should eql((expected_fields + ['new_appointments']).sort)
    json['start_at'].should eql "2012-01-01T12:00:00Z"
    json['end_at'].should eql "2012-01-01T13:00:00Z"
    json['new_appointments'].size.should eql 1
    json['workflow_state'].should eql 'pending'
  end

  it 'should create a new appointment group with a sub_context' do
    json = api_call(:post, "/api/v1/appointment_groups",
                      {:controller => 'appointment_groups', :action => 'create', :format => 'json'},
                      {:appointment_group => {:context_codes => [@course.asset_string], :sub_context_codes => [@course.default_section.asset_string], :title => "ohai"} })
    json.keys.sort.should eql expected_fields
    json['workflow_state'].should eql 'pending'
    json['sub_context_codes'].should eql [@course.default_section.asset_string]
  end

  it 'should enforce update permissions' do
    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
    raw_api_call(:put, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'update', :format => 'json', :id => ag.id.to_s},
                      {:appointment_group => {:title => "lol"} })
    JSON.parse(response.body)['status'].should == 'unauthorized'
  end

  it 'should update an appointment group' do
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
    json = api_call(:put, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'update', :format => 'json', :id => ag.id.to_s},
                      {:appointment_group => {:title => "lol"} })
    json.keys.sort.should eql expected_fields
    json['title'].should eql 'lol'
  end

  it 'should publish an appointment group in an update through the api' do
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
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
                      {:appointment_group => {:context_codes => [@course.asset_string], :title => "ohai", :new_appointments => {'0' => ["2012-01-01 12:00:00", "2012-01-01 13:00:00"]}, :publish => '1'} })
    json['workflow_state'].should eql 'active'
    AppointmentGroup.find(json['id']).workflow_state.should eql 'active'
  end

  it 'should enforce delete permissions' do
    student_in_course :course => course(:active_all => true), :user => @me, :active_all => true
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
    raw_api_call(:delete, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'destroy', :format => 'json', :id => ag.id.to_s})
    JSON.parse(response.body)['status'].should == 'unauthorized'
  end

  it 'should delete an appointment group' do
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
    json = api_call(:delete, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'destroy', :format => 'json', :id => ag.id.to_s})
    json.keys.sort.should eql expected_fields
    json['workflow_state'].should eql 'deleted'
    ag.reload.should be_deleted
  end

  it 'should include participant count, if requested' do
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00",
                                                                                "#{Time.now.year + 1}-01-01 13:00:00"],
                                                                               ["#{Time.now.year + 1}-01-01 13:00:00",
                                                                                "#{Time.now.year + 1}-01-01 14:00:00"]], :contexts => [@course])
    student_in_course(:course => @course, :active_all => true)
    ag.appointments.first.reserve_for @student, @me
    student_in_course(:course => @course, :active_all => true)
    ag.appointments.last.reserve_for @student, @me

    @user = @me

    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&include[]=participant_count", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'manageable', :include => ['participant_count']})
    json.size.should eql 1
    json.first.keys.sort.should eql((expected_fields + ['participant_count']).sort)
    json.first['participant_count'].should eql(2)
  end

  it "should include the user's reserved times, if requested" do
    year = Time.now.year + 1
    appointment_times = [["#{year}-01-01T12:00:00Z", "#{year}-01-01T13:00:00Z"],
                         ["#{year}-01-01T13:00:00Z", "#{year}-01-01T14:00:00Z"]]
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => appointment_times, :contexts => [@course])
    ag.publish!
    student_in_course(:course => @course, :active_all => true)
    child_events = []
    ag.appointments.each {|appt| child_events << appt.reserve_for(@student, @me)}

    @user = @student

    json = api_call(:get, "/api/v1/appointment_groups?include[]=reserved_times", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :include => ['reserved_times']})
    json.size.should eql 1
    json.first.keys.sort.should eql((expected_fields + ['reserved_times']).sort)
    json.first['reserved_times'].length.should eql(child_events.length)
    child_events.each do |event|
      json.first['reserved_times'].should include({"id" => event.id, "start_at" => event.start_at.iso8601, "end_at" => event.end_at.iso8601})
    end
  end
  
  types = {
    'users' => proc {
      @ag = AppointmentGroup.create!(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"], ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]], :contexts => [@course])
      @ag.publish!
      @ag.appointments.first.reserve_for @student1, @me
    },
    'groups' => proc {
      cat = @course.group_categories.create(name: "foo")
      @ag = AppointmentGroup.create!(:title => "yay", :sub_context_codes => [cat.asset_string], :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"], ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]], :contexts => [@course])
      @ag.publish!
      group1 = cat.groups.create(:context => @course)
      group1.users << @student1
      @ag.appointments.first.reserve_for group1, @me
      group2 = cat.groups.create(:context => @course)
      group2.users << @student2
    }
  }
  types.each do |type, block|
    context "#{type.singularize}-level appointment groups" do
      before :once, &block

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
        response.headers['Link'].should match(%r{<http://www.example.com/api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=2.*>; rel="next",<http://www.example.com/api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=2.*>; rel="last"})

        json = api_call(:get, "/api/v1/appointment_groups/#{@ag.id}/#{type}?per_page=1&page=2", {
                          :controller => 'appointment_groups', :id => @ag.id.to_s, :action => type,
                          :format => 'json', :per_page => '1', :page => '2'})
        json.size.should eql 1
        response.headers['Link'].should match(%r{<http://www.example.com/api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=1.*>; rel="prev",<http://www.example.com/api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=2.*>; rel="last"})
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
