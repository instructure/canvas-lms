require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20140903152155_add_role_id_columns.rb'
require 'db/migrate/20140905171322_drop_role_name_columns.rb'

describe 'AddRoleIdColumns', shared_db: false do
  describe "up" do
    def create_role(account, name, base)
      role = account.roles.build(:name => name)
      role.base_role_type = base
      role.workflow_state = 'active'
      role.infer_root_account_id
      role.save(:validate => false)
      role
    end

    before do
      pending("PostgreSQL specific") unless ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'

      @pre_migration = AddRoleIdColumns.new
      @post_migration = DropRoleNameColumns.new

      @root_account = account_model
      @sub_account1 = @root_account.sub_accounts.create!
      @sub_sub_account = @sub_account1.sub_accounts.create! # should inherit roles from sub_account1
      @sub_account2 = @root_account.sub_accounts.create! # should not inherit roles from sub_account1

      @course_role1 = create_role(@root_account, "courserole1", 'StudentEnrollment')
      @course_role2 = create_role(@sub_account1, "courserole2", 'StudentEnrollment')
      @account_role1 = create_role(@root_account, "accountrole1", 'AccountMembership')
      @account_role2 = create_role(@sub_account1, "accountrole2", 'AccountMembership')
    end

    it "should de-dup account roles in the same chain that have the same name" do
      @post_migration.down
      @pre_migration.down

      duplicate_role1 = create_role(@sub_account1, "courserole1", 'StudentEnrollment')
      duplicate_role2 = create_role(@sub_sub_account, "courserole1", 'StudentEnrollment') # is a duplicate because it belongs to @root_account indirectly
      duplicate_role3 = create_role(@sub_sub_account, "courserole2", 'StudentEnrollment') # is a duplicate because it belongs to @sub_account1
      not_a_duplicate_role = create_role(@sub_account2, "courserole2", 'StudentEnrollment')

      @pre_migration.up
      @post_migration.up

      [duplicate_role1, duplicate_role2, duplicate_role3].each do |role|
        role.reload
        expect(role.deleted?).to eq true
      end
      not_a_duplicate_role.reload
      expect(not_a_duplicate_role.deleted?).to eq false
    end

    it "should have created built-in roles" do
      @post_migration.down
      @pre_migration.down

      expect(Role.where(:workflow_state => 'built_in').count).to eq 0

      @pre_migration.up
      @post_migration.up

      expect(Role.where(:workflow_state => 'built_in').map(&:name).sort).to eq Role::BASE_TYPES.sort
    end

    it "should convert account_user membership_type column to role_id" do
      # shares same name as @account_role2, but belongs to @sub_account2
      account_role2_lookalike = create_role(@sub_account2, "accountrole2", 'AccountMembership')

      plain_au = @sub_sub_account.account_users.create!(:user => user_factory)
      role1_au = @sub_account1.account_users.create!(:user => user_factory, :role => @account_role1)
      role2_au = @sub_sub_account.account_users.create!(:user => user_factory, :role => @account_role2)
      lookalike_au = @sub_account2.account_users.create!(:user => user_factory, :role => account_role2_lookalike)

      @post_migration.down
      @pre_migration.down

      # make sure that the down undoes all the things
      AccountUser.reset_column_information
      expect(AccountUser.connection.select_value("SELECT membership_type FROM #{AccountUser.quoted_table_name} WHERE id=#{plain_au.id}")).to eq "AccountAdmin"
      expect(AccountUser.connection.select_value("SELECT membership_type FROM #{AccountUser.quoted_table_name} WHERE id=#{role1_au.id}")).to eq "accountrole1"
      expect(AccountUser.connection.select_value("SELECT membership_type FROM #{AccountUser.quoted_table_name} WHERE id=#{role2_au.id}")).to eq "accountrole2"
      expect(AccountUser.connection.select_value("SELECT membership_type FROM #{AccountUser.quoted_table_name} WHERE id=#{lookalike_au.id}")).to eq "accountrole2"

      @pre_migration.up
      AccountUser.reset_column_information

      # make sure the triggers work while they need to

      # with a built-in role
      id1 = AccountUser.connection.insert("INSERT INTO #{AccountUser.quoted_table_name}(
        account_id, user_id, membership_type, created_at, updated_at)
        VALUES(#{@sub_account1.id}, #{user_factory.id}, 'AccountAdmin', '2014-07-07', '2014-07-07')")
      expect(AccountUser.find(id1).role_id).to eq admin_role.id

      # with role 1 for @sub_account1
      id2 = AccountUser.connection.insert("INSERT INTO #{AccountUser.quoted_table_name}(
        account_id, user_id, membership_type, created_at, updated_at)
        VALUES(#{@sub_account1.id}, #{user_factory.id}, 'accountrole1', '2014-07-07', '2014-07-07')")
      expect(AccountUser.find(id2).role_id).to eq @account_role1.id

      # with role 2 for @sub_account1
      id3 = AccountUser.connection.insert("INSERT INTO #{AccountUser.quoted_table_name}(
        account_id, user_id, membership_type, created_at, updated_at)
        VALUES(#{@sub_account1.id}, #{user_factory.id}, 'accountrole2', '2014-07-07', '2014-07-07')")
      expect(AccountUser.find(id3).role_id).to eq @account_role2.id

      # with the role name meant for the lookalike
      id4 = AccountUser.connection.insert("INSERT INTO #{AccountUser.quoted_table_name}(
        account_id, user_id, membership_type, created_at, updated_at)
        VALUES(#{@sub_account2.id}, #{user_factory.id}, 'accountrole2', '2014-07-07', '2014-07-07')")
      expect(AccountUser.find(id4).role_id).to eq account_role2_lookalike.id

      # also make sure the data fixes worked
      expect(AccountUser.find(plain_au.id).role_id).to eq admin_role.id
      expect(AccountUser.find(role1_au.id).role_id).to eq @account_role1.id
      expect(AccountUser.find(role2_au.id).role_id).to eq @account_role2.id
      expect(AccountUser.find(lookalike_au.id).role_id).to eq account_role2_lookalike.id
    end

    it "should convert enrollment role_name column to role_id" do
      @user = user_factory
      @course_role2.update_attribute(:workflow_state, "inactive")
      ssa1_course = course_factory(:account => @sub_sub_account)
      sa2_course = course_factory(:account => @sub_account2)

      # shares same name as @course_role2, but belongs to @sub_account2
      course_role2_lookalike = create_role(@sub_account2, "courserole2", 'StudentEnrollment')

      plain_enrollment = ssa1_course.enroll_user(@user, 'StudentEnrollment')
      role1_enrollment = ssa1_course.enroll_user(@user, 'StudentEnrollment', :role => @course_role1)
      role2_enrollment = ssa1_course.enroll_user(@user, 'StudentEnrollment', :role => @course_role2)
      lookalike_enrollment = sa2_course.enroll_user(@user, 'StudentEnrollment', :role => course_role2_lookalike)

      @post_migration.down
      @pre_migration.down

      # make sure that the down undoes all the things
      Enrollment.reset_column_information
      expect(Enrollment.connection.select_value("SELECT role_name FROM #{Enrollment.quoted_table_name} WHERE id=#{plain_enrollment.id}")).to be_nil
      expect(Enrollment.connection.select_value("SELECT role_name FROM #{Enrollment.quoted_table_name} WHERE id=#{role1_enrollment.id}")).to eq "courserole1"
      expect(Enrollment.connection.select_value("SELECT role_name FROM #{Enrollment.quoted_table_name} WHERE id=#{role2_enrollment.id}")).to eq "courserole2"
      expect(Enrollment.connection.select_value("SELECT role_name FROM #{Enrollment.quoted_table_name} WHERE id=#{lookalike_enrollment.id}")).to eq "courserole2"

      @user2 = user_factory
      null_en_id = Enrollment.connection.insert("INSERT INTO #{Enrollment.quoted_table_name}(
        course_id, course_section_id, root_account_id, user_id, type, workflow_state, created_at, updated_at, role_name)
        VALUES(#{ssa1_course.id}, #{ssa1_course.default_section.id}, #{@root_account.id}, #{@user2.id},
          'StudentEnrollment', 'active', '2014-07-07', '2014-07-07', 'NonExistentRole')")

      @pre_migration.up
      Enrollment.reset_column_information

      # preserve the unique index by migrating missing roles to their own no-op roles
      null_role = Role.where(:name => 'NonExistentRole').first
      expect(null_role.base_role_type).to eq 'StudentEnrollment'
      expect(Enrollment.find(null_en_id).role_id).to eq null_role.id

      # make sure the triggers work while they need to

      # with no role name
      id1 = Enrollment.connection.insert("INSERT INTO #{Enrollment.quoted_table_name}(
        course_id, course_section_id, root_account_id, user_id, type, workflow_state, created_at, updated_at)
        VALUES(#{ssa1_course.id}, #{ssa1_course.default_section.id}, #{@root_account.id}, #{@user2.id},
          'StudentEnrollment', 'active', '2014-07-07', '2014-07-07')")
      expect(Enrollment.find(id1).role_id).to eq student_role.id

      # with a role name for course_role1
      id2 = Enrollment.connection.insert("INSERT INTO #{Enrollment.quoted_table_name}(
        course_id, course_section_id, root_account_id, user_id, type, role_name, workflow_state, created_at, updated_at)
        VALUES(#{ssa1_course.id}, #{ssa1_course.default_section.id}, #{@root_account.id}, #{@user2.id},
          'StudentEnrollment', 'courserole1', 'active', '2014-07-07', '2014-07-07')")
      expect(Enrollment.find(id2).role_id).to eq @course_role1.id

      # with a role name meant for the lookalike
      id3 = Enrollment.connection.insert("INSERT INTO #{Enrollment.quoted_table_name}(
        course_id, course_section_id, root_account_id, user_id, type, role_name, workflow_state, created_at, updated_at)
        VALUES(#{sa2_course.id}, #{sa2_course.default_section.id}, #{@root_account.id}, #{@user2.id},
          'StudentEnrollment', 'courserole2', 'active', '2014-07-07', '2014-07-07')")
      expect(Enrollment.find(id3).role_id).to eq course_role2_lookalike.id


      # also make sure the first round of data fixes worked
      expect(Enrollment.find(plain_enrollment.id).role_id).to be_nil # don't do this quite yet because there's an awful lot of plain enrollments

      expect(Enrollment.find(role1_enrollment.id).role_id).to eq @course_role1.id
      expect(Enrollment.find(role2_enrollment.id).role_id).to eq @course_role2.id
      expect(Enrollment.find(lookalike_enrollment.id).role_id).to eq course_role2_lookalike.id

      @post_migration.up

      Enrollment.reset_column_information
      # now the delayed job fixup for the plain enrollments should have worked
      expect(Enrollment.find(plain_enrollment.id).role_id).to eq student_role.id
    end

    it "should convert role_override enrollment_type column to role_id" do
      # shares same name as @account_role2, but belongs to @sub_account2
      account_role2_lookalike = create_role(@sub_account2, "accountrole2", 'AccountMembership')

      plain_ro = @sub_account1.role_overrides.create!(:permission => 'manage_content',
                                                      :role => teacher_role)
      role1_ro = @sub_account1.role_overrides.create!(:permission => 'manage_content', :role => @account_role1)
      role2_ro = @sub_sub_account.role_overrides.create!(:permission => 'manage_content', :role => @account_role2)
      lookalike_ro = @sub_account2.role_overrides.create!(:permission => 'manage_content', :role => account_role2_lookalike)

      @post_migration.down
      @pre_migration.down

      # make sure that the down undoes all the things
      RoleOverride.reset_column_information
      expect(RoleOverride.connection.select_value("SELECT enrollment_type FROM #{RoleOverride.quoted_table_name} WHERE id=#{plain_ro.id}")).to eq "TeacherEnrollment"
      expect(RoleOverride.connection.select_value("SELECT enrollment_type FROM #{RoleOverride.quoted_table_name} WHERE id=#{role1_ro.id}")).to eq "accountrole1"
      expect(RoleOverride.connection.select_value("SELECT enrollment_type FROM #{RoleOverride.quoted_table_name} WHERE id=#{role2_ro.id}")).to eq "accountrole2"
      expect(RoleOverride.connection.select_value("SELECT enrollment_type FROM #{RoleOverride.quoted_table_name} WHERE id=#{lookalike_ro.id}")).to eq "accountrole2"

      @pre_migration.up
      RoleOverride.reset_column_information

      # make sure the triggers work while they need to

      # with a built-in role
      id1 = RoleOverride.connection.insert("INSERT INTO #{RoleOverride.quoted_table_name}(
        context_id, context_type, enrollment_type, created_at, updated_at)
        VALUES(#{@sub_account1.id}, 'Account', 'TeacherEnrollment', '2014-07-07', '2014-07-07')")
      expect(RoleOverride.find(id1).role_id).to eq teacher_role.id

      # with role 1 for @sub_account1
      id2 = RoleOverride.connection.insert("INSERT INTO #{RoleOverride.quoted_table_name}(
        context_id, context_type, enrollment_type, created_at, updated_at)
        VALUES(#{@sub_account1.id}, 'Account', 'accountrole1', '2014-07-07', '2014-07-07')")
      expect(RoleOverride.find(id2).role_id).to eq @account_role1.id

      # with role 2 for @sub_account1
      id3 = RoleOverride.connection.insert("INSERT INTO #{RoleOverride.quoted_table_name}(
        context_id, context_type, enrollment_type, created_at, updated_at)
        VALUES(#{@sub_account1.id}, 'Account', 'accountrole2', '2014-07-07', '2014-07-07')")
      expect(RoleOverride.find(id3).role_id).to eq @account_role2.id

      # with the role name meant for the lookalike
      id4 = RoleOverride.connection.insert("INSERT INTO #{RoleOverride.quoted_table_name}(
        context_id, context_type, enrollment_type, created_at, updated_at)
        VALUES(#{@sub_account2.id}, 'Account', 'accountrole2', '2014-07-07', '2014-07-07')")
      expect(RoleOverride.find(id4).role_id).to eq account_role2_lookalike.id

      # also make sure the data fixes worked
      expect(RoleOverride.find(plain_ro.id).role_id).to eq teacher_role.id
      expect(RoleOverride.find(role1_ro.id).role_id).to eq @account_role1.id
      expect(RoleOverride.find(role2_ro.id).role_id).to eq @account_role2.id
      expect(RoleOverride.find(lookalike_ro.id).role_id).to eq account_role2_lookalike.id
    end

    it "should convert account_notification_roles role_type column to role_id" do
      # shares same name as @account_role2, but belongs to @sub_account2
      account_role2_lookalike = create_role(@sub_account2, "accountrole2", 'AccountMembership')

      an1 = account_notification(:account => @sub_account1,
        :role_ids => [teacher_role.id, @account_role2.id])
      an2 = account_notification(:account => @sub_account2,
       :role_ids => [account_role2_lookalike.id, nil])

      @post_migration.down
      @pre_migration.down

      # make sure that the down undoes all the things
      AccountNotificationRole.reset_column_information
      expect(AccountNotificationRole.connection.select_values("SELECT role_type FROM #{AccountNotificationRole.quoted_table_name} WHERE account_notification_id=#{an1.id}").sort).to eq ["accountrole2", "TeacherEnrollment"].sort
      expect(AccountNotificationRole.connection.select_values("SELECT role_type FROM #{AccountNotificationRole.quoted_table_name} WHERE account_notification_id=#{an2.id}").sort).to eq ["accountrole2", "NilEnrollment"].sort

      null_anr_id = AccountNotificationRole.connection.insert("INSERT INTO #{AccountNotificationRole.quoted_table_name}(
        account_notification_id, role_type)
        VALUES(#{an1.id}, 'NonExistentRole')")

      @pre_migration.up
      AccountNotificationRole.reset_column_information

      expect(AccountNotificationRole.where(:id => null_anr_id).first).to be_nil

      # make sure the data fixes worked
      expect(AccountNotificationRole.where(:account_notification_id => an1.id).map(&:role_id).sort).to eq(
          [teacher_role.id, @account_role2.id].sort)
      role_ids = AccountNotificationRole.where(:account_notification_id => an2.id).map(&:role_id)
      expect(role_ids).to include(account_role2_lookalike.id)
      expect(role_ids).to include(nil) # for NilEnrollment

      AccountNotificationRole.where(:account_notification_id => an1.id).delete_all
      AccountNotificationRole.where(:account_notification_id => an2.id).delete_all

      # make sure the triggers work while they need to

      # with a built-in role
      id1 = AccountNotificationRole.connection.insert("INSERT INTO #{AccountNotificationRole.quoted_table_name}(
        account_notification_id, role_type)
        VALUES(#{an1.id}, 'AccountAdmin')")
      expect(AccountNotificationRole.find(id1).role_id).to eq admin_role.id

      # with role 1 for @sub_account1
      id2 = AccountNotificationRole.connection.insert("INSERT INTO #{AccountNotificationRole.quoted_table_name}(
        account_notification_id, role_type)
        VALUES(#{an1.id}, 'accountrole1')")
      expect(AccountNotificationRole.find(id2).role_id).to eq @account_role1.id

      # with the role name meant for the lookalike
      id3 = AccountNotificationRole.connection.insert("INSERT INTO #{AccountNotificationRole.quoted_table_name}(
        account_notification_id, role_type)
        VALUES(#{an2.id}, 'accountrole2')")
      expect(AccountNotificationRole.find(id3).role_id).to eq account_role2_lookalike.id
    end

    it "should convert alert recipients to role objects" do
      # shares same name as @account_role2, but belongs to @sub_account2
      account_role2_lookalike = create_role(@sub_account2, "accountrole2", 'AccountMembership')

      alert1 = Alert.create!(:context => @sub_sub_account,
                             :recipients => [:student, {:role_id => admin_role.id}, {:role_id => @account_role1.id}],
                             :criteria => [{:criterion_type => 'Interaction', :threshold => 1}])
      alert2 = Alert.create!(:context => @sub_account2, :recipients => [{:role_id => account_role2_lookalike.id}],
                             :criteria => [{:criterion_type => 'Interaction', :threshold => 1}])

      @post_migration.down
      @pre_migration.down

      # make sure that the down undoes all the things
      expect(Alert.find(alert1.id).recipients).to eq [:student, "AccountAdmin", "accountrole1"]
      expect(Alert.find(alert2.id).recipients).to eq ["accountrole2"]

      @pre_migration.up
      @post_migration.up

      expect(Alert.find(alert1.id).recipients).to eq [:student, {:role_id => admin_role.id},  {:role_id => @account_role1.id}]
      expect(Alert.find(alert2.id).recipients).to eq [{:role_id => account_role2_lookalike.id}]
    end
  end
end
