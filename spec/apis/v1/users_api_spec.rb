#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../file_uploads_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../cassandra_spec_helper')

class TestUserApi
  include Api::V1::User
  attr_accessor :services_enabled, :context, :current_user, :params, :request
  def service_enabled?(service); @services_enabled.include? service; end

  def avatar_image_url(*args); "avatar_image_url(#{args.first})"; end

  def course_student_grades_url(course_id, user_id); ""; end

  def course_user_url(course_id, user_id); ""; end

  def initialize
    @domain_root_account = Account.default
    @params = {}
    @request = OpenStruct.new
  end
end

describe Api::V1::User do
  before :once do
    @admin = account_admin_user
    course_with_student(:user => user_with_pseudonym(:name => 'Student', :username => 'pvuser@example.com'))
    @student = @user
    @student.pseudonym.update_attribute(:sis_user_id, 'sis-user-id')
    @user = @admin
    Account.default.tap { |a| a.enable_service(:avatars) }.save
    user_with_pseudonym(:user => @user)
  end

  before :each do
    @test_api = TestUserApi.new
    @test_api.services_enabled = []
    @test_api.request.protocol = 'http'
  end

  context 'user_json' do
    it 'should support optionally providing the avatar if avatars are enabled' do
      @student.account.set_service_availability(:avatars, false)
      @student.account.save!
      expect(@test_api.user_json(@student, @admin, {}, ['avatar_url'], @course).has_key?("avatar_url")).to be_falsey
      @student.account.set_service_availability(:avatars, true)
      @student.account.save!
      expect(@test_api.user_json(@student, @admin, {}, [], @course).has_key?("avatar_url")).to be_falsey
      expect(@test_api.user_json(@student, @admin, {}, ['avatar_url'], @course)["avatar_url"]).to match("h:/images/messages/avatar-50.png")
    end

    it 'only loads pseudonyms for the user once, even if there are multiple enrollments' do
      sis_stub = SisPseudonym.for(@student, @course, type: :trusted)
      expect(SisPseudonym).to receive(:for).once.and_return(sis_stub)
      ta_enrollment = ta_in_course(user: @student, course: @course)
      teacher_enrollment = teacher_in_course(user: @student, course: @course)
      @test_api.current_user = @admin
      @test_api.user_json(@student, @admin, {}, [], @course, [ta_enrollment, teacher_enrollment])
    end

    it 'should support optionally including group_ids' do
      @group = @course.groups.create!(:name => "My Group")
      @group.add_user(@student, 'accepted', true)
      expect(@test_api.user_json(@student, @admin, {}, [], @course).has_key?("group_ids")).to be_falsey
      expect(@test_api.user_json(@student, @admin, {}, ['group_ids'], @course)["group_ids"]).to eq([@group.id])
    end

    it 'should use the correct SIS pseudonym' do
      @user = User.create!(:name => 'User')
      @account2 = Account.create!
      @user.pseudonyms.create!(:unique_id => 'abc', :account => @account2) { |p| p.sis_user_id = 'abc' }
      @user.pseudonyms.create!(:unique_id => 'xyz', :account => Account.default) { |p| p.sis_user_id = 'xyz' }
      expect(@test_api.user_json(@user, @admin, {}, [], Account.default)).to eq({
          'name' => 'User',
          'sortable_name' => 'User',
          'sis_import_id' => nil,
          'id' => @user.id,
          'short_name' => 'User',
          'sis_user_id' => 'xyz',
          'integration_id' => nil,
          'login_id' => 'xyz'
        })
    end

    it 'should show SIS data to sub account admins' do
      student = User.create!(:name => 'User')
      student.pseudonyms.create!(:unique_id => 'xyz', :account => Account.default) { |p| p.sis_user_id = 'xyz' }

      sub_account = Account.create!(:parent_account => Account.default)
      sub_admin = account_admin_user(:account => sub_account)

      course = sub_account.courses.create!

      expect(@test_api.user_json(student, sub_admin, {}, [], course)).to eq({
        'name' => 'User',
        'sortable_name' => 'User',
        'id' => student.id,
        'short_name' => 'User',
        'sis_user_id' => 'xyz',
        'integration_id' => nil,
        'login_id' => 'xyz'
      })
    end

    it 'should show SIS data to teachers only in courses they are teachers in' do
      student = User.create!(:name => 'User')
      student.pseudonyms.create!(:unique_id => 'xyz', :account => Account.default) { |p| p.sis_user_id = 'xyz' }

      teacher = user_factory
      course1 = course_factory(active_all: true)
      course1.enroll_user(teacher, "TeacherEnrollment").accept!
      course2 = course_factory(active_all: true)
      course2.enroll_user(teacher, "StudentEnrollment").accept!

      expect(@test_api.user_json(student, teacher, {}, [], course1)).to eq({
        'name' => 'User',
        'sortable_name' => 'User',
        'id' => student.id,
        'short_name' => 'User',
        'sis_user_id' => 'xyz',
        'integration_id' => nil,
        'login_id' => 'xyz'
      })

      expect(@test_api.user_json(student, teacher, {}, [], course2)).to eq({
        'name' => 'User',
        'sortable_name' => 'User',
        'id' => student.id,
        'short_name' => 'User'
      })

    end

    it 'should show SIS data to teachers in groups in their courses' do
      student = User.create!(:name => 'User')
      student.pseudonyms.create!(:unique_id => 'xyz', :account => Account.default) { |p| p.sis_user_id = 'xyz' }

      teacher = user_factory
      course1 = course_factory(active_all: true)
      course1.enroll_user(teacher, "TeacherEnrollment").accept!
      course2 = course_factory(active_all: true)
      course2.enroll_user(teacher, "StudentEnrollment").accept!
      group1 = course1.groups.create!(:name => 'Group 1')
      group2 = course2.groups.create!(:name => 'Group 2')

      expect(@test_api.user_json(student, teacher, {}, [], group1)).to eq({
        'name' => 'User',
        'sortable_name' => 'User',
        'id' => student.id,
        'short_name' => 'User',
        'sis_user_id' => 'xyz',
        'integration_id' => nil,
        'login_id' => 'xyz'
      })

      expect(@test_api.user_json(student, teacher, {}, [], group2)).to eq({
        'name' => 'User',
        'sortable_name' => 'User',
        'id' => student.id,
        'short_name' => 'User'
      })

    end

    it 'should use the SIS pseudonym instead of another pseudonym' do
      @user = User.create!(:name => 'User')
      @account2 = Account.create!
      @user.pseudonyms.create!(:unique_id => 'abc', :account => Account.default)
      p = @user.pseudonyms.create!(:unique_id => 'xyz', :account => Account.default) { |p| p.sis_user_id = 'xyz' }
      sis_batch = p.account.sis_batches.create
      SisBatch.where(id: sis_batch).update_all(workflow_state: 'imported')
      Pseudonym.where(id: p.id).update_all(sis_batch_id: sis_batch.id)
      expect(@test_api.user_json(@user, @admin, {}, [], Account.default)).to eq({
          'name' => 'User',
          'sortable_name' => 'User',
          'sis_import_id' => sis_batch.id,
          'id' => @user.id,
          'short_name' => 'User',
          'sis_user_id' => 'xyz',
          'integration_id' => nil,
          'login_id' => 'xyz'
        })
    end

    it 'should use an sis pseudonym from another account if necessary' do
      @user = User.create!(:name => 'User')
      @account2 = Account.create!
      @user.pseudonyms.destroy_all
      p = @user.pseudonyms.create!(:unique_id => 'abc', :account => @account2) { |p| p.sis_user_id = 'a'}
      allow(p).to receive(:works_for_account?).with(Account.default, true).and_return(true)
      allow_any_instantiation_of(Account.default).to receive(:trust_exists?).and_return(true)
      allow_any_instantiation_of(Account.default).to receive(:trusted_account_ids).and_return([@account2.id])
      expect(HostUrl).to receive(:context_host).with(@account2).and_return('school1')
      expect(@test_api.user_json(@user, @admin, {}, [], Account.default)).to eq({
          'name' => 'User',
          'sortable_name' => 'User',
          'id' => @user.id,
          'short_name' => 'User',
          'login_id' => 'abc',
          'sis_user_id' => 'a',
          'integration_id' => nil,
          'root_account' => 'school1',
          'sis_import_id' => nil,
      })
    end

    it 'should use the correct pseudonym' do
      @user = User.create!(:name => 'User')
      @account2 = Account.create!
      @user.pseudonyms.create!(:unique_id => 'abc', :account => @account2)
      @pseudonym = @user.pseudonyms.create!(:unique_id => 'xyz', :account => Account.default)
      allow(SisPseudonym).to receive(:for).with(@user, Account.default, type: :implicit, require_sis: false).and_return(@pseudonym)
      expect(@test_api.user_json(@user, @admin, {}, [], Account.default)).to eq({
          'name' => 'User',
          'sortable_name' => 'User',
          'id' => @user.id,
          'short_name' => 'User',
          'integration_id' => nil,
          'sis_import_id' => nil,
          'sis_user_id' => nil,
          'login_id' => 'xyz',
        })
    end

    it "requires :view_user_logins to return login_id" do
      RoleOverride.create!(context: Account.default, role: Role.get_built_in_role('AccountAdmin'),
            permission: 'view_user_logins', enabled: false)
      @user = User.create!(:name => 'Test User')
      @user.pseudonyms.create!(:unique_id => 'abc', :account => Account.default)
      json = @test_api.user_json(@user, @admin, {}, [], Account.default)
      expect(json.keys).not_to include 'login_id'
    end

    context "include[]=email" do
      before :once do
        @user = User.create!(:name => 'User')
        @user.pseudonyms.create!(:unique_id => 'abc', :account => Account.default)
        @user.communication_channels.create(:path => 'abc@example.com').confirm!
      end

      it "includes email if requested" do
        json = @test_api.user_json(@user, @admin, {}, ['email'], Account.default)
        expect(json['email']).to eq 'abc@example.com'
      end

      it "does not include email without :read_email_addresses permission" do
        RoleOverride.create!(context: Account.default, role: Role.get_built_in_role('AccountAdmin'),
            permission: 'read_email_addresses', enabled: false)
        json = @test_api.user_json(@user, @admin, {}, ['email'], Account.default)
        expect(json.keys).not_to include 'email'
      end
    end

    context "computed scores" do
      before :once do
        @enrollment.scores.create!
        assignment_group = @course.assignment_groups.create!
        @enrollment.find_score(course_score: true).
          update!(current_score: 95.0, final_score: 85.0, unposted_current_score: 90.0, unposted_final_score: 87.0)
        @enrollment.find_score(assignment_group_id: assignment_group).
          update!(current_score: 50.0, final_score: 40.0, unposted_current_score: 55.0, unposted_final_score: 45.0)
        @student1 = @student
        @student1_enrollment = @enrollment
        @student2 = course_with_student(:course => @course).user
      end

      before :each do
        @course.grading_standard_enabled = true
        @course.save!
      end

      it "should return posted course scores as admin" do
        json = @test_api.user_json(@student, @admin, {}, [], @course, [@student1_enrollment])
        expect(json['enrollments'].first['grades']).to eq({
          "html_url" => "",
          "current_score" => 95.0,
          "final_score" => 85.0,
          "current_grade" => "A",
          "final_grade" => "B",
          "unposted_current_grade" => "A-",
          "unposted_current_score" => 90.0,
          "unposted_final_grade" => "B+",
          "unposted_final_score" => 87.0
        })
      end

      it "should not return unposted course scores as a student" do
        json = @test_api.user_json(@student1, @student1, {}, [], @course, [@student1_enrollment])
        expect(json['enrollments'].first['grades']).to eq({
          "html_url" => "",
          "current_score" => 95.0,
          "final_score" => 85.0,
          "current_grade" => "A",
          "final_grade" => "B",
        })
      end

      it "should not return course scores as another student" do
        json = @test_api.user_json(@student1, @student2, {}, [], @course, [@student1_enrollment])
        expect(json['enrollments'].first['grades'].keys).to eq ["html_url"]
      end
    end

    def test_context(mock_context, context_to_pass)
      expect(mock_context).to receive(:account).and_return(mock_context)
      expect(mock_context).to receive(:global_id).and_return(42).twice
      expect(mock_context).to receive(:grants_any_right?).with(@admin, :manage_students, :read_sis).and_return(true)
      expect(mock_context).to receive(:grants_right?).with(@admin, {}, :view_user_logins).and_return(true)
      json = if context_to_pass
        @test_api.user_json(@student, @admin, {}, [], context_to_pass)
      else
        @test_api.user_json(@student, @admin, {}, [])
      end
      expect(json).to eq({
        "name"=>"Student",
        "sortable_name"=>"Student",
        "id"=>@student.id,
        "short_name"=>"Student",
        "sis_user_id"=>"sis-user-id",
        "integration_id" => nil,
        "sis_import_id"=>@student.pseudonym.sis_batch_id,
        "login_id" => "pvuser@example.com"
      })
    end

    it 'should support manually passing the context' do
      mock_context = double()
      test_context(mock_context, mock_context)
    end

    it 'should support loading the context as a member var' do
      @test_api.context = double()
      test_context(@test_api.context, nil)
    end
  end

  context 'user_json_is_admin?' do

    it 'should support manually passing the current user' do
      @test_api.context = double()
      expect(@test_api.context).to receive(:global_id).and_return(42)
      expect(@test_api.context).to receive(:account).and_return(@test_api.context)
      expect(@test_api.context).to receive(:grants_any_right?).with(@admin, :manage_students, :read_sis).and_return(true)
      @test_api.current_user = @admin
      expect(@test_api.user_json_is_admin?).to eq true
    end

    it 'should support loading the current user as a member var' do
      mock_context = double()
      expect(mock_context).to receive(:global_id).and_return(42)
      expect(mock_context).to receive(:account).and_return(mock_context)
      expect(mock_context).to receive(:grants_any_right?).with(@admin, :manage_students, :read_sis).and_return(true)
      @test_api.current_user = @admin
      expect(@test_api.user_json_is_admin?(mock_context, @admin)).to eq true
    end

    it 'should support loading multiple different things (via args)' do
      expect(@test_api.user_json_is_admin?(@admin, @student)).to be_falsey
      expect(@test_api.user_json_is_admin?(@student, @admin)).to be_truthy
      expect(@test_api.user_json_is_admin?(@student, @admin)).to be_truthy
      expect(@test_api.user_json_is_admin?(@admin, @student)).to be_falsey
      expect(@test_api.user_json_is_admin?(@admin, @student)).to be_falsey
    end

    it 'should support loading multiple different things (via member vars)' do
      @test_api.current_user = @student
      @test_api.context = @admin
      expect(@test_api.user_json_is_admin?).to be_falsey
      @test_api.current_user = @admin
      @test_api.context = @student
      expect(@test_api.user_json_is_admin?).to be_truthy
      expect(@test_api.user_json_is_admin?).to be_truthy
      @test_api.current_user = @student
      @test_api.context = @admin
      expect(@test_api.user_json_is_admin?).to be_falsey
      expect(@test_api.user_json_is_admin?).to be_falsey
    end

  end

end

describe "Users API", type: :request do
  def avatar_url(id)
    "http://www.example.com/images/users/#{User.avatar_key(id)}?fallback=http%3A%2F%2Fwww.example.com%2Fimages%2Fmessages%2Favatar-50.png"
  end

  before :once do
    @admin = account_admin_user
    course_with_student(:user => user_with_pseudonym(:name => 'Student', :username => 'pvuser@example.com', :active_user => true))
    @student.pseudonym.update_attribute(:sis_user_id, 'sis-user-id')
    @user = @admin
    Account.default.tap { |a| a.enable_service(:avatars) }.save
    user_with_pseudonym(:user => @user)
  end

  it "shouldn't return disallowed avatars" do
    @user = @student
    raw_api_call(:get, "/api/v1/users/#{@admin.id}/avatars",
                 :controller => "profile", :action => "profile_pics", :user_id => @admin.to_param, :format => 'json')
    assert_status(401)
  end

  shared_examples_for "page view api" do
    describe "page view api" do
      before do
        @timestamp = Time.zone.at(1.day.ago.to_i)
        page_view_model(:user => @student, :created_at => @timestamp - 1.day)
        page_view_model(:user => @student, :created_at => @timestamp + 1.day)
        page_view_model(:user => @student, :created_at => @timestamp, developer_key: DeveloperKey.default)
      end

      it "should return page view history" do
        Setting.set('api_max_per_page', '2')
        json = api_call(:get, "/api/v1/users/#{@student.id}/page_views?per_page=1000",
                           { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :per_page => '1000' })
        expect(json.size).to eq 2
        json.each { |j| expect(j['url']).to eq "http://www.example.com/courses/1" }
        expect(json[0]['created_at']).to be > json[1]['created_at']
        expect(json[0]['app_name']).to be_nil
        expect(json[1]['app_name']).to eq 'User-Generated'
        expect(response.headers['Link']).to match /next/
        expect(response.headers['Link']).not_to match /last/
        response.headers['Link'].split(',').find { |l| l =~ /<([^>]+)>.+next/ }
        url = $1
        path, querystring = url.split("?")
        page = Rack::Utils.parse_nested_query(querystring)['page']
        json = api_call(:get, url,
                           { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :page => page, :per_page => Setting.get('api_max_per_page', '2') })
        expect(json.size).to eq 1
        json.each { |j| expect(j['url']).to eq "http://www.example.com/courses/1" }
        expect(response.headers['Link']).not_to match /next/
        expect(response.headers['Link']).to match /last/
      end

      it "should recognize start_time parameter" do
        Setting.set('api_max_per_page', '3')
        start_time = @timestamp.iso8601
        json = api_call(:get, "/api/v1/users/#{@student.id}/page_views?start_time=#{start_time}",
                           { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :start_time => start_time })
        expect(json.size).to eq 2
        json.each { |j| expect(CanvasTime.try_parse(j['created_at']).to_i).to be >= @timestamp.to_i }
      end

      it "should recognize end_time parameter" do
        Setting.set('api_max_per_page', '3')
        end_time = @timestamp.iso8601
        json = api_call(:get, "/api/v1/users/#{@student.id}/page_views?end_time=#{end_time}",
                           { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :end_time => end_time })
        expect(json.size).to eq 2
        json.each { |j| expect(CanvasTime.try_parse(j['created_at']).to_i).to be <= @timestamp.to_i }
      end
    end
  end

  include_examples "page view api"

  describe "cassandra page views" do
    before do
      # can't use :once'd @student, since cassandra doesn't reset
      student_in_course(:course => @course, :user => user_with_pseudonym(:name => 'Student', :username => 'pvuser2@example.com', :active_user => true))
      @user = @admin
    end
    include_examples "cassandra page views"
    include_examples "page view api"
  end

  it "shouldn't find users in other root accounts by sis id" do
    acct = account_model(:name => 'other root')
    acct.account_users.create!(user: @user)
    @me = @user
    course_with_student(:account => acct, :active_all => true, :user => user_with_pseudonym(:name => 's2', :username => 'other@example.com'))
    @other_user = @user
    @other_user.pseudonym.update_attribute('sis_user_id', 'other-sis')
    @other_user.pseudonym.update_attribute('account_id', acct.id)
    @user = @me
    raw_api_call(:get, "/api/v1/users/sis_user_id:other-sis/page_views",
                       { :controller => "page_views", :action => "index", :user_id => 'sis_user_id:other-sis', :format => 'json' })
    assert_status(404)
  end

  it "should allow id of 'self'" do
    page_view_model(:user => @admin)
    json = api_call(:get, "/api/v1/users/self/page_views?per_page=1000",
                       { :controller => "page_views", :action => "index", :user_id => 'self', :format => 'json', :per_page => '1000' })
    expect(json.size).to eq 1
  end

  describe "api_show" do
    before :each do
      @other_user = User.create!(:name => "user name")
      email = "email@somewhere.org"
      @other_user.pseudonyms.create!(:unique_id => email, :account => Account.default) { |p| p.sis_user_id = email }
      Account.default.tap { |a| a.disable_service(:avatars) }.save
    end

    it "should retrieve user details as an admin user" do
      account_admin_user
      json = api_call(:get, "/api/v1/users/#{@other_user.id}",
                      { :controller => 'users', :action => 'api_show', :id => @other_user.id.to_param, :format => 'json' })

      expect(json).to eq({
         'name' => @other_user.name,
         'sortable_name' => @other_user.sortable_name,
         'sis_import_id' => nil,
         'id' => @other_user.id,
         'short_name' => @other_user.short_name,
         'sis_user_id' => @other_user.pseudonym.sis_user_id,
         'integration_id' => nil,
         'login_id' => @other_user.pseudonym.unique_id,
         'locale' => nil,
         'permissions' => {'can_update_name' => true, 'can_update_avatar' => false},
         'email' => @other_user.email
      })
    end

    it "should retrieve limited user details as self" do
      @user = @other_user
      json = api_call(:get, "/api/v1/users/self",
                      { :controller => 'users', :action => 'api_show', :id => 'self', :format => 'json' })
      expect(json).to eq({
         'name' => @other_user.name,
         'sortable_name' => @other_user.sortable_name,
         'id' => @other_user.id,
         'short_name' => @other_user.short_name,
         'locale' => nil,
         'permissions' => {'can_update_name' => true, 'can_update_avatar' => false}
      })
    end

    it "should retrieve the right permissions" do
      @user = @other_user
      Account.default.tap { |a| a.settings[:users_can_edit_name] = false }.save
      json = api_call(:get, "/api/v1/users/self",
                      { :controller => 'users', :action => 'api_show', :id => 'self', :format => 'json' })
      expect(json['permissions']).to eq({'can_update_name' => false, 'can_update_avatar' => false})

      Account.default.tap { |a| a.enable_service(:avatars) }.save
      json = api_call(:get, "/api/v1/users/self",
                      { :controller => 'users', :action => 'api_show', :id => 'self', :format => 'json' })
      expect(json['permissions']).to eq({'can_update_name' => false, 'can_update_avatar' => true})
    end

    it "requires :read_roster or :manage_user_logins permission from the account" do
      account_admin_user_with_role_changes(:role_changes => {:read_roster => false, :manage_user_logins => false})
      api_call(:get, "/api/v1/users/#{@other_user.id}",
               {:controller => 'users', :action => 'api_show', :id => @other_user.id.to_param, :format => 'json'},
               {}, {}, {:expected_status => 401})
    end
  end

  describe "user account listing" do
    it "should return users for an account" do
      @account = Account.default
      users = []
      [['Test User1', 'test@example.com'], ['Test User2', 'test2@example.com'], ['Test User3', 'test3@example.com']].each_with_index do |u, i|
        users << User.create!(:name => u[0])
        users[i].pseudonyms.create!(:unique_id => u[1], :account => @account) { |p| p.sis_user_id = u[1] }
      end
      @account.all_users.order(:sortable_name).each_with_index do |user, i|
        next unless users.find { |u| u == user }
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/users",
               { :controller => 'users', :action => 'index', :account_id => @account.id.to_param, :format => 'json' },
               { :per_page => 1, :page => i + 1 })
        expect(json).to eq [{
          'name' => user.name,
          'sortable_name' => user.sortable_name,
          'sis_import_id' => nil,
          'id' => user.id,
          'short_name' => user.short_name,
          'sis_user_id' => user.pseudonym.sis_user_id,
          'integration_id' => nil,
          'login_id' => user.pseudonym.unique_id
        }]
      end
    end

    it "should limit the maximum number of users returned" do
      @account = @user.account
      3.times do |n|
        user = User.create(:name => "u#{n}")
        user.pseudonyms.create!(:unique_id => "u#{n}@example.com", :account => @account)
      end
      expect(api_call(:get, "/api/v1/accounts/#{@account.id}/users?per_page=2", :controller => "users", :action => "index", :account_id => @account.id.to_param, :format => 'json', :per_page => '2').size).to eq 2
      Setting.set('api_max_per_page', '1')
      expect(api_call(:get, "/api/v1/accounts/#{@account.id}/users?per_page=2", :controller => "users", :action => "index", :account_id => @account.id.to_param, :format => 'json', :per_page => '2').size).to eq 1
    end

    it "should return unauthorized for users without permissions" do
      @account = @student.account
      @user    = @student
      raw_api_call(:get, "/api/v1/accounts/#{@account.id}/users", :controller => "users", :action => "index", :account_id => @account.id.to_param, :format => "json")
      expect(response.code).to eql "401"
    end

    it "returns an error when search_term is fewer than 3 characters" do
      @account = Account.default
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/users", { :controller => 'users', :action => "index", :format => 'json', :account_id => @account.id.to_param }, {:search_term => 'ab'}, {}, :expected_status => 400)
      error = json["errors"].first
      verify_json_error(error, "search_term", "invalid", "3 or more characters is required")
    end

    it "returns a list of users filtered by search_term" do
      @account = Account.default
      expected_keys = %w{id name sortable_name short_name}

      users = []
      [['Test User1', 'test@example.com'], ['Test User2', 'test2@example.com'], ['Test User3', 'test3@example.com']].each_with_index do |u, i|
        users << User.create!(:name => u[0])
        users[i].pseudonyms.create!(:unique_id => u[1], :account => @account) { |p| p.sis_user_id = u[1] }
      end

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/users", { :controller => 'users', :action => "index", :format => 'json', :account_id => @account.id.to_param }, {:search_term => 'test3@example.com'})

      expect(json.count).to eq 1
      json.each do |user|
        expect((user.keys & expected_keys).sort).to eq expected_keys.sort
        expect(users.map(&:id)).to include(user['id'])
      end
    end

    it "doesn't kersplode when filtering by role and sorting" do
      @account = Account.default
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/users",
        { :controller => 'users', :action => "index", :format => 'json', :account_id => @account.id.to_param },
        { :role_filter_id => student_role.id.to_s, :sort => "sis_id"})
      
      expect(json.map{|r| r['id']}).to eq [@student.id]

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/users",
        { :controller => 'users', :action => "index", :format => 'json', :account_id => @account.id.to_param },
        { :role_filter_id => student_role.id.to_s, :sort => "email"})

      expect(json.map{|r| r['id']}).to eq [@student.id]
    end

    it "includes last login info" do
      @account = Account.default
      u = User.create!(name: 'test user')
      p = u.pseudonyms.create!(account: @account, unique_id: 'user')
      p.current_login_at = Time.now.utc
      p.save!

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/users", { :controller => 'users', :action => "index", :format => 'json', :account_id => @account.id.to_param }, { include: ['last_login'], search_term: u.id.to_s })

      expect(json.count).to eq 1
      expect(json.first['last_login']).to eq p.current_login_at.iso8601

      # it should sort too
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/users",
        { :controller => 'users', :action => "index", :format => 'json', :account_id => @account.id.to_param },
        { include: ['last_login'], sort: "last_login", order: 'desc'})
      expect(json.first['last_login']).to eq p.current_login_at.iso8601
    end
  end

  describe "user account creation" do
    def create_user_skip_cc_confirm(admin_user)
      json = api_call(:post, "/api/v1/accounts/#{admin_user.account.id}/users",
                      { :controller => 'users', :action => 'create', :format => 'json', :account_id => admin_user.account.id.to_s },
                      {
                          :user => {
                              :name          => "Test User",
                              :short_name    => "Test",
                              :sortable_name => "User, T.",
                              :time_zone     => "Mountain Time (US & Canada)",
                              :locale        => 'en'
                          },
                          :pseudonym => {
                              :unique_id         => "test@example.com",
                              :password          => "password123",
                              :sis_user_id       => "12345",
                              :send_confirmation => 0
                          },
                          :communication_channel => {
                              :type => "sms",
                              :address => '8018888888',
                              :skip_confirmation => 1
                          }
                      }
      )
      users = User.where(name: "Test User").to_a
      expect(users.length).to eql 1
      user = users.first
      expect(user.sms_channel.workflow_state).to eq 'active'
    end

    context 'as a site admin' do
      before :once do
        @site_admin = user_with_pseudonym
        Account.site_admin.account_users.create!(user: @site_admin)
      end

      context 'using force_validations param' do
        it "validates with force_validations set to true" do
          @site_admin.account.create_terms_of_service!(terms_type: "default", passive: false)
          raw_api_call(:post, "/api/v1/accounts/#{@site_admin.account.id}/users",
            { :controller => 'users', :action => 'create', :format => 'json', :account_id => @site_admin.account.id.to_s },
            {
              :user => {
                :name => ""
              },
              :pseudonym => {
                :unique_id  => "bademail@",
              },
              :force_validations => true
            }
          )

          assert_status(400)
          errors = JSON.parse(response.body)['errors']
          expect(errors['user']['name']).to be_present
          expect(errors['user']['terms_of_use']).to be_present
          expect(errors['pseudonym']).to be_present
          expect(errors['pseudonym']['unique_id']).to be_present
        end

        it "does not validate when force_validations is not set to true" do
          # successful request even with oddball user params because we're making the request as an admin
          json = api_call(:post, "/api/v1/accounts/#{@site_admin.account.id}/users",
            { :controller => 'users', :action => 'create', :format => 'json', :account_id => @site_admin.account.id.to_s },
            {
              :user => {
                :name => ""
              },
              :pseudonym => {
                :unique_id  => "bademail@",
              }
            }
          )

          users = User.where(name: "").to_a
          expect(users.length).to eql 1
          user = users.first

          expect(json).to eq({
            "id"            => user.id,
            "integration_id"=> nil,
            "name"          => "",
            "sortable_name" => "",
            "short_name"    => "",
            "sis_import_id" => nil,
            "sis_user_id"   => nil,
            "login_id"      => "bademail@",
            "locale"        => nil
          })
        end
      end

      it "should allow site admins to create users" do
        json = api_call(:post, "/api/v1/accounts/#{@site_admin.account.id}/users",
          { :controller => 'users', :action => 'create', :format => 'json', :account_id => @site_admin.account.id.to_s },
          {
            :user => {
              :name          => "Test User",
              :short_name    => "Test",
              :sortable_name => "User, T.",
              :time_zone     => "Mountain Time (US & Canada)",
              :locale        => 'en'
            },
            :pseudonym => {
              :unique_id         => "test@example.com",
              :password          => "password123",
              :sis_user_id       => "12345",
              :send_confirmation => 0
            },
            :communication_channel => {
              :confirmation_url => true
            }
          }
        )
        users = User.where(name: "Test User").to_a
        expect(users.length).to eql 1
        user = users.first
        expect(user.name).to eql "Test User"
        expect(user.short_name).to eql "Test"
        expect(user.sortable_name).to eql "User, T."
        expect(user.time_zone.name).to eql "Mountain Time (US & Canada)"
        expect(user.locale).to eql 'en'

        expect(user.pseudonyms.count).to eql 1
        pseudonym = user.pseudonyms.first
        expect(pseudonym.unique_id).to eql "test@example.com"
        expect(pseudonym.sis_user_id).to eql "12345"

        expect(JSON.parse(response.body)).to eq({
          "name"             => "Test User",
          "short_name"       => "Test",
          "sortable_name"    => "User, T.",
          "id"               => user.id,
          "sis_user_id"      => "12345",
          "sis_import_id"    => user.pseudonym.sis_batch_id,
          "login_id"         => "test@example.com",
          "integration_id"   => nil,
          "locale"           => "en",
          "confirmation_url" => user.communication_channels.email.first.confirmation_url
        })
      end

      it "accepts a valid destination param" do
        json = api_call(:post, "/api/v1/accounts/#{@site_admin.account.id}/users",
                        { :controller => 'users', :action => 'create', :format => 'json', :account_id => @site_admin.account.id.to_s },
                        {
                          user: {
                            name: "Test User",
                          },
                          pseudonym: {
                            unique_id: "test@example.com",
                            password: "password123",
                          },
                          destination: 'http://www.example.com/courses/1'
                        }
        )
        expect(json['destination']).to start_with('http://www.example.com/courses/1?session_token=')
      end

      it "ignores a destination with a mismatched host" do
        json = api_call(:post, "/api/v1/accounts/#{@site_admin.account.id}/users",
                        { :controller => 'users', :action => 'create', :format => 'json', :account_id => @site_admin.account.id.to_s },
                        {
                          user: {
                            name: "Test User",
                          },
                          pseudonym: {
                            unique_id: "test@example.com",
                            password: "password123",
                          },
                          destination: 'http://hacker.com/courses/1'
                        }
        )
        expect(json['destination']).to be_nil
      end

      it "ignores a destination with an unrecognized path" do
        json = api_call(:post, "/api/v1/accounts/#{@site_admin.account.id}/users",
                        { :controller => 'users', :action => 'create', :format => 'json', :account_id => @site_admin.account.id.to_s },
                        {
                          user: {
                            name: "Test User",
                          },
                          pseudonym: {
                            unique_id: "test@example.com",
                            password: "password123",
                          },
                          destination: 'http://www.example.com/hacker/1'
                        }
        )
        expect(json['destination']).to be_nil
      end

      context "sis reactivation" do
        it "should allow reactivating deleting users using sis_user_id" do
          other_user = user_with_pseudonym(:active_all => true)
          @pseudonym.sis_user_id = "12345"
          @pseudonym.save!
          other_user.remove_from_root_account(Account.default)

          @user = @site_admin
          json = api_call(:post, "/api/v1/accounts/#{Account.default.id}/users",
            { :controller => 'users', :action => 'create', :format => 'json', :account_id => Account.default.id.to_s },
            { :enable_sis_reactivation => '1', :user => { :name => "Test User" },
              :pseudonym => { :unique_id => "test@example.com", :password => "password123", :sis_user_id => "12345"},
            }
          )

          expect(other_user).to eq User.find(json['id'])
          other_user.reload
          @pseudonym.reload
          expect(other_user).to be_registered
          expect(other_user.user_account_associations.where(:account_id => Account.default).first).to_not be_nil
          expect(@pseudonym).to be_active
        end

        it "should raise an error trying to reactivate an active section" do
          other_user = user_with_pseudonym(:active_all => true)
          @pseudonym.sis_user_id = "12345"
          @pseudonym.save!

          @user = @site_admin
          json = api_call(:post, "/api/v1/accounts/#{Account.default.id}/users",
            { :controller => 'users', :action => 'create', :format => 'json', :account_id => Account.default.id.to_s },
            { :enable_sis_reactivation => '1', :user => { :name => "Test User" },
              :pseudonym => { :unique_id => "test@example.com", :password => "password123", :sis_user_id => "12345"},
            }, {}, {:expected_status => 400}
          )
        end

        it "should carry on if there's no section to reactivate" do
          json = api_call(:post, "/api/v1/accounts/#{Account.default.id}/users",
            { :controller => 'users', :action => 'create', :format => 'json', :account_id => Account.default.id.to_s },
            { :enable_sis_reactivation => '1', :user => { :name => "Test User" },
              :pseudonym => { :unique_id => "test@example.com", :password => "password123", :sis_user_id => "12345"},
            }
          )

          user = User.find(json['id'])
          expect(user.pseudonym.sis_user_id).to eq '12345'
        end
      end

      it "should catch invalid dates before passing to the database" do
        json = api_call(:post, "/api/v1/accounts/#{@site_admin.account.id}/users",
                        { :controller => 'users', :action => 'create', :format => 'json', :account_id => @site_admin.account.id.to_s },
                        { :pseudonym => { :unique_id => "test@example.com"},
                          :user => { :name => "Test User", :birthdate => "-3587-11-20" } }, {}, {:expected_status => 400} )
      end

      it "should allow site admins to create users and auto-validate communication channel" do
        create_user_skip_cc_confirm(@site_admin)
      end

      context "sharding" do
        specs_require_sharding
        it "should allow creating users on cross-shard accounts" do
          @other_account = @shard1.activate { Account.create! }
          json = api_call(:post, "/api/v1/accounts/#{@other_account.id}/users",
            { :controller => 'users', :action => 'create', :format => 'json', :account_id => @other_account.id.to_s },
            { :user => { :name => "Test User" }, :pseudonym => { :unique_id => "test@example.com", :password => "password123"} }
          )
          new_user = User.find(json['id'])
          expect(new_user.shard).to eq @shard1
          expect(new_user.pseudonym.account).to eq @other_account
        end
      end

      it "respects authentication_provider_id" do
        ap = Account.site_admin.authentication_providers.create!(auth_type: 'facebook')
        api_call(:post, "/api/v1/accounts/#{Account.site_admin.id}/users",
                 {controller: 'users', action: 'create', format: 'json', account_id: Account.site_admin.id.to_s},
                 {
                     user: {
                         name: "Test User",
                         short_name: "Test",
                         sortable_name: "User, T.",
                         time_zone: "Mountain Time (US & Canada)",
                         locale: 'en'
                     },
                     pseudonym: {
                         unique_id: "test@example.com",
                         password: "password123",
                         sis_user_id: "12345",
                         send_confirmation: 0,
                         authentication_provider_id: 'facebook'
                     },
                     communication_channel: {
                         type: "sms",
                         address: '8018888888',
                         skip_confirmation: 1
                     }
                 }
                )
        users = User.where(name: "Test User").to_a
        expect(users.length).to eql 1
        user = users.first
        expect(user.pseudonyms.first.authentication_provider).to eq ap
      end
    end

    context 'as an account admin' do
      it "should allow account admins to create users and auto-validate communication channel" do
        create_user_skip_cc_confirm(@admin)
      end
    end

    context "as a non-administrator" do
      before :once do
        user_factory(active_all: true)
      end

      it "should not let you create a user if self_registration is off" do
        raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
          { :controller => 'users', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
          {
            :user      => { :name => "Test User" },
            :pseudonym => { :unique_id => "test@example.com" }
          }
        )
        assert_status(403)
      end

      it "should require an email pseudonym" do
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        @admin.account.save!
        raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
          { :controller => 'users', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
          {
            :user      => { :name => "Test User", :terms_of_use => "1" },
            :pseudonym => { :unique_id => "invalid" }
          }
        )
        assert_status(400)
      end

      it "should require acceptance of the terms" do
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        @admin.account.create_terms_of_service!(terms_type: "default", passive: false)
        @admin.account.save!
        raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
          { :controller => 'users', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
          {
            :user      => { :name => "Test User" },
            :pseudonym => { :unique_id => "test@example.com" }
          }
        )
        assert_status(400)
      end

      it "should let you create a user if you pass all the validations" do
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        @admin.account.save!
        json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
          { :controller => 'users', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
          {
            :user      => { :name => "Test User", :terms_of_use => "1" },
            :pseudonym => { :unique_id => "test@example.com" }
          }
        )
        expect(json['name']).to eq 'Test User'
      end
    end

    it "should send a confirmation if send_confirmation is set to 1" do
      expect_any_instance_of(Pseudonym).to receive(:send_registration_done_notification!)
      api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
        { :controller => 'users', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
        {
          :user => {
            :name => "Test User"
          },
          :pseudonym => {
            :unique_id         => "test@example.com",
            :password          => "password123",
            :send_confirmation => 1
          }
        }
      )
    end

    it "should return a 400 error if the request doesn't include a unique id" do
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
        { :controller => 'users', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
        {
          :user      => { :name => "Test User" },
          :pseudonym => { :password => "password123" }
        }
      )
      assert_status(400)
      errors = JSON.parse(response.body)['errors']
      expect(errors['pseudonym']).to be_present
      expect(errors['pseudonym']['unique_id']).to be_present
    end

    it "should set user's email address via communication_channel[address]" do
      api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
        { :controller => 'users',
          :action => 'create',
          :format => 'json',
          :account_id => @admin.account.id.to_s
        },
        {
          :user => {
            :name => "Test User"
          },
          :pseudonym => {
            :unique_id         => "test",
            :password          => "password123"
          },
          :communication_channel => {
            :address           => "test@example.com"
          }
        }
      )
      expect(response).to be_successful
      users = User.where(name: "Test User").to_a
      expect(users.size).to eq 1
      expect(users.first.pseudonyms.first.unique_id).to eq "test"
      email = users.first.communication_channels.email.first
      expect(email.path).to eq "test@example.com"
      expect(email.path_type).to eq 'email'
    end

    context "as an anonymous user" do
      before :each do
        user_factory(active_all: true)
        @user = nil
      end

      it "should not let you create a user if self_registration is off" do
        raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/self_registration",
                     { :controller => 'users', :action => 'create_self_registered_user', :format => 'json', :account_id => @admin.account.id.to_s },
                     {
                         :user      => { :name => "Test User" },
                         :pseudonym => { :unique_id => "test@example.com" }
                     }
                    )
        assert_status(403)
      end

      it "should require an email pseudonym" do
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/self_registration",
                     { :controller => 'users', :action => 'create_self_registered_user', :format => 'json', :account_id => @admin.account.id.to_s },
                     {
                         :user      => { :name => "Test User", :terms_of_use => "1" },
                         :pseudonym => { :unique_id => "invalid" }
                     }
                    )
        assert_status(400)
      end

      it "should require acceptance of the terms" do
        @admin.account.create_terms_of_service!(terms_type: "default", passive: false)
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/self_registration",
                     { :controller => 'users', :action => 'create_self_registered_user', :format => 'json', :account_id => @admin.account.id.to_s },
                     {
                         :user      => { :name => "Test User" },
                         :pseudonym => { :unique_id => "test@example.com" }
                     }
                    )
        assert_status(400)
      end

      it "should let you create a user if you pass all the validations" do
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/self_registration",
                        { :controller => 'users', :action => 'create_self_registered_user', :format => 'json', :account_id => @admin.account.id.to_s },
                        {
                            :user      => { :name => "Test User", :terms_of_use => "1" },
                            :pseudonym => { :unique_id => "test@example.com" }
                        }
                       )
        expect(json['name']).to eq 'Test User'
      end

      it "should return a 400 error if the request doesn't include a unique id" do
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/self_registration",
                     { :controller => 'users',
                       :action => 'create_self_registered_user',
                       :format => 'json',
                       :account_id => @admin.account.id.to_s
                     },
                     {
                         :user      => { :name => "Test User", :terms_of_use => "1"  },
                         :pseudonym => { :password => "password123" }
                     }
                    )
        assert_status(400)
        errors = JSON.parse(response.body)['errors']
        expect(errors['pseudonym']).to be_present
        expect(errors['pseudonym']['unique_id']).to be_present
      end

      it "should set user's email address via communication_channel[address]" do
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        api_call(:post, "/api/v1/accounts/#{@admin.account.id}/self_registration",
                 { :controller => 'users',
                   :action => 'create_self_registered_user',
                   :format => 'json',
                   :account_id => @admin.account.id.to_s
                 },
                 {
                     :user      => { :name => "Test User", :terms_of_use => "1" },
                     :pseudonym => {
                         :unique_id         => "test@test.com",
                         :password          => "password123"
                     },
                     :communication_channel => {
                         :address           => "test@example.com"
                     }
                 }
                )
        expect(response).to be_successful
        users = User.where(name: "Test User").to_a
        expect(users.size).to eq 1
        expect(users.first.pseudonyms.first.unique_id).to eq "test@test.com"
        email = users.first.communication_channels.email.first
        expect(email.path).to eq "test@example.com"
        expect(email.path_type).to eq 'email'
      end
    end
  end

  describe "user account updates" do
    before :once do
      # an outer before sets this
      @student.pseudonym.update_attribute(:sis_user_id, nil)

      @admin = account_admin_user
      course_with_student(:user => user_with_pseudonym(:name => 'Student', :username => 'student@example.com'))
      @student = @user
      @student.pseudonym.update_attribute(:sis_user_id, 'sis-user-id')
      @user = @admin
      @path = "/api/v1/users/#{@student.id}"
      @path_options = { :controller => 'users', :action => 'update', :format => 'json', :id => @student.id.to_param }
      user_with_pseudonym(:user => @user, :username => 'admin@example.com')
    end
    context "an admin user" do
      it "should be able to update a user" do
        birthday = Time.now
        json = api_call(:put, @path, @path_options, {
          :user => {
            :name => 'Tobias Funke',
            :short_name => 'Tobias',
            :sortable_name => 'Funke, Tobias',
            :time_zone => 'Tijuana',
            :birthdate => birthday.iso8601,
            :locale => 'en',
            :email => "somenewemail@example.com"
          }
        })
        user = User.find(json['id'])
        avatar_url = json.delete("avatar_url")
        expect(json).to eq({
          'name' => 'Tobias Funke',
          'sortable_name' => 'Funke, Tobias',
          'sis_user_id' => 'sis-user-id',
          'sis_import_id' => nil,
          'id' => user.id,
          'short_name' => 'Tobias',
          'integration_id' => nil,
          'login_id' => 'student@example.com',
          'email' => 'somenewemail@example.com',
          'locale' => 'en',
          'time_zone' => "Tijuana"
        })

        expect(user.birthdate.to_date).to eq birthday.getutc.to_date
        expect(user.time_zone.name).to eql 'Tijuana'
      end

      it "should be able to update email alone" do
        enable_cache do
          @student.email

          Timecop.freeze(5.seconds.from_now) do
            new_email = "bloop@shoop.whoop"
            json = api_call(:put, @path, @path_options, {
              :user => {:email => new_email}
            })
            expect(json['email']).to eq new_email
            user = User.find(json['id'])
            expect(user.email).to eq new_email
          end
        end
      end

      it "should catch invalid dates" do
        birthday = Time.now
        json = api_call(:put, @path, @path_options, {
            :user => {
                :name => 'Tobias Funke',
                :short_name => 'Tobias',
                :sortable_name => 'Funke, Tobias',
                :time_zone => 'Tijuana',
                :birthdate => "-4000-02-01 10:20",
                :locale => 'en'
            }
        }, {}, {:expected_status => 400})
      end

      it "should allow updating without any params" do
        json = api_call(:put, @path, @path_options, {})
        expect(json).not_to be_nil
      end

      it "should update the user's avatar with a token" do
        json = api_call(:get, "/api/v1/users/#{@student.id}/avatars",
                        :controller => "profile", :action => "profile_pics", :user_id => @student.to_param, :format => 'json')
        to_set = json.first

        expect(@student.avatar_image_source).not_to eql to_set['type']
        json = api_call(:put, @path, @path_options, {
          :user => {
            :avatar => {
              :token => to_set['token']
            }
          }
        })
        user = User.find(json['id'])
        expect(user.avatar_image_source).to eql to_set['type']
        expect(user.avatar_state).to eql :approved
      end

      it "should re-lock the avatar after being updated by an admin" do
        json = api_call(:get, "/api/v1/users/#{@student.id}/avatars",
                        :controller => "profile", :action => "profile_pics", :user_id => @student.to_param, :format => 'json')
        to_set = json.first

        old_source = to_set['type'] == 'gravatar' ? 'twitter' : 'gravatar'
        @student.avatar_image_source = old_source
        @student.avatar_state = 'locked'
        @student.save!

        expect(@student.avatar_image_source).not_to eql to_set['type']
        json = api_call(:put, @path, @path_options, {
          :user => {
            :avatar => {
              :token => to_set['token']
            }
          }
        })
        user = User.find(json['id'])
        expect(user.avatar_image_source).to eql to_set['type']
        expect(user.avatar_state).to eql :locked
      end

      it "should not allow the user's avatar to be set to an external url" do
        url_to_set = 'https://www.instructure.example.com/image.jpg'
        json = api_call(:put, @path, @path_options, {
          :user => {
            :avatar => {
              :url => url_to_set
            }
          }
        })
        user = User.find(json['id'])
        expect(user.avatar_image_source).to eql 'no_pic'
        expect(user.avatar_image_url).to eql nil
      end

      it "should be able to update a name without changing sortable name if sent together" do
        sortable = "Name, Sortable"
        @student.update_attributes(:name => "Sortable Name", :sortable_name => sortable)
        api_call(:put, @path, @path_options, {
          :user => {:name => "Other Name", :sortable_name => sortable}
        })
        expect(@student.reload.sortable_name).to eq sortable

        @student.update_attributes(:name => "Sortable Name", :sortable_name => sortable) # reset
        api_call(:put, @path, @path_options, {:user => {:name => "Other Name"}}) # only send in the name
        expect(@student.reload.sortable_name).to eq "Name, Other" # should auto sync
      end
    end

    context "non-account-admin user" do
      before :once do
        user_with_pseudonym name: "Earnest Lambert Watkins"
        course_with_teacher user: @user, active_all: true
      end

      context "with users_can_edit_name enabled" do
        before :once do
          @course.root_account.settings = { users_can_edit_name: true }
          @course.root_account.save!
        end

        it "should allow user to rename self" do
          json = api_call(:put, "/api/v1/users/#{@user.id}", @path_options.merge(id: @user.id),
                          { user: { name: "Blue Ivy Carter" } })
          expect(json["name"]).to eq "Blue Ivy Carter"
        end
      end

      context "with users_can_edit_name disabled" do
        before :once do
          @course.root_account.settings = { users_can_edit_name: false }
          @course.root_account.save!
        end

        it "should not allow user to rename self" do
          api_call(:put, "/api/v1/users/#{@user.id}", @path_options.merge(id: @user.id),
                   { user: { name: "Ovaltine Jenkins" } }, {}, { expected_status: 401 })
        end
      end
    end

    context "an unauthorized user" do
      it "should receive a 401" do
        user_factory
        raw_api_call(:put, @path, @path_options, {
          :user => { :name => 'Gob Bluth' }
        })
        expect(response.code).to eql '401'
      end
    end
  end

  describe "user settings" do
    before :once do
      course_with_student(active_all: true)
      account_admin_user
    end

    let(:path) { "/api/v1/users/#{@student.to_param}/settings" }
    let(:path_options) {
      { controller: 'users', action: 'settings', format: 'json',
        id: @student.to_param }
    }

    context "an admin user" do
      it "should be able to view other users' settings" do
        json = api_call(:get, path, path_options)
        expect(json['manual_mark_as_read']).to be_falsey
      end

      it "should be able to update other users' settings" do
        json = api_call(:put, path, path_options, manual_mark_as_read: true)
        expect(json['manual_mark_as_read']).to be_truthy

        json = api_call(:put, path, path_options, manual_mark_as_read: false)
        expect(json['manual_mark_as_read']).to be_falsey
      end
    end

    context "a student" do
      before do
        @user = @student
      end

      it "should be able to view its own settings" do
        json = api_call(:get, path, path_options)
        expect(json['manual_mark_as_read']).to be_falsey
      end

      it "should be able to update its own settings" do
        json = api_call(:put, path, path_options, manual_mark_as_read: true)
        expect(json['manual_mark_as_read']).to be_truthy

        json = api_call(:put, path, path_options, manual_mark_as_read: false)
        expect(json['manual_mark_as_read']).to be_falsey
      end

      it "should receive 401 if updating another user's settings" do
        @course.enroll_student(user_factory).accept!
        raw_api_call(:put, path, path_options, manual_mark_as_read: true)
        expect(response.code).to eq '401'
      end
    end
  end

  describe "user custom_data" do
    let(:namespace_a) { 'com.awesome-developer.mobile' }
    let(:namespace_b) { 'org.charitable-developer.generosity' }
    let(:scope) { 'nice/scope' }
    let(:scope2) { 'something-different' }
    let(:path) { "/api/v1/users/#{@student.to_param}/custom_data/#{scope}" }
    let(:path2) { "/api/v1/users/#{@student.to_param}/custom_data/#{scope2}" }
    let(:path_opts_put) { {controller: 'custom_data',
                              action: 'set_data',
                              format: 'json',
                              user_id: @student.to_param,
                              scope: scope} }
    let(:path_opts_get) { path_opts_put.merge({action: 'get_data'}) }
    let(:path_opts_del) { path_opts_put.merge({action: 'delete_data'}) }
    let(:path_opts_put2) { path_opts_put.merge({scope: scope2}) }
    let(:path_opts_get2) { path_opts_put2.merge({action: 'get_data'}) }

    it "scopes storage by namespace and a *scope glob" do
      data = 'boom shaka-laka'
      other_data = 'whoop there it is'
      data2 = 'whatevs'
      other_data2 = 'totes'
      api_call(:put, path,  path_opts_put,  {ns: namespace_a, data: data})
      api_call(:put, path2, path_opts_put2, {ns: namespace_a, data: data2})
      api_call(:put, path,  path_opts_put,  {ns: namespace_b, data: other_data})
      api_call(:put, path2, path_opts_put2, {ns: namespace_b, data: other_data2})

      body = api_call(:get, path, path_opts_get, {ns: namespace_a})
      expect(body).to eq({'data'=>data})

      body = api_call(:get, path, path_opts_get, {ns: namespace_b})
      expect(body).to eq({'data'=>other_data})

      body = api_call(:get, path2, path_opts_get2, {ns: namespace_a})
      expect(body).to eq({'data'=>data2})

      body = api_call(:get, path2, path_opts_get2, {ns: namespace_b})
      expect(body).to eq({'data'=>other_data2})
    end

    it "turns JSON hashes into scopes" do
      data = JSON.parse '{"a":"nice JSON","b":"dont you think?"}'
      get_path = path + '/b'
      get_scope = scope + '/b'
      api_call(:put, path, path_opts_put, {ns: namespace_a, data: data})
      body = api_call(:get, get_path, path_opts_get.merge({scope: get_scope}), {ns: namespace_a})
      expect(body).to eq({'data'=>'dont you think?'})
    end

    it "is deleteable" do
      data = JSON.parse '{"a":"nice JSON","b":"dont you think?"}'
      del_path = path + '/b'
      del_scope = scope + '/b'
      api_call(:put, path, path_opts_put, {ns: namespace_a, data: data})
      body = api_call(:delete, del_path, path_opts_del.merge({scope: del_scope}), {ns: namespace_a})
      expect(body).to eq({'data'=>'dont you think?'})

      body = api_call(:get, path, path_opts_get, {ns: namespace_a})
      expect(body).to eq({'data'=>{'a'=>'nice JSON'}})
    end

    context "without a namespace" do
      it "responds 400 to GET" do
        api_call(:get, path, path_opts_get, {}, {}, {expected_status: 400})
      end

      it "responds 400 to PUT" do
        api_call(:put, path, path_opts_put, {data: 'whatevs'}, {}, {expected_status: 400})
      end

      it "responds 400 to DELETE" do
        api_call(:delete, path, path_opts_del, {}, {}, {expected_status: 400})
      end
    end

    context "PUT" do
      it "responds 409 when the requested scope is invalid" do
        deeper_path = path + '/whoa'
        deeper_scope = scope + '/whoa'
        api_call(:put, path, path_opts_put, {ns: namespace_a, data: 'ohai!'})
        raw_api_call(:put, deeper_path, path_opts_put.merge({scope: deeper_scope}), {ns: namespace_a, data: 'dood'})
        expect(response.code).to eql '409'
      end
    end
  end

  describe "removing user from account" do
    before :once do
      @admin = account_admin_user
      course_with_student(:user => user_with_pseudonym(:name => 'Student', :username => 'student@example.com'))
      @student = @user
      @user = @admin
      @path = "/api/v1/accounts/#{Account.default.id}/users/#{@student.id}"
      @path_options = { :controller => 'accounts', :action => 'remove_user',
        :format => 'json', :user_id => @student.to_param,
        :account_id => Account.default.to_param }
    end

    context "a user with permissions" do
      it "should be able to delete a user" do
        Timecop.freeze do
          json = api_call(:delete, @path, @path_options)
          expect(@student.associated_accounts).not_to include(Account.default)
          expect(json.to_json).to eq @student.reload.to_json
        end
      end

      it "should be able to delete a user by SIS ID" do
        @student.pseudonym.update_attribute(:sis_user_id, '12345')
        id_param = "sis_user_id:#{@student.pseudonyms.first.sis_user_id}"

        path = "/api/v1/accounts/#{Account.default.id}/users/#{id_param}"
        path_options = @path_options.merge(:user_id => id_param)
        api_call(:delete, path, path_options)
        expect(response.code).to eql '200'
        expect(@student.associated_accounts).not_to include(Account.default)
      end

      it 'should be able to delete itself' do
        Timecop.freeze do
          path = "/api/v1/accounts/#{Account.default.to_param}/users/#{@user.id}"
          json = api_call(:delete, path, @path_options.merge(:user_id => @user.to_param))
          expect(@user.associated_accounts).not_to include(Account.default)
          expect(json.to_json).to eq @user.reload.to_json
        end
      end
    end

    context 'an unauthorized user' do
      it "should receive a 401" do
        user_factory
        raw_api_call(:delete, @path, @path_options)
        expect(response.code).to eql '401'
      end
    end

    context 'a non-admin user' do
      it 'should not be able to delete itself' do
        path = "/api/v1/accounts/#{Account.default.to_param}/users/#{@student.id}"
        api_call_as_user(@student, :delete, path, @path_options.merge(:user_id => @student.to_param), {}, {}, expected_status: 401)
      end
    end
  end

  context "user files" do
    before :each do
      @context = @user
    end

    include_examples "file uploads api with folders"
    include_examples "file uploads api with quotas"

    def preflight(preflight_params, opts = {})
      api_call(:post, "/api/v1/users/self/files",
        { :controller => "users", :action => "create_file", :format => "json", :user_id => 'self', },
        preflight_params,
        {},
        opts)
    end

    def has_query_exemption?
      false
    end

    def context
      @user
    end

    it "should not allow uploading to other users" do
      user2 = User.create!
      api_call(:post, "/api/v1/users/#{user2.id}/files",
        { :controller => "users", :action => "create_file", :format => "json", :user_id => user2.to_param, },
        { :name => "my_essay.doc" }, {}, :expected_status => 401)
    end
  end

  describe "user merge and split" do
    before :once do
      @account = Account.default
      @user1 = user_with_managed_pseudonym(
        active_all: true, account: @account, name: 'Jony Ive',
        username: 'jony@apple.com', sis_user_id: 'user_sis_id_01'
      )
      @user2 = user_with_managed_pseudonym(
        active_all: true, name: 'Steve Jobs', account: @account,
        username: 'steve@apple.com', sis_user_id: 'user_sis_id_02'
      )
      @user = account_admin_user(account: @account)
    end

    it "should merge and split users" do
      api_call(
        :put, "/api/v1/users/#{@user2.id}/merge_into/#{@user1.id}",
        {controller: 'users', action: 'merge_into', format: 'json',
         id: @user2.to_param, destination_user_id: @user1.to_param}
      )
      expect(Pseudonym.where(sis_user_id: 'user_sis_id_02').first.user_id).to eq @user1.id
      expect(@user2.pseudonyms).to be_empty
      api_call(
        :post, "/api/v1/users/#{@user1.id}/split/",
        {controller: 'users', action: 'split', format: 'json', id: @user1.to_param}
      )
      expect(Pseudonym.where(sis_user_id: 'user_sis_id_01').first.user_id).to eq @user1.id
      expect(Pseudonym.where(sis_user_id: 'user_sis_id_02').first.user_id).to eq @user2.id
    end

    it "should merge and split users cross accounts" do
      account = Account.create(name: 'new account')
      @user1.pseudonym.account_id = account.id
      @user1.pseudonym.save!
      @user = account_admin_user(account: account, user: @user)

      api_call(
        :put,
        "/api/v1/users/sis_user_id:user_sis_id_02/merge_into/accounts/#{account.id}/users/sis_user_id:user_sis_id_01",
        {controller: 'users', action: 'merge_into', format: 'json',
         id: 'sis_user_id:user_sis_id_02',
         destination_user_id: 'sis_user_id:user_sis_id_01',
         destination_account_id: account.to_param
        }
      )
      expect(Pseudonym.where(sis_user_id: 'user_sis_id_02').first.user_id).to eq @user1.id
      expect(@user2.pseudonyms).to be_empty
      api_call(
        :post, "/api/v1/users/#{@user1.id}/split/",
        {controller: 'users', action: 'split', format: 'json', id: @user1.to_param}
      )
      expect(Pseudonym.where(sis_user_id: 'user_sis_id_01').first.user_id).to eq @user1.id
      expect(Pseudonym.where(sis_user_id: 'user_sis_id_02').first.user_id).to eq @user2.id
    end

    it "should fail to merge users cross accounts without permissions" do
      account = Account.create(name: 'new account')
      @user1.pseudonym.account_id = account.id
      @user1.pseudonym.save!

      raw_api_call(
        :put,
        "/api/v1/users/#{@user2.id}/merge_into/#{@user1.id}",
        {controller: 'users', action: 'merge_into', format: 'json',
         id: @user2.to_param, destination_user_id: @user1.to_param}
      )
      assert_status(401)
    end

    it "should fail to split users that have not been merged" do
      raw_api_call(:post, "/api/v1/users/#{@user2.id}/split/",
                   {controller: 'users', action: 'split', format: 'json', id: @user2.to_param})
      assert_status(400)
    end
  end

  describe 'Custom Colors' do
    before :each do
      @a = Account.default
      @u = user_factory(active_all: true)
      @a.account_users.create!(user: @u)
    end

    describe 'GET custom colors' do
      before :each do
        @user.preferences[:custom_colors] = {
          "user_#{@user.id}" => "efefef",
          "course_3" => "ababab"
        }
        @user.save!
      end

      it "should return an empty object if nothing is stored" do
        @user.preferences.delete(:custom_colors)
        @user.save!

        json = api_call(
          :get,
          "/api/v1/users/#{@user.id}/colors",
          { controller: 'users', action: 'get_custom_colors', format: 'json',
            id: @user.to_param
          },
          {:expected_status => 200}
        )
        expect(json['custom_colors'].size).to eq 0
      end

      it "should return all custom colors for the user" do
        json = api_call(
          :get,
          "/api/v1/users/#{@user.id}/colors",
          { controller: 'users', action: 'get_custom_colors', format: 'json',
            id: @user.to_param
          },
          {:expected_status => 200}
        )
        expect(json['custom_colors'].size).to eq 2
      end

      it "should return the color for a context when requested" do
        json = api_call(
          :get,
          "/api/v1/users/#{@user.id}/colors/user_#{@user.id}",
          { controller: 'users', action: 'get_custom_color', format: 'json',
            id: @user.to_param, asset_string: "user_#{@user.id}"
          },
          {:expected_status => 200}
        )
        expect(json['hexcode']).to eq "efefef"
      end
    end

    describe 'PUT custom colors' do
      it "should not allow creating entries for entities that do not exist" do
        api_call(
          :put,
          "/api/v1/users/#{@user.id}/colors/course_999",
          { controller: 'users', action: 'set_custom_color', format: 'json',
            id: @user.to_param, asset_string: "course_999", hexcode: 'ababab'
          },
          {},
          {},
          {:expected_status => 404}
        )
      end

      it "should not allow creating entries for entities the user doesn't have read access to" do
        course_with_teacher

        api_call(
          :put,
          "/api/v1/users/#{@user.id}/colors/course_#{@course.id}",
          { controller: 'users', action: 'set_custom_color', format: 'json',
            id: @user.to_param, asset_string: "course_#{@course.id}", hexcode: 'ababab'
          },
          {},
          {},
          {:expected_status => 401}
        )
      end

      it "should throw a bad request if a color isn't provided" do
        course_with_student(active_all: true)
        @user = @student
        api_call(
          :put,
          "/api/v1/users/#{@user.id}/colors/course_#{@course.id}",
          { controller: 'users', action: 'set_custom_color', format: 'json',
            id: @user.to_param, asset_string: "course_#{@course.id}"
          },
          {},
          {},
          {:expected_status => 400}
        )
      end

      it "should throw a bad request if an invalid hexcode is provided" do
        course_with_student(active_all: true)
        @user = @student
        api_call(
          :put,
          "/api/v1/users/#{@user.id}/colors/course_#{@course.id}",
          { controller: 'users', action: 'set_custom_color', format: 'json',
            id: @user.to_param, asset_string: "course_#{@course.id}", hexcode: 'yellow'
          },
          {},
          {},
          {:expected_status => 400}
        )
      end

      it "should add an entry for entities the user has access to" do
        course_with_student(active_all: true)
        @user = @student
        json = api_call(
          :put,
          "/api/v1/users/#{@user.id}/colors/course_#{@course.id}",
          { controller: 'users', action: 'set_custom_color', format: 'json',
            id: @user.to_param, asset_string: "course_#{@course.id}", hexcode: 'ababab'
          },
          {},
          {},
          {:expected_status => 200}
        )
        expect(json['hexcode']).to eq '#ababab'
      end
    end
  end

  describe "dashboard positions" do
    before :each do
      @a = Account.default
      @u = user_factory(active_all: true)
      @a.account_users.create!(user: @u)
    end

    describe "GET dashboard positions" do
      before :each do
        @user.preferences[:dashboard_positions] = {
          "course_1" => 3,
          "course_2" => 1,
          "course_3" => 2
        }
        @user.save!
      end

      it "should return dashboard postions for a user" do
        json = api_call(
          :get,
          "/api/v1/users/#{@user.id}/dashboard_positions",
          { controller: "users", action: "get_dashboard_positions", format: "json",
            id: @user.to_param
          },
          {:expected_status => 200}
        )
        expect(json["dashboard_positions"].size).to eq 3
      end

      it "should return an empty if the user has no ordering set" do
        @user.preferences.delete(:dashboard_positions)
        @user.save!

        json = api_call(
          :get,
          "/api/v1/users/#{@user.id}/dashboard_positions",
          { controller: "users", action: "get_dashboard_positions", format: "json",
            id: @user.to_param
          },
          {:expected_status => 200}
        )
        expect(json["dashboard_positions"].size).to eq 0
      end
    end

    describe "PUT dashboard positions" do
      it "should allow setting dashboard positions" do
        course1 = course_factory(active_all: true)
        course2 = course_factory(active_all: true)
        json = api_call(
          :put,
          "/api/v1/users/#{@user.id}/dashboard_positions",
          { controller: "users", action: "set_dashboard_positions", format: "json",
            id: @user.to_param
          },
          {
            dashboard_positions: {
              "course_#{course1.id}" => 3,
              "course_#{course2.id}" => 1,
            }
          },
          {},
          {:expected_status => 200}
        )
        expected = {
          "course_#{course1.id}" => "3",
          "course_#{course2.id}" => "1",
        }
        expect(json["dashboard_positions"]).to eq expected
      end

      it "should not allow creating entries for entities that do not exist" do
        course1 = course_factory(active_all: true)
        course1.enroll_user(@user, "TeacherEnrollment").accept!
        api_call(
          :put,
          "/api/v1/users/#{@user.id}/dashboard_positions",
          { controller: "users", action: "set_dashboard_positions", format: "json",
            id: @user.to_param
          },
          {
            dashboard_positions: {
              "course_#{course1.id}" => 3,
              "course_100001" => 1,
            }
          },
          {},
          {:expected_status => 404}
        )
      end

      it "should not allow creating entries for entities that the user doesn't have read access to" do
        course_with_student(:active_all => true)
        course1 = @course
        course2 = course_factory

        api_call(
          :put,
          "/api/v1/users/#{@user.id}/dashboard_positions",
          { controller: "users", action: "set_dashboard_positions", format: "json",
            id: @user.to_param
          },
          {
            dashboard_positions: {
              "course_#{course1.id}" => 3,
              "course_#{course2.id}" => 1,
            }
          },
          {},
          {:expected_status => 401}
        )
      end

      it "should not allow setting positions to strings" do
        course1 = course_factory(active_all: true)
        course2 = course_factory(active_all: true)

        api_call(
          :put,
          "/api/v1/users/#{@user.id}/dashboard_positions",
          { controller: "users", action: "set_dashboard_positions", format: "json",
            id: @user.to_param
          },
          {
            dashboard_positions: {
              "course_#{course1.id}" => "top",
              "course_#{course2.id}" => 1,
            }
          },
          {},
          {:expected_status => 400}
        )
      end

    end
  end

  describe "New User Tutorial Collapsed Status" do
    before :once do
      @a = Account.default
      @u = user_factory(active_all: true)
      @a.account_users.create!(user: @u)
    end

    describe "GET new user tutorial statuses" do
      before :once do
        @user.preferences[:new_user_tutorial_statuses] = {
          "home" => true,
          "modules" => false,
        }
        @user.save!
      end

      it "should return new user tutorial collapsed statuses for a user" do
        json = api_call(
          :get,
          "/api/v1/users/#{@user.id}/new_user_tutorial_statuses",
          { controller: "users", action: "get_new_user_tutorial_statuses", format: "json",
            id: @user.to_param }
        )
        expect(json).to eq({"new_user_tutorial_statuses" => {"collapsed" => {"home" => true, "modules" => false}}})
      end

      it "should return empty if the user has no preference set" do
        @user.preferences.delete(:new_user_tutorial_statuses)
        @user.save!

        json = api_call(
          :get,
          "/api/v1/users/#{@user.id}/new_user_tutorial_statuses",
          { controller: "users", action: "get_new_user_tutorial_statuses", format: "json",
            id: @user.to_param }
        )
        expect(json).to eq({"new_user_tutorial_statuses" => {"collapsed" => {}}})
      end
    end

    describe "PUT new user tutorial status" do
      it "should allow setting new user tutorial status" do
        page_name = "modules"
        json = api_call(
          :put,
          "/api/v1/users/#{@user.id}/new_user_tutorial_statuses/#{page_name}",
          { controller: "users", action: "set_new_user_tutorial_status", format: "json",
            id: @user.to_param, page_name: page_name },
          {
            collapsed: true
          },
          {}
        )
        expect(json["new_user_tutorial_statuses"]["collapsed"]["modules"]).to eq true
      end

      it "should reject setting status for pages that are not whitelisted" do
        page_name = "some_random_page"
        api_call(
          :put,
          "/api/v1/users/#{@user.id}/new_user_tutorial_statuses/#{page_name}",
          { controller: "users", action: "set_new_user_tutorial_status", format: "json",
            id: @user.to_param, page_name: page_name },
          {},
          {},
          {:expected_status => 400}
        )
      end

    end
  end

  describe 'missing submissions' do
    before :once do
      course_with_student(active_all: true)
      @observer = user_factory(active_all: true, active_state: 'active')
      @observer.as_observer_observation_links.create do |uo|
        uo.user_id = @student.id
      end
      @user = @observer
      due_date = 2.days.ago
      2.times do
        @course.assignments.create!(due_at: due_date, workflow_state: 'published', submission_types: "online_text_entry")
      end
      @path = "/api/v1/users/#{@student.id}/missing_submissions"
      @params = {controller: "users", action: "missing_submissions", user_id: @student.id, format: "json"}
    end

    it "should return unsubmitted assignments due in the past" do
      json = api_call(:get, @path, @params)
      expect(json.length).to eql 2
    end

    it "should return assignments in order of the submission time for the user" do
      assign = @course.assignments.create!(due_at: 5.days.ago, workflow_state: 'published', submission_types: "online_text_entry")
      create_adhoc_override_for_assignment(assign, @student, due_at: 3.days.ago)
      DueDateCacher.recompute(assign)

      json = api_call(:get, @path, @params)
      expect(json[0]['id']).to eq assign.id
    end

    it "paginates properly when multiple submissions have the same cached_due_date" do
      id1 = api_call(:get, @path, @params.merge(per_page: 1, page: 1))[0]['id'].to_i
      id2 = api_call(:get, @path, @params.merge(per_page: 1, page: 2))[0]['id'].to_i
      expect([id1, id2]).to eq @course.assignments.pluck(:id).sort
    end

    it "should not return locked assignments if filter is set to 'submittable'" do
      @course.assignments.create!(due_at: 3.days.ago,
                                  workflow_state: 'published',
                                  submission_types: 'online_text_entry',
                                  lock_at: 2.days.ago)
      json = api_call(:get, @path, @params)
      expect(json.length).to eql 3

      submittable_json = api_call(:get, @path, @params.merge(:filter => ["submittable"]))
      expect(submittable_json.length).to eql 2
    end

    it "should return course information if requested" do
      @params['include'] = ['course']
      json = api_call(:get, @path, @params)
      expect(json.first['course']['name']).to eq(@course.name)
    end

    it "should not return submitted assignments due in the past" do
      @course.assignments.first.submit_homework @student, :submission_type => "online_text_entry"
      json = api_call(:get, @path, @params)
      expect(json.length).to eql 1
    end

    it "should not return assignments that don't expect a submission" do
      ungraded = @course.assignments.create! due_at: 2.days.from_now, workflow_state: 'published', submission_types: 'not_graded'
      json = api_call(:get, @path, @params)
      expect(json.map { |a| a['id'] }).not_to include ungraded.id
    end

    it "should show assignments past their due dates because of overrides" do
      assignment_with_override(course: @course, due_at: 1.day.from_now, submission_types: ['online_text_entry'])
      @override.due_at_overridden = true
      @override.due_at = 1.day.ago
      @override.save!
      json = api_call(:get, @path, @params)
      expect(json.length).to eq 3
      expect(json.last["id"]).to eq @assignment.id
      expect(json.last["due_at"]).to eq @override.due_at.iso8601
    end

    it "should not show assignments past their due dates if the user is not assigned" do
      add_section('Section 1')
      differentiated_assignment(course: @course, course_section: @course_section, due_at: 1.day.ago,
        submission_types: ['online_text_entry'], only_visible_to_overrides: true)
      json = api_call(:get, @path, @params)
      expect(json.length).to eq 2
    end

    it "should not show deleted assignments" do
      a = @course.assignments.create!(due_at: 2.days.ago, workflow_state: 'published', submission_types: "online_text_entry")
      a.destroy
      json = api_call(:get, @path, @params)
      expect(json.map {|i| i["id"]}).not_to be_include a.id
    end

    it "should not show unpublished assignments" do
      a = @course.assignments.create!(due_at: 2.days.ago, workflow_state: 'unpublished', submission_types: "online_text_entry")
      json = api_call(:get, @path, @params)
      expect(json.map {|i| i["id"]}).not_to be_include a.id
    end
  end

  describe 'POST pandata_events_token' do
    let(:fake_secrets){
      {
        "url" => "https://example.com/pandata/events",
        "ios-key" => "IOS_key",
        "ios-secret" => "LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1JSGJBZ0VCQkVFemZx\nZStiTjhEN2VRY0tKa3hHSlJpd0dqaHE0eXBsdFJ3aXNMUkx6ZXpBSmQ4QTlL\nRTdNY2YKbkorK0ptNGpwcjNUaFpybHRyN2dXQ2VJWWdvZDZPSmhzS0FIQmdV\ncmdRUUFJNkdCaVFPQmhnQUVBSmV5NCszeAp0UGlja2h1RFQ3QWFsTW1BWVdz\neU5IMnlEejRxRjhCamhHZzgwVkE2QWJPMHQ2YVE4TGQyaktMVEFrU1U5SFFW\nClkrMlVVeUp0Q3FTWEg4dVlBTEI0ZmFwbGhwVWNoQ1pSa3pMMXcrZzVDUUJY\nMlhFS25PdXJabU5ieEVSRzJneGoKb3hsbmxub0pwQjR5YUkvbWNpWkJOYlVz\nL0hTSGJtRzRFUFVxeVViQgotLS0tLUVORCBFQyBQUklWQVRFIEtFWS0tLS0t\nCg==\n",
        "android-key" => "ANDROID_key",
        "android-secret" => "surrendernoworpreparetofight"
      }
    }

    before do
      allow(Canvas::DynamicSettings).to receive(:find).
        with(any_args).and_call_original
      allow(Canvas::DynamicSettings).to receive(:find).
        with('events', service: 'pandata').and_return(fake_secrets)
    end

    it 'returns token and expiration' do
      Setting.set("pandata_events_token_allowed_developer_key_ids", DeveloperKey.default.global_id)
      json = api_call(:post, "/api/v1/users/self/pandata_events_token",
          { controller: 'users', action: 'pandata_events_token', format:'json', id: @user.to_param },
          { app_key: 'IOS_key'}
      )
      expect(json['url']).to be_present
      expect(json['auth_token']).to be_present
      expect(json['props_token']).to be_present
      expect(json['expires_at']).to be_present

      public_key = OpenSSL::PKey::EC.new(<<-PUBLIC)
-----BEGIN PUBLIC KEY-----
MIGbMBAGByqGSM49AgEGBSuBBAAjA4GGAAQAl7Lj7fG0+JySG4NPsBqUyYBhazI0
fbIPPioXwGOEaDzRUDoBs7S3ppDwt3aMotMCRJT0dBVj7ZRTIm0KpJcfy5gAsHh9
qmWGlRyEJlGTMvXD6DkJAFfZcQqc66tmY1vEREbaDGOjGWeWegmkHjJoj+ZyJkE1
tSz8dIduYbgQ9SrJRsE=
-----END PUBLIC KEY-----
PUBLIC
      body = Canvas::Security.decode_jwt(json['auth_token'], [public_key])
      expect(body[:iss]).to eq "IOS_key"
    end

    it 'returns bad_request for incorrect app keys' do
      Setting.set("pandata_events_token_allowed_developer_key_ids", DeveloperKey.default.global_id)
      json = api_call(:post, "/api/v1/users/self/pandata_events_token",
          { controller: 'users', action: 'pandata_events_token', format:'json', id: @user.to_param },
          { app_key: 'IOS_not_right'}
      )
      assert_status(400)
      expect(json['message']).to eq "Invalid app key"
    end

    it 'returns forbidden if the tokens key is not authorized' do
      json = api_call(:post, "/api/v1/users/self/pandata_events_token",
          { controller: 'users', action: 'pandata_events_token', format:'json', id: @user.to_param },
          { app_key: 'IOS_key'}
      )
      assert_status(403)
      expect(json['message']).to eq "Developer key not authorized"
    end
  end
end
