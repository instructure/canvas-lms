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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe Account do

  it "should provide a list of courses" do
    @account = Account.new
    lambda{@account.courses}.should_not raise_error
  end

  context "equella_settings" do
    it "should respond to :equella_settings" do
      Account.new.should respond_to(:equella_settings)
      Account.new.equella_settings.should be_nil
    end

    it "should return the equella_settings data if defined" do
      a = Account.new
      a.equella_endpoint = "http://oer.equella.com/signon.do"
      a.equella_settings.should_not be_nil
      a.equella_settings.endpoint.should eql("http://oer.equella.com/signon.do")
      a.equella_settings.default_action.should_not be_nil
    end
  end

  # it "should have an atom feed" do
    # account_model
    # @a.to_atom.should be_is_a(Atom::Entry)
  # end

  context "course lists" do
    before(:each) do
      @account = Account.create!
      process_csv_data_cleanly([
        "user_id,login_id,first_name,last_name,email,status",
        "U001,user1,User,One,user1@example.com,active",
        "U002,user2,User,Two,user2@example.com,active",
        "U003,user3,User,Three,user3@example.com,active",
        "U004,user4,User,Four,user4@example.com,active",
        "U005,user5,User,Five,user5@example.com,active",
        "U006,user6,User,Six,user6@example.com,active",
        "U007,user7,User,Seven,user7@example.com,active",
        "U008,user8,User,Eight,user8@example.com,active",
        "U009,user9,User,Nine,user9@example.com,active",
        "U010,user10,User,Ten,user10@example.com,active",
        "U011,user11,User,Eleven,user11@example.com,deleted"
      ])
      process_csv_data_cleanly([
        "term_id,name,status,start_date,end_date",
        "T001,Term 1,active,,",
        "T002,Term 2,active,,",
        "T003,Term 3,active,,"
      ])
      process_csv_data_cleanly([
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,C001,Test Course 1,,T001,active",
        "C002,C002,Test Course 2,,T001,deleted",
        "C003,C003,Test Course 3,,T002,deleted",
        "C004,C004,Test Course 4,,T002,deleted",
        "C005,C005,Test Course 5,,T003,active",
        "C006,C006,Test Course 6,,T003,active",
        "C007,C007,Test Course 7,,T003,active",
        "C008,C008,Test Course 8,,T003,active",
        "C009,C009,Test Course 9,,T003,active",
        "C001S,C001S,Test search Course 1,,T001,active",
        "C002S,C002S,Test search Course 2,,T001,deleted",
        "C003S,C003S,Test search Course 3,,T002,deleted",
        "C004S,C004S,Test search Course 4,,T002,deleted",
        "C005S,C005S,Test search Course 5,,T003,active",
        "C006S,C006S,Test search Course 6,,T003,active",
        "C007S,C007S,Test search Course 7,,T003,active",
        "C008S,C008S,Test search Course 8,,T003,active",
        "C009S,C009S,Test search Course 9,,T003,active"
      ])
      process_csv_data_cleanly([
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec1,,,active",
        "S002,C002,Sec2,,,active",
        "S003,C003,Sec3,,,active",
        "S004,C004,Sec4,,,active",
        "S005,C005,Sec5,,,active",
        "S006,C006,Sec6,,,active",
        "S007,C007,Sec7,,,deleted",
        "S008,C001,Sec8,,,deleted",
        "S009,C008,Sec9,,,active",
        "S001S,C001S,Sec1,,,active",
        "S002S,C002S,Sec2,,,active",
        "S003S,C003S,Sec3,,,active",
        "S004S,C004S,Sec4,,,active",
        "S005S,C005S,Sec5,,,active",
        "S006S,C006S,Sec6,,,active",
        "S007S,C007S,Sec7,,,deleted",
        "S008S,C001S,Sec8,,,deleted",
        "S009S,C008S,Sec9,,,active"
      ])

      process_csv_data_cleanly([
        "course_id,user_id,role,section_id,status,associated_user_id",
        ",U001,student,S001,active,",
        ",U002,student,S002,active,",
        ",U003,student,S003,active,",
        ",U004,student,S004,active,",
        ",U005,student,S005,active,",
        ",U006,student,S006,deleted,",
        ",U007,student,S007,active,",
        ",U008,student,S008,active,",
        ",U009,student,S005,deleted,",
        ",U001,student,S001S,active,",
        ",U002,student,S002S,active,",
        ",U003,student,S003S,active,",
        ",U004,student,S004S,active,",
        ",U005,student,S005S,active,",
        ",U006,student,S006S,deleted,",
        ",U007,student,S007S,active,",
        ",U008,student,S008S,active,",
        ",U009,student,S005S,deleted,"
      ])
    end

    context "fast list" do
      it "should list associated courses" do
        @account.fast_all_courses.map(&:sis_source_id).sort.should == [
          "C001", "C005", "C006", "C007", "C008", "C009",

          "C001S", "C005S", "C006S", "C007S", "C008S", "C009S", ].sort
      end

      it "should list associated courses by term" do
        @account.fast_all_courses({:term => EnrollmentTerm.find_by_sis_source_id("T001")}).map(&:sis_source_id).sort.should == ["C001", "C001S"]
        @account.fast_all_courses({:term => EnrollmentTerm.find_by_sis_source_id("T002")}).map(&:sis_source_id).sort.should == []
        @account.fast_all_courses({:term => EnrollmentTerm.find_by_sis_source_id("T003")}).map(&:sis_source_id).sort.should == ["C005", "C006", "C007", "C008", "C009", "C005S", "C006S", "C007S", "C008S", "C009S"].sort
      end

      it "should list associated nonenrollmentless courses" do
        @account.fast_all_courses({:hide_enrollmentless_courses => true}).map(&:sis_source_id).sort.should == ["C001", "C005", "C007", "C001S", "C005S", "C007S"].sort #C007 probably shouldn't be here, cause the enrollment section is deleted, but we kinda want to minimize database traffic
      end

      it "should list associated nonenrollmentless courses by term" do
        @account.fast_all_courses({:term => EnrollmentTerm.find_by_sis_source_id("T001"), :hide_enrollmentless_courses => true}).map(&:sis_source_id).sort.should == ["C001", "C001S"]
        @account.fast_all_courses({:term => EnrollmentTerm.find_by_sis_source_id("T002"), :hide_enrollmentless_courses => true}).map(&:sis_source_id).sort.should == []
        @account.fast_all_courses({:term => EnrollmentTerm.find_by_sis_source_id("T003"), :hide_enrollmentless_courses => true}).map(&:sis_source_id).sort.should == ["C005", "C007", "C005S", "C007S"].sort
      end
    end

    context "name searching" do
      it "should list associated courses" do
        @account.courses_name_like("search").map(&:sis_source_id).sort.should == [
          "C001S", "C005S", "C006S", "C007S", "C008S", "C009S"]
      end

      it "should list associated courses by term" do
        @account.courses_name_like("search", {:term => EnrollmentTerm.find_by_sis_source_id("T001")}).map(&:sis_source_id).sort.should == ["C001S"]
        @account.courses_name_like("search", {:term => EnrollmentTerm.find_by_sis_source_id("T002")}).map(&:sis_source_id).sort.should == []
        @account.courses_name_like("search", {:term => EnrollmentTerm.find_by_sis_source_id("T003")}).map(&:sis_source_id).sort.should == ["C005S", "C006S", "C007S", "C008S", "C009S"]
      end

      it "should list associated nonenrollmentless courses" do
        @account.courses_name_like("search", {:hide_enrollmentless_courses => true}).map(&:sis_source_id).sort.should == ["C001S", "C005S", "C007S"] #C007 probably shouldn't be here, cause the enrollment section is deleted, but we kinda want to minimize database traffic
      end

      it "should list associated nonenrollmentless courses by term" do
        @account.courses_name_like("search", {:term => EnrollmentTerm.find_by_sis_source_id("T001"), :hide_enrollmentless_courses => true}).map(&:sis_source_id).sort.should == ["C001S"]
        @account.courses_name_like("search", {:term => EnrollmentTerm.find_by_sis_source_id("T002"), :hide_enrollmentless_courses => true}).map(&:sis_source_id).sort.should == []
        @account.courses_name_like("search", {:term => EnrollmentTerm.find_by_sis_source_id("T003"), :hide_enrollmentless_courses => true}).map(&:sis_source_id).sort.should == ["C005S", "C007S"]
      end
    end
  end

  context "services" do
    before(:each) do
      @a = Account.new
    end
    it "should be able to specify a list of enabled services" do
      @a.allowed_services = 'facebook,twitter'
      @a.service_enabled?(:facebook).should be_true
      @a.service_enabled?(:twitter).should be_true
      @a.service_enabled?(:diigo).should be_false
      @a.service_enabled?(:avatars).should be_false
    end

    it "should not enable services off by default" do
      @a.service_enabled?(:facebook).should be_true
      @a.service_enabled?(:avatars).should be_false
    end

    it "should add and remove services from the defaults" do
      @a.allowed_services = '+avatars,-facebook'
      @a.service_enabled?(:avatars).should be_true
      @a.service_enabled?(:twitter).should be_true
      @a.service_enabled?(:facebook).should be_false
    end

    it "should allow settings services" do
      lambda {@a.enable_service(:completly_bogs)}.should raise_error

      @a.disable_service(:twitter)
      @a.service_enabled?(:twitter).should be_false

      @a.enable_service(:twitter)
      @a.service_enabled?(:twitter).should be_true
    end

    it "should use + and - by default when setting service availabilty" do
      @a.enable_service(:twitter)
      @a.service_enabled?(:twitter).should be_true
      @a.allowed_services.should be_nil

      @a.disable_service(:twitter)
      @a.allowed_services.should match('\-twitter')

      @a.disable_service(:avatars)
      @a.service_enabled?(:avatars).should be_false
      @a.allowed_services.should_not match('avatars')

      @a.enable_service(:avatars)
      @a.service_enabled?(:avatars).should be_true
      @a.allowed_services.should match('\+avatars')
    end

    it "should be able to set service availibity for previously hard-coded values" do
      @a.allowed_services = 'avatars,facebook'

      @a.enable_service(:twitter)
      @a.service_enabled?(:twitter).should be_true
      @a.allowed_services.should match(/twitter/)
      @a.allowed_services.should_not match(/[+-]/)

      @a.disable_service(:facebook)
      @a.allowed_services.should_not match(/facebook/)
      @a.allowed_services.should_not match(/[+-]/)

      @a.disable_service(:avatars)
      @a.disable_service(:twitter)
      @a.allowed_services.should be_nil
    end

    it "should not wipe out services that are substrings of each other" do
      @a.disable_service('google_docs_previews')
      @a.disable_service('google_docs')
      @a.allowed_services.should == '-google_docs_previews,-google_docs'
    end

    describe "services_exposed_to_ui_hash" do
      it "should return all ui services by default" do
        Account.services_exposed_to_ui_hash.keys.should == Account.allowable_services.reject { |h,k| !k[:expose_to_ui] || (k[:expose_to_ui_proc] && !k[:expose_to_ui_proc].call(nil)) }.keys
      end

      it "should return services of a type if specified" do
        Account.services_exposed_to_ui_hash(:setting).keys.should == Account.allowable_services.reject { |h,k| k[:expose_to_ui] != :setting || (k[:expose_to_ui_proc] && !k[:expose_to_ui_proc].call(nil)) }.keys
      end

      it "should filter based on user and account if a proc is specified" do
        user1 = User.create!
        user2 = User.create!
        Account.register_service(:myservice, {
          name: "My Test Service",
          description: "Nope",
          expose_to_ui: :setting,
          default: false,
          expose_to_ui_proc: proc { |user, account| user == user2 && account == Account.default },
        })
        Account.services_exposed_to_ui_hash(:setting).keys.should_not be_include(:myservice)
        Account.services_exposed_to_ui_hash(:setting, user1, Account.default).keys.should_not be_include(:myservice)
        Account.services_exposed_to_ui_hash(:setting, user2, Account.default).keys.should be_include(:myservice)
      end
    end

    describe "plugin services" do
      before do
        Account.register_service(:myplugin, { :name => "My Plugin", :description => "", :expose_to_ui => :setting, :default => false })
      end

      it "should return the service" do
        Account.allowable_services.keys.should be_include(:myplugin)
      end

      it "should allow setting the service" do
        @a.service_enabled?(:myplugin).should be_false

        @a.enable_service(:myplugin)
        @a.service_enabled?(:myplugin).should be_true
        @a.allowed_services.should match(/\+myplugin/)

        @a.disable_service(:myplugin)
        @a.service_enabled?(:myplugin).should be_false
        @a.allowed_services.should be_blank
      end

      describe "services_exposed_to_ui_hash" do
        it "should return services defined in a plugin" do
          Account.services_exposed_to_ui_hash().keys.should be_include(:myplugin)
          Account.services_exposed_to_ui_hash(:setting).keys.should be_include(:myplugin)
        end
      end
    end
  end

  context "settings=" do
    it "should filter disabled settings" do
      a = Account.new
      a.root_account_id = 1
      a.settings = {'global_javascript' => 'something'}.with_indifferent_access
      a.settings[:global_javascript].should eql(nil)

      a.root_account_id = nil
      a.settings = {'global_javascript' => 'something'}.with_indifferent_access
      a.settings[:global_javascript].should eql(nil)

      a.settings[:global_includes] = true
      a.settings = {'global_javascript' => 'something'}.with_indifferent_access
      a.settings[:global_javascript].should eql('something')

      a.settings = {'error_reporting' => 'string'}.with_indifferent_access
      a.settings[:error_reporting].should eql(nil)

      a.settings = {'error_reporting' => {
        'action' => 'email',
        'email' => 'bob@yahoo.com',
        'extra' => 'something'
      }}.with_indifferent_access
      a.settings[:error_reporting].should be_is_a(Hash)
      a.settings[:error_reporting][:action].should eql('email')
      a.settings[:error_reporting][:email].should eql('bob@yahoo.com')
      a.settings[:error_reporting][:extra].should eql(nil)
    end
  end

  context "turnitin secret" do
    it "should decrypt the turnitin secret to the original value" do
      a = Account.new
      a.turnitin_shared_secret = "asdf"
      a.turnitin_shared_secret.should eql("asdf")
      a.turnitin_shared_secret = "2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3"
      a.turnitin_shared_secret.should eql("2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3")
    end
  end

  context "closest_turnitin_pledge" do
    it "should work for custom sub, custom root" do
      root_account = Account.create!(:turnitin_pledge => "root")
      sub_account = Account.create!(:parent_account => root_account, :turnitin_pledge => "sub")
      root_account.closest_turnitin_pledge.should == "root"
      sub_account.closest_turnitin_pledge.should == "sub"
    end

    it "should work for nil sub, custom root" do
      root_account = Account.create!(:turnitin_pledge => "root")
      sub_account = Account.create!(:parent_account => root_account)
      root_account.closest_turnitin_pledge.should == "root"
      sub_account.closest_turnitin_pledge.should == "root"
    end

    it "should work for nil sub, nil root" do
      root_account = Account.create!
      sub_account = Account.create!(:parent_account => root_account)
      root_account.closest_turnitin_pledge.should_not be_empty
      sub_account.closest_turnitin_pledge.should_not be_empty
    end
  end

  it "should make a default enrollment term if necessary" do
    a = Account.create!(:name => "nada")
    a.enrollment_terms.size.should == 1
    a.enrollment_terms.first.name.should == EnrollmentTerm::DEFAULT_TERM_NAME

    # don't create a new default term for sub-accounts
    a2 = a.all_accounts.create!(:name => "sub")
    a2.enrollment_terms.size.should == 0
  end

  def account_with_admin_and_restricted_user(account)
    role = account.roles.build(:name => 'Restricted Admin')
    role.base_role_type = AccountUser::BASE_ROLE_NAME
    role.workflow_state = 'active'
    role.save!
    admin = User.create
    user = User.create
    account.account_users.create(:user => admin, :membership_type => 'AccountAdmin')
    account.account_users.create(:user => user, :membership_type => 'Restricted Admin')
    [ admin, user ]
  end


  it "should set up access policy correctly" do
    # stub out any "if" permission conditions
    RoleOverride.permissions.each do |k, v|
      next unless v[:if]
      Account.any_instance.stubs(v[:if]).returns(true)
    end

    # Set up a hierarchy of 4 accounts - a root account, a sub account,
    # a sub sub account, and SiteAdmin account.  Create a 'Restricted Admin'
    # role in each one, and create an admin user and a user in the restricted
    # admin role for each one
    root_account = Account.create
    sub_account = Account.create(:parent_account => root_account)
    sub_sub_account = Account.create(:parent_account => sub_account)

    hash = {}
    hash[:site_admin] = { :account => Account.site_admin}
    hash[:root] = { :account => root_account}
    hash[:sub] = { :account => sub_account}
    hash[:sub_sub] = { :account => sub_sub_account}

    hash.each do |k, v|
      v[:account].update_attribute(:settings, {:no_enrollments_can_create_courses => false})
      admin, user = account_with_admin_and_restricted_user(v[:account])
      hash[k][:admin] = admin
      hash[k][:user] = user
    end

    limited_access = [ :read, :manage, :update, :delete, :read_outcomes ]
    account_enabled_access = [ :view_notifications ]
    full_access = RoleOverride.permissions.keys + limited_access - account_enabled_access + [:create_courses]
    siteadmin_access = [:app_profiling]
    full_root_access = full_access - RoleOverride.permissions.select { |k, v| v[:account_only] == :site_admin }.map(&:first)
    full_sub_access = full_root_access - RoleOverride.permissions.select { |k, v| v[:account_only] == :root }.map(&:first)
    # site admin has access to everything everywhere
    hash.each do |k, v|
      account = v[:account]
      account.check_policy(hash[:site_admin][:admin]).should =~ full_access + (k == :site_admin ? [:read_global_outcomes] : [])
      account.check_policy(hash[:site_admin][:user]).should =~ siteadmin_access + limited_access + (k == :site_admin ? [:read_global_outcomes] : [])
    end

    # root admin has access to everything except site admin
    account = hash[:site_admin][:account]
    account.check_policy(hash[:root][:admin]).should =~ [:read_global_outcomes]
    account.check_policy(hash[:root][:user]).should =~ [:read_global_outcomes]
    hash.each do |k, v|
      next if k == :site_admin
      account = v[:account]
      account.check_policy(hash[:root][:admin]).should =~ full_root_access
      account.check_policy(hash[:root][:user]).should =~ limited_access
    end

    # sub account has access to sub and sub_sub
    hash.each do |k, v|
      next unless k == :site_admin || k == :root
      account = v[:account]
      account.check_policy(hash[:sub][:admin]).should =~ (k == :site_admin ? [:read_global_outcomes] : [:read_outcomes])
      account.check_policy(hash[:sub][:user]).should =~ (k == :site_admin ? [:read_global_outcomes] : [:read_outcomes])
    end
    hash.each do |k, v|
      next if k == :site_admin || k == :root
      account = v[:account]
      account.check_policy(hash[:sub][:admin]).should =~ full_sub_access
      account.check_policy(hash[:sub][:user]).should =~ limited_access
    end

    # Grant 'Restricted Admin' a specific permission, and re-check everything
    some_access = [:read_reports] + limited_access
    hash.each do |k, v|
      account = v[:account]
      account.role_overrides.create!(:permission => 'read_reports', :enrollment_type => 'Restricted Admin', :enabled => true)
      # clear caches
      v[:account] = Account.find(account)
    end
    RoleOverride.clear_cached_contexts
    hash.each do |k, v|
      account = v[:account]
      account.check_policy(hash[:site_admin][:admin]).should =~ full_access + (k == :site_admin ? [:read_global_outcomes] : [])
      account.check_policy(hash[:site_admin][:user]).should =~ siteadmin_access + some_access + (k == :site_admin ? [:read_global_outcomes] : [])
    end

    account = hash[:site_admin][:account]
    account.check_policy(hash[:root][:admin]).should =~ [:read_global_outcomes]
    account.check_policy(hash[:root][:user]).should =~ [:read_global_outcomes]
    hash.each do |k, v|
      next if k == :site_admin
      account = v[:account]
      account.check_policy(hash[:root][:admin]).should =~ full_root_access
      account.check_policy(hash[:root][:user]).should =~ some_access
    end

    # sub account has access to sub and sub_sub
    hash.each do |k, v|
      next unless k == :site_admin || k == :root
      account = v[:account]
      account.check_policy(hash[:sub][:admin]).should =~ (k == :site_admin ? [:read_global_outcomes] : [:read_outcomes])
      account.check_policy(hash[:sub][:user]).should =~ (k == :site_admin ? [:read_global_outcomes] : [:read_outcomes])
    end
    hash.each do |k, v|
      next if k == :site_admin || k == :root
      account = v[:account]
      account.check_policy(hash[:sub][:admin]).should =~ full_sub_access
      account.check_policy(hash[:sub][:user]).should =~ some_access
    end
  end

  it "should allow no_enrollments_can_create_courses correctly" do
    a = Account.default
    a.settings = { :no_enrollments_can_create_courses => true }
    a.save!

    user
    a.grants_right?(@user, :create_courses).should be_true
  end

  it "should correctly return sub-accounts as options" do
    a = Account.default
    sub = Account.create!(:name => 'sub', :parent_account => a)
    sub2 = Account.create!(:name => 'sub2', :parent_account => a)
    sub2_1 = Account.create!(:name => 'sub2-1', :parent_account => sub2)
    options = a.sub_accounts_as_options
    options.should ==
      [
        ["Default Account", a.id],
        ["&nbsp;&nbsp;sub", sub.id],
        ["&nbsp;&nbsp;sub2", sub2.id],
        ["&nbsp;&nbsp;&nbsp;&nbsp;sub2-1", sub2_1.id]
      ]
  end

  it "should return the correct user count" do
    a = Account.default
    a.all_users.count.should == a.user_count
    a.user_count.should == 0

    u = User.create!
    a.account_users.create!(user: u)
    a.all_users.count.should == a.user_count
    a.user_count.should == 1

    course_with_teacher
    @teacher.update_account_associations
    a.all_users.count.should == a.user_count
    a.user_count.should == 2

    a2 = a.sub_accounts.create!
    course_with_teacher(:account => a2)
    @teacher.update_account_associations
    a.all_users.count.should == a.user_count
    a.user_count.should == 3

    user_with_pseudonym
    a.all_users.count.should == a.user_count
    a.user_count.should == 4

  end

  it "group_categories should not include deleted categories" do
    account = Account.default
    account.group_categories.count.should == 0
    category1 = account.group_categories.create(:name => 'category 1')
    category2 = account.group_categories.create(:name => 'category 2')
    account.group_categories.count.should == 2
    category1.destroy
    account.reload
    account.group_categories.count.should == 1
    account.group_categories.to_a.should == [category2]
  end

  it "all_group_categories should include deleted categories" do
    account = Account.default
    account.all_group_categories.count.should == 0
    category1 = account.group_categories.create(:name => 'category 1')
    category2 = account.group_categories.create(:name => 'category 2')
    account.all_group_categories.count.should == 2
    category1.destroy
    account.reload
    account.all_group_categories.count.should == 2
  end

  it "should return correct values for login_handle_name based on authorization_config" do
    account = Account.default
    account.login_handle_name.should == "Email"

    config = account.account_authorization_configs.create(:auth_type => 'cas')
    account.login_handle_name.should == "Login"

    config.auth_type = 'saml'
    config.save
    account.reload.login_handle_name.should == "Login"

    config.auth_type = 'ldap'
    config.save
    account.reload.login_handle_name.should == "Email"
    config.login_handle_name = "LDAP Login"
    config.save
    account.reload.login_handle_name.should == "LDAP Login"
  end

  context "users_not_in_groups" do
    before :each do
      @account = Account.default
      @user1 = account_admin_user(:account => @account)
      @user2 = account_admin_user(:account => @account)
      @user3 = account_admin_user(:account => @account)
    end

    it "should not include deleted users" do
      @user1.destroy
      @account.users_not_in_groups([]).size.should == 2
    end

    it "should not include users in one of the groups" do
      group = @account.groups.create
      group.add_user(@user1)
      users = @account.users_not_in_groups([group])
      users.size.should == 2
      users.should_not be_include(@user1)
    end

    it "should include users otherwise" do
      group = @account.groups.create
      group.add_user(@user1)
      users = @account.users_not_in_groups([group])
      users.should be_include(@user2)
      users.should be_include(@user3)
    end

    it "should allow ordering by user's sortable name" do
      @user1.sortable_name = 'jonny'; @user1.save
      @user2.sortable_name = 'bob'; @user2.save
      @user3.sortable_name = 'richard'; @user3.save
      users = @account.users_not_in_groups([], order: User.sortable_name_order_by_clause('users'))
      users.map{ |u| u.id }.should == [@user2.id, @user1.id, @user3.id]
    end
  end

  context "tabs_available" do
    it "should include 'Developer Keys' for the authorized users of the site_admin account" do
      account_admin_user(:account => Account.site_admin)
      tabs = Account.site_admin.tabs_available(@admin)
      tabs.map{|t| t[:id] }.should be_include(Account::TAB_DEVELOPER_KEYS)

      tabs = Account.site_admin.tabs_available(nil)
      tabs.map{|t| t[:id] }.should_not be_include(Account::TAB_DEVELOPER_KEYS)
    end

    it "should not include 'Developer Keys' for non-site_admin accounts" do
      @account = Account.default.sub_accounts.create!(:name => "sub-account")
      tabs = @account.tabs_available(nil)
      tabs.map{|t| t[:id] }.should_not be_include(Account::TAB_DEVELOPER_KEYS)

      tabs = @account.root_account.tabs_available(nil)
      tabs.map{|t| t[:id] }.should_not be_include(Account::TAB_DEVELOPER_KEYS)
    end

    it "should not include external tools if not configured for course navigation" do
      @account = Account.default.sub_accounts.create!(:name => "sub-account")
      tool = @account.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :domain => "example.com")
      tool.user_navigation = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      tool.has_account_navigation.should == false
      tabs = @account.tabs_available(nil)
      tabs.map{|t| t[:id] }.should_not be_include(tool.asset_string)
    end

    it "should include active external tools if configured on the account" do
      @account = Account.default.sub_accounts.create!(:name => "sub-account")
      tools = []
      2.times do |n|
        t = @account.context_external_tools.new(
          :name => "bob",
          :consumer_key => "bob",
          :shared_secret => "bob",
          :domain => "example.com"
        )
        t.account_navigation = {
          :text => "Example URL",
          :url  =>  "http://www.example.com",
        }
        t.save!
        tools << t
      end
      tool1, tool2 = tools
      tool2.destroy

      tools.each { |t| t.has_account_navigation.should == true }

      tabs = @account.tabs_available
      tab_ids = tabs.map{|t| t[:id] }
      tab_ids.should be_include(tool1.asset_string)
      tab_ids.should_not be_include(tool2.asset_string)
      tab = tabs.detect{|t| t[:id] == tool1.asset_string }
      tab[:label].should == tool1.settings[:account_navigation][:text]
      tab[:href].should == :account_external_tool_path
      tab[:args].should == [@account.id, tool1.id]
    end

    it "should include external tools if configured on the root account" do
      @account = Account.default.sub_accounts.create!(:name => "sub-account")
      tool = @account.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :domain => "example.com")
      tool.account_navigation = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      tool.has_account_navigation.should == true
      tabs = @account.tabs_available(nil)
      tabs.map{|t| t[:id] }.should be_include(tool.asset_string)
      tab = tabs.detect{|t| t[:id] == tool.asset_string }
      tab[:label].should == tool.settings[:account_navigation][:text]
      tab[:href].should == :account_external_tool_path
      tab[:args].should == [@account.id, tool.id]
    end
  end

  describe "fast_all_users" do
    it "should preserve sortable_name" do
      user_with_pseudonym(:active_all => 1)
      @user.update_attributes(:name => "John St. Clair", :sortable_name => "St. Clair, John")
      @johnstclair = @user
      user_with_pseudonym(:active_all => 1, :username => 'jt@instructure.com', :name => 'JT Olds')
      @jtolds = @user
      Account.default.fast_all_users.should == [@jtolds, @johnstclair]
    end
  end

  it "should not allow setting an sis id for a root account" do
    @account = Account.create!
    @account.sis_source_id = 'abc'
    @account.save.should be_false
  end

  describe "user_list_search_mode_for" do
    it "should be preferred for anyone if open registration is turned on" do
      account = Account.default
      account.settings = { :open_registration => true }
      account.user_list_search_mode_for(nil).should == :preferred
      account.user_list_search_mode_for(user).should == :preferred
    end

    it "should be preferred for account admins" do
      account = Account.default
      account.user_list_search_mode_for(nil).should == :closed
      account.user_list_search_mode_for(user).should == :closed
      user
      account.account_users.create!(user: @user)
      account.user_list_search_mode_for(@user).should == :preferred
    end
  end

  context "settings" do
    describe ":condition" do
      it "should not allow setting things where condition is false" do
        account = Account.default
        account.stubs(:global_includes?).returns(false)
        account.settings = { :global_javascript => 'bob' }
        account.settings[:global_javascript].should be_nil
        account.stubs(:global_includes?).returns(true)
        account.settings = { :global_javascript => 'bob' }
        account.settings[:global_javascript].should == 'bob'
      end
    end
  end

  context "sharding" do
    specs_require_sharding

    it "should properly return site admin permissions regardless of active shard" do
      enable_cache do
        user
        site_admin = Account.site_admin
        site_admin.account_users.create!(user: @user)

        @shard1.activate do
          site_admin.grants_right?(@user, :manage_site_settings).should be_true
        end
        site_admin.grants_right?(@user, :manage_site_settings).should be_true

        user
        @shard1.activate do
          site_admin.grants_right?(@user, :manage_site_settings).should be_false
        end
        site_admin.grants_right?(@user, :manage_site_settings).should be_false
      end
    end
  end

  context "permissions" do
    it "should grant :read_sis to teachers" do
      user_with_pseudonym(:active_all => 1)
      Account.default.grants_right?(@user, :read_sis).should be_false
      @course = Account.default.courses.create!
      @course.enroll_teacher(@user).accept!
      Account.default.grants_right?(@user, :read_sis).should be_true
    end

    it "should grant :read_global_outcomes to any user iff site_admin" do
      @site_admin = Account.site_admin
      @site_admin.grants_right?(User.new, :read_global_outcomes).should be_true

      @subaccount = @site_admin.sub_accounts.create!
      @subaccount.grants_right?(User.new, :read_global_outcomes).should be_false
    end

    it "should not grant :read_outcomes to user's outside the account" do
      Account.default.grants_right?(User.new, :read_outcomes).should be_false
    end

    it "should grant :read_outcomes to account admins" do
      account_admin_user(:account => Account.default)
      Account.default.grants_right?(@admin, :read_outcomes).should be_true
    end

    it "should grant :read_outcomes to subaccount admins" do
      account_admin_user(:account => Account.default.sub_accounts.create!)
      Account.default.grants_right?(@admin, :read_outcomes).should be_true
    end

    it "should grant :read_outcomes to enrollees in account courses" do
      course(:account => Account.default)
      teacher_in_course
      student_in_course
      Account.default.grants_right?(@teacher, :read_outcomes).should be_true
      Account.default.grants_right?(@student, :read_outcomes).should be_true
    end

    it "should grant :read_outcomes to enrollees in subaccount courses" do
      course(:account => Account.default.sub_accounts.create!)
      teacher_in_course
      student_in_course
      Account.default.grants_right?(@teacher, :read_outcomes).should be_true
      Account.default.grants_right?(@student, :read_outcomes).should be_true
    end
  end

  describe "canvas_authentication?" do
    it "should be true if there's not an AAC" do
      Account.default.settings[:canvas_authentication] = false
      Account.default.canvas_authentication?.should be_true
      Account.default.account_authorization_configs.create!(:auth_type => 'ldap')
      Account.default.canvas_authentication?.should be_false
    end
  end

  context "manually created courses account" do
    it "should still work with existing manually created courses accounts" do
      acct = Account.default
      sub = acct.sub_accounts.create!(:name => "Manually-Created Courses")
      manual_courses_account = acct.manually_created_courses_account
      manual_courses_account.id.should == sub.id
      acct.reload.settings[:manually_created_courses_account_id].should == sub.id
    end

    it "should not create a duplicate manual courses account when locale changes" do
      acct = Account.default
      sub1 = acct.manually_created_courses_account
      I18n.locale = "es"
      sub2 = acct.manually_created_courses_account
      I18n.locale = "en"
      sub1.id.should == sub2.id
    end

    it "should work if the saved account id doesn't exist" do
      acct = Account.default
      acct.settings[:manually_created_courses_account_id] = acct.id + 1000
      acct.save!
      acct.manually_created_courses_account.should be_present
    end

    it "should work if the saved account id is not a sub-account" do
      acct = Account.default
      bad_acct = Account.create!
      acct.settings[:manually_created_courses_account_id] = bad_acct.id
      acct.save!
      manual_course_account = acct.manually_created_courses_account
      manual_course_account.id.should_not == bad_acct.id
    end
  end

  describe "account_users_for" do
    it "should be cache coherent for site admin" do
      enable_cache do
        user
        sa = Account.site_admin
        sa.account_users_for(@user).should == []

        au = sa.account_users.create!(user: @user)
        # out-of-proc cache should clear, but we have to manually clear
        # the in-proc cache
        sa = Account.find(sa)
        sa.account_users_for(@user).should == [au]

        au.destroy
        #ditto
        sa = Account.find(sa)
        sa.account_users_for(@user).should == []
      end
    end

    context "sharding" do
      specs_require_sharding

      it "should be cache coherent for site admin" do
        enable_cache do
          user
          sa = Account.site_admin
          @shard1.activate do
            sa.account_users_for(@user).should == []

            au = sa.account_users.create!(user: @user)
            # out-of-proc cache should clear, but we have to manually clear
            # the in-proc cache
            sa = Account.find(sa)
            sa.account_users_for(@user).should == [au]

            au.destroy
            #ditto
            sa = Account.find(sa)
            sa.account_users_for(@user).should == []
          end
        end
      end
    end
  end

  describe "available_course_roles_by_name" do
    before do
      account_model
      @roleA = @account.roles.create :name => 'A'
      @roleA.base_role_type = 'StudentEnrollment'
      @roleA.save!
      @roleB = @account.roles.create :name => 'B'
      @roleB.base_role_type = 'StudentEnrollment'
      @roleB.save!
      @sub_account = @account.sub_accounts.create!
      @roleBsub = @sub_account.roles.create :name => 'B'
      @roleBsub.base_role_type = 'StudentEnrollment'
      @roleBsub.save!
    end

    it "should return roles indexed by name" do
      @account.available_course_roles_by_name.should == { 'A' => @roleA, 'B' => @roleB }
    end

    it "should not return inactive roles" do
      @roleB.deactivate!
      @account.available_course_roles_by_name.should == { 'A' => @roleA }
    end

    it "should not return deleted roles" do
      @roleA.destroy
      @account.available_course_roles_by_name.should == { 'B' => @roleB }
    end

    it "should find the most derived version of each role" do
      @sub_account.available_course_roles_by_name.should == { 'A' => @roleA, 'B' => @roleBsub }
    end

    it "should find a base role if the derived version is inactive" do
      @roleBsub.deactivate!
      @sub_account.available_course_roles_by_name.should == { 'A' => @roleA, 'B' => @roleB }
    end
  end

  describe "account_chain" do
    context "sharding" do
      specs_require_sharding

      it "should find parent accounts when not on the correct shard" do
        @shard1.activate do
          @account1 = Account.create!
          @account2 = @account1.sub_accounts.create!
          @account3 = @account2.sub_accounts.create!
        end

        @account3.account_chain.should == [@account3, @account2, @account1]
      end
    end
  end

  describe "#can_see_admin_tools_tab?" do
    it "returns false if no user is present" do
      account = Account.create!
      account.can_see_admin_tools_tab?(nil).should be_false
    end

    it "returns false if you are a site admin" do
      admin = account_admin_user(:account => Account.site_admin)
      Account.site_admin.can_see_admin_tools_tab?(admin).should be_false
    end

    it "doesn't have permission, it returns false" do
      account = Account.create!
      account.stubs(:grants_right?).returns(false)
      account_admin_user(:account => account)
      account.can_see_admin_tools_tab?(@admin).should be_false
    end

    it "does have permission, it returns true" do
      account = Account.create!
      account.stubs(:grants_right?).returns(true)
      account_admin_user(:account => account)
      account.can_see_admin_tools_tab?(@admin).should be_true
    end
  end

  describe "#update_account_associations" do
    it "should update associations for all courses" do
      account = Account.create!
      c1 = account.courses.create!
      c2 = account.courses.create!
      account.course_account_associations.scoped.delete_all
      account.associated_courses.should == []
      account.update_account_associations
      account.reload
      account.associated_courses.sort_by(&:id).should == [c1, c2]
    end
  end

  describe "default_time_zone" do
    context "root account" do
      before do
        @account = Account.create!
      end

      it "should use provided value when set" do
        @account.default_time_zone = 'America/New_York'
        @account.default_time_zone.should == ActiveSupport::TimeZone['Eastern Time (US & Canada)']
      end

      it "should have a sensible default if not set" do
        @account.default_time_zone.should == ActiveSupport::TimeZone[Account.time_zone_attribute_defaults[:default_time_zone]]
      end
    end

    context "sub account" do
      before do
        @root_account = Account.create!
        @account = @root_account.sub_accounts.create!
        @account.root_account = @root_account
      end

      it "should use provided value when set, regardless of root account setting" do
        @root_account.default_time_zone = 'America/Chicago'
        @account.default_time_zone = 'America/New_York'
        @account.default_time_zone.should == ActiveSupport::TimeZone['Eastern Time (US & Canada)']
      end

      it "should default to root account value if not set" do
        @root_account.default_time_zone = 'America/Chicago'
        @account.default_time_zone.should == ActiveSupport::TimeZone['Central Time (US & Canada)']
      end

      it "should have a sensible default if neither is set" do
        @account.default_time_zone.should == ActiveSupport::TimeZone[Account.time_zone_attribute_defaults[:default_time_zone]]
      end
    end
  end
end
