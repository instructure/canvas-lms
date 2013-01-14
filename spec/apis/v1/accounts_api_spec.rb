#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

  it "should update the name for an account" do
    new_name = 'root2'
    json = api_call(:put, "/api/v1/accounts/#{@a1.id}",
                    { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' },
                    { :account => {:name => new_name} })
    expected =
        {
            'id' => @a1.id,
            'name' => new_name
        }

    (expected.to_a - json.to_a).should be_empty

    @a1.reload
    @a1.name.should == new_name
  end

  it "should not update with a blank name" do
    @a1.name = "blah"
    @a1.save!
    json = api_call(:put, "/api/v1/accounts/#{@a1.id}",
      { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' },
      { :account => {:name => ""} }, {}, :expected_status => 400)

    json["errors"]["name"].first["message"].should == "The account name cannot be blank"

    json = api_call(:put, "/api/v1/accounts/#{@a1.id}",
      { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' },
      { :account => {:name => nil} }, {}, :expected_status => 400)

    json["errors"]["name"].first["message"].should == "The account name cannot be blank"

    @a1.reload
    @a1.name.should == "blah"
  end

  it "should not update other attributes (yet)" do
    json = api_call(:put, "/api/v1/accounts/#{@a1.id}",
                    { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' },
                    { :account => {:settings => {:setting => 'set'}}} )

    expected =
      {
        'id' => @a1.id,
        'name' => @a1.name
      }

    (expected.to_a - json.to_a).should be_empty
    @a1.reload
    @a1.settings.should be_empty
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
      json.first['id'].should == @c1.id
      json.first['name'].should == 'c1'
      json.first['account_id'].should == @c1.account_id

      json.last['id'].should == @c2.id
      json.last['name'].should == 'c2'
      json.last['account_id'].should == @c2.account_id

      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json' },
                        { :hide_enrollmentless_courses => '1' })
      json.first['id'].should == @c2.id
      json.first['name'].should == 'c2'
      json.first['account_id'].should == @c2.account_id

      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json' },
                        { :per_page => 1, :page => 2 })
      json.first['id'].should == @c2.id
      json.first['name'].should == 'c2'
      json.first['account_id'].should == @c2.account_id

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

  describe "?with_enrollments" do
    before do
      @me = @user
      c1 = course_model(:account => @a1, :name => 'c1')    # has a teacher
      c2 = Course.create!(:account => @a1, :name => 'c2')  # has no enrollments
      @user = @me
    end

    it "should not apply if not specified" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json' })
      json.collect{|row|row['name']}.should eql ['c1', 'c2']
    end

    it "should filter on courses with enrollments" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?with_enrollments=1",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json', :with_enrollments => "1" })
      json.collect{|row|row['name']}.should eql ['c1']
    end

    it "should filter on courses without enrollments" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?with_enrollments=0",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json', :with_enrollments => "0" })
      json.collect{|row|row['name']}.should eql ['c2']
    end
  end

  describe "?published" do
    before do
      @me = @user
      [:c1, :c2].each do |course|
        instance_variable_set("@#{course}".to_sym, course_model(:name => course.to_s, :account => @a1))
      end
      @c1.offer!
      @user = @me
    end

    it "should not apply if not specified" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json' })
      json.collect{|row|row['name']}.should eql ['c1', 'c2']
    end

    it "should filter courses on published state" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?published=true",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json', :published => "true" })
      json.collect{|row|row['name']}.should eql ['c1']
    end

    it "should filter courses on non-published state" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?published=false",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json', :published => "false" })
      json.collect{|row|row['name']}.should eql ['c2']
    end
  end

  describe "?completed" do
    before do
      @me = @user
      [:c1, :c2, :c3, :c4].each do |course|
        instance_variable_set("@#{course}".to_sym, course_model(:name => course.to_s, :account => @a1, :conclude_at => 2.days.from_now))
      end

      @c2.conclude_at = 1.week.ago
      @c2.save!

      term = @c3.root_account.enrollment_terms.create! :end_at => 2.days.ago
      @c3.enrollment_term = term
      @c3.save!

      @c4.complete!
      @user = @me
    end

    it "should not apply if not specified" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json' })
      json.collect{|row|row['name']}.should eql ['c1', 'c2', 'c3', 'c4']
    end

    it "should filter courses on completed state" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?completed=yes",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json', :completed => "yes" })
      json.collect{|row|row['name']}.should eql ['c2', 'c3', 'c4']
    end

    it "should filter courses on non-completed state" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?completed=no",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json', :completed => "no" })
      json.collect{|row|row['name']}.should eql ['c1']
    end
  end

  describe "?by_teachers" do
    before do
      @me = @user
      course_with_teacher(:account => @a1, :course_name => 'c1a', :user => user_with_pseudonym(:account => @a1))
      @pseudonym.sis_user_id = 'a_sis_id'
      @pseudonym.save!
      @t1 = @teacher
      course_with_teacher(:account => @a1, :user => @t1, :course_name => 'c1b')
      course_with_teacher(:account => @a1, :course_name => 'c2')
      @teacher
      course_with_teacher(:account => @a1, :course_name => 'c3')
      @t3 = @teacher
      @user = @me
    end

    it "should not apply when not specified" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json' },
                      {}, {}, { :domain_root_account => @a1 })
      json.collect{|row|row['name']}.should eql ['c1a', 'c1b', 'c2', 'c3']
    end

    it "should filter courses by teacher enrollments" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?by_teachers[]=sis_user_id:a_sis_id&by_teachers[]=#{@t3.id}",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json', :by_teachers => ['sis_user_id:a_sis_id', "#{@t3.id}"] },
                      {}, {}, { :domain_root_account => @a1 })
      json.collect{|row|row['name']}.should eql ['c1a', 'c1b', 'c3']
    end

    it "should not break with an empty result set" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?by_teachers[]=bad_id",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json', :by_teachers => ['bad_id'] },
                      {}, {}, { :domain_root_account => @a1 })
      json.should eql []
    end
  end

  describe "?by_subaccounts" do
    before do
      @me = @user
      @sub1 = account_model(:name => 'sub1', :parent_account => @a1, :root_account => @a1, :sis_source_id => 'sub1')
      @sub1a = account_model(:name => 'sub1a', :parent_account => @sub1, :root_account => @a1, :sis_source_id => 'sub1a')
      @sub1b = account_model(:name => 'sub1b', :parent_account => @sub1, :root_account => @a1, :sis_source_id => 'sub1b')
      @sub2 = account_model(:name => 'sub2', :parent_account => @a1, :root_account => @a1, :sis_source_id => 'sub2')

      course_model(:name => 'in sub1', :account => @sub1)
      course_model(:name => 'in sub1a', :account => @sub1a)
      course_model(:name => 'in sub1b', :account => @sub1b)
      course_model(:name => 'in sub2', :account => @sub2)
      course_model(:name => 'in top level', :account => @a1)
      @user = @me
    end

    it "should not apply when not specified" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json' },
                      {}, {}, { :domain_root_account => @a1 })
      json.collect{|row|row['name']}.should eql ['in sub1', 'in sub1a', 'in sub1b', 'in sub2', 'in top level']
    end

    it "should include descendants of the specified subaccount" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?by_subaccounts[]=sis_account_id:sub1",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json', :by_subaccounts => ['sis_account_id:sub1'] },
                      {}, {}, { :domain_root_account => @a1 })
      json.collect{|row|row['name']}.should eql ['in sub1', 'in sub1a', 'in sub1b']
    end

    it "should work with multiple subaccounts specified" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?by_subaccounts[]=sis_account_id:sub1a&by_subaccounts[]=sis_account_id:sub1b",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json', :by_subaccounts => ['sis_account_id:sub1a', 'sis_account_id:sub1b'] },
                      {}, {}, { :domain_root_account => @a1 })
      json.collect{|row|row['name']}.should eql ['in sub1a', 'in sub1b']
    end

    it "should work with a numeric ID" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?by_subaccounts[]=#{@sub2.id}",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json', :by_subaccounts => ["#{@sub2.id}"] },
                      {}, {}, { :domain_root_account => @a1 })
      json.collect{|row|row['name']}.should eql ['in sub2']
    end

    it "should not break with an empty result set" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?by_subaccounts[]=bad_id",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param, :format => 'json', :by_subaccounts => ['bad_id'] },
                      {}, {}, { :domain_root_account => @a1 })
      json.should eql []
    end
  end

  it "should limit the maximum per-page returned" do
    @me = @user
    15.times { |i| course_model(:name => "c#{i}", :account => @a1, :root_account => @a1) }
    @user = @me
    api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?per_page=12", :controller => "accounts", :action => "courses_api", :account_id => @a1.to_param, :format => 'json', :per_page => '12').size.should == 12
    Setting.set('api_max_per_page', '5')
    api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?per_page=12", :controller => "accounts", :action => "courses_api", :account_id => @a1.to_param, :format => 'json', :per_page => '12').size.should == 5
  end

  context "account api extension" do
    module MockPlugin
      def self.extend_account_json(hash, account, user, session, includes)
        hash[:extra_thing] = "something"
      end
    end

    module BadMockPlugin
      def self.not_the_right_method
      end
    end

    include Api::V1::Account

    it "should allow a plugin to extend the account_json method" do
      Api::V1::Account.register_extension(BadMockPlugin).should be_false
      Api::V1::Account.register_extension(MockPlugin).should be_true

      begin
        account_json(@a1, @me, @session, [])[:extra_thing].should == "something"
      ensure
        Api::V1::Account.deregister_extension(MockPlugin)
      end
    end
  end
end
