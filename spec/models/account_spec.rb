# frozen_string_literal: true

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

describe Account do
  include_examples "outcome import context examples"

  describe "relationships" do
    it { is_expected.to have_many(:feature_flags) }
    it { is_expected.to have_one(:outcome_proficiency).dependent(:destroy) }
    it { is_expected.to have_many(:lti_resource_links).class_name("Lti::ResourceLink") }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:account_calendar_subscription_type).in_array(Account::CALENDAR_SUBSCRIPTION_TYPES) }
  end

  context "domain_method" do
    it "retrieves correct account domain" do
      root_account = Account.create!
      AccountDomain.create!(host: "canvas.instructure.com", account: root_account)
      expect(root_account.domain).to eq "canvas.instructure.com"
    end
  end

  context "environment_specific_domain" do
    let(:root_account) { Account.create! }

    before do
      allow(HostUrl).to receive(:context_host).and_call_original
      allow(HostUrl).to receive(:context_host).with(root_account, "beta").and_return("canvas.beta.instructure.com")
      AccountDomain.create!(host: "canvas.instructure.com", account: root_account)
    end

    it "retrieves correct beta domain" do
      allow(ApplicationController).to receive(:test_cluster_name).and_return("beta")
      expect(root_account.environment_specific_domain).to eq "canvas.beta.instructure.com"
    end

    it "retrieves correct prod domain" do
      allow(ApplicationController).to receive(:test_cluster_name).and_return(nil)
      expect(root_account.environment_specific_domain).to eq "canvas.instructure.com"
    end
  end

  context "resolved_outcome_proficiency_method" do
    before do
      @root_account = Account.create!
      @subaccount = @root_account.sub_accounts.create!
    end

    it "retrieves parent account's outcome proficiency" do
      proficiency = outcome_proficiency_model(@root_account)
      expect(@subaccount.resolved_outcome_proficiency).to eq proficiency
    end

    it "ignores soft deleted calculation methods" do
      proficiency = outcome_proficiency_model(@root_account)
      subproficiency = outcome_proficiency_model(@subaccount)
      subproficiency.update! workflow_state: :deleted
      expect(@subaccount.outcome_proficiency).to eq subproficiency
      expect(@subaccount.resolved_outcome_proficiency).to eq proficiency
    end

    context "cache" do
      it "uses the cache" do
        enable_cache do
          proficiency = outcome_proficiency_model(@root_account)

          # prime the cache
          @root_account.resolved_outcome_proficiency

          # update without callbacks
          OutcomeProficiency.where(id: proficiency.id).update_all workflow_state: "deleted"

          # verify cached version wins with new AR object
          cached = Account.find(@root_account.id).resolved_outcome_proficiency
          expect(cached.workflow_state).not_to eq "deleted"
        end
      end

      it "updates when account chain is changed" do
        enable_cache do
          other_subaccount = @root_account.sub_accounts.create!
          other_proficiency = outcome_proficiency_model(other_subaccount)

          expect(@subaccount.resolved_outcome_proficiency).to eq @root_account.resolved_outcome_proficiency
          @subaccount.update! parent_account: other_subaccount
          expect(@subaccount.resolved_outcome_proficiency).to eq other_proficiency
        end
      end

      it "updates when outcome_proficiency_id cache changed" do
        enable_cache do
          subsubaccount = @subaccount.sub_accounts.create!

          old_proficiency = outcome_proficiency_model(@root_account)
          expect(subsubaccount.reload.resolved_outcome_proficiency).to eq old_proficiency

          new_proficiency = outcome_proficiency_model(@subaccount)
          expect(subsubaccount.reload.resolved_outcome_proficiency).to eq new_proficiency

          new_proficiency.destroy!
          expect(subsubaccount.reload.resolved_outcome_proficiency).to eq old_proficiency
        end
      end

      it "does not conflict with other caches" do
        enable_cache do
          Timecop.freeze do
            outcome_proficiency_model(@root_account)
            outcome_calculation_method_model(@root_account)

            # cache proficiency
            @root_account.resolved_outcome_proficiency

            calc_method = @root_account.resolved_outcome_calculation_method
            expect(calc_method.class).to eq OutcomeCalculationMethod
          end
        end
      end
    end

    context "with the account_level_mastery_scales FF enabled" do
      before do
        @root_account.enable_feature!(:account_level_mastery_scales)
      end

      it "returns a OutcomeProficiency default at the root level if no proficiency exists" do
        expect(@root_account.outcome_proficiency).to be_nil
        expect(@subaccount.outcome_proficiency).to be_nil
        expect(@subaccount.resolved_outcome_proficiency).to eq OutcomeProficiency.find_or_create_default!(@root_account)
        expect(@root_account.resolved_outcome_proficiency).to eq OutcomeProficiency.find_or_create_default!(@root_account)
      end
    end

    context "with the account_level_mastery_scales FF disabled" do
      it "can be nil" do
        @root_account.disable_feature!(:account_level_mastery_scales)
        expect(@root_account.resolved_outcome_proficiency).to be_nil
        expect(@subaccount.resolved_outcome_proficiency).to be_nil
      end
    end
  end

  context "resolved_outcome_calculation_method" do
    before do
      @root_account = Account.create!
      @subaccount = @root_account.sub_accounts.create!
    end

    it "retrieves parent account's outcome calculation method" do
      method = OutcomeCalculationMethod.create! context: @root_account, calculation_method: :highest
      expect(@root_account.outcome_calculation_method).to eq method
      expect(@subaccount.outcome_calculation_method).to be_nil
      expect(@root_account.resolved_outcome_calculation_method).to eq method
      expect(@subaccount.resolved_outcome_calculation_method).to eq method
    end

    it "can override parent account's outcome calculation method" do
      method = OutcomeCalculationMethod.create! context: @root_account, calculation_method: :highest
      submethod = OutcomeCalculationMethod.create! context: @subaccount, calculation_method: :latest
      expect(@root_account.outcome_calculation_method).to eq method
      expect(@subaccount.outcome_calculation_method).to eq submethod
      expect(@root_account.resolved_outcome_calculation_method).to eq method
      expect(@subaccount.resolved_outcome_calculation_method).to eq submethod
    end

    it "ignores soft deleted calculation methods" do
      method = OutcomeCalculationMethod.create! context: @root_account, calculation_method: :highest
      submethod = OutcomeCalculationMethod.create! context: @subaccount, calculation_method: :latest, workflow_state: :deleted
      expect(@subaccount.outcome_calculation_method).to eq submethod
      expect(@subaccount.resolved_outcome_calculation_method).to eq method
    end

    context "cache" do
      it "uses the cache" do
        enable_cache do
          method = outcome_calculation_method_model(@root_account)

          # prime the cache
          @root_account.resolved_outcome_calculation_method

          # update without callbacks
          OutcomeCalculationMethod.where(id: method.id).update_all workflow_state: "deleted"

          # verify cached version wins with new AR object
          cached = Account.find(@root_account.id).resolved_outcome_calculation_method
          expect(cached.workflow_state).not_to eq "deleted"
        end
      end

      it "updates when account chain is changed" do
        enable_cache do
          other_subaccount = @root_account.sub_accounts.create!
          other_method = outcome_calculation_method_model(other_subaccount)

          expect(@subaccount.resolved_outcome_calculation_method).to eq @root_account.resolved_outcome_calculation_method
          @subaccount.update! parent_account: other_subaccount
          expect(@subaccount.resolved_outcome_calculation_method).to eq other_method
        end
      end

      it "updates when outcome_calculation_method_id cache changed" do
        enable_cache do
          subsubaccount = @subaccount.sub_accounts.create!

          old_method = outcome_calculation_method_model(@root_account)
          expect(subsubaccount.reload.resolved_outcome_calculation_method).to eq old_method

          new_method = outcome_calculation_method_model(@subaccount)
          expect(subsubaccount.reload.resolved_outcome_calculation_method).to eq new_method

          new_method.destroy!
          expect(subsubaccount.reload.resolved_outcome_calculation_method).to eq old_method
        end
      end
    end

    context "with the account_level_mastery_scales FF enabled" do
      before do
        @root_account.enable_feature!(:account_level_mastery_scales)
      end

      it "returns a OutcomeCalculationMethod default if no method exists" do
        expect(@root_account.outcome_calculation_method).to be_nil
        expect(@subaccount.outcome_calculation_method).to be_nil
        expect(@root_account.resolved_outcome_calculation_method).to eq OutcomeCalculationMethod.find_or_create_default!(@root_account)
        expect(@subaccount.resolved_outcome_calculation_method).to eq OutcomeCalculationMethod.find_or_create_default!(@root_account)
      end
    end

    context "with the account_level_mastery_scales FF disabled" do
      it "can be nil" do
        @root_account.disable_feature!(:account_level_mastery_scales)
        expect(@root_account.resolved_outcome_calculation_method).to be_nil
        expect(@subaccount.resolved_outcome_calculation_method).to be_nil
      end
    end
  end

  it "provides a list of courses" do
    expect { Account.new.courses }.not_to raise_error
  end

  context "equella_settings" do
    it "responds to :equella_settings" do
      expect(Account.new).to respond_to(:equella_settings)
      expect(Account.new.equella_settings).to be_nil
    end

    it "returns the equella_settings data if defined" do
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
  #
  context "pronouns" do
    it "uses an empty array if the setting is not on" do
      account = Account.create!
      expect(account.pronouns).to be_empty

      # still returns empty array even if you explicitly set some
      account.pronouns = ["Dude/Guy", "Dudette/Gal"]
      expect(account.pronouns).to be_empty
    end

    it "uses defaults if setting is enabled and nothing is explicitly set" do
      account = Account.create!
      account.settings[:can_add_pronouns] = true
      expect(account.pronouns).to eq ["She/Her", "He/Him", "They/Them"]
    end

    it "uses custom set things if explicitly provided (and strips whitespace)" do
      account = Account.create!
      account.settings[:can_add_pronouns] = true
      account.pronouns = [" Dude/Guy   ", "She/Her  "]

      # it "untranslates" "she/her" when it serializes it to the db
      expect(account.settings[:pronouns]).to eq ["Dude/Guy", "she_her"]
      # it "translates" "she/her" when it reads it
      expect(account.pronouns).to eq ["Dude/Guy", "She/Her"]
    end
  end

  context "services" do
    before do
      @a = Account.new
    end

    it "is able to specify a list of enabled services" do
      @a.allowed_services = "fakeService"
      # expect(@a.service_enabled?(:twitter)).to be_truthy
      expect(@a.service_enabled?(:diigo)).to be_falsey
      expect(@a.service_enabled?(:avatars)).to be_falsey
    end

    it "does not enable services off by default" do
      expect(@a.service_enabled?(:avatars)).to be_falsey
    end

    it "adds and remove services from the defaults" do
      @a.allowed_services = "+avatars,-myplugin"
      expect(@a.service_enabled?(:avatars)).to be_truthy
      expect(@a.service_enabled?(:myplugin)).to be_falsey
    end

    it "allows settings services" do
      expect { @a.enable_service(:completly_bogs) }.to raise_error("Invalid Service")

      @a.disable_service(:avatars)
      expect(@a.service_enabled?(:avatars)).to be_falsey

      @a.enable_service(:avatars)
      expect(@a.service_enabled?(:avatars)).to be_truthy
    end

    it "uses + and - by default when setting service availability" do
      @a.disable_service(:avatars)
      expect(@a.service_enabled?(:avatars)).to be_falsey
      expect(@a.allowed_services).not_to match("avatars")

      @a.enable_service(:avatars)
      expect(@a.service_enabled?(:avatars)).to be_truthy
      expect(@a.allowed_services).to match("\\+avatars")
    end

    it "is able to set service availibity for previously hard-coded values" do
      @a.allowed_services = "avatars"

      @a.enable_service(:avatars)
      expect(@a.service_enabled?(:avatars)).to be_truthy
      expect(@a.allowed_services).to match(/avatars/)
      expect(@a.allowed_services).not_to match(/[+-]/)

      @a.disable_service(:avatars)
      expect(@a.allowed_services).to be_nil
    end

    it "does not wipe out services that are substrings of each other" do
      AccountServices.register_service(
        :google_docs_prev,
        {
          name: "My google docs prev", description: "", expose_to_ui: :service, default: true
        }
      )

      @a.disable_service("google_docs_previews")
      @a.disable_service("google_docs_prev")
      expect(@a.allowed_services).to eq "-google_docs_previews,-google_docs_prev"
    end

    describe "services_exposed_to_ui_hash" do
      it "returns all ui services by default" do
        expected_services = AccountServices.allowable_services.reject { |_, k| !k[:expose_to_ui] || (k[:expose_to_ui_proc] && !k[:expose_to_ui_proc].call(nil)) }.keys
        expect(Account.services_exposed_to_ui_hash.keys).to eq expected_services
      end

      it "returns services of a type if specified" do
        expected_services = AccountServices.allowable_services.reject { |_, k| k[:expose_to_ui] != :setting || (k[:expose_to_ui_proc] && !k[:expose_to_ui_proc].call(nil)) }.keys
        expect(Account.services_exposed_to_ui_hash(:setting).keys).to eq expected_services
      end

      it "filters based on user and account if a proc is specified" do
        user1 = User.create!
        user2 = User.create!
        AccountServices.register_service(:myservice, {
                                           name: "My Test Service",
                                           description: "Nope",
                                           expose_to_ui: :setting,
                                           default: false,
                                           expose_to_ui_proc: proc { |user, account| user == user2 && account == Account.default },
                                         })
        expect(Account.services_exposed_to_ui_hash(:setting).keys).not_to include(:myservice)
        expect(Account.services_exposed_to_ui_hash(:setting, user1, Account.default).keys).not_to include(:myservice)
        expect(Account.services_exposed_to_ui_hash(:setting, user2, Account.default).keys).to include(:myservice)
      end
    end

    describe "plugin services" do
      before do
        AccountServices.register_service(:myplugin, { name: "My Plugin", description: "", expose_to_ui: :setting, default: false })
      end

      it "returns the service" do
        expect(AccountServices.allowable_services.keys).to include(:myplugin)
      end

      it "allows setting the service" do
        expect(@a.service_enabled?(:myplugin)).to be_falsey

        @a.enable_service(:myplugin)
        expect(@a.service_enabled?(:myplugin)).to be_truthy
        expect(@a.allowed_services).to match(/\+myplugin/)

        @a.disable_service(:myplugin)
        expect(@a.service_enabled?(:myplugin)).to be_falsey
        expect(@a.allowed_services).to be_blank
      end

      describe "services_exposed_to_ui_hash" do
        it "returns services defined in a plugin" do
          expect(Account.services_exposed_to_ui_hash.keys).to include(:myplugin)
          expect(Account.services_exposed_to_ui_hash(:setting).keys).to include(:myplugin)
        end
      end
    end
  end

  context "settings=" do
    it "filters non-hash hash settings" do
      a = Account.new
      a.settings = { "sis_default_grade_export" => "string" }.with_indifferent_access
      expect(a.settings[:error_reporting]).to be_nil

      a.settings = { "sis_default_grade_export" => {
        "value" => true
      } }.with_indifferent_access
      expect(a.settings[:sis_default_grade_export]).to be_is_a(Hash)
      expect(a.settings[:sis_default_grade_export][:value]).to be true
    end
  end

  context "allow_global_includes?" do
    let(:root) { Account.default }

    it "false unless they've checked the box to allow it" do
      expect(root.allow_global_includes?).to be_falsey
    end

    it "true if they've checked the box to allow it" do
      root.settings = { "global_includes" => true }
      expect(root.allow_global_includes?).to be_truthy
    end

    describe "subaccount" do
      let(:sub_account) { root.sub_accounts.create! }

      it "false if root account hasn't checked global_includes AND subaccount branding" do
        expect(sub_account.allow_global_includes?).to be_falsey

        sub_account.root_account.settings = { "global_includes" => true, "sub_account_includes" => false }
        expect(sub_account.allow_global_includes?).to be_falsey

        sub_account.root_account.settings = { "global_includes" => false, "sub_account_includes" => true }
        expect(sub_account.allow_global_includes?).to be_falsey
      end

      it "true if root account HAS checked global_includes and turned on subaccount branding" do
        sub_account.root_account.settings = { "global_includes" => true, "sub_account_includes" => true }
        expect(sub_account.allow_global_includes?).to be_truthy
      end
    end
  end

  context "turnitin secret" do
    it "decrypts the turnitin secret to the original value" do
      a = Account.new
      a.turnitin_shared_secret = "asdf"
      expect(a.turnitin_shared_secret).to eql("asdf")
      a.turnitin_shared_secret = "2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3"
      expect(a.turnitin_shared_secret).to eql("2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3")
    end
  end

  context "closest_turnitin_originality" do
    before do
      @root_account = Account.create!(turnitin_pledge: "root")
      @root_account.turnitin_originality = "after_grading"
      @root_account.save!
    end

    it "finds closest_turnitin_originality from root account" do
      expect(@root_account.closest_turnitin_originality).to eq("after_grading")
    end

    it "finds closest_turnitin_originality from sub account" do
      sub_account = Account.create(name: "sub", parent_account: @root_account)
      sub_account.turnitin_originality = "never"
      expect(sub_account.closest_turnitin_originality).to eq("never")
    end

    it "finds closest_turnitin_originality from sub account when set on root account" do
      sub_account = Account.create(name: "sub", parent_account: @root_account)
      expect(sub_account.closest_turnitin_originality).to eq("after_grading")
    end
  end

  context "closest_turnitin_pledge" do
    it "works for custom sub, custom root" do
      root_account = Account.create!(turnitin_pledge: "root")
      sub_account = Account.create!(parent_account: root_account, turnitin_pledge: "sub")
      expect(root_account.closest_turnitin_pledge).to eq "root"
      expect(sub_account.closest_turnitin_pledge).to eq "sub"
    end

    it "works for nil sub, custom root" do
      root_account = Account.create!(turnitin_pledge: "root")
      sub_account = Account.create!(parent_account: root_account)
      expect(root_account.closest_turnitin_pledge).to eq "root"
      expect(sub_account.closest_turnitin_pledge).to eq "root"
    end

    it "works for nil sub, nil root" do
      root_account = Account.create!
      sub_account = Account.create!(parent_account: root_account)
      expect(root_account.closest_turnitin_pledge).not_to be_empty
      expect(sub_account.closest_turnitin_pledge).not_to be_empty
    end

    it "uses the default message if pledge is nil or empty" do
      account = Account.create!(turnitin_pledge: "")
      expect(account.closest_turnitin_pledge).to eq "This assignment submission is my own, original work"
    end
  end

  it "makes a default enrollment term if necessary" do
    a = Account.create!(name: "nada")
    expect(a.enrollment_terms.size).to eq 1
    expect(a.enrollment_terms.first.name).to eq EnrollmentTerm::DEFAULT_TERM_NAME

    # don't create a new default term for sub-accounts
    a2 = a.all_accounts.create!(name: "sub")
    expect(a2.enrollment_terms.size).to eq 0
  end

  def account_with_admin_and_restricted_user(account, restricted_role)
    admin = User.create
    user = User.create
    account.account_users.create!(user: admin, role: admin_role)
    account.account_users.create!(user:, role: restricted_role)
    [admin, user]
  end

  it "sets up access policy correctly" do
    # double out any "if" permission conditions
    RoleOverride.permissions.each_value do |v|
      next unless v[:if]

      allow_any_instance_of(Account).to receive(v[:if]).and_return(true)
    end
    site_admin = Account.site_admin

    # Set up a hierarchy of 4 accounts - a root account, a sub account,
    # a sub sub account, and SiteAdmin account.  Create a 'Restricted Admin'
    # role available for each one, and create an admin user and a user in that restricted role
    @sa_role = custom_account_role("Restricted SA Admin", account: site_admin)

    site_admin.settings[:mfa_settings] = "required"
    site_admin.save!
    root_account = Account.create
    @root_role = custom_account_role("Restricted Root Admin", account: root_account)

    sub_account = Account.create(parent_account: root_account)
    sub_sub_account = Account.create(parent_account: sub_account)

    hash = {}
    hash[:site_admin] = { account: Account.site_admin }
    hash[:root] = { account: root_account }
    hash[:sub] = { account: sub_account }
    hash[:sub_sub] = { account: sub_sub_account }

    hash.each do |k, v|
      v[:account].update_attribute(:settings, { no_enrollments_can_create_courses: false })
      admin, user = account_with_admin_and_restricted_user(v[:account], ((k == :site_admin) ? @sa_role : @root_role))
      hash[k][:admin] = admin
      hash[k][:user] = user
    end

    limited_access = %i[read read_as_admin manage update delete read_outcomes read_terms read_files launch_external_tool]
    conditional_access = RoleOverride.permissions.select { |_, v| v[:account_allows] }.map(&:first)
    conditional_access += [:view_bounced_emails, :view_account_calendar_details] # since this depends on :view_notifications
    disabled_by_default = RoleOverride.permissions.select { |_, v| v[:true_for].empty? }.map(&:first)
    full_access = RoleOverride.permissions.keys +
                  limited_access - disabled_by_default - conditional_access +
                  [:create_courses]
    full_access << :create_tool_manually unless root_account.feature_enabled?(:granular_permissions_manage_lti)

    full_root_access = full_access - RoleOverride.permissions.select { |_k, v| v[:account_only] == :site_admin }.map(&:first)
    full_sub_access = full_root_access - RoleOverride.permissions.select { |_k, v| v[:account_only] == :root }.map(&:first)
    # site admin has access to everything everywhere
    hash.each do |k, v|
      account = v[:account]

      common_siteadmin_privileges = []
      common_siteadmin_privileges += [:read_global_outcomes] if k == :site_admin

      admin_privileges = full_access + common_siteadmin_privileges

      user_privileges = limited_access + common_siteadmin_privileges
      expect(account.check_policy(hash[:site_admin][:admin]) - conditional_access).to match_array admin_privileges
      expect(account.check_policy(hash[:site_admin][:user]) - conditional_access).to match_array user_privileges
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
      expect(account.check_policy(hash[:sub][:admin])).to match_array((k == :site_admin) ? [:read_global_outcomes] : %i[read_outcomes read_terms launch_external_tool])
      expect(account.check_policy(hash[:sub][:user])).to match_array((k == :site_admin) ? [:read_global_outcomes] : %i[read_outcomes read_terms launch_external_tool])
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
      account.role_overrides.create!(permission: "read_reports", role: ((k == :site_admin) ? @sa_role : @root_role), enabled: true)
      account.role_overrides.create!(permission: "reset_any_mfa", role: @sa_role, enabled: true)
      # clear caches
      account.tap do |a|
        a.settings[:mfa_settings] = :optional
        a.save!
      end
      v[:account] = Account.find(account.id)
    end
    AdheresToPolicy::Cache.clear
    hash.each do |k, v|
      account = v[:account]
      admin_privileges = full_access.clone
      admin_privileges += [:read_global_outcomes] if k == :site_admin
      user_array = some_access + [:reset_any_mfa] +
                   ((k == :site_admin) ? [:read_global_outcomes] : [])
      expect(account.check_policy(hash[:site_admin][:admin]) - conditional_access).to match_array admin_privileges
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
      expect(account.check_policy(hash[:sub][:admin])).to match_array((k == :site_admin) ? [:read_global_outcomes] : %i[read_outcomes read_terms launch_external_tool])
      expect(account.check_policy(hash[:sub][:user])).to match_array((k == :site_admin) ? [:read_global_outcomes] : %i[read_outcomes read_terms launch_external_tool])
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

    it "does not query when the target account is site admin" do
      teacher_in_course
      site_admin = Account.site_admin

      expect(Course).not_to receive(:connection)
      expect(site_admin.grants_right?(@user, :read)).to be false
    end

    it "queries for enrollments correctly when another shard is active" do
      teacher_in_course
      @enrollment.accept!

      @shard1.activate do
        expect(@course.grants_right?(@user, :read_sis)).to be true
      end
    end

    it "returns sub account ids recursively when another shard is active" do
      a = Account.default
      subs = []
      sub = Account.create!(name: "sub", parent_account: a)
      subs << grand_sub = Account.create!(name: "grand_sub", parent_account: sub)
      subs << great_grand_sub = Account.create!(name: "great_grand_sub", parent_account: grand_sub)
      subs << Account.create!(name: "great_great_grand_sub", parent_account: great_grand_sub)
      @shard1.activate do
        expect(Account.select(:id).sub_accounts_recursive(sub.id, :pluck).sort).to eq(subs.map(&:id).sort)
        expect(Account.sub_accounts_recursive(sub.id).sort_by(&:id)).to eq(subs.sort_by(&:id))
      end
    end

    it "properly returns site admin permissions regardless of active shard" do
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

  # TODO: deprecated; need to look into removing this setting
  it "allows no_enrollments_can_create_courses correctly" do
    a = Account.default
    a.disable_feature!(:granular_permissions_manage_courses)
    a.settings = { no_enrollments_can_create_courses: true }
    a.save!

    user_factory
    expect(a.manually_created_courses_account.grants_right?(@user, :create_courses)).to be_truthy
  end

  it "does not allow create_courses even to admins on site admin and children" do
    a = Account.site_admin
    a.settings = { no_enrollments_can_create_courses: true }
    a.save!
    manual = a.manually_created_courses_account
    user_factory

    expect(a.grants_right?(@user, :create_courses)).to be false
    expect(manual.grants_right?(@user, :create_courses)).to be false
  end

  it "does not allow create courses for student view students" do
    a = Account.default
    a.settings = { no_enrollments_can_create_courses: true }
    a.save!

    manual = a.manually_created_courses_account
    course = manual.courses.create!
    user = course.student_view_student

    expect(a.grants_right?(user, :create_courses)).to be false
    expect(manual.grants_right?(user, :create_courses)).to be false
  end

  it "does not allow create courses for student view students (granular permissions)" do
    a = Account.default
    a.settings = { no_enrollments_can_create_courses: true }
    a.save!
    a.enable_feature!(:granular_permissions_manage_courses)

    manual = a.manually_created_courses_account
    course = manual.courses.create!
    user = course.student_view_student

    expect(a.grants_right?(user, :create_courses)).to be false
    expect(manual.grants_right?(user, :create_courses)).to be false
  end

  it "returns sub-accounts as options correctly" do
    a = Account.default
    sub = Account.create!(name: "sub", parent_account: a)
    sub2 = Account.create!(name: "sub2", parent_account: a)
    sub2_1 = Account.create!(name: "sub2-1", parent_account: sub2)
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

  it "correctly returns sub-account_ids recursively" do
    a = Account.default
    subs = []
    sub = Account.create!(name: "sub", parent_account: a)
    subs << grand_sub = Account.create!(name: "grand_sub", parent_account: sub)
    subs << great_grand_sub = Account.create!(name: "great_grand_sub", parent_account: grand_sub)
    subs << Account.create!(name: "great_great_grand_sub", parent_account: great_grand_sub)
    expect(Account.select(:id).sub_accounts_recursive(sub.id, :pluck).sort).to eq(subs.map(&:id).sort)
    expect(Account.limit(10).sub_accounts_recursive(sub.id).sort).to eq(subs.sort_by(&:id))
  end

  it "returns the correct user count" do
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
    course_with_teacher(account: a2)
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
    category1 = account.group_categories.create(name: "category 1")
    category2 = account.group_categories.create(name: "category 2")
    expect(account.group_categories.count).to eq 2
    category1.destroy
    account.reload
    expect(account.group_categories.count).to eq 1
    expect(account.group_categories.to_a).to eq [category2]
  end

  it "group_categories.active should not include deleted categories" do
    account = Account.default
    expect(account.group_categories.active.count).to eq 0
    category1 = account.group_categories.create(name: "category 1")
    category2 = account.group_categories.create(name: "category 2")
    expect(account.group_categories.active.count).to eq 2
    category1.destroy
    account.reload
    expect(account.group_categories.active.count).to eq 1
    expect(account.all_group_categories.count).to eq 2
    expect(account.group_categories.active.to_a).to eq [category2]
  end

  it "returns correct values for login_handle_name_with_inference" do
    account = Account.default
    expect(account.login_handle_name_with_inference).to eq "Email"

    config = account.authentication_providers.create!(auth_type: "cas")
    account.authentication_providers.first.move_to_bottom
    expect(account.login_handle_name_with_inference).to eq "Login"

    config.destroy
    config = account.authentication_providers.create!(auth_type: "saml")
    account.authentication_providers.active.first.move_to_bottom
    expect(account.reload.login_handle_name_with_inference).to eq "Login"

    config.destroy
    account.authentication_providers.create!(auth_type: "ldap")
    account.authentication_providers.active.first.move_to_bottom
    expect(account.reload.login_handle_name_with_inference).to eq "Email"
    account.login_handle_name = "LDAP Login"
    account.save!
    expect(account.reload.login_handle_name_with_inference).to eq "LDAP Login"
  end

  context "users_not_in_groups" do
    before :once do
      @account = Account.default
      @user1 = account_admin_user(account: @account)
      @user2 = account_admin_user(account: @account)
      @user3 = account_admin_user(account: @account)
    end

    it "does not include deleted users" do
      @user1.destroy
      expect(@account.users_not_in_groups([]).size).to eq 2
    end

    it "does not include users in one of the groups" do
      group = @account.groups.create
      group.add_user(@user1)
      users = @account.users_not_in_groups([group])
      expect(users.size).to eq 2
      expect(users).not_to include(@user1)
    end

    it "includes users otherwise" do
      group = @account.groups.create
      group.add_user(@user1)
      users = @account.users_not_in_groups([group])
      expect(users).to include(@user2)
      expect(users).to include(@user3)
    end

    it "allows ordering by user's sortable name" do
      @user1.sortable_name = "jonny"
      @user1.save
      @user2.sortable_name = "bob"
      @user2.save
      @user3.sortable_name = "richard"
      @user3.save
      users = @account.users_not_in_groups([], order: User.sortable_name_order_by_clause("users"))
      expect(users.map(&:id)).to eq [@user2.id, @user1.id, @user3.id]
    end
  end

  context "tabs_available" do
    before :once do
      @account = Account.default.sub_accounts.create!(name: "sub-account")
    end

    it "includes 'Developer Keys' for the authorized users of the site_admin account" do
      account_admin_user(account: Account.site_admin)
      tabs = Account.site_admin.tabs_available(@admin)
      expect(tabs.pluck(:id)).to include(Account::TAB_DEVELOPER_KEYS)

      tabs = Account.site_admin.tabs_available(nil)
      expect(tabs.pluck(:id)).not_to include(Account::TAB_DEVELOPER_KEYS)
    end

    it "includes 'Developer Keys' for the admin users of an account" do
      account = Account.create!
      account_admin_user(account:)
      tabs = account.tabs_available(@admin)
      expect(tabs.pluck(:id)).to include(Account::TAB_DEVELOPER_KEYS)

      tabs = account.tabs_available(nil)
      expect(tabs.pluck(:id)).not_to include(Account::TAB_DEVELOPER_KEYS)
    end

    it "does not include 'Developer Keys' for non-site_admin accounts" do
      tabs = @account.tabs_available(nil)
      expect(tabs.pluck(:id)).not_to include(Account::TAB_DEVELOPER_KEYS)

      tabs = @account.root_account.tabs_available(nil)
      expect(tabs.pluck(:id)).not_to include(Account::TAB_DEVELOPER_KEYS)
    end

    it "does not include external tools if not configured for account navigation" do
      tool = @account.context_external_tools.new(name: "bob", consumer_key: "bob", shared_secret: "bob", domain: "example.com")
      tool.user_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(tool.has_placement?(:account_navigation)).to be false
      tabs = @account.tabs_available(nil)
      expect(tabs.pluck(:id)).not_to include(tool.asset_string)
    end

    it "includes active external tools if configured on the account" do
      tools = Array.new(2) do
        t = @account.context_external_tools.new(
          name: "bob",
          consumer_key: "bob",
          shared_secret: "bob",
          domain: "example.com"
        )
        t.account_navigation = {
          text: "Example URL",
          url: "http://www.example.com",
        }
        t.tap(&:save!)
      end
      tool1, tool2 = tools
      tool2.destroy

      tools.each { |t| expect(t.has_placement?(:account_navigation)).to be true }

      tabs = @account.tabs_available
      tab_ids = tabs.pluck(:id)
      expect(tab_ids).to include(tool1.asset_string)
      expect(tab_ids).not_to include(tool2.asset_string)
      tab = tabs.detect { |t| t[:id] == tool1.asset_string }
      expect(tab[:label]).to eq tool1.settings[:account_navigation][:text]
      expect(tab[:href]).to eq :account_external_tool_path
      expect(tab[:args]).to eq [@account.id, tool1.id]
    end

    it "includes external tools if configured on the root account" do
      tool = @account.context_external_tools.new(name: "bob", consumer_key: "bob", shared_secret: "bob", domain: "example.com")
      tool.account_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(tool.has_placement?(:account_navigation)).to be true
      tabs = @account.tabs_available(nil)
      expect(tabs.pluck(:id)).to include(tool.asset_string)
      tab = tabs.detect { |t| t[:id] == tool.asset_string }
      expect(tab[:label]).to eq tool.settings[:account_navigation][:text]
      expect(tab[:href]).to eq :account_external_tool_path
      expect(tab[:args]).to eq [@account.id, tool.id]
    end

    it "does not include external tools for subaccounts if 'root_account_only' is used" do
      expect(@account.root_account?).to be false
      course_with_teacher(account: @account.root_account)
      tool = @account.root_account.context_external_tools.new(name: "bob", consumer_key: "bob", shared_secret: "bob", domain: "example.com")
      tool.account_navigation = { url: "http://www.example.com", text: "Example URL", root_account_only: true }
      tool.save!
      expect(@account.root_account.tabs_available(@teacher).pluck(:id)).to include(tool.asset_string)
      expect(@account.tabs_available(@teacher).pluck(:id)).to_not include(tool.asset_string)
    end

    it "does not include external tools for non-admins if visibility is set" do
      course_with_teacher(account: @account)
      tool = @account.context_external_tools.new(name: "bob", consumer_key: "bob", shared_secret: "bob", domain: "example.com")
      tool.account_navigation = { url: "http://www.example.com", text: "Example URL", visibility: "admins" }
      tool.save!
      expect(tool.has_placement?(:account_navigation)).to be true
      tabs = @account.tabs_available(@teacher)
      expect(tabs.pluck(:id)).to_not include(tool.asset_string)

      admin = account_admin_user(account: @account)
      tabs = @account.tabs_available(admin)
      expect(tabs.pluck(:id)).to include(tool.asset_string)
    end

    it "uses localized labels" do
      tool = @account.context_external_tools.new(name: "bob",
                                                 consumer_key: "test",
                                                 shared_secret: "secret",
                                                 url: "http://example.com")

      account_navigation = {
        text: "this should not be the title",
        url: "http://www.example.com",
        labels: {
          "en" => "English Label",
          "sp" => "Spanish Label"
        }
      }

      tool.settings[:account_navigation] = account_navigation
      tool.save!

      tabs = @account.external_tool_tabs({}, User.new)

      expect(tabs.first[:label]).to eq "English Label"
    end

    it "includes message handlers" do
      mock_tab = {
        id: "1234",
        label: "my_label",
        css_class: "1234",
        href: :launch_path_helper,
        visibility: nil,
        external: true,
        hidden: false,
        args: [1, 2]
      }
      allow(Lti::MessageHandler).to receive(:lti_apps_tabs).and_return([mock_tab])
      expect(@account.tabs_available(nil)).to include(mock_tab)
    end

    it "uses :manage_assignments to determine question bank tab visibility" do
      account_admin_user_with_role_changes(account: @account, role_changes: { manage_assignments: true, manage_grades: false })
      tabs = @account.tabs_available(@admin)
      expect(tabs.pluck(:id)).to include(Account::TAB_QUESTION_BANKS)
    end

    describe "account calendars tab" do
      it "is shown if the user has manage_account_calendar_visibility permission" do
        account_admin_user_with_role_changes(account: @account)
        expect(@account.tabs_available(@admin).pluck(:id)).to include(Account::TAB_ACCOUNT_CALENDARS)
      end

      it "is not shown if the user lacks manage_account_calendar_visibility permission" do
        account_admin_user_with_role_changes(account: @account, role_changes: { manage_account_calendar_visibility: false })
        expect(@account.tabs_available(@admin).pluck(:id)).not_to include(Account::TAB_ACCOUNT_CALENDARS)
      end
    end

    describe "'ePortfolio Moderation' tab" do
      let(:tab_ids) { @account.tabs_available(@admin).pluck(:id) }

      it "is shown if the user has the moderate_user_content permission" do
        account_admin_user_with_role_changes(account: @account, role_changes: { moderate_user_content: true })
        expect(tab_ids).to include(Account::TAB_EPORTFOLIO_MODERATION)
      end

      it "is not shown if the user lacks the moderate_user_content permission" do
        account_admin_user_with_role_changes(account: @account, role_changes: { moderate_user_content: false })
        expect(tab_ids).not_to include(Account::TAB_EPORTFOLIO_MODERATION)
      end
    end

    describe "rubrics permissions" do
      let(:tab_ids) { @account.tabs_available(@admin).pluck(:id) }

      it "returns the rubrics tab for admins by default" do
        account_admin_user(account: @account)
        expect(tab_ids).to include(Account::TAB_RUBRICS)
      end

      it "the rubrics tab is not shown if the user lacks permission (manage_rubrics)" do
        account_admin_user_with_role_changes(account: @account, role_changes: { manage_rubrics: false })
        expect(tab_ids).not_to include(Account::TAB_RUBRICS)
      end
    end
  end

  describe "fast_all_users" do
    it "preserves sortable_name" do
      user_with_pseudonym(active_all: 1)
      @user.update(name: "John St. Clair", sortable_name: "St. Clair, John")
      @johnstclair = @user
      user_with_pseudonym(active_all: 1, username: "jt@instructure.com", name: "JT Olds")
      @jtolds = @user
      expect(Account.default.fast_all_users).to eq [@jtolds, @johnstclair]
    end
  end

  it "does not allow setting an sis id for a root account" do
    @account = Account.create!
    @account.sis_source_id = "abc"
    expect(@account.save).to be_falsey
  end

  describe "user_list_search_mode_for" do
    let_once(:account) { Account.default }
    it "is preferred for anyone if open registration is turned on" do
      account.settings = { open_registration: true }
      expect(account.user_list_search_mode_for(nil)).to eq :preferred
      expect(account.user_list_search_mode_for(user_factory)).to eq :preferred
    end

    it "is preferred for account admins" do
      expect(account.user_list_search_mode_for(nil)).to eq :closed
      expect(account.user_list_search_mode_for(user_factory)).to eq :closed
      user_factory
      account.account_users.create!(user: @user)
      expect(account.user_list_search_mode_for(@user)).to eq :preferred
    end
  end

  context "permissions" do
    before(:once) { Account.default }

    it "grants :read_global_outcomes to any user iff site_admin" do
      @site_admin = Account.site_admin
      expect(@site_admin.grants_right?(User.new, :read_global_outcomes)).to be_truthy

      @subaccount = @site_admin.sub_accounts.create!
      expect(@subaccount.grants_right?(User.new, :read_global_outcomes)).to be_falsey
    end

    shared_examples_for "a permission granted to account admins and enrollees" do |perm|
      it "does not grant #{perm} to user's outside the account" do
        expect(Account.default.grants_right?(User.new, perm)).to be_falsey
      end

      it "grants #{perm} to account admins" do
        account_admin_user(account: Account.default)
        expect(Account.default.grants_right?(@admin, perm)).to be_truthy
      end

      it "grants #{perm} to subaccount admins" do
        account_admin_user(account: Account.default.sub_accounts.create!)
        expect(Account.default.grants_right?(@admin, perm)).to be_truthy
      end

      it "grants #{perm} to enrollees in account courses" do
        course_factory(account: Account.default)
        teacher_in_course
        student_in_course
        expect(Account.default.grants_right?(@teacher, perm)).to be_truthy
        expect(Account.default.grants_right?(@student, perm)).to be_truthy
      end

      it "grants #{perm} to enrollees in subaccount courses" do
        course_factory(account: Account.default.sub_accounts.create!)
        teacher_in_course
        student_in_course
        expect(Account.default.grants_right?(@teacher, perm)).to be_truthy
        expect(Account.default.grants_right?(@student, perm)).to be_truthy
      end

      it "grants launch_external_tool to site admin users" do
        sa_user = account_admin_user account: Account.site_admin
        expect(Account.default.grants_right?(sa_user, perm)).to be_truthy
      end
    end

    describe "read_outcomes permission" do
      it_behaves_like "a permission granted to account admins and enrollees", :read_outcomes
    end

    describe "launch_external_tool permission" do
      it_behaves_like "a permission granted to account admins and enrollees", :launch_external_tool
    end

    context "view_account_calendar_details permission" do
      before :once do
        @account = Account.default
      end

      it "is true for an account admin on a visible calendar" do
        @account.account_calendar_visible = true
        @account.save!
        account_admin_user(active_all: true, account: @account)
        expect(@account.grants_right?(@admin, :view_account_calendar_details)).to be_truthy
      end

      it "is true for an account admin with :manage_account_calendar_visibility on a hidden calendar" do
        account_admin_user(active_all: true, account: @account)
        expect(@account.grants_right?(@admin, :view_account_calendar_details)).to be_truthy
      end

      it "is true for an account admin without :manage_account_calendar_visibility on a visible calendar" do
        @account.account_calendar_visible = true
        @account.save!
        account_admin_user_with_role_changes(active_all: true,
                                             account: @account,
                                             role_changes: { manage_account_calendar_visibility: false })
        expect(@account.grants_right?(@admin, :view_account_calendar_details)).to be_truthy
      end

      it "is false for an account admin without :manage_account_calendar_visibility on a hidden calendar" do
        account_admin_user_with_role_changes(active_all: true,
                                             account: @account,
                                             role_changes: { manage_account_calendar_visibility: false })
        expect(@account.grants_right?(@admin, :view_account_calendar_details)).to be_falsey
      end

      it "is true for an account admin on a random subaccount" do
        subaccount = @account.sub_accounts.create!
        account_admin_user(active_all: true, account: @account)
        expect(subaccount.grants_right?(@admin, :view_account_calendar_details)).to be_truthy
      end

      it "is true for a student only on associated accounts with a visible calendar" do
        subaccount1 = @account.sub_accounts.create!
        subaccount2 = @account.sub_accounts.create!
        [@account, subaccount1, subaccount2].each do |a|
          a.account_calendar_visible = true
          a.save!
        end
        course_with_student(active_all: true, account: subaccount1)
        expect(@account.grants_right?(@student, :view_account_calendar_details)).to be_truthy
        expect(subaccount1.grants_right?(@student, :view_account_calendar_details)).to be_truthy
        expect(subaccount2.grants_right?(@student, :view_account_calendar_details)).to be_falsey
      end

      it "is false for a student on associated accounts with hidden calendars" do
        @account.account_calendar_visible = true
        @account.save!
        subaccount = @account.sub_accounts.create!
        course_with_student(active_all: true, account: subaccount)
        expect(@account.grants_right?(@student, :view_account_calendar_details)).to be_truthy
        expect(subaccount.grants_right?(@student, :view_account_calendar_details)).to be_falsey
      end
    end
  end

  describe "authentication_providers.active" do
    let(:account) { Account.default }
    let!(:aac) { account.authentication_providers.create!(auth_type: "facebook") }

    it "pulls active AACS" do
      expect(account.authentication_providers.active).to include(aac)
    end

    it "ignores deleted AACs" do
      aac.destroy
      expect(account.authentication_providers.active).to_not include(aac)
    end
  end

  describe "delegated_authentication?" do
    let(:account) { Account.default }

    before do
      account.authentication_providers.scope.delete_all
    end

    it "is false for LDAP" do
      account.authentication_providers.create!(auth_type: "ldap")
      expect(account.delegated_authentication?).to be false
    end

    it "is true for CAS" do
      account.authentication_providers.create!(auth_type: "cas")
      expect(account.delegated_authentication?).to be true
    end
  end

  describe "#non_canvas_auth_configured?" do
    let(:account) { Account.default }

    it "is false for no aacs" do
      expect(account.non_canvas_auth_configured?).to be_falsey
    end

    it "is true for having aacs" do
      Account.default.authentication_providers.create!(auth_type: "ldap")
      expect(account.non_canvas_auth_configured?).to be_truthy
    end

    it "is false after aacs deleted" do
      Account.default.authentication_providers.create!(auth_type: "ldap")
      account.authentication_providers.destroy_all
      expect(account.non_canvas_auth_configured?).to be_falsey
    end
  end

  describe "#find_child" do
    it "works for root accounts" do
      sub = Account.default.sub_accounts.create!
      expect(Account.default.find_child(sub.id)).to eq sub
    end

    it "works for children accounts" do
      sub = Account.default.sub_accounts.create!
      sub_sub = sub.sub_accounts.create!
      sub_sub_sub = sub_sub.sub_accounts.create!
      expect(sub.find_child(sub_sub_sub.id)).to eq sub_sub_sub
    end

    it "raises for out-of-tree accounts" do
      sub = Account.default.sub_accounts.create!
      sub_sub = sub.sub_accounts.create!
      sibling = sub.sub_accounts.create!
      expect { sub_sub.find_child(sibling.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "manually created courses account" do
    it "still works with existing manually created courses accounts" do
      acct = Account.default
      sub = acct.sub_accounts.create!(name: "Manually-Created Courses")
      manual_courses_account = acct.manually_created_courses_account
      expect(manual_courses_account.id).to eq sub.id
      expect(acct.reload.settings[:manually_created_courses_account_id]).to eq sub.id
    end

    it "does not create a duplicate manual courses account when locale changes" do
      acct = Account.default
      sub1 = acct.manually_created_courses_account
      sub2 = I18n.with_locale(:es) do
        acct.manually_created_courses_account
      end
      expect(sub1.id).to eq sub2.id
    end

    it "works if the saved account id doesn't exist" do
      acct = Account.default
      acct.settings[:manually_created_courses_account_id] = acct.id + 1000
      acct.save!
      expect(acct.manually_created_courses_account).to be_present
    end

    it "works if the saved account id is not a sub-account" do
      acct = Account.default
      bad_acct = Account.create!
      acct.settings[:manually_created_courses_account_id] = bad_acct.id
      acct.save!
      manual_course_account = acct.manually_created_courses_account
      expect(manual_course_account.id).not_to eq bad_acct.id
    end
  end

  describe "account_users_for" do
    it "is cache coherent for site admin" do
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
        # ditto
        sa = Account.find(sa.id)
        expect(sa.account_users_for(@user)).to eq []
      end
    end

    context "sharding" do
      specs_require_sharding

      it "is cache coherent for site admin" do
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
            # ditto
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
      @roleA = @account.roles.create name: "A"
      @roleA.base_role_type = "StudentEnrollment"
      @roleA.save!
      @roleB = @account.roles.create name: "B"
      @roleB.base_role_type = "StudentEnrollment"
      @roleB.save!
      @sub_account = @account.sub_accounts.create!
      @roleC = @sub_account.roles.create name: "C"
      @roleC.base_role_type = "StudentEnrollment"
      @roleC.save!
    end

    it "returns roles indexed by name" do
      expect(@account.available_custom_course_roles.sort_by(&:id)).to eq [@roleA, @roleB].sort_by(&:id)
    end

    it "does not return inactive roles" do
      @roleB.deactivate!
      expect(@account.available_custom_course_roles).to eq [@roleA]
    end

    it "does not return deleted roles" do
      @roleA.destroy
      expect(@account.available_custom_course_roles).to eq [@roleB]
    end

    it "derives roles from parents" do
      expect(@sub_account.available_custom_course_roles.sort_by(&:id)).to eq [@roleA, @roleB, @roleC].sort_by(&:id)
    end

    it "includes built-in roles when called" do
      expect(@sub_account.available_course_roles.sort_by(&:id)).to eq ([@roleA, @roleB, @roleC] + Role.built_in_course_roles(root_account_id: @account.id)).sort_by(&:id)
    end
  end

  describe "account_chain" do
    context "sharding" do
      specs_require_sharding

      it "finds parent accounts when not on the correct shard" do
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

      chain = account4.account_chain
      expect(chain).to eq [account4, account3, account2, account1]
      # ensure pre-loading worked correctly
      expect(chain.map { |a| a.association(:parent_account).loaded? }).to eq [true, true, true, true]
      expect(chain.map(&:parent_account)).to eq [account3, account2, account1, nil]
      expect(chain.map { |a| a.association(:root_account).loaded? }).to eq [true, true, true, false]
      expect(chain.map(&:root_account)).to eq [account1, account1, account1, account1]

      chain = account4.account_chain(include_site_admin: true)
      sa = Account.site_admin
      expect(chain).to eq [account4, account3, account2, account1, sa]
      # ensure pre-loading worked correctly
      expect(chain.map { |a| a.association(:parent_account).loaded? }).to eq [true, true, true, true, true]
      expect(chain.map(&:parent_account)).to eq [account3, account2, account1, nil, nil]
      expect(chain.map { |a| a.association(:root_account).loaded? }).to eq [true, true, true, false, false]
      expect(chain.map(&:root_account)).to eq [account1, account1, account1, account1, sa]
    end
  end

  describe "#can_see_admin_tools_tab?" do
    let_once(:account) { Account.create! }
    it "returns false if no user is present" do
      expect(account.can_see_admin_tools_tab?(nil)).to be_falsey
    end

    it "returns false if you are a site admin" do
      admin = account_admin_user(account: Account.site_admin)
      expect(Account.site_admin.can_see_admin_tools_tab?(admin)).to be_falsey
    end

    it "doesn't have permission, it returns false" do
      allow(account).to receive(:grants_right?).and_return(false)
      account_admin_user(account:)
      expect(account.can_see_admin_tools_tab?(@admin)).to be_falsey
    end

    it "does have permission, it returns true" do
      allow(account).to receive(:grants_right?).and_return(true)
      account_admin_user(account:)
      expect(account.can_see_admin_tools_tab?(@admin)).to be_truthy
    end
  end

  describe "#update_account_associations" do
    before do
      @account = Account.default.sub_accounts.create!
      @c1 = @account.courses.create!
      @c2 = @account.courses.create!
      @account.course_account_associations.scope.delete_all
    end

    it "updates associations for all courses" do
      expect(@account.associated_courses).to eq []
      @account.update_account_associations
      @account.reload
      expect(@account.associated_courses.sort_by(&:id)).to eq [@c1, @c2]
    end

    it "can update associations in batch" do
      expect(@account.associated_courses).to eq []
      Account.update_all_update_account_associations
      @account.reload
      expect(@account.associated_courses.sort_by(&:id)).to eq [@c1, @c2]
    end
  end

  describe "default_time_zone" do
    context "root account" do
      before :once do
        @account = Account.create!
      end

      it "uses provided value when set" do
        @account.default_time_zone = "America/New_York"
        expect(@account.default_time_zone).to eq ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
      end

      it "has a sensible default if not set" do
        expect(@account.default_time_zone).to eq ActiveSupport::TimeZone[Account.time_zone_attribute_defaults[:default_time_zone]]
      end
    end

    context "sub account" do
      before :once do
        @root_account = Account.create!
        @account = @root_account.sub_accounts.create!
        @account.root_account = @root_account
      end

      it "uses provided value when set, regardless of root account setting" do
        @root_account.default_time_zone = "America/Chicago"
        @account.default_time_zone = "America/New_York"
        expect(@account.default_time_zone).to eq ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
      end

      it "defaults to root account value if not set" do
        @root_account.default_time_zone = "America/Chicago"
        expect(@account.default_time_zone).to eq ActiveSupport::TimeZone["Central Time (US & Canada)"]
      end

      it "has a sensible default if neither is set" do
        expect(@account.default_time_zone).to eq ActiveSupport::TimeZone[Account.time_zone_attribute_defaults[:default_time_zone]]
      end
    end
  end

  it "sets allow_sis_import if root_account" do
    account = Account.create!
    expect(account.allow_sis_import).to be true
    sub = account.sub_accounts.create!
    expect(sub.allow_sis_import).to be false
  end

  describe "#ensure_defaults" do
    it "assigns an lti_guid postfixed by canvas-lms" do
      account = Account.new
      account.uuid = "12345"
      account.ensure_defaults
      expect(account.lti_guid).to eq "12345:canvas-lms"
    end

    it "does not change existing an lti_guid" do
      account = Account.new
      account.lti_guid = "12345"
      account.ensure_defaults
      expect(account.lti_guid).to eq "12345"
    end

    it "removes carriage returns from the name" do
      account = Account.new
      account.name = "Hello\r\nWorld"
      account.ensure_defaults
      expect(account.name).to eq "Hello\nWorld"
    end
  end

  it "formats a referer url" do
    account = Account.new
    expect(account.format_referer(nil)).to be_nil
    expect(account.format_referer("")).to be_nil
    expect(account.format_referer("not a url")).to be_nil
    expect(account.format_referer("http://example.com/")).to eq "http://example.com"
    expect(account.format_referer("http://example.com/index.html")).to eq "http://example.com"
    expect(account.format_referer("http://example.com:80")).to eq "http://example.com"
    expect(account.format_referer("https://example.com:443")).to eq "https://example.com"
    expect(account.format_referer("http://example.com:3000")).to eq "http://example.com:3000"
  end

  it "formats trusted referers when set" do
    account = Account.new
    account.trusted_referers = "https://example.com/,http://example.com:80,http://example.com:3000"
    expect(account.settings[:trusted_referers]).to eq "https://example.com,http://example.com,http://example.com:3000"

    account.trusted_referers = nil
    expect(account.settings[:trusted_referers]).to be_nil

    account.trusted_referers = ""
    expect(account.settings[:trusted_referers]).to be_nil
  end

  describe "trusted_referer?" do
    let!(:account) do
      account = Account.new
      account.settings[:trusted_referers] = "https://example.com,http://example.com,http://example.com:3000"
      account
    end

    it "is true when a referer is trusted" do
      expect(account.trusted_referer?("http://example.com")).to be_truthy
      expect(account.trusted_referer?("http://example.com:3000")).to be_truthy
      expect(account.trusted_referer?("http://example.com:80")).to be_truthy
      expect(account.trusted_referer?("https://example.com:443")).to be_truthy
    end

    it "is false when a referer is not provided" do
      expect(account.trusted_referer?(nil)).to be_falsey
      expect(account.trusted_referer?("")).to be_falsey
    end

    it "is false when a referer is not trusted" do
      expect(account.trusted_referer?("https://example.com:5000")).to be_falsey
    end

    it "is false when the account has no trusted referer setting" do
      account.settings.delete(:trusted_referers)
      expect(account.trusted_referer?("https://example.com")).to be_falsey
    end

    it "is false when the account has nil trusted referer setting" do
      account.settings[:trusted_referers] = nil
      expect(account.trusted_referer?("https://example.com")).to be_falsey
    end

    it "is false when the account has empty trusted referer setting" do
      account.settings[:trusted_referers] = ""
      expect(account.trusted_referer?("https://example.com")).to be_falsey
    end
  end

  context "quota cache" do
    it "only clears the quota cache if something changes" do
      account = account_model

      expect(Account).to receive(:invalidate_inherited_caches).once

      account.default_storage_quota = 10.megabytes
      account.save! # clear here

      account.reload
      account.save!

      account.default_storage_quota = 10.megabytes
      account.save!
    end

    it "inherits from a parent account's default_storage_quota" do
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

    it "inherits from a new parent account's default_storage_quota if parent account changes" do
      enable_cache do
        account = account_model

        sub1 = account.sub_accounts.create!
        sub2 = account.sub_accounts.create!
        sub2.update(default_storage_quota: 10.megabytes)

        to_be_subaccount = sub1.sub_accounts.create!
        expect(to_be_subaccount.default_storage_quota).to eq Account::DEFAULT_STORAGE_QUOTA

        # should clear caches
        Timecop.travel(1.second.from_now) do
          to_be_subaccount.update(parent_account: sub2)
          to_be_subaccount = Account.find(to_be_subaccount.id)
          expect(to_be_subaccount.default_storage_quota).to eq 10.megabytes
        end
      end
    end
  end

  context "inheritable settings" do
    before :once do
      @settings = [:restrict_student_future_view, :lock_all_announcements]
    end

    before :once do
      account_model
      @sub1 = @account.sub_accounts.create!
      @sub2 = @sub1.sub_accounts.create!
    end

    it "uses the default value if nothing is set anywhere" do
      expected = { locked: false, value: false }
      [@account, @sub1, @sub2].each do |a|
        expect(a.restrict_student_future_view).to eq expected
        expect(a.lock_all_announcements).to eq expected
      end
    end

    it "is able to lock values for sub-accounts" do
      @settings.each do |key|
        @sub1.settings[key] = { locked: true, value: true }
      end
      @sub1.save!
      # should ignore the subaccount's wishes
      @settings.each do |key|
        @sub2.settings[key] = { locked: true, value: false }
      end
      @sub2.save!

      @settings.each do |key|
        expect(@account.send(key)).to eq({ locked: false, value: false })
        expect(@sub1.send(key)).to eq({ locked: true, value: true })
        expect(@sub2.send(key)).to eq({ locked: true, value: true, inherited: true })
      end
    end

    it "grandfathers old pre-hash values in" do
      @settings.each do |key|
        @account.settings[key] = true
      end
      @account.save!

      @settings.each do |key|
        @sub2.settings[key] = false
      end
      @sub2.save!

      @settings.each do |key|
        expect(@account.send(key)).to eq({ locked: false, value: true })
        expect(@sub1.send(key)).to eq({ locked: false, value: true, inherited: true })
        expect(@sub2.send(key)).to eq({ locked: false, value: false })
      end
    end

    it "translates string values in mass-assignment" do
      settings = {}
      settings[:restrict_student_future_view] = { "value" => "1", "locked" => "0" }
      settings[:lock_all_announcements] = { "value" => "1", "locked" => "0" }
      @account.settings = settings
      @account.save!

      expect(@account.restrict_student_future_view).to eq({ locked: false, value: true })
      expect(@account.lock_all_announcements).to eq({ locked: false, value: true })
    end

    context "empty setting elision" do
      before :once do
        @account.update settings: { sis_assignment_name_length_input: { value: "100" } }
        @sub1.update settings: { sis_assignment_name_length_input: { value: "150" } }
        @sub2.update settings: { sis_assignment_name_length_input: { value: "200" } }
      end

      it "elides an empty setting" do
        @sub1.update settings: { sis_assignment_name_length_input: { value: "" } }
        expect(@sub1.sis_assignment_name_length_input).to eq({ value: "100", inherited: true })
      end

      it "elides a nil setting" do
        @sub1.update settings: { sis_assignment_name_length_input: { value: nil } }
        expect(@sub1.sis_assignment_name_length_input).to eq({ value: "100", inherited: true })
      end

      it "elides an explicitly-unlocked setting" do
        @sub1.update settings: { sis_assignment_name_length_input: { value: nil, locked: false } }
        expect(@sub1.sis_assignment_name_length_input).to eq({ value: "100", inherited: true })
      end

      it "doesn't elide a locked setting" do
        @sub1.update settings: { sis_assignment_name_length_input: { value: nil, locked: true } }
        expect(@sub2.sis_assignment_name_length_input).to eq({ value: nil, inherited: true, locked: true })
      end
    end

    context "caching" do
      specs_require_sharding
      it "clears cached values correctly" do
        enable_cache do
          # preload the cached values
          [@account, @sub1, @sub2].each(&:restrict_student_future_view)
          [@account, @sub1, @sub2].each(&:lock_all_announcements)

          @sub1.settings = @sub1.settings.merge(restrict_student_future_view: { locked: true, value: true }, lock_all_announcements: { locked: true, value: true })
          @sub1.save!

          # hard reload
          @account = Account.find(@account.id)
          @sub1 = Account.find(@sub1.id)
          @sub2 = Account.find(@sub2.id)

          expect(@account.restrict_student_future_view).to eq({ locked: false, value: false })
          expect(@account.lock_all_announcements).to eq({ locked: false, value: false })

          expect(@sub1.restrict_student_future_view).to eq({ locked: true, value: true })
          expect(@sub1.lock_all_announcements).to eq({ locked: true, value: true })

          expect(@sub2.restrict_student_future_view).to eq({ locked: true, value: true, inherited: true })
          expect(@sub2.lock_all_announcements).to eq({ locked: true, value: true, inherited: true })
        end
      end
    end
  end

  context "require terms of use" do
    describe "#terms_required?" do
      it "returns true by default" do
        expect(account_model.terms_required?).to be true
      end

      it "returns false by default for new accounts" do
        TermsOfService.skip_automatic_terms_creation = false
        expect(account_model.terms_required?).to be false
      end

      it "returns false if Setting is false" do
        Setting.set(:terms_required, "false")
        expect(account_model.terms_required?).to be false
      end

      it "returns false if account setting is false" do
        account = account_model(settings: { account_terms_required: false })
        expect(account.terms_required?).to be false
      end

      it "consults root account setting" do
        parent_account = account_model(settings: { account_terms_required: false })
        child_account = Account.create!(parent_account:)
        expect(child_account.terms_required?).to be false
      end
    end
  end

  context "account cache" do
    specs_require_sharding

    describe ".find_cached" do
      let(:nonsense_id) { 987_654_321 }

      it "works relative to a different shard" do
        @shard1.activate do
          a = Account.create!
          expect(Account.find_cached(a.id)).to eq a
        end
      end

      it "errors if infrastructure fails and we can't see the account" do
        expect { Account.find_cached(nonsense_id) }.to raise_error(Canvas::AccountCacheError)
      end

      it "includes the account id in the error message" do
        Account.find_cached(nonsense_id)
      rescue Canvas::AccountCacheError => e
        expect(e.message).to eq("Couldn't find Account with 'id'=#{nonsense_id}")
      end
    end

    describe ".invalidate_cache" do
      it "works relative to a different shard" do
        enable_cache do
          @shard1.activate do
            a = Account.create!
            Account.find_cached(a.id) # set the cache
            expect(Account.invalidate_cache(a.id)).to be true
          end
        end
      end
    end
  end

  describe "#users_name_like" do
    context "sharding" do
      specs_require_sharding

      it "works cross-shard" do
        @shard1.activate do
          @account = Account.create!
          @user = user_factory(name: "silly name")
          @user.account_users.create(account: @account)
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

  it "clears special account cache on updates to special accounts" do
    expect(Account.default.settings[:blah]).to be_nil

    non_cached = Account.find(Account.default.id)
    non_cached.settings[:blah] = true
    non_cached.save!

    expect(Account.default.settings[:blah]).to be true
  end

  it_behaves_like "a learning outcome context"

  describe "#default_dashboard_view" do
    before(:once) do
      @account = Account.create!
    end

    it "is nil by default" do
      expect(@account.default_dashboard_view).to be_nil
    end

    it "updates if view is valid" do
      @account.default_dashboard_view = "activity"
      @account.save!

      expect(@account.default_dashboard_view).to eq "activity"
    end

    it "does not update if view is invalid" do
      @account.default_dashboard_view = "junk"
      expect { @account.save! }.not_to change { @account.default_dashboard_view }
    end

    it "contains planner" do
      @account.default_dashboard_view = "planner"
      @account.save!
      expect(@account.default_dashboard_view).to eq "planner"
    end
  end

  describe "#update_user_dashboards" do
    before :once do
      @account = Account.create!

      @user1 = user_factory(active_all: true)
      @account.pseudonyms.create!(unique_id: "user1", user: @user1)
      @user1.dashboard_view = "activity"
      @user1.save

      @user2 = user_factory(active_all: true)
      @account.pseudonyms.create!(unique_id: "user2", user: @user2)
      @user2.dashboard_view = "cards"
      @user2.save
    end

    it "adds or overwrite all account users' dashboard_view preference" do
      @account.default_dashboard_view = "planner"
      @account.save!
      @account.reload

      expect([@user1.dashboard_view(@account), @user2.dashboard_view(@account)]).to match_array(["activity", "cards"])
      @account.update_user_dashboards(synchronous: true)
      @account.reload
      expect([@user1.reload.dashboard_view(@account), @user2.reload.dashboard_view(@account)]).to match_array(Array.new(2, "planner"))
    end
  end

  it "only sends new account user notifications to active admins" do
    active_admin = account_admin_user(active_all: true)
    deleted_admin = account_admin_user(active_all: true)
    deleted_admin.account_users.destroy_all
    Account.default.reload
    n = Notification.create(name: "New Account User", category: "TestImmediately")
    [active_admin, deleted_admin].each do |u|
      NotificationPolicy.create(notification: n, communication_channel: u.communication_channel, frequency: "immediately")
    end
    user_factory(active_all: true)
    au = Account.default.account_users.create!(user: @user)
    expect(au.messages_sent[n.name].map(&:user)).to match_array [active_admin, @user]
  end

  context "fancy redis caching" do
    specs_require_cache(:redis_cache_store)

    describe "cached_account_users_for" do
      before do
        @account = Account.create!
        @user = User.create!
      end

      def cached_account_users
        %i[@account_users_cache @account_chain_ids @account_chain].each do |iv|
          @account.instance_variable_set(iv, nil)
        end
        @account.cached_account_users_for(@user)
      end

      it "caches" do
        expect_any_instantiation_of(@account).to receive(:account_users_for).once.and_call_original
        2.times { cached_account_users }
      end

      it "skips cache if disabled" do
        allow(Canvas::CacheRegister).to receive(:enabled?).and_return(false)
        expect_any_instantiation_of(@account).to receive(:account_users_for).exactly(2).times.and_call_original
        2.times { cached_account_users }
      end

      it "updates if the account chain changes" do
        other_account = Account.create!
        au = AccountUser.create!(account: other_account, user: @user)
        expect(cached_account_users).to eq []
        @account.update_attribute(:parent_account, other_account)
        @account.reload
        expect(cached_account_users).to eq [au]
      end

      it "updates if the user has an account user added" do
        expect(cached_account_users).to eq []
        au = AccountUser.create!(account: @account, user: @user)
        expect(cached_account_users).to eq [au]
      end
    end

    describe "account_chain_ids" do
      let(:account1) { Account.default.sub_accounts.create! }

      before do
        account1
      end

      it "caches" do
        expect(Account.connection).to receive(:select_values).once.and_call_original
        2.times { Account.account_chain_ids(Account.default.id) }
      end

      it "skips cache if disabled" do
        allow(Canvas::CacheRegister).to receive(:enabled?).and_return(false)
        expect(Account.connection).to receive(:select_values).exactly(2).times.and_call_original
        2.times { Account.account_chain_ids(Account.default.id) }
      end

      it "updates if the account chain changes" do
        account2 = Account.default.sub_accounts.create!
        expect(Account.account_chain_ids(account2.id)).to eq [account2.id, Account.default.id]
        account2.update_attribute(:parent_account, account1)
        expect(Account.account_chain_ids(account2.id)).to eq [account2.id, account1.id, Account.default.id]
      end

      def expect_id_chain_for_account(account, id_chain)
        # frd disable caching for testing, so that calls with either
        # Account or id still exercise all logic
        allow(Account).to receive(:cache_key_for_id).and_return(nil)
        expect(Account.account_chain_ids(account.id)).to eq id_chain
        expect(Account.account_chain_ids(account)).to eq id_chain
      end

      it "returns local ids" do
        expect_id_chain_for_account(account1, [account1.id, Account.default.id])
      end

      context "on another shard" do
        specs_require_sharding

        it "returns correct global ids" do
          @shard1.activate do
            expect_id_chain_for_account(account1, [account1.global_id, Account.default.global_id])
          end
        end

        it "returns correct global ids when used twice on different shards (doesn't cache across shards)" do
          expect(account1.account_chain_ids).to eq([account1.id, Account.default.id])
          @shard1.activate do
            expect(account1.account_chain_ids).to eq([account1.id, Account.default.id])
          end
        end
      end
    end
  end

  context "#destroy on sub accounts" do
    before :once do
      @root_account = Account.create!
      @sub_account = @root_account.sub_accounts.create!
    end

    it "wont let you destroy if there are active sub accounts" do
      @sub_account.sub_accounts.create!
      expect { @sub_account.destroy! }.to raise_error ActiveRecord::RecordInvalid
    end

    it "wont let you destroy if there are active courses" do
      @sub_account.courses.create!
      expect { @sub_account.destroy! }.to raise_error ActiveRecord::RecordInvalid
    end

    it "destroys associated account users" do
      account_user1 = @sub_account.account_users.create!(user: User.create!)
      account_user2 = @sub_account.account_users.create!(user: User.create!)
      @sub_account.destroy!
      expect(account_user1.reload.workflow_state).to eq "deleted"
      expect(account_user2.reload.workflow_state).to eq "deleted"
    end
  end

  context "custom help link validation" do
    before do
      account_model
    end

    it "is valid if custom help links are not present" do
      @account.settings[:foo] = "bar"
      expect(@account.valid?).to be true
    end

    it "is valid if custom help links are valid" do
      @account.settings[:custom_help_links] = [{ is_new: true, is_featured: false }, { is_new: false, is_featured: true }]
      expect(@account.valid?).to be true
    end

    it "is not valid if custom help links are invalid" do
      @account.settings[:custom_help_links] = [{ is_new: true, is_featured: true }]
      expect(@account.valid?).to be false
    end

    it "does not check custom help links if not changed" do
      @account.update_attribute(:settings, [{ is_new: true, is_featured: true }]) # skips validation
      @account.name = "foo"
      expect(@account.valid?).to be true
    end
  end

  describe "#allow_disable_post_to_sis_when_grading_period_closed?" do
    let(:root_account) { Account.create!(root_account: nil) }
    let(:subaccount) { Account.create!(root_account:) }

    it "returns false if the account is not a root account" do
      root_account.enable_feature!(:new_sis_integrations)
      root_account.enable_feature!(:disable_post_to_sis_when_grading_period_closed)

      expect(subaccount).not_to be_allow_disable_post_to_sis_when_grading_period_closed
    end

    context "for a root account" do
      it "returns false if the root account does not enable the relevant feature flag" do
        root_account.enable_feature!(:disable_post_to_sis_when_grading_period_closed)

        expect(root_account).not_to be_allow_disable_post_to_sis_when_grading_period_closed
      end

      it "returns false if this account does not enable the new_sis_integrations feature flag" do
        root_account.enable_feature!(:new_sis_integrations)

        expect(root_account).not_to be_allow_disable_post_to_sis_when_grading_period_closed
      end

      it "returns true when the relevant feature flags are enabled" do
        root_account.enable_feature!(:new_sis_integrations)
        root_account.enable_feature!(:disable_post_to_sis_when_grading_period_closed)

        expect(root_account).to be_allow_disable_post_to_sis_when_grading_period_closed
      end
    end
  end

  context "default_locale cached recursive search" do
    specs_require_cache(:redis_cache_store)

    it "caches" do
      sub_acc1 = Account.default.sub_accounts.create!(default_locale: "es")
      sub_acc2 = sub_acc1.sub_accounts.create!
      expect(Account.recursive_default_locale_for_id(sub_acc2.id)).to eq "es"
      Account.where(id: sub_acc1).update_all(default_locale: "de") # directly update db - shouldn't invalidate cache
      expect(Account.recursive_default_locale_for_id(sub_acc2.id)).to eq "es"

      sub_acc1.update_attribute(:default_locale, "en") # should invalidate cache downstream
      expect(Account.recursive_default_locale_for_id(sub_acc2.id)).to eq "en"
    end
  end

  context "effective_brand_config caching" do
    specs_require_cache(:redis_cache_store)

    it "caches the brand config" do
      @parent_account = Account.default
      config1 = BrandConfig.create(variables: { "ic-brand-primary" => "#321" })
      config2 = BrandConfig.create(variables: { "ic-brand-primary" => "#123" })
      Account.default.update_attribute(:brand_config_md5, config1.md5)

      sub_acc1 = Account.default.sub_accounts.create!
      sub_acc2 = sub_acc1.sub_accounts.create!
      expect(sub_acc2.effective_brand_config).to eq config1
      Account.where(id: sub_acc1).update_all(brand_config_md5: config2.md5) # directly update db - shouldn't invalidate cache
      expect(Account.find(sub_acc2.id).effective_brand_config).to eq config1

      Account.default.update_attribute(:brand_config_md5, config2.md5) # should invalidate downstream
      expect(Account.find(sub_acc2.id).effective_brand_config).to eq config2
    end
  end

  context "#roles_with_enabled_permission" do
    def create_role_override(permission, role, context, enabled = true)
      RoleOverride.create!(
        context:,
        permission:,
        role:,
        enabled:
      )
    end
    let(:account) { account_model }

    it "returns expected roles with the given permission" do
      account.disable_feature!(:granular_permissions_manage_courses)
      role = account.roles.create name: "AssistantGrader"
      role.base_role_type = "TaEnrollment"
      role.workflow_state = "active"
      role.save!
      create_role_override("change_course_state", role, account)
      expect(
        account.roles_with_enabled_permission(:change_course_state).map(&:name).sort
      ).to eq %w[AccountAdmin AssistantGrader DesignerEnrollment TeacherEnrollment]
    end

    it "returns expected roles with the given permission (granular permissions)" do
      account.enable_feature!(:granular_permissions_manage_courses)
      role = account.roles.create name: "TeacherAdmin"
      role.base_role_type = "TeacherEnrollment"
      role.workflow_state = "active"
      role.save!
      create_role_override("manage_courses_add", role, account)
      create_role_override("manage_courses_publish", role, account)
      create_role_override("manage_courses_conclude", role, account)
      create_role_override("manage_courses_reset", role, account)
      create_role_override("manage_courses_delete", role, account)
      expect(
        account.roles_with_enabled_permission(:manage_courses_add).map(&:name).sort
      ).to eq %w[AccountAdmin]
      expect(
        account.roles_with_enabled_permission(:manage_courses_publish).map(&:name).sort
      ).to eq %w[AccountAdmin DesignerEnrollment TeacherAdmin TeacherEnrollment]
      expect(
        account.roles_with_enabled_permission(:manage_courses_conclude).map(&:name).sort
      ).to eq %w[AccountAdmin DesignerEnrollment TeacherAdmin TeacherEnrollment]
      expect(
        account.roles_with_enabled_permission(:manage_courses_reset).map(&:name).sort
      ).to eq %w[AccountAdmin TeacherAdmin]
      expect(
        account.roles_with_enabled_permission(:manage_courses_delete).map(&:name).sort
      ).to eq %w[AccountAdmin TeacherAdmin]
    end
  end

  describe "#invalidate_caches_if_changed" do
    it "works for root accounts" do
      Account.default.name = "Something new"
      expect(Account).to receive(:invalidate_cache).with(Account.default.id).at_least(1)
      allow(Rails.cache).to receive(:delete)
      expect(Rails.cache).to receive(:delete).with(["account2", Account.default.id].cache_key)
      Account.default.save!
    end

    it "works for sub accounts" do
      a = Account.default.manually_created_courses_account
      a.name = "something else"
      expect(Rails.cache).to receive(:delete).with("short_name_lookup/account_#{a.id}").ordered
      expect(Rails.cache).to receive(:delete).with(["account2", a.id].cache_key).ordered
      a.save!
    end
  end

  describe "allow_observers_in_appointment_groups?" do
    before :once do
      @account = Account.default
      @account.settings[:allow_observers_in_appointment_groups] = { value: true }
      @account.save!
    end

    it "returns true if the setting is enabled and the observer_appointment_groups flag is enabled" do
      expect(@account.allow_observers_in_appointment_groups?).to be true
    end

    it "returns false if the observer_appointment_groups flag is disabled" do
      Account.site_admin.disable_feature!(:observer_appointment_groups)
      expect(@account.allow_observers_in_appointment_groups?).to be false
    end
  end

  describe "enable_as_k5_account setting" do
    it "enable_as_k5_account? helper returns false by default" do
      account = Account.create!
      expect(account).not_to be_enable_as_k5_account
    end

    it "enable_as_k5_account? and enable_as_k5_account helpers return correct values" do
      account = Account.create!
      account.settings[:enable_as_k5_account] = {
        value: true,
        locked: true
      }
      expect(account).to be_enable_as_k5_account
      expect(account.enable_as_k5_account[:value]).to be_truthy
      expect(account.enable_as_k5_account[:locked]).to be_truthy
    end
  end

  describe "#multi_parent_sub_accounts_recursive" do
    subject { Account.multi_parent_sub_accounts_recursive(parent_account_ids) }

    let_once(:root_account) { Account.create! }

    let_once(:level_one_sub_accounts) do
      3.times do |i|
        root_account.sub_accounts.create!(name: "Level 1 - Sub-account #{i}")
      end

      root_account.sub_accounts
    end

    let_once(:level_two_sub_accounts) do
      root_account.sub_accounts.map do |sa|
        sa.sub_accounts.create!(name: "Level 2 - Sub account")
      end
    end

    context "with empty parent account ids" do
      let(:parent_account_ids) { [] }

      it { is_expected.to match_array [] }
    end

    context "with a single root account id" do
      let(:parent_account_ids) { [root_account.id] }

      it "returns all sub-accounts" do
        expect(subject).to match_array(
          level_one_sub_accounts + level_two_sub_accounts + [root_account]
        )
      end
    end

    context "with a single sub-account parent account id" do
      let(:parent_sub_account) { level_two_sub_accounts.first }
      let(:parent_account_ids) { [parent_sub_account.id] }

      it "returns all sub-accounts that belong to the parent account" do
        expect(subject).to match_array(
          parent_sub_account.sub_accounts + [parent_sub_account]
        )
      end
    end

    context "with multiple parent account ids" do
      let(:parent_account_one) { level_one_sub_accounts.first }
      let(:parent_account_two) { level_one_sub_accounts.second }
      let(:parent_account_ids) { [parent_account_one.id, parent_account_two.id] }

      it "returns all sub-accounts that belong to the parent accounts" do
        expect(subject).to match_array(
          parent_account_one.sub_accounts + parent_account_two.sub_accounts + [parent_account_one, parent_account_two]
        )
      end

      context "and not all parent account IDs are on the same shard" do
        specs_require_sharding

        let(:cross_shard_parent_account) { @shard1.activate { Account.create! } }
        let(:parent_account_ids) { [root_account.id, cross_shard_parent_account.id] }

        it "raises an argument error" do
          expect { subject }.to raise_error(
            ArgumentError,
            "all parent_account_ids must be in the same shard"
          )
        end
      end

      context "and another shard is active" do
        specs_require_sharding

        subject { @shard1.activate { Account.multi_parent_sub_accounts_recursive(parent_account_ids) } }

        let(:parent_account_one) { level_one_sub_accounts.first }
        let(:parent_account_two) { level_one_sub_accounts.second }
        let(:parent_account_ids) { [parent_account_one.global_id, parent_account_two.global_id] }

        it "returns all sub-accounts that belong to the parent accounts" do
          expect(subject).to match_array(
            parent_account_one.sub_accounts + parent_account_two.sub_accounts + [parent_account_one, parent_account_two]
          )
        end
      end

      context "and there is overlap in the sub accounts" do
        let(:parent_account_one) { root_account }
        let(:parent_account_two) { level_one_sub_accounts.first }
        let(:parent_account_ids) { [parent_account_one.id, parent_account_two.id] }

        it "Does not include duplicate accounts" do
          expect(subject).to match_array(
            level_one_sub_accounts + level_two_sub_accounts + [root_account]
          )
        end
      end
    end
  end

  describe "#effective_course_template" do
    let(:root_account) { Account.create! }
    let(:sub_account) { root_account.sub_accounts.create! }
    let(:template) { root_account.courses.create!(template: true) }

    it "returns an explicit template" do
      sub_account.update!(course_template: template)
      expect(sub_account.effective_course_template).to eq template
    end

    it "inherits a template" do
      root_account.update!(course_template: template)
      expect(sub_account.effective_course_template).to eq template
    end

    it "doesn't use an explicit non-template" do
      root_account.update!(course_template: template)
      Course.ensure_dummy_course
      sub_account.update!(course_template_id: 0)
      expect(sub_account.effective_course_template).to be_nil
    end
  end

  describe "#course_template_id" do
    it "resets id of 0 to nil on root accounts" do
      a = Account.new
      a.course_template_id = 0
      expect(a).to be_valid
      expect(a.course_template_id).to be_nil
    end

    it "requires the course template to be in the same root account" do
      a = Account.create!
      a2 = Account.create!
      c = a2.courses.create!(template: true)
      a.course_template = c
      expect(a).not_to be_valid
      expect(a.errors.to_h.keys).to eq [:course_template_id]
    end

    it "requires the course template to actually be a template" do
      a = Account.create!
      c = a.courses.create!
      a.course_template = c
      expect(a).not_to be_valid
      expect(a.errors.to_h.keys).to eq [:course_template_id]
    end

    it "allows a valid course template" do
      a = Account.create!
      c = a.courses.create!(template: true)
      a.course_template = c
      expect(a).to be_valid
    end
  end

  describe "#dummy?" do
    it "returns false for most accounts" do
      act = Account.new(id: 1)
      expect(act.dummy?).to be_falsey
    end

    it "is true for a 0-id account" do
      act = Account.new(id: 0)
      expect(act.dummy?).to be_truthy
    end

    it "determines the outcome of `unless_dummy`" do
      act = Account.new(id: 0)
      expect(act.unless_dummy).to be_nil
      act.id = 1
      expect(act.unless_dummy).to be(act)
    end
  end

  describe "logging Restrict Quantitative Data (RQD) setting enable/disable" do
    before do
      # @account = Account.create!
      account_model
      @account.enable_feature!(:restrict_quantitative_data)

      allow(InstStatsd::Statsd).to receive(:increment)
    end

    it "restrict_quantitative_data? helper returns false by default" do
      expect(@account.restrict_quantitative_data?).to be false
    end

    it "increments enabled log when setting is turned on" do
      @account.settings[:restrict_quantitative_data] = { locked: false, value: true }
      @account.save!
      expect(@account.restrict_quantitative_data?).to be true

      expect(InstStatsd::Statsd).to have_received(:increment).with("account.settings.restrict_quantitative_data.enabled").once
    end

    it "increments disabled log when setting is turned off" do
      @account.settings[:restrict_quantitative_data] = { locked: false, value: true }
      @account.save!
      expect(@account.restrict_quantitative_data?).to be true
      @account.settings[:restrict_quantitative_data] = { locked: false, value: false }
      @account.save!
      expect(@account.restrict_quantitative_data?).to be false

      expect(InstStatsd::Statsd).to have_received(:increment).with("account.settings.restrict_quantitative_data.enabled").once.ordered
      expect(InstStatsd::Statsd).to have_received(:increment).with("account.settings.restrict_quantitative_data.disabled").once.ordered
    end

    it "doesn't increment either log when settings update but RQD setting is unchanged" do
      expect(@account.restrict_student_future_view[:value]).to be false
      @account.settings[:restrict_student_future_view] = { locked: false, value: true }
      @account.save!
      expect(@account.restrict_student_future_view[:value]).to be true

      expect(InstStatsd::Statsd).not_to have_received(:increment).with("account.settings.restrict_quantitative_data.enabled")
      expect(InstStatsd::Statsd).not_to have_received(:increment).with("account.settings.restrict_quantitative_data.disabled")
    end

    it "doesn't increment either counter when parent account setting is changed" do
      @sub_account = @account.sub_accounts.create!
      @sub_account.settings[:restrict_quantitative_data] = { locked: false, value: true }
      @sub_account.save!

      expect(@sub_account.restrict_quantitative_data?).to be true
      expect(InstStatsd::Statsd).to have_received(:increment).with("account.settings.restrict_quantitative_data.enabled").once

      @account.settings[:restrict_quantitative_data] = { locked: true, value: false }
      @account.save!
      # Ignores changes completely
      expect(@sub_account.restrict_quantitative_data?).to be true

      expect(InstStatsd::Statsd).not_to have_received(:increment).with("account.settings.restrict_quantitative_data.disabled")
    end
  end

  describe "#enable_user_notes" do
    let(:account) { account_model(enable_user_notes: true) }

    context "when the deprecate_faculty_journal flag is enabled" do
      before { Account.site_admin.enable_feature!(:deprecate_faculty_journal) }

      it "returns false" do
        expect(account.enable_user_notes).to be false
      end
    end

    context "when the deprecate_faculty_journal flag is disabled" do
      before { Account.site_admin.disable_feature!(:deprecate_faculty_journal) }

      it "returns the value stored on the account model" do
        expect(account.enable_user_notes).to be true
        account.update_attribute(:enable_user_notes, false)
        expect(account.enable_user_notes).to be false
      end
    end
  end

  describe ".having_user_notes_enabled" do
    let!(:enabled_account) { account_model(enable_user_notes: true) }

    before { account_model(enable_user_notes: false) }

    context "when the deprecate_faculty_journal flag is disabled" do
      before { Account.site_admin.disable_feature!(:deprecate_faculty_journal) }

      it "only returns accounts having user notes enabled" do
        expect(Account.having_user_notes_enabled).to match_array [enabled_account]
      end
    end

    it "returns no accounts" do
      expect(Account.having_user_notes_enabled).to be_empty
    end
  end

  context "account grading standards" do
    before do
      account_model
    end

    def example_grading_standard(context)
      gs = GradingStandard.new(context:, workflow_state: "active")
      gs.data = [["A", 0.9], ["B", 0.8], ["C", -0.7]]
      gs.save(validate: false)
      gs
    end

    describe "#grading_standard_enabled" do
      it "returns false by default" do
        expect(@account.grading_standard_enabled?).to be false
      end

      it "returns true when grading_standard is set" do
        @account.grading_standard = example_grading_standard(@account)
        @account.save!
        expect(@account.grading_standard_enabled?).to be true
      end

      it "returns true if a parent account has a grading_standard" do
        @account.grading_standard_id = example_grading_standard(@account).id
        @account.save
        @sub_account = @account.sub_accounts.create!

        expect(@sub_account.grading_standard_enabled?).to be true
      end

      it "returns false if no parent account has a grading standard" do
        @sub_account1 = @account.sub_accounts.create!
        @sub_account2 = @sub_account1.sub_accounts.create!
        @sub_account3 = @sub_account2.sub_accounts.create!

        expect(@sub_account3.grading_standard_enabled?).to be false
      end

      it "returns true if a deeply nested parent account has a grading_standard" do
        @account.grading_standard = example_grading_standard(@account)
        @account.save
        @sub_account1 = @account.sub_accounts.create!
        @sub_account2 = @sub_account1.sub_accounts.create!
        @sub_account3 = @sub_account2.sub_accounts.create!

        expect(@sub_account3.grading_standard_enabled?).to be true
      end
    end

    describe "#default_grading_standard" do
      it "returns nil by default" do
        expect(@account.default_grading_standard).to be_nil
      end

      it "returns the grading_standard if set" do
        @account.grading_standard = example_grading_standard(@account)
        expect(@account.default_grading_standard).to eq @account.grading_standard
      end

      it "returns the parent account's grading_standard if set" do
        @account.grading_standard = example_grading_standard(@account)
        @account.save
        @sub_account = @account.sub_accounts.create!

        expect(@sub_account.default_grading_standard).to eq @account.grading_standard
      end

      it "returns nil if no parent account has a grading standard" do
        @sub_account1 = @account.sub_accounts.create!
        @sub_account2 = @sub_account1.sub_accounts.create!
        @sub_account3 = @sub_account2.sub_accounts.create!

        expect(@sub_account3.default_grading_standard).to be_nil
      end

      it "returns a deeply nested parent account's grading_standard if set" do
        @account.grading_standard = example_grading_standard(@account)
        @account.save
        @sub_account1 = @account.sub_accounts.create!
        @sub_account2 = @sub_account1.sub_accounts.create!
        @sub_account3 = @sub_account2.sub_accounts.create!

        expect(@sub_account3.default_grading_standard).to eq @account.grading_standard
      end

      it "returns correct parent's grading standard in deeply nested accounts" do
        @account.grading_standard = example_grading_standard(@account)
        @account.save
        @sub_account1 = @account.sub_accounts.create!
        @sub_account1.grading_standard = example_grading_standard(@sub_account1)
        @sub_account1.save
        @sub_account2 = @sub_account1.sub_accounts.create!
        @sub_account3 = @sub_account2.sub_accounts.create!

        expect(@sub_account3.default_grading_standard).to eq @sub_account1.grading_standard
      end
    end
  end
end
