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
    expect(json.size).to eql 2
    expect(json.first.keys.sort).to eql expected_fields
    expect(json.first.slice('id', 'title', 'participant_type')).to eql({'id' => ag1.id, 'title' => 'something', 'participant_type' => 'User'})
    expect(json.last.slice('id', 'title', 'participant_type')).to eql({'id' => ag2.id, 'title' => 'another', 'participant_type' => 'Group'})
  end

  it "should return past manageable appointment groups, if requested" do
    ag = AppointmentGroup.create!(:title => "past", :new_appointments => [["#{Time.now.year - 1}-01-01 12:00:00", "#{Time.now.year - 1}-01-01 13:00:00"]], :contexts => [@course])
    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&include_past_appointments=1", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'manageable', :include_past_appointments => '1'})
    expect(json.size).to eql 1
  end

  it "should restrict manageable appointment groups by context_codes" do
    ag1 = AppointmentGroup.create!(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :contexts => [@course1])
    ag2 = AppointmentGroup.create!(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :contexts => [@course2])

    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable", {
        :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'manageable'})
    expect(json.size).to eql 2

    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&context_codes[]=course_#{@course2.id}", {
        :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'manageable', :context_codes => ["course_#{@course2.id}"]})
    expect(json.size).to eql 1
  end

  it 'should return reservable appointment groups' do
    ag1 = AppointmentGroup.create!(:title => "can't reserve", :contexts => [@course])
    ag1.publish!
    ag2 = AppointmentGroup.create!(:title => "me neither", :contexts => [Course.create!])
    ag2.publish!

    student_in_course :course => course_factory(active_all: true), :user => @me
    ag3 = AppointmentGroup.create!(:title => "enrollment not active", :contexts => [@course])
    ag3.publish!

    student_in_course :course => course_factory(active_all: true), :user => @me, :active_all => true
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
    expect(json.size).to eql 2
    expect(json.first.keys.sort).to eql expected_fields
    expect(json.first.slice('id', 'title', 'participant_type')).to eql({'id' => ag6.id, 'title' => 'yay', 'participant_type' => 'User'})
    expect(json.last.slice('id', 'title', 'participant_type')).to eql({'id' => ag7.id, 'title' => 'double yay', 'participant_type' => 'Group'})

    [user_in_c1s2, user_in_c2s2].each do |user|
      @user = user
      json = api_call(:get, "/api/v1/appointment_groups?scope=reservable", {
                        :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'reservable'})
      expect(json.size).to eql 1
      expect(json.first['id']).to eql ag9.id
    end
  end

  it "should restrict reservable appointment groups by context_codes" do
    student_in_course :course => course_factory(active_all: true), :user => @me, :active_all => true
    ag1 = AppointmentGroup.create!(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :contexts => [@course])
    ag1.publish!

    student_in_course :course => course_factory(active_all: true), :user => @me, :active_all => true
    ag2 = AppointmentGroup.create!(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :contexts => [@course])
    ag2.publish!

    json = api_call(:get, "/api/v1/appointment_groups?scope=reservable", {
        :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'reservable'})
    expect(json.size).to eql 2

    json = api_call(:get, "/api/v1/appointment_groups?scope=reservable&context_codes[]=course_#{@course.id}", {
        :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'reservable', :context_codes => ["course_#{@course.id}"]})
    expect(json.size).to eql 1
  end

  it "should return past reservable appointment groups, if requested" do
    student_in_course :course => course_factory(active_all: true), :user => @me, :active_all => true
    ag = AppointmentGroup.create!(:title => "past", :new_appointments => [["#{Time.now.year - 1}-01-01 12:00:00", "#{Time.now.year - 1}-01-01 13:00:00"]], :contexts => [@course])
    ag.publish!
    json = api_call(:get, "/api/v1/appointment_groups?scope=reservable&include_past_appointments=1", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'reservable', :include_past_appointments => '1'})
    expect(json.size).to eql 1
  end

  it 'should paginate appointment groups' do
    ids = 5.times.map { |i| AppointmentGroup.create!(:title => "#{i}".object_id, :contexts => [@course]) }
    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&per_page=2", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json',
                      :scope => 'manageable', :per_page => '2'})
    expect(json.size).to eql 2
    expect(response.headers['Link']).to match(%r{<http://www.example.com/api/v1/appointment_groups\?.*page=2.*>; rel="next",<http://www.example.com/api/v1/appointment_groups\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/appointment_groups\?.*page=3.*>; rel="last"})

    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&per_page=2&page=3", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json',
                      :scope => 'manageable', :per_page => '2', :page => '3'})
    expect(json.size).to eql 1
    expect(response.headers['Link']).to match(%r{<http://www.example.com/api/v1/appointment_groups\?.*page=2.*>; rel="prev",<http://www.example.com/api/v1/appointment_groups\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/appointment_groups\?.*page=3.*>; rel="last"})
  end

  it 'should include appointments and child_events, if requested' do
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :contexts => [@course])
    ag.appointments.first.reserve_for @student1, @me

    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&include[]=appointments", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'manageable', :include => ['appointments']})
    expect(json.size).to eql 1
    expect(json.first.keys.sort).to eql((expected_fields + ['appointments']).sort)

    json = api_call(:get, "/api/v1/appointment_groups?scope=manageable&include[]=appointments&include[]=child_events", {
                      :controller => 'appointment_groups', :action => 'index', :format => 'json', :scope => 'manageable', :include => ['appointments', 'child_events']})
    expect(json.size).to eql 1
    expect(json.first.keys.sort).to eql((expected_fields + ['appointments']).sort)
    ajson = json.first['appointments']
    expect(ajson.first.keys).to include('child_events')
    cjson = ajson.first['child_events']
    expect(cjson.first.keys).to include('user')
    expect(cjson.first['user']['id']).to eql @student1.id
  end

  it 'should include all associated context codes, if requested' do
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])

    json = api_call(:get, "/api/v1/appointment_groups/#{ag.id}?include[]=all_context_codes", {
                      :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => ag.id.to_s, :include => ['all_context_codes']})
    expect(json.keys.sort).to eql((expected_fields + ['all_context_codes', 'appointments']).sort)
    expect(json['id']).to eql ag.id
    ccs = json['all_context_codes']
    expect(ccs).to eql [@course.asset_string]
  end

  it 'should get a manageable appointment group' do
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])

    json = api_call(:get, "/api/v1/appointment_groups/#{ag.id}", {
                      :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => ag.id.to_s})
    expect(json.keys.sort).to eql((expected_fields + ['appointments']).sort)
    expect(json['id']).to eql ag.id
    expect(json['requiring_action']).to be_falsey
    expect(json['appointments'].size).to eql 1
    expect(json['appointments'].first.keys).to include('child_events_count')
    expect(json['appointments'].first.keys).not_to include('child_events')
  end

  it 'should include child_events, if requested' do
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
    ag.appointments.first.reserve_for @student1, @me

    json = api_call(:get, "/api/v1/appointment_groups/#{ag.id}?include[]=child_events", {
                      :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => ag.id.to_s, :include => ['child_events']})
    expect(json.keys.sort).to eql((expected_fields + ['appointments']).sort)
    expect(json['id']).to eql ag.id
    expect(json['requiring_action']).to be_falsey
    ajson = json['appointments']
    expect(ajson.first.keys).to include('child_events')
    cjson = ajson.first['child_events']
    expect(cjson.first.keys).to include('user')
    expect(cjson.first['user']['id']).to eql @student1.id
  end

  it 'should get a reservable appointment group' do
    student_in_course :course => course_factory(active_all: true), :user => @me, :active_all => true
    ag = AppointmentGroup.create!(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :contexts => [@course])
    ag.publish!

    json = api_call(:get, "/api/v1/appointment_groups/#{ag.id}", {
                      :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => ag.id.to_s})
    expect(json.keys.sort).to eql((expected_fields + ['appointments']).sort)
    expect(json['id']).to eql ag.id
    expect(json['requiring_action']).to be_falsey
  end

  it "should return the correct context for appointment slots with existing signups in a different course" do
    course1 = course_with_teacher(:active_all => true).course
    student1 = student_in_course(:course => course1, :active_all => true).user
    course2 = course_with_teacher(:active_all => true, :user => @teacher).course
    student2 = student_in_course(:course => course2, :active_all => true).user
    ag = AppointmentGroup.create!(:title => 'bleh',
                             :participants_per_appointment => 2,
                             :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"],
                                                   ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]],
                             :contexts => [course1, course2])
    ag.publish!
    ag.appointments.first.reserve_for(student1, @teacher)
    json = api_call_as_user(student2, :get, "/api/v1/appointment_groups/#{ag.id}?include[]=child_events", {
      :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => ag.to_param, :include => ['child_events'] })
    appointments = json['appointments']
    expect(appointments.length).to eq 2
    expect(appointments[0]['context_code']).to eq course2.asset_string
    expect(appointments[1]['context_code']).to eq course2.asset_string
  end

  it 'should require action until the min has been met' do
    student_in_course :course => course_factory(active_all: true), :user => @me, :active_all => true
    ag = AppointmentGroup.create!(:title => "yay", :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]], :min_appointments_per_participant => 1, :contexts => [@course])
    ag.publish!
    appt = ag.appointments.first

    json = api_call(:get, "/api/v1/appointment_groups/#{ag.id}", {
                      :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => ag.id.to_s})
    expect(json.keys.sort).to eql((expected_fields + ['appointments']).sort)
    expect(json['id']).to eql ag.id
    expect(json['requiring_action']).to be_truthy

    appt.reserve_for(@me, @me)

    json = api_call(:get, "/api/v1/appointment_groups/#{ag.id}", {
                      :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => ag.id.to_s})
    expect(json.keys.sort).to eql((expected_fields + ['appointments']).sort)
    expect(json['id']).to eql ag.id
    expect(json['requiring_action']).to be_falsey
  end

  describe 'past appointments' do
    before :once do
      @ag = AppointmentGroup.create!(:title => "yay",
                                     :new_appointments => [["#{Time.now.year - 1}-01-01 12:00:00", "#{Time.now.year - 1}-01-01 13:00:00"],
                                                           ["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]],
                                     :contexts => [@course])
      @ag.publish!
    end

    it 'returns past appointment slots for teachers' do
      json = api_call_as_user(@teacher, :get, "/api/v1/appointment_groups/#{@ag.id}",
              { :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => @ag.to_param})
      expect(json['appointments'].size).to eq 2
    end

    it 'does not return past appointment slots for students' do
      json = api_call_as_user(@student, :get, "/api/v1/appointment_groups/#{@ag.id}",
              { :controller => 'appointment_groups', :action => 'show', :format => 'json', :id => @ag.to_param})
      expect(json['appointments'].size).to eq 1
    end
  end

  it 'should enforce create permissions' do
    student_in_course :course => course_factory(active_all: true), :user => @me, :active_all => true
    raw_api_call(:post, "/api/v1/appointment_groups",
                      {:controller => 'appointment_groups', :action => 'create', :format => 'json'},
                      {:appointment_group => {:context_codes => [@course.asset_string], :title => "ohai"} })
    expect(JSON.parse(response.body)['status']).to eq 'unauthorized'
  end

  it 'should create a new appointment group' do
    json = api_call(:post, "/api/v1/appointment_groups",
                      {:controller => 'appointment_groups', :action => 'create', :format => 'json'},
                      {:appointment_group => {:context_codes => [@course.asset_string], :title => "ohai", :new_appointments => {'0' => ["2012-01-01 12:00:00", "2012-01-01 13:00:00"]}} })
    expect(json.keys.sort).to eql((expected_fields + ['new_appointments']).sort)
    expect(json['start_at']).to eql "2012-01-01T12:00:00Z"
    expect(json['end_at']).to eql "2012-01-01T13:00:00Z"
    expect(json['new_appointments'].size).to eql 1
    expect(json['workflow_state']).to eql 'pending'
  end

  it 'should create a new appointment group with a sub_context' do
    json = api_call(:post, "/api/v1/appointment_groups",
                      {:controller => 'appointment_groups', :action => 'create', :format => 'json'},
                      {:appointment_group => {:context_codes => [@course.asset_string], :sub_context_codes => [@course.default_section.asset_string], :title => "ohai"} })
    expect(json.keys.sort).to eql expected_fields
    expect(json['workflow_state']).to eql 'pending'
    expect(json['sub_context_codes']).to eql [@course.default_section.asset_string]
  end

  it 'should enforce update permissions' do
    student_in_course :course => course_factory(active_all: true), :user => @me, :active_all => true
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
    raw_api_call(:put, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'update', :format => 'json', :id => ag.id.to_s},
                      {:appointment_group => {:title => "lol"} })
    expect(JSON.parse(response.body)['status']).to eq 'unauthorized'
  end

  it 'should update an appointment group' do
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
    json = api_call(:put, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'update', :format => 'json', :id => ag.id.to_s},
                      {:appointment_group => {:title => "lol"} })
    expect(json.keys.sort).to eql expected_fields
    expect(json['title']).to eql 'lol'
  end

  it 'should publish an appointment group in an update through the api' do
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
    expect(ag.workflow_state).to eq 'pending'
    json = api_call(:put, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'update', :format => 'json', :id => ag.id.to_s},
                      {:appointment_group => {:publish => '1'} })
    ag.reload
    expect(ag.workflow_state).to eq 'active'
  end

  it 'should publish an appointment group when creating through the api when requested' do
    json = api_call(:post, "/api/v1/appointment_groups",
                      {:controller => 'appointment_groups', :action => 'create', :format => 'json'},
                      {:appointment_group => {:context_codes => [@course.asset_string], :title => "ohai", :new_appointments => {'0' => ["2012-01-01 12:00:00", "2012-01-01 13:00:00"]}, :publish => '1'} })
    expect(json['workflow_state']).to eql 'active'
    expect(AppointmentGroup.find(json['id']).workflow_state).to eql 'active'
  end

  it 'should enforce delete permissions' do
    student_in_course :course => course_factory(active_all: true), :user => @me, :active_all => true
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
    raw_api_call(:delete, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'destroy', :format => 'json', :id => ag.id.to_s})
    expect(JSON.parse(response.body)['status']).to eq 'unauthorized'
  end

  it 'should delete an appointment group' do
    ag = AppointmentGroup.create!(:title => "something", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
    json = api_call(:delete, "/api/v1/appointment_groups/#{ag.id}",
                      {:controller => 'appointment_groups', :action => 'destroy', :format => 'json', :id => ag.id.to_s})
    expect(json.keys.sort).to eql expected_fields
    expect(json['workflow_state']).to eql 'deleted'
    expect(ag.reload).to be_deleted
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
    expect(json.size).to eql 1
    expect(json.first.keys.sort).to eql((expected_fields + ['participant_count']).sort)
    expect(json.first['participant_count']).to eql(2)
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
    expect(json.size).to eql 1
    expect(json.first.keys.sort).to eql((expected_fields + ['reserved_times']).sort)
    expect(json.first['reserved_times'].length).to eql(child_events.length)
    child_events.each do |event|
      expect(json.first['reserved_times']).to include({"id" => event.id, "start_at" => event.start_at.iso8601, "end_at" => event.end_at.iso8601})
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
        expect(json.size).to eql 2
        expect(json.map{ |j| j['id'] }).to eql @ag.possible_participants.map(&:id)
      end

      it "should paginate #{type}" do
        json = api_call(:get, "/api/v1/appointment_groups/#{@ag.id}/#{type}?per_page=1", {
                          :controller => 'appointment_groups', :id => @ag.id.to_s, :action => type,
                          :format => 'json', :per_page => '1'})
        expect(json.size).to eql 1
        expect(response.headers['Link']).to match(%r{<http://www.example.com/api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=2.*>; rel="next",<http://www.example.com/api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=2.*>; rel="last"})

        json = api_call(:get, "/api/v1/appointment_groups/#{@ag.id}/#{type}?per_page=1&page=2", {
                          :controller => 'appointment_groups', :id => @ag.id.to_s, :action => type,
                          :format => 'json', :per_page => '1', :page => '2'})
        expect(json.size).to eql 1
        expect(response.headers['Link']).to match(%r{<http://www.example.com/api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=1.*>; rel="prev",<http://www.example.com/api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/appointment_groups/#{@ag.id}/#{type}\?.*page=2.*>; rel="last"})
      end

      it "should return registered #{type}" do
        json = api_call(:get, "/api/v1/appointment_groups/#{@ag.id}/#{type}?registration_status=registered", {
                          :controller => 'appointment_groups', :id => @ag.id.to_s, :action => type,
                          :registration_status => 'registered', :format => 'json'})
        expect(json.size).to eql 1
        expect(json.map{ |j| j['id'] }).to eql @ag.possible_participants(registration_status: 'registered').map(&:id)
      end

      it "should return unregistered #{type}" do
        json = api_call(:get, "/api/v1/appointment_groups/#{@ag.id}/#{type}?registration_status=unregistered", {
                          :controller => 'appointment_groups', :id => @ag.id.to_s, :action => type,
                          :registration_status => 'unregistered', :format => 'json'})
        expect(json.size).to eql 1
        expect(json.map{ |j| j['id'] }).to eql @ag.possible_participants(registration_status: 'unregistered').map(&:id)
      end

      it "should not return non-#{type.singularize} participants" do
        (types.keys - [type]).each do |other_type|
          json = api_call(:get, "/api/v1/appointment_groups/#{@ag.id}/#{other_type}", {
                            :controller => 'appointment_groups', :id => @ag.id.to_s, :action => other_type, :format => 'json'})
          expect(json).to be_empty
        end
      end
    end
  end

  describe "next_appointment" do
    before :once do
      @ag1 = AppointmentGroup.create!(:title => "past", :contexts => [@course2], :new_appointments =>
                                       [["#{Time.now.year - 1}-01-01 12:00:00", "#{Time.now.year - 1}-01-01 13:00:00"]])
      @ag1.publish!
      @ag2 = AppointmentGroup.create!(:title => "future1", :contexts => [@course2],
                                      :participants_per_appointment => 1, :max_appointments_per_participant => 1,
                                      :new_appointments =>
                                       [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"],
                                        ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]])
      @ag2.publish!
      @ag2.appointments.first.reserve_for(@student1, @me)
      @path = "/api/v1/appointment_groups/next_appointment?appointment_group_ids[]=#{@ag1.to_param}&appointment_group_ids[]=#{@ag2.to_param}"
      @params = { :controller => 'appointment_groups', :action => 'next_appointment', :format => 'json',
                  :appointment_group_ids => [@ag1.to_param, @ag2.to_param] }
    end

    it 'returns the first available appointment in the future' do
      json = api_call_as_user(@student2, :get, @path, @params)
      expect(json.length).to eq 1
      expect(json[0]['id']).to eq @ag2.appointments.last.id
    end

    it 'returns an empty array if no future appointments are available' do
      @ag2.appointments.last.reserve_for(@student2, @me)
      json = api_call_as_user(@student2, :get, @path, @params)
      expect(json.length).to eq 0
    end
  end
end
