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

describe "Accounts API", :type => :integration do
  before do
    Pseudonym.any_instance.stubs(:works_for_account?).returns(true)
    user_with_pseudonym(:active_all => true)
    @a1 = account_model(:name => 'root')
    @a1.add_user(@user)
    @a2 = account_model(:name => 'subby', :parent_account => @a1, :root_account => @a1, :sis_source_id => 'sis1')
    @a2.add_user(@user)
    @a3 = account_model(:name => 'no-access')
    # even if we have access to it implicitly, it's not listed
    @a4 = account_model(:name => 'implicit-access', :parent_account => @a1, :root_account => @a1)
  end

  it "should return the account list" do
    json = api_call(:get, "/api/v1/accounts.json",
                    { :controller => 'accounts', :action => 'index', :format => 'json' })
    json.sort_by { |a| a['id'] }.should == [
      {
        'id' => @a1.id,
        'name' => 'root',
        'root_account_id' => nil,
        'parent_account_id' => nil
      },
      {
        'id' => @a2.id,
        'name' => 'subby',
        'root_account_id' => @a1.id,
        'parent_account_id' => @a1.id,
        'sis_account_id' => 'sis1',
      },
    ]
  end

  it "should return an individual account" do
    # by id
    json = api_call(:get, "/api/v1/accounts/#{@a1.id}",
                    { :controller => 'accounts', :action => 'show', :id => @a1.to_param, :format => 'json' })
    json.should ==
      {
        'id' => @a1.id,
        'name' => 'root',
        'root_account_id' => nil,
        'parent_account_id' => nil
      }
  end

  it "should find accounts by sis in only this root account" do
    Account.default.add_user(@user)
    other_sub = account_model(:name => 'other_sub', :parent_account => Account.default, :root_account => Account.default, :sis_source_id => 'sis1')
    other_sub.add_user(@user)

    # this is scoped to Account.default
    json = api_call(:get, "/api/v1/accounts/sis_account_id:sis1",
                    { :controller => 'accounts', :action => 'show', :id => "sis_account_id:sis1", :format => 'json' })
    json['id'].should == other_sub.id

    # we shouldn't find the account in the other root account by sis
    other_sub.update_attribute(:sis_source_id, 'sis2')
    raw_api_call(:get, "/api/v1/accounts/sis_account_id:sis1",
                    { :controller => 'accounts', :action => 'show', :id => "sis_account_id:sis1", :format => 'json' })
    response.status.should == "404 Not Found"
  end

  it "should return courses for an account" do
    Time.use_zone(@user.time_zone) do
      @me = @user
      @c1 = course_model(:name => 'c1', :account => @a1, :root_account => @a1)
      @c1.enrollments.delete_all
      @c2 = course_model(:name => 'c2', :account => @a2, :root_account => @a1, :sis_source_id => 'sis2')
      @c2.course_sections.create!
      @c2.course_sections.create!
      @user = @me
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json' })

      [@c1, @c2].each { |c| c.reload }
      json.should == [
        {
          'id' => @c1.id,
          'name' => 'c1',
          'account_id' => @c1.account_id,
          'course_code' => 'c1',
          'sis_course_id' => nil,
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@c1.uuid}.ics" },
          'start_at' => @c1.start_at.as_json,
          'end_at' => @c1.end_at.as_json
        },
        {
          'id' => @c2.id,
          'name' => 'c2',
          'account_id' => @c2.account_id,
          'course_code' => 'c2',
          'sis_course_id' => 'sis2',
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@c2.uuid}.ics" },
          'start_at' => @c2.start_at.as_json,
          'end_at' => @c2.end_at.as_json
        }
      ]

      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json' },
                        { :hide_enrollmentless_courses => '1' })
      json.should == [
        {
          'id' => @c2.id,
          'name' => 'c2',
          'account_id' => @c2.account_id,
          'course_code' => 'c2',
          'sis_course_id' => 'sis2',
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@c2.uuid}.ics" },
          'start_at' => @c2.start_at.as_json,
          'end_at' => @c2.end_at.as_json
        }
      ]

      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json' },
                        { :per_page => 1, :page => 2 })
      json.should == [
        {
          'id' => @c2.id,
          'name' => 'c2',
          'account_id' => @c2.account_id,
          'course_code' => 'c2',
          'sis_course_id' => 'sis2',
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@c2.uuid}.ics" },
          'start_at' => @c2.start_at.as_json,
          'end_at' => @c2.end_at.as_json
        }
      ]
    end
  end

  it "should return courses filtered by state[]" do
    @me = @user
    [:c1, :c2].each do |course|
      instance_variable_set("@#{course}".to_sym, course_model(:name => course.to_s, :account => @a1))
    end
    @c2.destroy
    @user = @me

    json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?state[]=deleted",
      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json', :state => %w[deleted] })

    json.length.should eql 1
    json.first['name'].should eql 'c2'
  end

  it "should limit the maximum per-page returned" do
    @me = @user
    15.times { |i| course_model(:name => "c#{i}", :account => @a1, :root_account => @a1) }
    @user = @me
    api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?per_page=12", :controller => "accounts", :action => "courses_api", :account_id => @a1.to_param, :format => 'json', :per_page => '12').size.should == 12
    Setting.set('api_max_per_page', '5')
    api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?per_page=12", :controller => "accounts", :action => "courses_api", :account_id => @a1.to_param, :format => 'json', :per_page => '12').size.should == 5
  end
end

