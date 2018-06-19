#
# Copyright (C) 2011 - present Instructure, Inc.
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
  include_examples "outcome import context examples"

  describe 'relationships' do
    it { is_expected.to have_many(:feature_flags) }
  end

  it "should provide a list of courses" do
    expect{ Account.new.courses }.not_to raise_error
  end

  context "equella_settings" do
    it "should respond to :equella_settings" do
      expect(Account.new).to respond_to(:equella_settings)
      expect(Account.new.equella_settings).to be_nil
    end

    it "should return the equella_settings data if defined" do
      a = Account.new
      a.equella_endpoint = "http://oer.equella.com/signon.do"
      expect(a.equella_settings).not_to be_nil
      expect(a.equella_settings.endpoint).to eql("http://oer.equella.com/signon.do")
      expect(a.equella_settings.default_action).not_to be_nil
    end
  end

  # it "should have an atom feed" do
    # account_model
    # @a.to_atom.should be_is_a(Atom::Entry)
  # end

  context "course lists" do
    before :once do
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
        "S007,C007,Sec7,,,active",
        "S008,C001,Sec8,,,active",
        "S009,C008,Sec9,,,active",
        "S001S,C001S,Sec1,,,active",
        "S002S,C002S,Sec2,,,active",
        "S003S,C003S,Sec3,,,active",
        "S004S,C004S,Sec4,,,active",
        "S005S,C005S,Sec5,,,active",
        "S006S,C006S,Sec6,,,active",
        "S007S,C007S,Sec7,,,active",
        "S008S,C001S,Sec8,,,active",
        "S009S,C008S,Sec9,,,active"
      ])

      process_csv_data_cleanly([
        "course_id,user_id,role,section_id,status,associated_user_id",
        ",U001,student,S001,active,",
        ",U005,student,S005,active,",
        ",U006,student,S006,deleted,",
        ",U007,student,S007,active,",
        ",U008,student,S008,active,",
        ",U009,student,S005,deleted,",
        ",U001,student,S001S,active,",
        ",U005,student,S005S,active,",
        ",U006,student,S006S,deleted,",
        ",U007,student,S007S,active,",
        ",U008,student,S008S,active,",
        ",U009,student,S005S,deleted,"
      ])
    end

    context "fast list" do
      it "should list associated courses" do
        expect(@account.fast_all_courses.map(&:sis_source_id).sort).to eq [
          "C001", "C005", "C006", "C007", "C008", "C009",

          "C001S", "C005S", "C006S", "C007S", "C008S", "C009S", ].sort
      end

      it "should list associated courses by term" do
        expect(@account.fast_all_courses({:term => EnrollmentTerm.where(sis_source_id: "T001").first}).map(&:sis_source_id).sort).to eq ["C001", "C001S"]
        expect(@account.fast_all_courses({:term => EnrollmentTerm.where(sis_source_id: "T002").first}).map(&:sis_source_id).sort).to eq []
        expect(@account.fast_all_courses({:term => EnrollmentTerm.where(sis_source_id: "T003").first}).map(&:sis_source_id).sort).to eq ["C005", "C006", "C007", "C008", "C009", "C005S", "C006S", "C007S", "C008S", "C009S"].sort
      end

      it "counting cross-listed courses only if requested" do
        def check_account(account, include_crosslisted_courses, expected_length, expected_course_names)
          actual_courses = account.fast_all_courses({ :include_crosslisted_courses => include_crosslisted_courses })
          expect(actual_courses.length).to eq expected_length
          actual_course_names = actual_courses.pluck("name").sort!
          expect(actual_course_names).to eq(expected_course_names.sort!)
        end

        root_account = Account.create!
        account_a = Account.create!({ :root_account => root_account })
        account_b = Account.create!({ :root_account => root_account })
        course_a = course_factory({ :account => account_a, :course_name => "course_a" })
        course_b = course_factory({ :account => account_b, :course_name => "course_b" })
        course_b.course_sections.create!({ :name => "section_b" })
        course_b.course_sections.first.crosslist_to_course(course_a)
        check_account(account_a, false, 1, ["course_a"])
        check_account(account_a, true, 1, ["course_a"])
        check_account(account_b, false, 1, ["course_b"])
        check_account(account_b, true, 2, ["course_a", "course_b"])
      end

      it "should list associated nonenrollmentless courses" do
        expect(@account.fast_all_courses({:hide_enrollmentless_courses => true}).map(&:sis_source_id).sort).to eq ["C001", "C005", "C007", "C001S", "C005S", "C007S"].sort #C007 probably shouldn't be here, cause the enrollment section is deleted, but we kinda want to minimize database traffic
      end

      it "should list associated nonenrollmentless courses by term" do
        expect(@account.fast_all_courses({:term => EnrollmentTerm.where(sis_source_id: "T001").first, :hide_enrollmentless_courses => true}).map(&:sis_source_id).sort).to eq ["C001", "C001S"]
        expect(@account.fast_all_courses({:term => EnrollmentTerm.where(sis_source_id: "T002").first, :hide_enrollmentless_courses => true}).map(&:sis_source_id).sort).to eq []
        expect(@account.fast_all_courses({:term => EnrollmentTerm.where(sis_source_id: "T003").first, :hide_enrollmentless_courses => true}).map(&:sis_source_id).sort).to eq ["C005", "C007", "C005S", "C007S"].sort
      end

      it "should order list by specified parameter" do
        order = "courses.created_at ASC"
        expect(@account).to receive(:fast_course_base).with(order: order)
        @account.fast_all_courses(order: order)
      end
    end

    context "name searching" do
      it "should list associated courses" do
        expect(@account.courses_name_like("search").map(&:sis_source_id).sort).to eq [
          "C001S", "C005S", "C006S", "C007S", "C008S", "C009S"]
      end

      it "should list associated courses by term" do
        expect(@account.courses_name_like("search", {:term => EnrollmentTerm.where(sis_source_id: "T001").first}).map(&:sis_source_id).sort).to eq ["C001S"]
        expect(@account.courses_name_like("search", {:term => EnrollmentTerm.where(sis_source_id: "T002").first}).map(&:sis_source_id).sort).to eq []
        expect(@account.courses_name_like("search", {:term => EnrollmentTerm.where(sis_source_id: "T003").first}).map(&:sis_source_id).sort).to eq ["C005S", "C006S", "C007S", "C008S", "C009S"]
      end

      it "should list associated nonenrollmentless courses" do
        expect(@account.courses_name_like("search", {:hide_enrollmentless_courses => true}).map(&:sis_source_id).sort).to eq ["C001S", "C005S", "C007S"] #C007 probably shouldn't be here, cause the enrollment section is deleted, but we kinda want to minimize database traffic
      end

      it "should list associated nonenrollmentless courses by term" do
        expect(@account.courses_name_like("search", {:term => EnrollmentTerm.where(sis_source_id: "T001").first, :hide_enrollmentless_courses => true}).map(&:sis_source_id).sort).to eq ["C001S"]
        expect(@account.courses_name_like("search", {:term => EnrollmentTerm.where(sis_source_id: "T002").first, :hide_enrollmentless_courses => true}).map(&:sis_source_id).sort).to eq []
        expect(@account.courses_name_like("search", {:term => EnrollmentTerm.where(sis_source_id: "T003").first, :hide_enrollmentless_courses => true}).map(&:sis_source_id).sort).to eq ["C005S", "C007S"]
      end
    end
  end

  context "services" do
    before do
      @a = Account.new
    end
    it "should be able to specify a list of enabled services" do
      @a.allowed_services = 'linked_in,twitter'
      expect(@a.service_enabled?(:linked_in)).to be_truthy
      expect(@a.service_enabled?(:twitter)).to be_truthy
      expect(@a.service_enabled?(:diigo)).to be_falsey
      expect(@a.service_enabled?(:avatars)).to be_falsey
    end

    it "should not enable services off by default" do
      expect(@a.service_enabled?(:linked_in)).to be_truthy
      expect(@a.service_enabled?(:avatars)).to be_falsey
    end

    it "should add and remove services from the defaults" do
      @a.allowed_services = '+avatars,-linked_in'
      expect(@a.service_enabled?(:avatars)).to be_truthy
      expect(@a.service_enabled?(:twitter)).to be_truthy
      expect(@a.service_enabled?(:linked_in)).to be_falsey
    end

    it "should allow settings services" do
      expect {@a.enable_service(:completly_bogs)}.to raise_error("Invalid Service")

      @a.disable_service(:twitter)
      expect(@a.service_enabled?(:twitter)).to be_falsey

      @a.enable_service(:twitter)
      expect(@a.service_enabled?(:twitter)).to be_truthy
    end

    it "should use + and - by default when setting service availability" do
      @a.enable_service(:twitter)
      expect(@a.service_enabled?(:twitter)).to be_truthy
      expect(@a.allowed_services).to be_nil

      @a.disable_service(:twitter)
      expect(@a.allowed_services).to match('\-twitter')

      @a.disable_service(:avatars)
      expect(@a.service_enabled?(:avatars)).to be_falsey
      expect(@a.allowed_services).not_to match('avatars')

      @a.enable_service(:avatars)
      expect(@a.service_enabled?(:avatars)).to be_truthy
      expect(@a.allowed_services).to match('\+avatars')
    end

    it "should be able to set service availibity for previously hard-coded values" do
      @a.allowed_services = 'avatars,linked_in'

      @a.enable_service(:twitter)
      expect(@a.service_enabled?(:twitter)).to be_truthy
      expect(@a.allowed_services).to match(/twitter/)
      expect(@a.allowed_services).not_to match(/[+-]/)

      @a.disable_service(:linked_in)
      expect(@a.allowed_services).not_to match(/linked_in/)
      expect(@a.allowed_services).not_to match(/[+-]/)

      @a.disable_service(:avatars)
      @a.disable_service(:twitter)
      expect(@a.allowed_services).to be_nil
    end

    it "should not wipe out services that are substrings of each other" do

      AccountServices.register_service(
        :google_docs_prev,
        {
          :name => "My google docs prev", :description => "", :expose_to_ui => :service, :default => true
        }
      )

      @a.disable_service('google_docs_previews')
      @a.disable_service('google_docs_prev')
      expect(@a.allowed_services).to eq '-google_docs_previews,-google_docs_prev'
    end

    describe "services_exposed_to_ui_hash" do
      it "should return all ui services by default" do
        expected_services = AccountServices.allowable_services.reject { |_, k| !k[:expose_to_ui] || (k[:expose_to_ui_proc] && !k[:expose_to_ui_proc].call(nil)) }.keys
        expect(Account.services_exposed_to_ui_hash.keys).to eq expected_services
      end

      it "should return services of a type if specified" do
        expected_services = AccountServices.allowable_services.reject { |_, k| k[:expose_to_ui] != :setting || (k[:expose_to_ui_proc] && !k[:expose_to_ui_proc].call(nil)) }.keys
        expect(Account.services_exposed_to_ui_hash(:setting).keys).to eq expected_services
      end

      it "should filter based on user and account if a proc is specified" do
        user1 = User.create!
        user2 = User.create!
        AccountServices.register_service(:myservice, {
          name: "My Test Service",
          description: "Nope",
          expose_to_ui: :setting,
          default: false,
          expose_to_ui_proc: proc { |user, account| user == user2 && account == Account.default },
        })
        expect(Account.services_exposed_to_ui_hash(:setting).keys).not_to be_include(:myservice)
        expect(Account.services_exposed_to_ui_hash(:setting, user1, Account.default).keys).not_to be_include(:myservice)
        expect(Account.services_exposed_to_ui_hash(:setting, user2, Account.default).keys).to be_include(:myservice)
      end
    end

    describe "plugin services" do
      before do
        AccountServices.register_service(:myplugin, { :name => "My Plugin", :description => "", :expose_to_ui => :setting, :default => false })
      end

      it "should return the service" do
        expect(AccountServices.allowable_services.keys).to be_include(:myplugin)
      end

      it "should allow setting the service" do
        expect(@a.service_enabled?(:myplugin)).to be_falsey

        @a.enable_service(:myplugin)
        expect(@a.service_enabled?(:myplugin)).to be_truthy
        expect(@a.allowed_services).to match(/\+myplugin/)

        @a.disable_service(:myplugin)
        expect(@a.service_enabled?(:myplugin)).to be_falsey
        expect(@a.allowed_services).to be_blank
      end

      describe "services_exposed_to_ui_hash" do
        it "should return services defined in a plugin" do
          expect(Account.services_exposed_to_ui_hash().keys).to be_include(:myplugin)
          expect(Account.services_exposed_to_ui_hash(:setting).keys).to be_include(:myplugin)
        end
      end
    end
  end

  context "settings=" do
    it "should filter non-hash hash settings" do
      a = Account.new
      a.settings = {'sis_default_grade_export' => 'string'}.with_indifferent_access
      expect(a.settings[:error_reporting]).to eql(nil)

      a.settings = {'sis_default_grade_export' => {
        'value' => true
      }}.with_indifferent_access
      expect(a.settings[:sis_default_grade_export]).to be_is_a(Hash)
      expect(a.settings[:sis_default_grade_export][:value]).to eql true
    end
  end

  context "allow_global_includes?" do
    let(:root){ Account.default }
    it "false unless they've checked the box to allow it" do
      expect(root.allow_global_includes?).to be_falsey
    end

    it "true if they've checked the box to allow it" do
      root.settings = {'global_includes' => true}
      expect(root.allow_global_includes?).to be_truthy
    end

    describe "subaccount" do
      let(:sub_account){ root.sub_accounts.create! }

      it "false if root account hasn't checked global_includes AND subaccount branding" do
        expect(sub_account.allow_global_includes?).to be_falsey

        sub_account.root_account.settings = {'global_includes' => true, 'sub_account_includes' => false}
        expect(sub_account.allow_global_includes?).to be_falsey

        sub_account.root_account.settings = {'global_includes' => false, 'sub_account_includes' => true}
        expect(sub_account.allow_global_includes?).to be_falsey
      end

      it "true if root account HAS checked global_includes and turned on subaccount branding" do
        sub_account.root_account.settings = {'global_includes' => true, 'sub_account_includes' => true}
        expect(sub_account.allow_global_includes?).to be_truthy
      end
    end
  end

  context "turnitin secret" do
    it "should decrypt the turnitin secret to the original value" do
      a = Account.new
      a.turnitin_shared_secret = "asdf"
      expect(a.turnitin_shared_secret).to eql("asdf")
      a.turnitin_shared_secret = "2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3"
      expect(a.turnitin_shared_secret).to eql("2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3")
    end
  end

  context "closest_turnitin_originality" do
    before :each do
        @root_account = Account.create!(:turnitin_pledge => "root")
        @root_account.turnitin_originality = 'after_grading'
        @root_account.save!
    end

    it "should find closest_turnitin_originality from root account" do
      expect(@root_account.closest_turnitin_originality).to eq('after_grading')
    end

    it "should find closest_turnitin_originality from sub account" do
      sub_account = Account.create(:name => 'sub', :parent_account => @root_account)
      sub_account.turnitin_originality = 'never'
      expect(sub_account.closest_turnitin_originality).to eq('never')
    end

    it "should find closest_turnitin_originality from sub account when set on root account" do
      sub_account = Account.create(:name => 'sub', :parent_account => @root_account)
      expect(sub_account.closest_turnitin_originality).to eq('after_grading')
    end
  end

  context "closest_turnitin_pledge" do
    it "should work for custom sub, custom root" do
      root_account = Account.create!(:turnitin_pledge => "root")
      sub_account = Account.create!(:parent_account => root_account, :turnitin_pledge => "sub")
      expect(root_account.closest_turnitin_pledge).to eq "root"
      expect(sub_account.closest_turnitin_pledge).to eq "sub"
    end

    it "should work for nil sub, custom root" do
      root_account = Account.create!(:turnitin_pledge => "root")
      sub_account = Account.create!(:parent_account => root_account)
      expect(root_account.closest_turnitin_pledge).to eq "root"
      expect(sub_account.closest_turnitin_pledge).to eq "root"
    end

    it "should work for nil sub, nil root" do
      root_account = Account.create!
      sub_account = Account.create!(:parent_account => root_account)
      expect(root_account.closest_turnitin_pledge).not_to be_empty
      expect(sub_account.closest_turnitin_pledge).not_to be_empty
    end

    it 'uses the default message if pledge is nil or empty' do
      account = Account.create!(turnitin_pledge: '')
      expect(account.closest_turnitin_pledge).to eq 'This assignment submission is my own, original work'
    end
  end

  it "should make a default enrollment term if necessary" do
    a = Account.create!(:name => "nada")
    expect(a.enrollment_terms.size).to eq 1
    expect(a.enrollment_terms.first.name).to eq EnrollmentTerm::DEFAULT_TERM_NAME

    # don't create a new default term for sub-accounts
    a2 = a.all_accounts.create!(:name => "sub")
    expect(a2.enrollment_terms.size).to eq 0
  end

  def account_with_admin_and_restricted_user(account, restricted_role)
    admin = User.create
    user = User.create
    account.account_users.create!(:user => admin, :role => admin_role)
    account.account_users.create!(:user => user, :role => restricted_role)
    [ admin, user ]
  end

  it "should set up access policy correctly" do
    # double out any "if" permission conditions
    RoleOverride.permissions.each do |k, v|
      next unless v[:if]
      allow_any_instance_of(Account).to receive(v[:if]).and_return(true)
    end
    site_admin = Account.site_admin

    # Set up a hierarchy of 4 accounts - a root account, a sub account,
    # a sub sub account, and SiteAdmin account.  Create a 'Restricted Admin'
    # role available for each one, and create an admin user and a user in that restricted role
    @sa_role = custom_account_role('Restricted SA Admin', account: site_admin)

    site_admin.settings[:mfa_settings] = 'required'
    site_admin.save!
    root_account = Account.create
    @root_role = custom_account_role('Restricted Root Admin', :account => root_account)

    sub_account = Account.create(:parent_account => root_account)
    sub_sub_account = Account.create(:parent_account => sub_account)

    hash = {}
    hash[:site_admin] = { :account => Account.site_admin}
    hash[:root] = { :account => root_account}
    hash[:sub] = { :account => sub_account}
    hash[:sub_sub] = { :account => sub_sub_account}

    hash.each do |k, v|
      v[:account].update_attribute(:settings, {:no_enrollments_can_create_courses => false})
      admin, user = account_with_admin_and_restricted_user(v[:account], (k == :site_admin ? @sa_role : @root_role))
      hash[k][:admin] = admin
      hash[k][:user] = user
    end

    limited_access = [ :read, :read_as_admin, :manage, :update, :delete, :read_outcomes, :read_terms ]
    conditional_access = RoleOverride.permissions.select { |_, v| v[:account_allows] }.map(&:first)
    full_access = RoleOverride.permissions.keys +
                  limited_access - conditional_access +
                  [:create_courses] +
                  [:create_tool_manually]

    full_root_access = full_access - RoleOverride.permissions.select { |k, v| v[:account_only] == :site_admin }.map(&:first)
    full_sub_access = full_root_access - RoleOverride.permissions.select { |k, v| v[:account_only] == :root }.map(&:first)
    # site admin has access to everything everywhere
    hash.each do |k, v|
      account = v[:account]
      expect(account.check_policy(hash[:site_admin][:admin]) - conditional_access).to match_array full_access + (k == :site_admin ? [:read_global_outcomes] : [])
      expect(account.check_policy(hash[:site_admin][:user]) - conditional_access).to match_array limited_access + (k == :site_admin ? [:read_global_outcomes] : [])
    end

    # root admin has access to everything except site admin
    account = hash[:site_admin][:account]
    expect(account.check_policy(hash[:root][:admin])).to match_array [:read_global_outcomes]
    expect(account.check_policy(hash[:root][:user])).to match_array [:read_global_outcomes]
    hash.each do |k, v|
      next if k == :site_admin
      account = v[:account]
      expect(account.check_policy(hash[:root][:admin]) - conditional_access).to match_array full_root_access
      expect(account.check_policy(hash[:root][:user])).to match_array limited_access
    end

    # sub account has access to sub and sub_sub
    hash.each do |k, v|
      next unless k == :site_admin || k == :root
      account = v[:account]
      expect(account.check_policy(hash[:sub][:admin])).to match_array(k == :site_admin ? [:read_global_outcomes] : [:read_outcomes, :read_terms])
      expect(account.check_policy(hash[:sub][:user])).to match_array(k == :site_admin ? [:read_global_outcomes] : [:read_outcomes, :read_terms])
    end
    hash.each do |k, v|
      next if k == :site_admin || k == :root
      account = v[:account]
      expect(account.check_policy(hash[:sub][:admin]) - conditional_access).to match_array full_sub_access
      expect(account.check_policy(hash[:sub][:user])).to match_array limited_access
    end

    # Grant 'Restricted Admin' a specific permission, and re-check everything
    some_access = [:read_reports] + limited_access
    hash.each do |k, v|
      account = v[:account]
      account.role_overrides.create!(:permission => 'read_reports', :role => (k == :site_admin ? @sa_role : @root_role), :enabled => true)
      account.role_overrides.create!(:permission => 'reset_any_mfa', :role => @sa_role, :enabled => true)
      # clear caches
      account.tap{|a| a.settings[:mfa_settings] = :optional; a.save!}
      v[:account] = Account.find(account.id)
    end
    RoleOverride.clear_cached_contexts
    AdheresToPolicy::Cache.clear
    hash.each do |k, v|
      account = v[:account]
      admin_array = full_access + (k == :site_admin ? [:read_global_outcomes] : [])
      user_array = some_access + [:reset_any_mfa] +
        (k == :site_admin ? [:read_global_outcomes] : [])
      expect(account.check_policy(hash[:site_admin][:admin]) - conditional_access).to match_array admin_array
      expect(account.check_policy(hash[:site_admin][:user])).to match_array user_array
    end

    account = hash[:site_admin][:account]
    expect(account.check_policy(hash[:root][:admin])).to match_array [:read_global_outcomes]
    expect(account.check_policy(hash[:root][:user])).to match_array [:read_global_outcomes]
    hash.each do |k, v|
      next if k == :site_admin
      account = v[:account]
      expect(account.check_policy(hash[:root][:admin]) - conditional_access).to match_array full_root_access
      expect(account.check_policy(hash[:root][:user])).to match_array some_access
    end

    # sub account has access to sub and sub_sub
    hash.each do |k, v|
      next unless k == :site_admin || k == :root
      account = v[:account]
      expect(account.check_policy(hash[:sub][:admin])).to match_array(k == :site_admin ? [:read_global_outcomes] : [:read_outcomes, :read_terms])
      expect(account.check_policy(hash[:sub][:user])).to match_array(k == :site_admin ? [:read_global_outcomes] : [:read_outcomes, :read_terms])
    end
    hash.each do |k, v|
      next if k == :site_admin || k == :root
      account = v[:account]
      expect(account.check_policy(hash[:sub][:admin]) - conditional_access).to match_array full_sub_access
      expect(account.check_policy(hash[:sub][:user])).to match_array some_access
    end
  end

  context "sharding" do
    specs_require_sharding

    it "queries for enrollments correctly when another shard is active" do
      teacher_in_course
      @enrollment.accept!

      @shard1.activate do
        expect(@course.grants_right?(@user, :read_sis)).to eq true
      end
    end
  end

  it "should allow no_enrollments_can_create_courses correctly" do
    a = Account.default
    a.settings = { :no_enrollments_can_create_courses => true }
    a.save!

    user_factory
    expect(a.grants_right?(@user, :create_courses)).to be_truthy
  end

  it "does not allow create_courses even to admins on site admin and children" do
    a = Account.site_admin
    a.settings = { :no_enrollments_can_create_courses => true }
    a.save!
    manual = a.manually_created_courses_account
    user_factory

    expect(a.grants_right?(@user, :create_courses)).to eq false
    expect(manual.grants_right?(@user, :create_courses)).to eq false
  end

  it "should correctly return sub-accounts as options" do
    a = Account.default
    sub = Account.create!(:name => 'sub', :parent_account => a)
    sub2 = Account.create!(:name => 'sub2', :parent_account => a)
    sub2_1 = Account.create!(:name => 'sub2-1', :parent_account => sub2)
    options = a.sub_accounts_as_options
    expect(options).to eq(
      [
        ["Default Account", a.id],
        ["&nbsp;&nbsp;sub", sub.id],
        ["&nbsp;&nbsp;sub2", sub2.id],
        ["&nbsp;&nbsp;&nbsp;&nbsp;sub2-1", sub2_1.id]
      ]
    )
  end

  it "should correctly return sub-account_ids recursively" do
    a = Account.default
    subs = []
    sub = Account.create!(name: 'sub', parent_account: a)
    subs << grand_sub = Account.create!(name: 'grand_sub', parent_account: sub)
    subs << great_grand_sub = Account.create!(name: 'great_grand_sub', parent_account: grand_sub)
    subs << Account.create!(name: 'great_great_grand_sub', parent_account: great_grand_sub)
    expect(Account.sub_account_ids_recursive(sub.id).sort).to eq(subs.map(&:id).sort)
  end

  it "should return the correct user count" do
    a = Account.default
    expect(a.all_users.count).to eq a.user_count
    expect(a.user_count).to eq 0

    u = User.create!
    a.account_users.create!(user: u)
    expect(a.all_users.count).to eq a.user_count
    expect(a.user_count).to eq 1

    course_with_teacher
    @teacher.update_account_associations
    expect(a.all_users.count).to eq a.user_count
    expect(a.user_count).to eq 2

    a2 = a.sub_accounts.create!
    course_with_teacher(:account => a2)
    @teacher.update_account_associations
    expect(a.all_users.count).to eq a.user_count
    expect(a.user_count).to eq 3

    user_with_pseudonym
    expect(a.all_users.count).to eq a.user_count
    expect(a.user_count).to eq 4

  end

  it "group_categories should not include deleted categories" do
    account = Account.default
    expect(account.group_categories.count).to eq 0
    category1 = account.group_categories.create(:name => 'category 1')
    category2 = account.group_categories.create(:name => 'category 2')
    expect(account.group_categories.count).to eq 2
    category1.destroy
    account.reload
    expect(account.group_categories.count).to eq 1
    expect(account.group_categories.to_a).to eq [category2]
  end

  it "group_categories.active should not include deleted categories" do
    account = Account.default
    expect(account.group_categories.active.count).to eq 0
    category1 = account.group_categories.create(name: 'category 1')
    category2 = account.group_categories.create(name: 'category 2')
    expect(account.group_categories.active.count).to eq 2
    category1.destroy
    account.reload
    expect(account.group_categories.active.count).to eq 1
    expect(account.all_group_categories.count).to eq 2
    expect(account.group_categories.active.to_a).to eq [category2]
  end

  it "should return correct values for login_handle_name_with_inference" do
    account = Account.default
    expect(account.login_handle_name_with_inference).to eq "Email"

    config = account.authentication_providers.create!(auth_type: 'cas')
    account.authentication_providers.first.move_to_bottom
    expect(account.login_handle_name_with_inference).to eq "Login"

    config.destroy
    config = account.authentication_providers.create!(auth_type: 'saml')
    account.authentication_providers.active.first.move_to_bottom
    expect(account.reload.login_handle_name_with_inference).to eq "Login"

    config.destroy
    account.authentication_providers.create!(auth_type: 'ldap')
    account.authentication_providers.active.first.move_to_bottom
    expect(account.reload.login_handle_name_with_inference).to eq "Email"
    account.login_handle_name = "LDAP Login"
    account.save!
    expect(account.reload.login_handle_name_with_inference).to eq "LDAP Login"
  end

  context "users_not_in_groups" do
    before :once do
      @account = Account.default
      @user1 = account_admin_user(:account => @account)
      @user2 = account_admin_user(:account => @account)
      @user3 = account_admin_user(:account => @account)
    end

    it "should not include deleted users" do
      @user1.destroy
      expect(@account.users_not_in_groups([]).size).to eq 2
    end

    it "should not include users in one of the groups" do
      group = @account.groups.create
      group.add_user(@user1)
      users = @account.users_not_in_groups([group])
      expect(users.size).to eq 2
      expect(users).not_to be_include(@user1)
    end

    it "should include users otherwise" do
      group = @account.groups.create
      group.add_user(@user1)
      users = @account.users_not_in_groups([group])
      expect(users).to be_include(@user2)
      expect(users).to be_include(@user3)
    end

    it "should allow ordering by user's sortable name" do
      @user1.sortable_name = 'jonny'; @user1.save
      @user2.sortable_name = 'bob'; @user2.save
      @user3.sortable_name = 'richard'; @user3.save
      users = @account.users_not_in_groups([], order: User.sortable_name_order_by_clause('users'))
      expect(users.map{ |u| u.id }).to eq [@user2.id, @user1.id, @user3.id]
    end
  end

  context "tabs_available" do
    before :once do
      @account = Account.default.sub_accounts.create!(:name => "sub-account")
    end

    it "should include 'Developer Keys' for the authorized users of the site_admin account" do
      account_admin_user(:account => Account.site_admin)
      tabs = Account.site_admin.tabs_available(@admin)
      expect(tabs.map{|t| t[:id] }).to be_include(Account::TAB_DEVELOPER_KEYS)

      tabs = Account.site_admin.tabs_available(nil)
      expect(tabs.map{|t| t[:id] }).not_to be_include(Account::TAB_DEVELOPER_KEYS)
    end

    it "should include 'Developer Keys' for the admin users of an account" do
      account = Account.create!
      account_admin_user(:account => account)
      tabs = account.tabs_available(@admin)
      expect(tabs.map{|t| t[:id] }).to be_include(Account::TAB_DEVELOPER_KEYS)

      tabs = account.tabs_available(nil)
      expect(tabs.map{|t| t[:id] }).not_to be_include(Account::TAB_DEVELOPER_KEYS)
    end

    it "should include 'Developer Keys' for the admin users of a sub account" do
      account = Account.create!
      account.enable_feature!(:developer_key_management)
      sub_account = Account.create!(parent_account: account)
      admin = account_admin_user(:account => sub_account)
      tabs = sub_account.tabs_available(admin)
      expect(tabs.map{|t| t[:id] }).to include(Account::TAB_DEVELOPER_KEYS)
    end

    it "should not include 'Developer Keys' for non-site_admin accounts" do
      tabs = @account.tabs_available(nil)
      expect(tabs.map{|t| t[:id] }).not_to be_include(Account::TAB_DEVELOPER_KEYS)

      tabs = @account.root_account.tabs_available(nil)
      expect(tabs.map{|t| t[:id] }).not_to be_include(Account::TAB_DEVELOPER_KEYS)
    end

    it "should not include external tools if not configured for account navigation" do
      tool = @account.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :domain => "example.com")
      tool.user_navigation = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      expect(tool.has_placement?(:account_navigation)).to eq false
      tabs = @account.tabs_available(nil)
      expect(tabs.map{|t| t[:id] }).not_to be_include(tool.asset_string)
    end

    it "should include active external tools if configured on the account" do
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

      tools.each { |t| expect(t.has_placement?(:account_navigation)).to eq true }

      tabs = @account.tabs_available
      tab_ids = tabs.map{|t| t[:id] }
      expect(tab_ids).to be_include(tool1.asset_string)
      expect(tab_ids).not_to be_include(tool2.asset_string)
      tab = tabs.detect{|t| t[:id] == tool1.asset_string }
      expect(tab[:label]).to eq tool1.settings[:account_navigation][:text]
      expect(tab[:href]).to eq :account_external_tool_path
      expect(tab[:args]).to eq [@account.id, tool1.id]
    end

    it "should include external tools if configured on the root account" do
      tool = @account.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :domain => "example.com")
      tool.account_navigation = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      expect(tool.has_placement?(:account_navigation)).to eq true
      tabs = @account.tabs_available(nil)
      expect(tabs.map{|t| t[:id] }).to be_include(tool.asset_string)
      tab = tabs.detect{|t| t[:id] == tool.asset_string }
      expect(tab[:label]).to eq tool.settings[:account_navigation][:text]
      expect(tab[:href]).to eq :account_external_tool_path
      expect(tab[:args]).to eq [@account.id, tool.id]
    end

    it "should not include external tools for non-admins if visibility is set" do
      course_with_teacher(:account => @account)
      tool = @account.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :domain => "example.com")
      tool.account_navigation = {:url => "http://www.example.com", :text => "Example URL", :visibility => "admins"}
      tool.save!
      expect(tool.has_placement?(:account_navigation)).to eq true
      tabs = @account.tabs_available(@teacher)
      expect(tabs.map{|t| t[:id] }).to_not be_include(tool.asset_string)

      admin = account_admin_user(:account => @account)
      tabs = @account.tabs_available(admin)
      expect(tabs.map{|t| t[:id] }).to be_include(tool.asset_string)
    end

    it "should use localized labels" do
      tool = @account.context_external_tools.new(:name => "bob", :consumer_key => "test", :shared_secret => "secret",
                                                 :url => "http://example.com")

      account_navigation = {
          :text => 'this should not be the title',
          :url => 'http://www.example.com',
          :labels => {
              'en' => 'English Label',
              'sp' => 'Spanish Label'
          }
      }

      tool.settings[:account_navigation] = account_navigation
      tool.save!

      tabs = @account.external_tool_tabs({})

      expect(tabs.first[:label]).to eq "English Label"
    end

    it 'includes message handlers' do
      mock_tab = {
        :id => '1234',
        :label => 'my_label',
        :css_class => '1234',
        :href => :launch_path_helper,
        :visibility => nil,
        :external => true,
        :hidden => false,
        :args => [1, 2]
      }
      allow(Lti::MessageHandler).to receive(:lti_apps_tabs).and_return([mock_tab])
      expect(@account.tabs_available(nil)).to include(mock_tab)
    end

    it 'uses :manage_assignments to determine question bank tab visibility' do
      account_admin_user_with_role_changes(acccount: @account, role_changes: { manage_assignments: true, manage_grades: false})
      tabs = @account.tabs_available(@admin)
      expect(tabs.map{|t| t[:id] }).to be_include(Account::TAB_QUESTION_BANKS)
    end
  end

  describe "fast_all_users" do
    it "should preserve sortable_name" do
      user_with_pseudonym(:active_all => 1)
      @user.update_attributes(:name => "John St. Clair", :sortable_name => "St. Clair, John")
      @johnstclair = @user
      user_with_pseudonym(:active_all => 1, :username => 'jt@instructure.com', :name => 'JT Olds')
      @jtolds = @user
      expect(Account.default.fast_all_users).to eq [@jtolds, @johnstclair]
    end
  end

  it "should not allow setting an sis id for a root account" do
    @account = Account.create!
    @account.sis_source_id = 'abc'
    expect(@account.save).to be_falsey
  end

  describe "user_list_search_mode_for" do
    let_once(:account) { Account.default }
    it "should be preferred for anyone if open registration is turned on" do
      account.settings = { :open_registration => true }
      expect(account.user_list_search_mode_for(nil)).to eq :preferred
      expect(account.user_list_search_mode_for(user_factory)).to eq :preferred
    end

    it "should be preferred for account admins" do
      expect(account.user_list_search_mode_for(nil)).to eq :closed
      expect(account.user_list_search_mode_for(user_factory)).to eq :closed
      user_factory
      account.account_users.create!(user: @user)
      expect(account.user_list_search_mode_for(@user)).to eq :preferred
    end
  end

  context "sharding" do
    specs_require_sharding

    it "should properly return site admin permissions regardless of active shard" do
      enable_cache do
        user_factory
        site_admin = Account.site_admin
        site_admin.account_users.create!(user: @user)

        @shard1.activate do
          expect(site_admin.grants_right?(@user, :manage_site_settings)).to be_truthy
        end
        expect(site_admin.grants_right?(@user, :manage_site_settings)).to be_truthy

        user_factory
        @shard1.activate do
          expect(site_admin.grants_right?(@user, :manage_site_settings)).to be_falsey
        end
        expect(site_admin.grants_right?(@user, :manage_site_settings)).to be_falsey
      end
    end
  end

  context "permissions" do
    before(:once) { Account.default }

    it "should grant :read_global_outcomes to any user iff site_admin" do
      @site_admin = Account.site_admin
      expect(@site_admin.grants_right?(User.new, :read_global_outcomes)).to be_truthy

      @subaccount = @site_admin.sub_accounts.create!
      expect(@subaccount.grants_right?(User.new, :read_global_outcomes)).to be_falsey
    end

    it "should not grant :read_outcomes to user's outside the account" do
      expect(Account.default.grants_right?(User.new, :read_outcomes)).to be_falsey
    end

    it "should grant :read_outcomes to account admins" do
      account_admin_user(:account => Account.default)
      expect(Account.default.grants_right?(@admin, :read_outcomes)).to be_truthy
    end

    it "should grant :read_outcomes to subaccount admins" do
      account_admin_user(:account => Account.default.sub_accounts.create!)
      expect(Account.default.grants_right?(@admin, :read_outcomes)).to be_truthy
    end

    it "should grant :read_outcomes to enrollees in account courses" do
      course_factory(:account => Account.default)
      teacher_in_course
      student_in_course
      expect(Account.default.grants_right?(@teacher, :read_outcomes)).to be_truthy
      expect(Account.default.grants_right?(@student, :read_outcomes)).to be_truthy
    end

    it "should grant :read_outcomes to enrollees in subaccount courses" do
      course_factory(:account => Account.default.sub_accounts.create!)
      teacher_in_course
      student_in_course
      expect(Account.default.grants_right?(@teacher, :read_outcomes)).to be_truthy
      expect(Account.default.grants_right?(@student, :read_outcomes)).to be_truthy
    end
  end

  describe "authentication_providers.active" do
    let(:account){ Account.default }
    let!(:aac){ account.authentication_providers.create!(auth_type: 'facebook') }

    it "pulls active AACS" do
      expect(account.authentication_providers.active).to include(aac)
    end

    it "ignores deleted AACs" do
      aac.destroy
      expect(account.authentication_providers.active).to_not include(aac)
    end
  end

  describe "delegated_authentication?" do
    let(:account){ Account.default }

    before do
      account.authentication_providers.scope.delete_all
    end

    it "is false for LDAP" do
      account.authentication_providers.create!(auth_type: 'ldap')
      expect(account.delegated_authentication?).to eq false
    end

    it "is true for CAS" do
      account.authentication_providers.create!(auth_type: 'cas')
      expect(account.delegated_authentication?).to eq true
    end
  end

  describe "#non_canvas_auth_configured?" do
    let(:account) { Account.default }

    it "is false for no aacs" do
      expect(account.non_canvas_auth_configured?).to be_falsey
    end

    it "is true for having aacs" do
      Account.default.authentication_providers.create!(auth_type: 'ldap')
      expect(account.non_canvas_auth_configured?).to be_truthy
    end

    it "is false after aacs deleted" do
      Account.default.authentication_providers.create!(auth_type: 'ldap')
      account.authentication_providers.destroy_all
      expect(account.non_canvas_auth_configured?).to be_falsey
    end
  end

  describe '#find_child' do
    it 'works for root accounts' do
      sub = Account.default.sub_accounts.create!
      expect(Account.default.find_child(sub.id)).to eq sub
    end

    it 'works for children accounts' do
      sub = Account.default.sub_accounts.create!
      sub_sub = sub.sub_accounts.create!
      sub_sub_sub = sub_sub.sub_accounts.create!
      expect(sub.find_child(sub_sub_sub.id)).to eq sub_sub_sub
    end

    it 'raises for out-of-tree accounts' do
      sub = Account.default.sub_accounts.create!
      sub_sub = sub.sub_accounts.create!
      sibling = sub.sub_accounts.create!
      expect { sub_sub.find_child(sibling.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "manually created courses account" do
    it "should still work with existing manually created courses accounts" do
      acct = Account.default
      sub = acct.sub_accounts.create!(:name => "Manually-Created Courses")
      manual_courses_account = acct.manually_created_courses_account
      expect(manual_courses_account.id).to eq sub.id
      expect(acct.reload.settings[:manually_created_courses_account_id]).to eq sub.id
    end

    it "should not create a duplicate manual courses account when locale changes" do
      acct = Account.default
      sub1 = acct.manually_created_courses_account
      I18n.locale = "es"
      sub2 = acct.manually_created_courses_account
      I18n.locale = "en"
      expect(sub1.id).to eq sub2.id
    end

    it "should work if the saved account id doesn't exist" do
      acct = Account.default
      acct.settings[:manually_created_courses_account_id] = acct.id + 1000
      acct.save!
      expect(acct.manually_created_courses_account).to be_present
    end

    it "should work if the saved account id is not a sub-account" do
      acct = Account.default
      bad_acct = Account.create!
      acct.settings[:manually_created_courses_account_id] = bad_acct.id
      acct.save!
      manual_course_account = acct.manually_created_courses_account
      expect(manual_course_account.id).not_to eq bad_acct.id
    end
  end

  describe "account_users_for" do
    it "should be cache coherent for site admin" do
      enable_cache do
        user_factory
        sa = Account.site_admin
        expect(sa.account_users_for(@user)).to eq []

        au = sa.account_users.create!(user: @user)
        # out-of-proc cache should clear, but we have to manually clear
        # the in-proc cache
        sa = Account.find(sa.id)
        expect(sa.account_users_for(@user)).to eq [au]

        au.destroy
        #ditto
        sa = Account.find(sa.id)
        expect(sa.account_users_for(@user)).to eq []
      end
    end

    context "sharding" do
      specs_require_sharding

      it "should be cache coherent for site admin" do
        enable_cache do
          user_factory
          sa = Account.site_admin
          @shard1.activate do
            expect(sa.account_users_for(@user)).to eq []

            au = sa.account_users.create!(user: @user)
            # out-of-proc cache should clear, but we have to manually clear
            # the in-proc cache
            sa = Account.find(sa.id)
            expect(sa.account_users_for(@user)).to eq [au]

            au.destroy
            #ditto
            sa = Account.find(sa.id)
            expect(sa.account_users_for(@user)).to eq []
          end
        end
      end
    end
  end

  describe "available_custom_course_roles" do
    before :once do
      account_model
      @roleA = @account.roles.create :name => 'A'
      @roleA.base_role_type = 'StudentEnrollment'
      @roleA.save!
      @roleB = @account.roles.create :name => 'B'
      @roleB.base_role_type = 'StudentEnrollment'
      @roleB.save!
      @sub_account = @account.sub_accounts.create!
      @roleC = @sub_account.roles.create :name => 'C'
      @roleC.base_role_type = 'StudentEnrollment'
      @roleC.save!
    end

    it "should return roles indexed by name" do
      expect(@account.available_custom_course_roles.sort_by(&:id)).to eq [ @roleA, @roleB ].sort_by(&:id)
    end

    it "should not return inactive roles" do
      @roleB.deactivate!
      expect(@account.available_custom_course_roles).to eq [ @roleA ]
    end

    it "should not return deleted roles" do
      @roleA.destroy
      expect(@account.available_custom_course_roles).to eq [ @roleB ]
    end

    it "should derive roles from parents" do
      expect(@sub_account.available_custom_course_roles.sort_by(&:id)).to eq [ @roleA, @roleB, @roleC ].sort_by(&:id)
    end

    it "should include built-in roles when called" do
      expect(@sub_account.available_course_roles.sort_by(&:id)).to eq ([ @roleA, @roleB, @roleC ] + Role.built_in_course_roles).sort_by(&:id)
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

        expect(@account3.account_chain).to eq [@account3, @account2, @account1]
      end
    end

    it "returns parent accounts in order up the tree" do
      account1 = Account.create!
      account2 = account1.sub_accounts.create!
      account3 = account2.sub_accounts.create!
      account4 = account3.sub_accounts.create!

      expect(account4.account_chain).to eq [account4, account3, account2, account1]
    end

  end

  describe "#can_see_admin_tools_tab?" do
    let_once(:account) { Account.create! }
    it "returns false if no user is present" do
      expect(account.can_see_admin_tools_tab?(nil)).to be_falsey
    end

    it "returns false if you are a site admin" do
      admin = account_admin_user(:account => Account.site_admin)
      expect(Account.site_admin.can_see_admin_tools_tab?(admin)).to be_falsey
    end

    it "doesn't have permission, it returns false" do
      allow(account).to receive(:grants_right?).and_return(false)
      account_admin_user(:account => account)
      expect(account.can_see_admin_tools_tab?(@admin)).to be_falsey
    end

    it "does have permission, it returns true" do
      allow(account).to receive(:grants_right?).and_return(true)
      account_admin_user(:account => account)
      expect(account.can_see_admin_tools_tab?(@admin)).to be_truthy
    end
  end

  describe "#update_account_associations" do
    it "should update associations for all courses" do
      account = Account.default.sub_accounts.create!
      c1 = account.courses.create!
      c2 = account.courses.create!
      account.course_account_associations.scope.delete_all
      expect(account.associated_courses).to eq []
      account.update_account_associations
      account.reload
      expect(account.associated_courses.sort_by(&:id)).to eq [c1, c2]
    end
  end

  describe "default_time_zone" do
    context "root account" do
      before :once do
        @account = Account.create!
      end

      it "should use provided value when set" do
        @account.default_time_zone = 'America/New_York'
        expect(@account.default_time_zone).to eq ActiveSupport::TimeZone['Eastern Time (US & Canada)']
      end

      it "should have a sensible default if not set" do
        expect(@account.default_time_zone).to eq ActiveSupport::TimeZone[Account.time_zone_attribute_defaults[:default_time_zone]]
      end
    end

    context "sub account" do
      before :once do
        @root_account = Account.create!
        @account = @root_account.sub_accounts.create!
        @account.root_account = @root_account
      end

      it "should use provided value when set, regardless of root account setting" do
        @root_account.default_time_zone = 'America/Chicago'
        @account.default_time_zone = 'America/New_York'
        expect(@account.default_time_zone).to eq ActiveSupport::TimeZone['Eastern Time (US & Canada)']
      end

      it "should default to root account value if not set" do
        @root_account.default_time_zone = 'America/Chicago'
        expect(@account.default_time_zone).to eq ActiveSupport::TimeZone['Central Time (US & Canada)']
      end

      it "should have a sensible default if neither is set" do
        expect(@account.default_time_zone).to eq ActiveSupport::TimeZone[Account.time_zone_attribute_defaults[:default_time_zone]]
      end
    end
  end

  it 'should set allow_sis_import if root_account' do
    account = Account.create!
    expect(account.allow_sis_import).to eq true
    sub = account.sub_accounts.create!
    expect(sub.allow_sis_import).to eq false
  end

  describe "#ensure_defaults" do
    it "assigns an lti_guid postfixed by canvas-lms" do
      account = Account.new
      account.uuid = '12345'
      account.ensure_defaults
      expect(account.lti_guid).to eq '12345:canvas-lms'
    end

    it "does not change existing an lti_guid" do
      account = Account.new
      account.lti_guid = '12345'
      account.ensure_defaults
      expect(account.lti_guid).to eq '12345'
    end
  end

  it 'should format a referer url' do
    account = Account.new
    expect(account.format_referer(nil)).to be_nil
    expect(account.format_referer('')).to be_nil
    expect(account.format_referer('not a url')).to be_nil
    expect(account.format_referer('http://example.com/')).to eq 'http://example.com'
    expect(account.format_referer('http://example.com/index.html')).to eq 'http://example.com'
    expect(account.format_referer('http://example.com:80')).to eq 'http://example.com'
    expect(account.format_referer('https://example.com:443')).to eq 'https://example.com'
    expect(account.format_referer('http://example.com:3000')).to eq 'http://example.com:3000'
  end

  it 'should format trusted referers when set' do
    account = Account.new
    account.trusted_referers = 'https://example.com/,http://example.com:80,http://example.com:3000'
    expect(account.settings[:trusted_referers]).to eq 'https://example.com,http://example.com,http://example.com:3000'

    account.trusted_referers = nil
    expect(account.settings[:trusted_referers]).to be_nil

    account.trusted_referers = ''
    expect(account.settings[:trusted_referers]).to be_nil
  end

  describe 'trusted_referer?' do
    let!(:account) do
      account = Account.new
      account.settings[:trusted_referers] = 'https://example.com,http://example.com,http://example.com:3000'
      account
    end

    it 'should be true when a referer is trusted' do
      expect(account.trusted_referer?('http://example.com')).to be_truthy
      expect(account.trusted_referer?('http://example.com:3000')).to be_truthy
      expect(account.trusted_referer?('http://example.com:80')).to be_truthy
      expect(account.trusted_referer?('https://example.com:443')).to be_truthy
    end

    it 'should be false when a referer is not provided' do
      expect(account.trusted_referer?(nil)).to be_falsey
      expect(account.trusted_referer?('')).to be_falsey
    end

    it 'should be false when a referer is not trusted' do
      expect(account.trusted_referer?('https://example.com:5000')).to be_falsey
    end

    it 'should be false when the account has no trusted referer setting' do
      account.settings.delete(:trusted_referers)
      expect(account.trusted_referer?('https://example.com')).to be_falsey
    end

    it 'should be false when the account has nil trusted referer setting' do
      account.settings[:trusted_referers] = nil
      expect(account.trusted_referer?('https://example.com')).to be_falsey
    end

    it 'should be false when the account has empty trusted referer setting' do
      account.settings[:trusted_referers] = ''
      expect(account.trusted_referer?('https://example.com')).to be_falsey
    end
  end

  context "quota cache" do
    it "should only clear the quota cache if something changes" do
      account = account_model

      expect(Account).to receive(:invalidate_inherited_caches).once

      account.default_storage_quota = 10.megabytes
      account.save! # clear here

      account.reload
      account.save!

      account.default_storage_quota = 10.megabytes
      account.save!
    end

    it "should inherit from a parent account's default_storage_quota" do
      enable_cache do
        account = account_model

        account.default_storage_quota = 10.megabytes
        account.save!

        subaccount = account.sub_accounts.create!
        expect(subaccount.default_storage_quota).to eq 10.megabytes

        account.default_storage_quota = 20.megabytes
        account.save!

        # should clear caches
        account = Account.find(account.id)
        expect(account.default_storage_quota).to eq 20.megabytes

        subaccount = Account.find(subaccount.id)
        expect(subaccount.default_storage_quota).to eq 20.megabytes
      end
    end

    it "should inherit from a new parent account's default_storage_quota if parent account changes" do
      enable_cache do
        account = account_model

        account.default_storage_quota = 10.megabytes
        account.save!

        to_be_subaccount = Account.create!
        expect(to_be_subaccount.default_storage_quota).to eq Account.default_storage_quota

        # should clear caches
        to_be_subaccount.parent_account = account
        to_be_subaccount.save!
        expect(to_be_subaccount.default_storage_quota).to eq 10.megabytes
      end
    end
  end

  context "inheritable settings" do
    before :each do
      account_model
      @sub1 = @account.sub_accounts.create!
      @sub2 = @sub1.sub_accounts.create!
    end

    it "should use the default value if nothing is set anywhere" do
      expected = {:locked => false, :value => false}
      [@account, @sub1, @sub2].each do |a|
        expect(a.restrict_student_future_view).to eq expected
        expect(a.lock_all_announcements).to eq expected
      end
    end

    it "should be able to lock values for sub-accounts" do
      @sub1.settings[:restrict_student_future_view] = {:locked => true, :value => true}
      @sub1.settings[:lock_all_announcements] = {:locked => true, :value => true}
      @sub1.save!
      # should ignore the subaccount's wishes
      @sub2.settings[:restrict_student_future_view] = {:locked => true, :value => false}
      @sub2.settings[:lock_all_announcements] = {:locked => true, :value => false}
      @sub2.save!

      expect(@account.restrict_student_future_view).to eq({:locked => false, :value => false})
      expect(@account.lock_all_announcements).to eq({:locked => false, :value => false})

      expect(@sub1.restrict_student_future_view).to eq({:locked => true, :value => true})
      expect(@sub1.lock_all_announcements).to eq({:locked => true, :value => true})

      expect(@sub2.restrict_student_future_view).to eq({:locked => true, :value => true, :inherited => true})
      expect(@sub2.lock_all_announcements).to eq({:locked => true, :value => true, :inherited => true})
    end

    it "should grandfather old pre-hash values in" do
      @account.settings[:restrict_student_future_view] = true
      @account.settings[:lock_all_announcements] = true
      @account.save!
      @sub2.settings[:restrict_student_future_view] = false
      @sub2.settings[:lock_all_announcements] = false
      @sub2.save!

      expect(@account.restrict_student_future_view).to eq({:locked => false, :value => true})
      expect(@account.lock_all_announcements).to eq({:locked => false, :value => true})

      expect(@sub1.restrict_student_future_view).to eq({:locked => false, :value => true, :inherited => true})
      expect(@sub1.lock_all_announcements).to eq({:locked => false, :value => true, :inherited => true})

      expect(@sub2.restrict_student_future_view).to eq({:locked => false, :value => false})
      expect(@sub2.lock_all_announcements).to eq({:locked => false, :value => false})
    end

    it "should translate string values in mass-assignment" do
      settings = @account.settings
      settings[:restrict_student_future_view] = {"value" => "1", "locked" => "0"}
      settings[:lock_all_announcements] = {"value" => "1", "locked" => "0"}
      @account.settings = settings
      @account.save!

      expect(@account.restrict_student_future_view).to eq({:locked => false, :value => true})
      expect(@account.lock_all_announcements).to eq({:locked => false, :value => true})
    end

    context "caching" do
      specs_require_sharding
      it "should clear cached values correctly" do
        enable_cache do
          # preload the cached values
          [@account, @sub1, @sub2].each(&:restrict_student_future_view)
          [@account, @sub1, @sub2].each(&:lock_all_announcements)

          @sub1.settings = @sub1.settings.merge(:restrict_student_future_view => {:locked => true, :value => true}, :lock_all_announcements => {:locked => true, :value => true})
          @sub1.save!

          # hard reload
          @account = Account.find(@account.id)
          @sub1 = Account.find(@sub1.id)
          @sub2 = Account.find(@sub2.id)

          expect(@account.restrict_student_future_view).to eq({:locked => false, :value => false})
          expect(@account.lock_all_announcements).to eq({:locked => false, :value => false})

          expect(@sub1.restrict_student_future_view).to eq({:locked => true, :value => true})
          expect(@sub1.lock_all_announcements).to eq({:locked => true, :value => true})

          expect(@sub2.restrict_student_future_view).to eq({:locked => true, :value => true, :inherited => true})
          expect(@sub2.lock_all_announcements).to eq({:locked => true, :value => true, :inherited => true})
        end
      end
    end
  end

  context "require terms of use" do
    describe "#terms_required?" do
      it "returns true by default" do
        expect(account_model.terms_required?).to eq true
      end

      it "returns false by default for new accounts" do
        TermsOfService.skip_automatic_terms_creation = false
        expect(account_model.terms_required?).to eq false
      end

      it "returns false if Setting is false" do
        Setting.set(:terms_required, "false")
        expect(account_model.terms_required?).to eq false
      end

      it "returns false if account setting is false" do
        account = account_model(settings: {account_terms_required: false})
        expect(account.terms_required?).to eq false
      end

      it "consults root account setting" do
        parent_account = account_model(settings: {account_terms_required: false})
        child_account = Account.create!(parent_account: parent_account)
        expect(child_account.terms_required?).to eq false
      end
    end
  end

  context "account cache" do
    specs_require_sharding

    describe ".find_cached" do
      let(:nonsense_id){ 987654321 }

      it "works relative to a different shard" do
        @shard1.activate do
          a = Account.create!
          expect(Account.find_cached(a.id)).to eq a
        end
      end

      it "errors if infrastructure fails and we can't see the account" do
        expect{ Account.find_cached(nonsense_id) }.to raise_error(::Canvas::AccountCacheError)
      end

      it "includes the account id in the error message" do
        begin
          Account.find_cached(nonsense_id)
        rescue ::Canvas::AccountCacheError => e
          expect(e.message).to eq("Couldn't find Account with 'id'=#{nonsense_id}")
        end
      end
    end

    describe ".invalidate_cache" do
      it "works relative to a different shard" do
        enable_cache do
          @shard1.activate do
            a = Account.create!
            Account.find_cached(a.id) # set the cache
            expect(Account.invalidate_cache(a.id)).to eq true
          end
        end
      end
    end
  end

  describe "#users_name_like" do
    context 'sharding' do
      specs_require_sharding

      it "should work cross-shard" do
        allow(ActiveRecord::Base.connection).to receive(:use_qualified_names?).and_return(true)
        @shard1.activate do
          @account = Account.create!
          @user = user_factory(:name => "silly name")
          @user.account_users.create(:account => @account)
        end
        expect(@account.users_name_like("silly").first).to eq @user
      end
    end
  end

  describe "#migrate_to_canvadocs?" do
    before(:once) do
      @account = Account.create!
    end

    it "is true if hijack_crocodoc_sessions is true" do
      allow(Canvadocs).to receive(:hijack_crocodoc_sessions?).and_return(true)
      expect(@account).to be_migrate_to_canvadocs
    end

    it "is false if hijack_crocodoc_sessions is false" do
      allow(Canvadocs).to receive(:hijack_crocodoc_sessions?).and_return(false)
      expect(@account).not_to be_migrate_to_canvadocs
    end
  end

  it "should clear special account cache on updates to special accounts" do
    expect(Account.default.settings[:blah]).to be_nil

    non_cached = Account.find(Account.default.id)
    non_cached.settings[:blah] = true
    non_cached.save!

    expect(Account.default.settings[:blah]).to eq true
  end

  it_behaves_like 'a learning outcome context'

  describe "#default_dashboard_view" do
    before(:once) do
      @account = Account.create!
    end

    it "should be nil by default" do
      expect(@account.default_dashboard_view).to be_nil
    end

    it "should update if view is valid" do
      @account.default_dashboard_view = "activity"
      @account.save!

      expect(@account.default_dashboard_view).to eq "activity"
    end

    it "should not update if view is invalid" do
      @account.default_dashboard_view = "junk"
      expect { @account.save! }.not_to change { @account.default_dashboard_view }
    end

    it "should not contain planner if feature is disabled" do
      @account.default_dashboard_view = "planner"
      @account.save!
      expect(@account.default_dashboard_view).not_to eq "planner"
    end

    it "should contain planner if feature is enabled" do
      @account.enable_feature! :student_planner
      @account.default_dashboard_view = "planner"
      @account.save!
      expect(@account.default_dashboard_view).to eq "planner"
    end
  end

  it "should only send new account user notifications to active admins" do
    active_admin = account_admin_user(:active_all => true)
    deleted_admin = account_admin_user(:active_all => true)
    deleted_admin.account_users.destroy_all
    n = Notification.create(:name => "New Account User", :category => "TestImmediately")
    [active_admin, deleted_admin].each do |u|
      NotificationPolicy.create(:notification => n, :communication_channel => u.communication_channel, :frequency => "immediately")
    end
    user_factory(:active_all => true)
    au = Account.default.account_users.create!(:user => @user)
    expect(au.messages_sent[n.name].map(&:user)).to match_array [active_admin, @user]
  end
end
