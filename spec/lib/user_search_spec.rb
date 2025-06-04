# frozen_string_literal: true

# Copyright (C) 2012 - present Instructure, Inc.
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

describe UserSearch do
  describe ".for_user_in_context" do
    let(:search_names) { ["Rose Tyler", "Martha Jones", "Rosemary Giver", "Martha Stewart", "Tyler Pickett", "Jon Stewart", "Stewart Little", "Ĭńşŧřůćƭǜȑȩ Person"] }
    let(:course) { Course.create!(workflow_state: "available") }
    let(:users) { UserSearch.for_user_in_context("Stewart", course, user, nil, sort: "username", order: "asc").to_a }
    let(:names) { users.map(&:name) }
    let(:user) { User.last }
    let(:student) { User.where(name: search_names.last).first }

    before do
      teacher = User.create!(name: "Tyler Teacher")
      TeacherEnrollment.create!(user: teacher, course:, workflow_state: "active")
      search_names.each do |name|
        student = User.create!(name:)
        StudentEnrollment.create!(user: student, course:, workflow_state: "active")
      end
      User.create!(name: "admin")
      TeacherEnrollment.create!(user:, course:, workflow_state: "active")
    end

    describe "when excluding a group" do
      it "does not include users in that group" do
        group = Group.create! name: "test", context: course
        group.add_user user
        expect(UserSearch.for_user_in_context("admin", course, user, nil, exclude_groups: [group.id]).size).to eq 0
      end
    end

    it "searches case-insensitively" do
      expect(UserSearch.for_user_in_context("steWArt", course, user).size).to eq 3
    end

    it "uses postgres lower(), not ruby downcase()" do
      # ruby 1.9 downcase doesn't handle the downcasing of many multi-byte characters correctly
      expect(UserSearch.for_user_in_context("Ĭńşŧřůćƭǜȑȩ", course, user).size).to eq 1
    end

    it "returns an enumerable" do
      expect(users.size).to eq 3
    end

    it "contains the matching users" do
      expect(names).to include("Martha Stewart")
      expect(names).to include("Stewart Little")
      expect(names).to include("Jon Stewart")
    end

    it "does not contain users I am not allowed to see" do
      unenrolled_user = User.create!(name: "Unenrolled User")
      search_results = UserSearch.for_user_in_context("Stewart", course, unenrolled_user).map(&:name)
      expect(search_results).to eq []
    end

    it "will not pickup students outside the course" do
      User.create!(name: "Stewart Stewart")
      # names is evaluated lazily from the 'let' block so ^ user is still being
      # created before the query executes
      expect(names).not_to include("Stewart Stewart")
    end

    it "will find teachers" do
      results = UserSearch.for_user_in_context("Tyler", course, user)
      expect(results.map(&:name)).to include("Tyler Teacher")
    end

    it "sorts by name" do
      expect(names.size).to eq 3
      expect(names[0]).to eq "Stewart Little"
      expect(names[1]).to eq "Jon Stewart"
      expect(names[2]).to eq "Martha Stewart"
    end

    describe "filtering by role" do
      subject { names }

      describe "to a single role" do
        let(:users) { UserSearch.for_user_in_context("Tyler", course, user, nil, enrollment_type: "student").to_a }

        it { is_expected.to include("Rose Tyler") }
        it { is_expected.to include("Tyler Pickett") }
        it { is_expected.not_to include("Tyler Teacher") }
      end

      describe "to multiple roles" do
        let(:users) { UserSearch.for_user_in_context("Tyler", course, student, nil, enrollment_type: ["ta", "teacher"]).to_a }

        before do
          ta = User.create!(name: "Tyler TA")
          TaEnrollment.create!(user: ta, course:, workflow_state: "active")
        end

        it { is_expected.to include("Tyler TA") }
        it { is_expected.to include("Tyler Teacher") }
        it { is_expected.not_to include("Rose Tyler") }
      end

      describe "FooEnrollment names" do
        let(:users) { UserSearch.for_user_in_context("Tyler", course, user, nil, enrollment_type: "StudentEnrollment").to_a }

        it { is_expected.to include("Rose Tyler") }
        it { is_expected.to include("Tyler Pickett") }
        it { is_expected.not_to include("Tyler Teacher") }
      end

      describe "with the broader role parameter" do
        let(:users) { UserSearch.for_user_in_context("Tyler", course, student, nil, enrollment_role: "ObserverEnrollment").to_a }

        before do
          ta = User.create!(name: "Tyler Observer")
          ObserverEnrollment.create!(user: ta, course:, workflow_state: "active")
          ta2 = User.create!(name: "Tyler Observer 2")
          ObserverEnrollment.create!(user: ta2, course:, workflow_state: "active")
          add_linked_observer(student, ta2)
        end

        it { is_expected.not_to include("Tyler Observer 2") }
        it { is_expected.not_to include("Tyler Observer") }
        it { is_expected.not_to include("Tyler Teacher") }
        it { is_expected.not_to include("Rose Tyler") }
      end

      describe "with the role name parameter" do
        before do
          newstudent = User.create!(name: "Tyler Student")
          StudentEnrollment.create!(user: newstudent, course:, workflow_state: "active")
        end

        describe "when the context is a course" do
          let(:users) { UserSearch.for_user_in_context("Tyler", course, user, nil, enrollment_role: "StudentEnrollment").to_a }

          it { is_expected.to include("Rose Tyler") }
          it { is_expected.to include("Tyler Pickett") }
          it { is_expected.to include("Tyler Student") }
          it { is_expected.not_to include("Tyler Teacher") }
        end

        describe "when the context is an account" do
          let(:users) { UserSearch.for_user_in_context("Tyler", course.account, user, nil, enrollment_role: "StudentEnrollment").to_a }

          it { is_expected.to include("Rose Tyler") }
          it { is_expected.to include("Tyler Pickett") }
          it { is_expected.to include("Tyler Student") }
          it { is_expected.not_to include("Tyler Teacher") }
        end
      end

      describe "with the role id parameter" do
        let(:users) { UserSearch.for_user_in_context("Tyler", course, student, nil, enrollment_role_id: student_role.id).to_a }

        before do
          newstudent = User.create!(name: "Tyler Student")
          StudentEnrollment.create!(user: newstudent, course:, workflow_state: "active")
        end

        it { is_expected.to include("Rose Tyler") }
        it { is_expected.to include("Tyler Pickett") }
        it { is_expected.to include("Tyler Student") }
        it { is_expected.not_to include("Tyler Teacher") }

        it "does not return results if role id is invalid" do
          expect(UserSearch.for_user_in_context("", course, student, nil, enrollment_role_id: student_role.id + 99_999).size).to eq 0
        end
      end
    end

    describe "searching on logins" do
      let(:pseudonym) { user.pseudonyms.build }

      before do
        pseudonym.sis_user_id = "SOME_SIS_ID"
        pseudonym.unique_id = "SOME_UNIQUE_ID@example.com"
        pseudonym.integration_id = "ACME_123"
        pseudonym.current_login_at = Time.utc(2019, 11, 11)
        pseudonym.save!
      end

      it "will match against an sis id" do
        expect(UserSearch.for_user_in_context("SOME_SIS", course, user)).to eq [user]
      end

      it "will match against an integration id" do
        expect(UserSearch.for_user_in_context("ACME", course, user)).to eq [user]
      end

      describe "will match against a suspended user" do
        before do
          pseudonym.workflow_state = "suspended"
          pseudonym.save!
        end

        it "by sis id" do
          expect(UserSearch.for_user_in_context("SOME_SIS", course, user)).to eq [user]
        end

        it "by integration id" do
          expect(UserSearch.for_user_in_context("ACME", course, user)).to eq [user]
        end

        it "by user name" do
          expect(UserSearch.for_user_in_context("admin", course, user)).to eq [user]
        end
      end

      describe "will match deleted users/pseudonyms if including deleted users" do
        before do
          pseudonym.update(workflow_state: "deleted")
          user.update(workflow_state: "pre_registered")
          account_admin_user
          @account = Account.default
        end

        it "by sis id" do
          expect(UserSearch.for_user_in_context("SOME_SIS", @account, @user, nil, { include_deleted_users: true })).to eq [user]
        end

        it "by integration id" do
          expect(UserSearch.for_user_in_context("ACME", @account, @user, nil, { include_deleted_users: true })).to eq [user]
        end

        it "by user name" do
          expect(UserSearch.for_user_in_context("admin", @account, @user, nil, { include_deleted_users: true })).to eq [user]
        end

        it "by user id" do
          expect(UserSearch.for_user_in_context(user.id, @account, @user, nil, { include_deleted_users: true })).to eq [user]
        end
      end

      it "will not match against a sis id without :read_sis permission" do
        RoleOverride.create!(context: Account.default,
                             role: teacher_role,
                             permission: "read_sis",
                             enabled: false)
        expect(UserSearch.for_user_in_context("SOME_SIS", course, user)).to eq []
      end

      it "will not match against an integration id without :read_sis permission" do
        RoleOverride.create!(context: Account.default,
                             role: teacher_role,
                             permission: "read_sis",
                             enabled: false)
        expect(UserSearch.for_user_in_context("ACME", course, user)).to eq []
      end

      it "will match against an sis id and regular id" do
        user2 = User.create(name: "user two")
        pseudonym.sis_user_id = user2.id.to_s
        pseudonym.save!
        course.enroll_user(user2)
        expect(UserSearch.for_user_in_context(user2.id.to_s, course, user)).to eq [user, user2]
      end

      it "handles search terms out of bounds for max bigint" do
        pseudonym.sis_user_id = "9223372036854775808"
        pseudonym.save!
        expect(UserSearch.for_user_in_context("9223372036854775808", course, user)).to eq [user]
      end

      it "will match against a login id" do
        expect(UserSearch.for_user_in_context("UNIQUE_ID", course, user)).to eq [user]
      end

      it "will not search login id without permission" do
        RoleOverride.create!(context: Account.default,
                             role: teacher_role,
                             permission: "view_user_logins",
                             enabled: false)
        expect(UserSearch.for_user_in_context("UNIQUE_ID", course, user)).to eq []
      end

      it "returns the last_login column when searching and sorting" do
        results = UserSearch.for_user_in_context("UNIQUE_ID", course, user, nil, sort: "last_login")
        expect(results.first["last_login"]).to eq(Time.utc(2019, 11, 11))
      end

      it "can match an SIS id and a user name in the same query" do
        pseudonym.sis_user_id = "MARTHA_SIS_ID"
        pseudonym.save!
        other_user = User.where(name: "Martha Stewart").first
        results = UserSearch.for_user_in_context("martha", course, user)
        expect(results).to include(user)
        expect(results).to include(other_user)
      end

      it "sorts by sis id" do
        User.find_by(name: "Rose Tyler").pseudonyms.create!(unique_id: "rose.tyler@example.com",
                                                            sis_user_id: "25rose",
                                                            account_id: course.root_account_id)
        User.find_by(name: "Tyler Pickett").pseudonyms.create!(unique_id: "tyler.pickett@example.com",
                                                               sis_user_id: "1tyler",
                                                               account_id: course.root_account_id)
        users = UserSearch.for_user_in_context("Tyler", course, user, nil, sort: "sis_id")
        expect(users.map(&:name)).to eq ["Tyler Pickett", "Rose Tyler", "Tyler Teacher"]
      end

      it "sorts by integration id" do
        User.find_by(name: "Rose Tyler").pseudonyms.create!(unique_id: "rose.tyler@example.com",
                                                            integration_id: "25rose",
                                                            account_id: course.root_account_id)
        User.find_by(name: "Tyler Pickett").pseudonyms.create!(unique_id: "tyler.pickett@example.com",
                                                               integration_id: "1tyler",
                                                               account_id: course.root_account_id)
        users = UserSearch.for_user_in_context("Tyler", course, user, nil, sort: "integration_id")
        expect(users.map(&:name)).to eq ["Tyler Pickett", "Rose Tyler", "Tyler Teacher"]
      end

      it "chooses user pseudonym based on collation_key" do
        # the unique_id "a" is the chosen pseudonym since we sort by collation_key
        User.find_by(name: "Rose Tyler").pseudonyms.create!(unique_id: "b", sis_user_id: "9", account_id: course.root_account_id)
        User.find_by(name: "Rose Tyler").pseudonyms.create!(unique_id: "a", sis_user_id: "1", account_id: course.root_account_id)
        User.find_by(name: "Tyler Pickett").pseudonyms.create!(unique_id: "tyler.pickett@example.com",
                                                               sis_user_id: "5",
                                                               account_id: course.root_account_id)
        users = UserSearch.for_user_in_context("Tyler", course, user, nil, sort: "sis_id")
        expect(users.map(&:name)).to eq ["Rose Tyler", "Tyler Pickett", "Tyler Teacher"]
      end

      it "does not return users twice if it matches their name and an old login" do
        tyler = User.find_by(name: "Tyler Pickett")
        tyler.pseudonyms.create!(unique_id: "Yo", account_id: course.root_account_id, current_login_at: Time.zone.now)
        tyler.pseudonyms.create!(unique_id: "Pickett", account_id: course.root_account_id, current_login_at: 1.week.ago)
        users = UserSearch.for_user_in_context("Pickett", course, user, nil, sort: "username")
        expect(users.map(&:name)).to eq ["Tyler Pickett"]
      end
    end

    describe "searching on emails" do
      let(:user1) { user_with_pseudonym(user:) }
      let(:cc) { communication_channel(user1, { username: "the.giver@example.com" }) }

      before do
        cc.confirm!
      end

      it "matches against an email" do
        expect(UserSearch.for_user_in_context("the.giver", course, user)).to eq [user]
      end

      it "requires :read_email_addresses permission" do
        RoleOverride.create!(context: Account.default,
                             role: teacher_role,
                             permission: "read_email_addresses",
                             enabled: false)
        expect(UserSearch.for_user_in_context("the.giver", course, user)).to eq []
      end

      it "can match an email and a name in the same query" do
        results = UserSearch.for_user_in_context("giver", course, user)
        expect(results).to include(user)
        expect(results).to include(User.where(name: "Rosemary Giver").first)
      end

      it "will not match channels where the type is not email" do
        cc.update!(path_type: CommunicationChannel::TYPE_SMS)
        expect(UserSearch.for_user_in_context("the.giver", course, user)).to eq []
      end

      it "doesn't match retired channels" do
        cc.retire!
        expect(UserSearch.for_user_in_context("the.giver", course, user)).to eq []
      end

      it "matches unconfirmed channels", priority: 1 do
        communication_channel(user, { username: "unconfirmed@example.com" })
        expect(UserSearch.for_user_in_context("unconfirmed", course, user)).to eq [user]
      end

      it "sorts by email" do
        communication_channel(User.find_by(name: "Tyler Pickett"), { username: "1tyler@example.com" })
        communication_channel(User.find_by(name: "Tyler Teacher"), { username: "25teacher@example.com" })
        users = UserSearch.for_user_in_context("Tyler", course, user, nil, sort: "email")
        expect(users.map(&:name)).to eq ["Tyler Pickett", "Tyler Teacher", "Rose Tyler"]
      end
    end

    describe "searching by a DB ID" do
      it "matches against the database id" do
        expect(UserSearch.for_user_in_context(user.id, course, user)).to eq [user]
      end

      it "matches against a database id and a user simultaneously" do
        other_user = student_in_course(course:, name: user.id.to_s).user
        expect(UserSearch.for_user_in_context(user.id, course, user)).to match_array [user, other_user]
      end

      describe "cross-shard users" do
        specs_require_sharding

        it "matches against the database id of a cross-shard user" do
          user = @shard1.activate { user_model }
          course.enroll_student(user)
          expect(UserSearch.for_user_in_context(user.global_id, course, user)).to eq [user]
          expect(UserSearch.for_user_in_context(user.global_id, course.account, user)).to eq [user]
        end

        it "doesn't try to query cross-shard when the search term is a foreign global id in account context with include_deleted_users" do
          user = @shard1.activate { user_model }
          course.enroll_student(user)
          scope = UserSearch.for_user_in_context(user.global_id, Account.default, account_admin_user, nil, include_deleted_users: true)
          sql = scope.to_sql
          expect(sql).to include user.global_id.to_s
          expect(sql).not_to include(@shard1.activate { User.quoted_table_name })
          expect(scope).to include user
        end
      end
    end

    describe "account user search with search term" do
      subject { names }

      before { Setting.set("user_search_with_full_complexity", "true") }

      let(:course1) { Course.create!(workflow_state: "available") }

      let(:user_names_not_enrolled) { ["not enrolled Tyler 01", "not enrolled 02"] }

      let(:user_names_enrolled_in_course1) { ["enrolled 01", "enrolled Tyler 02"] }

      let(:teacher_names_enrolled_in_course1) { ["enrolled teacher Tyler 01", "enrolled teacher 02"] }

      before do
        user_names_not_enrolled.each do |name|
          User.create!(name:)
        end

        user_names_enrolled_in_course1.each do |name|
          student = User.create!(name:)
          StudentEnrollment.create!(user: student, course: course1, workflow_state: "active")
        end

        teacher_names_enrolled_in_course1.each do |name|
          teacher = User.create!(name:)
          TeacherEnrollment.create!(user: teacher, course: course1, workflow_state: "active")
        end
      end

      describe "to a single role" do
        let(:users) { UserSearch.for_user_in_context("Tyler", course.account, user, nil, enrollment_type: "student").to_a }

        it { is_expected.to include("Rose Tyler") }
        it { is_expected.to include("Tyler Pickett") }
        # include students from different courses
        it { is_expected.to include("enrolled Tyler 02") }
        # don't include teachers
        it { is_expected.not_to include("enrolled teacher Tyler 01") }
        # don't include users not enrolled
        it { is_expected.not_to include("not enrolled Tyler 01") }
      end

      describe "to multiple roles" do
        let(:users) { UserSearch.for_user_in_context("Tyler", course.account, user, nil, enrollment_type: ["student", "teacher"]).to_a }

        it { is_expected.to include("Rose Tyler") }
        it { is_expected.to include("Tyler Pickett") }
        # include students from different courses
        it { is_expected.to include("enrolled Tyler 02") }
        # include teachers
        it { is_expected.to include("enrolled teacher Tyler 01") }
        # don't include users not enrolled
        it { is_expected.not_to include("not enrolled Tyler 01") }
      end

      describe "deleted users" do
        before :once do
          user_with_pseudonym(name: "Deleted User")
          @user.remove_from_root_account(course.account)
        end

        it "doesn't include deleted users" do
          users = UserSearch.for_user_in_context("Deleted", course.account, user, nil, sort: "username", order: "asc").to_a
          expect(users).not_to include(@user)
        end

        it "includes deleted users with option" do
          users = UserSearch.for_user_in_context("Deleted", course.account, user, nil, sort: "username", order: "asc", include_deleted_users: true).to_a
          expect(users).to include(@user)
        end
      end
    end
  end

  describe ".like_string_for" do
    it "modulos both sides" do
      expect(UserSearch.like_string_for("word")).to eq "%word%"
    end
  end

  describe ".scope_for" do
    let(:search_names) do
      ["Rose Tyler",
       "Martha Jones",
       "Rosemary Giver",
       "Martha Stewart",
       "Tyler Pickett",
       "Jon Stewart",
       "Stewart Little",
       "Ĭńşŧřůćƭǜȑȩ Person"]
    end

    let(:course) { Course.create!(workflow_state: "available") }
    let(:users) { UserSearch.scope_for(course, user, sort: "username", order: "desc").to_a }
    let(:names) { users.map(&:name) }
    let(:user) { User.last }
    let(:student) { User.where(name: search_names.last).first }

    before do
      search_names.each do |name|
        student = User.create!(name:)
        StudentEnrollment.create!(user: student, course:, workflow_state: "active")
      end
    end

    it "sorts by name desc" do
      expect(names.size).to eq 8
      expect(names[0]).to eq "Rose Tyler"
      expect(names[1]).to eq "Martha Stewart"
      expect(names[2]).to eq "Jon Stewart"
      expect(names[3]).to eq "Tyler Pickett"
      expect(names[4]).to eq "Ĭńşŧřůćƭǜȑȩ Person"
      expect(names[5]).to eq "Stewart Little"
      expect(names[6]).to eq "Martha Jones"
      expect(names[7]).to eq "Rosemary Giver"
    end

    it "raises an error if there is a bad enrollment type" do
      course = Course.create!
      student = User.create!
      bad_scope = -> { UserSearch.scope_for(course, student, enrollment_type: "all") }
      expect(&bad_scope).to raise_error(RequestError, "Invalid enrollment type: all")
    end

    it "doesn't explode with group context" do
      course_with_student
      group = @course.groups.create!
      group.add_user(@student)
      account_admin_user
      expect(UserSearch.scope_for(group, @admin, enrollment_type: ["student"], include_inactive_enrollments: true).to_a).to eq [@student]
      expect(UserSearch.scope_for(group, @admin, enrollment_type: ["teacher"]).to_a).to be_empty
    end

    describe "account user list filtering by role" do
      subject { names }

      let(:course1) { Course.create!(workflow_state: "available") }

      let(:user_names_not_enrolled) { ["not enrolled 01", "not enrolled 02"] }

      let(:user_names_enrolled_in_course1) { ["enrolled 01", "enrolled 02"] }

      let(:teacher_names_enrolled_in_course1) { ["enrolled teacher 01", "enrolled teacher 02"] }

      before do
        user_names_not_enrolled.each do |name|
          User.create!(name:)
        end

        user_names_enrolled_in_course1.each do |name|
          student = User.create!(name:)
          StudentEnrollment.create!(user: student, course: course1, workflow_state: "active")
        end

        teacher_names_enrolled_in_course1.each do |name|
          teacher = User.create!(name:)
          TeacherEnrollment.create!(user: teacher, course: course1, workflow_state: "active")
        end
      end

      describe "to a single role" do
        let(:users) { UserSearch.scope_for(course.account, nil, enrollment_type: "student").to_a }

        it { is_expected.to include("Rose Tyler") }
        it { is_expected.to include("Tyler Pickett") }
        # include students from different courses
        it { is_expected.to include("enrolled 01") }
        it { is_expected.to include("enrolled 02") }
        # don't include teachers
        it { is_expected.not_to include("enrolled teacher 01") }
        it { is_expected.not_to include("enrolled teacher 02") }
        # don't include users not enrolled
        it { is_expected.not_to include("not enrolled 01") }
        it { is_expected.not_to include("not enrolled 02") }
      end

      describe "to multiple roles" do
        let(:users) { UserSearch.scope_for(course.account, nil, enrollment_type: ["student", "teacher"]).to_a }

        it { is_expected.to include("Rose Tyler") }
        it { is_expected.to include("Tyler Pickett") }
        # include students from different courses
        it { is_expected.to include("enrolled 01") }
        it { is_expected.to include("enrolled 02") }
        # include teachers
        it { is_expected.to include("enrolled teacher 01") }
        it { is_expected.to include("enrolled teacher 02") }
        # don't include users not enrolled
        it { is_expected.not_to include("not enrolled 01") }
        it { is_expected.not_to include("not enrolled 02") }
      end
    end

    describe "sorting" do
      before do
        @test_teacher = User.create!(name: "Woody Walton")
        TeacherEnrollment.create!(user: @test_teacher, course:, workflow_state: "active")
        @sorted_by_name = ["Ĭńşŧřůćƭǜȑȩ Person", "Jon Stewart", "Martha Jones", "Martha Stewart", "Rose Tyler", "Rosemary Giver", "Stewart Little", "Tyler Pickett", "Woody Walton"]
      end

      describe "single value columns" do
        context "name" do
          it "sorts by name ascending" do
            users = UserSearch.scope_for(course, @test_teacher, sort: "name", order: "asc").to_a
            expect(users.map(&:name)).to eq @sorted_by_name
          end

          it "sorts by name descending" do
            users = UserSearch.scope_for(course, @test_teacher, sort: "name", order: "desc").to_a
            expect(users.map(&:name)).to eq @sorted_by_name.reverse
          end
        end

        context "login_id" do
          before do
            User.find_by(name: "Rose Tyler").pseudonyms.create!(unique_id: "tyler@example.com", account_id: course.root_account_id)
            User.find_by(name: "Tyler Pickett").pseudonyms.create!(unique_id: "pickett@example.com", account_id: course.root_account_id)
          end

          it "sorts by login_id ascending" do
            users = UserSearch.scope_for(course, @test_teacher, sort: "login_id", order: "asc").to_a
            login_ids = users.map { |u| u.pseudonyms&.first&.unique_id }

            expect(login_ids).to include("pickett@example.com")
            expect(login_ids).to include("tyler@example.com")
            expect(login_ids[0..1]).to eq ["pickett@example.com", "tyler@example.com"]
          end

          it "sorts by login_id descending" do
            users = UserSearch.scope_for(course, @test_teacher, sort: "login_id", order: "desc").to_a
            login_ids = users.map { |u| u.pseudonyms&.first&.unique_id }

            expect(login_ids).to include("tyler@example.com")
            expect(login_ids).to include("pickett@example.com")
            expect(login_ids[0..1]).to eq ["tyler@example.com", "pickett@example.com"]
          end

          context "with include_deleted_users" do
            before do
              @deleted_user = User.create!(name: "Deleted User")
              User.find_by(name: "Deleted User").pseudonyms.create!(unique_id: "deleted@example.com", account_id: course.root_account_id)
              @deleted_user.remove_from_root_account(course.root_account)
            end

            describe "when include_deleted_users is true" do
              it "includes deleted users when sorting by login_id ascending" do
                users = UserSearch.scope_for(course.root_account, @test_teacher, sort: "login_id", order: "asc", include_deleted_users: true).to_a
                login_ids = users.map { |u| u.pseudonyms&.first&.unique_id }

                expect(login_ids).to include("deleted@example.com")
                expect(login_ids).to include("pickett@example.com")
                expect(login_ids).to include("tyler@example.com")
                expect(login_ids[0..2]).to eq ["deleted@example.com", "pickett@example.com", "tyler@example.com"]
              end

              it "includes deleted users when sorting by login_id descending" do
                users = UserSearch.scope_for(course.root_account, @test_teacher, sort: "login_id", order: "desc", include_deleted_users: true).to_a
                login_ids = users.map { |u| u.pseudonyms&.first&.unique_id }

                expect(login_ids).to include("tyler@example.com")
                expect(login_ids).to include("pickett@example.com")
                expect(login_ids).to include("deleted@example.com")
                expect(login_ids[0..2]).to eq ["tyler@example.com", "pickett@example.com", "deleted@example.com"]
              end
            end

            describe "when include_deleted_users is false (default)" do
              it "excludes deleted users when sorting by login_id ascending" do
                users = UserSearch.scope_for(course.root_account, @test_teacher, sort: "login_id", order: "asc").to_a
                login_ids = users.map { |u| u.pseudonyms&.first&.unique_id }

                expect(login_ids).not_to include("deleted@example.com")
                expect(login_ids).to include("pickett@example.com")
                expect(login_ids).to include("tyler@example.com")
                expect(login_ids[0..1]).to eq ["pickett@example.com", "tyler@example.com"]
              end

              it "excludes deleted users when sorting by login_id descending" do
                users = UserSearch.scope_for(course.root_account, @test_teacher, sort: "login_id", order: "desc").to_a
                login_ids = users.map { |u| u.pseudonyms&.first&.unique_id }

                expect(login_ids).not_to include("deleted@example.com")
                expect(login_ids).to include("pickett@example.com")
                expect(login_ids).to include("tyler@example.com")
                expect(login_ids[0..1]).to eq ["tyler@example.com", "pickett@example.com"]
              end
            end
          end
        end

        context "total_activity_time" do
          before do
            User.find_by(name: "Rose Tyler").enrollments&.first&.update!(total_activity_time: 100)
            User.find_by(name: "Tyler Pickett").enrollments&.first&.update!(total_activity_time: 200)
          end

          it "sorts by total activity time ascending" do
            users = UserSearch.scope_for(course, @test_teacher, sort: "total_activity_time", order: "asc").to_a
            total_activity_times = users.map { |u| u.enrollments&.first&.total_activity_time }

            expect(total_activity_times[0..1]).to eq [100, 200]
          end

          it "sorts by total activity time descending" do
            users = UserSearch.scope_for(course, @test_teacher, sort: "total_activity_time", order: "desc").to_a
            total_activity_times = users.map { |u| u.enrollments&.first&.total_activity_time }

            expect(total_activity_times[0..1]).to eq [200, 100]
          end

          it "raises an error when context is not a course" do
            account = Account.create!
            expect do
              UserSearch.scope_for(account, @test_teacher, sort: "total_activity_time", order: "asc")
            end.to raise_error(RequestError, "Sorting by total_activity_time is only available within a course context")
          end
        end
      end

      describe "multiple value columns" do
        let(:course2) { Course.create! }
        let(:teacher1) { user_model(name: "Teacher One") }
        let(:ta1) { user_model(name: "TA One") }
        let(:student1) { user_model(name: "Student One") }
        let(:student2) { user_model(name: "Student Two") }
        let(:observer1) { user_model(name: "Observer One") }
        let(:designer1) { user_model(name: "Designer One") }
        let(:section1) { course2.course_sections.create!(name: "A Section") }
        let(:section2) { course2.course_sections.create!(name: "B Section") }
        let(:section3) { course2.course_sections.create!(name: "C Section") }
        let(:section4) { course2.course_sections.create!(name: "D Section") }
        let(:section5) { course2.course_sections.create!(name: "E Section") }
        let(:section6) { course2.course_sections.create!(name: "F Section") }
        let(:one_day_ago) { 1.day.ago }
        let(:two_days_ago) { 2.days.ago }
        let(:three_days_ago) { 3.days.ago }

        before do
          StudentEnrollment
            .create!(user: student1, course: course2, course_section: section3)
            .update!(last_activity_at: three_days_ago)
          StudentEnrollment
            .create!(user: student2, course: course2, course_section: section4)
            .update!(last_activity_at: two_days_ago)
          TeacherEnrollment
            .create!(user: teacher1, course: course2, course_section: section1)
            .update!(last_activity_at: one_day_ago)
          TaEnrollment.create!(user: ta1, course: course2, course_section: section2)
        end

        def sort_user_ids(sort, order = "asc")
          UserSearch.scope_for(course2, teacher1, sort:, order:).map(&:id)
        end

        context "last_activity_at" do
          context "single value per user" do
            it "sorts by last_activity_at ascending" do
              # teacher1 - 1 day ago
              # student2 - 2 days ago
              # student1 - 3 days ago
              # ta1 - none
              expect(sort_user_ids("last_activity_at")).to eq [teacher1.id, student2.id, student1.id, ta1.id]
            end

            it "sorts by last_activity_at descending" do
              # student1 - 3 days ago
              # student2 - 2 days ago
              # teacher1 - 1 day ago
              # ta1 - none
              expect(sort_user_ids("last_activity_at", "desc")).to eq [student1.id, student2.id, teacher1.id, ta1.id]
            end

            context "multiple users with the same last_activity_at" do
              it "sorts by last_activity_at ascending and then by user id ascending" do
                student1.enrollments.where(course_section: section3).update!(last_activity_at: two_days_ago)
                # teacher1 - 1 day ago
                # student1 - 2 days ago, student1.id < student2.id as student1 was created before student2
                # student2 - 2 days ago
                # ta1 - none
                expect(sort_user_ids("last_activity_at")).to eq [teacher1.id, student1.id, student2.id, ta1.id]
              end

              it "sorts by last_activity_at descending and then by user id descending" do
                student1.enrollments.where(course_section: section3).update!(last_activity_at: two_days_ago)
                # student2 - 2 days ago, student2.id > student1.id as student2 was created after student1
                # student1 - 2 days ago
                # teacher1 - 1 day ago
                # ta1 - none
                expect(sort_user_ids("last_activity_at", "desc")).to eq [student2.id, student1.id, teacher1.id, ta1.id]
              end
            end

            it "ignores last_activity_at for observers" do
              ObserverEnrollment
                .create!(user: observer1, course: course2)
                .update!(last_activity_at: 1.day.ago)
              # teacher1 - 1 day ago
              # student2 - 2 days ago
              # student1 - 3 days ago
              # ta1 - none (ta1 ranks before observer1 in ascending order because ta1.id < observer1.id as ta1 was created before observer1)
              # observer1 - none (even though observer1 has a last_activity_at, it is ignored)
              expect(sort_user_ids("last_activity_at")).to eq [teacher1.id, student2.id, student1.id, ta1.id, observer1.id]

              # student1 - 3 days ago
              # student2 - 2 days ago
              # teacher1 - 1 day ago
              # observer1 - none (even though observer1 has a last_activity_at, it is ignored)
              # ta1 - none (ta1 ranks after observer1 in descending order because ta1.id < observer1.id as ta1 was created before observer1)
              expect(sort_user_ids("last_activity_at", "desc")).to eq [student1.id, student2.id, teacher1.id, observer1.id, ta1.id]
            end
          end

          it "raises an error when context is not a course" do
            account = Account.create!
            expect do
              UserSearch.scope_for(account, teacher1, sort: "last_activity_at")
            end.to raise_error(RequestError, "Sorting by last_activity_at is only available within a course context")
          end

          context "multiple values per user" do
            before do
              # student1 - 3 days ago, 4 days ago
              # student2 - 2 days ago, 5 days ago
              # teacher1 - 1 day ago
              # ta1 - none
              enrollment4 = StudentEnrollment.create!(user: student1, course: course2)
              enrollment4.update!(last_activity_at: 4.days.ago)

              enrollment5 = StudentEnrollment.create!(user: student2, course: course2)
              enrollment5.update!(last_activity_at: 5.days.ago)
            end

            it "sorts by last_activity_at ascending" do
              # teacher1 - 1 day ago
              # student2 - 2 days ago
              # student1 - 3 days ago
              # ta1 - none
              expect(sort_user_ids("last_activity_at")).to eq [teacher1.id, student2.id, student1.id, ta1.id]
            end

            it "sorts by last_activity_at descending" do
              # student2 - 5 days ago
              # student1 - 4 days ago
              # teacher1 - 1 day ago
              # ta1 - none
              expect(sort_user_ids("last_activity_at", "desc")).to eq [student2.id, student1.id, teacher1.id, ta1.id]
            end
          end
        end

        context "section_name" do
          context "single value per user" do
            it "sorts by section_name ascending" do
              # teacher1 - A Section
              # ta1 - B Section
              # student1 - C Section
              # student2 - D Section
              expect(sort_user_ids("section_name")).to eq [teacher1.id, ta1.id, student1.id, student2.id]
            end

            it "sorts by section_name descending" do
              # student2 - D Section
              # student1 - C Section
              # ta1 - B Section
              # teacher1 - A Section
              expect(sort_user_ids("section_name", "desc")).to eq [student2.id, student1.id, ta1.id, teacher1.id]
            end

            it "ignores section_name for observers" do
              # observer1 - A Section
              ObserverEnrollment.create!(user: observer1, course: course2, course_section: section1)

              # teacher1 - A Section
              # ta1 - B Section
              # student1 - C Section
              # student2 - D Section
              # observer1 - none (even though observer1 has section_name, it is ignored)
              expect(sort_user_ids("section_name")).to eq [teacher1.id, ta1.id, student1.id, student2.id, observer1.id]

              # student2 - D Section
              # student1 - C Section
              # ta1 - B Section
              # teacher1 - A Section
              # observer1 - none (even though observer1 has section_name, it is ignored)
              expect(sort_user_ids("section_name", "desc")).to eq [student2.id, student1.id, ta1.id, teacher1.id, observer1.id]
            end
          end

          context "multiple values per user" do
            before do
              # teacher1 - A Section
              # ta1 - B Section, E Section
              # student1 - C Section, D Section
              # student2 - D Section, F Section
              StudentEnrollment.create!(user: student1, course: course2, course_section: section4)
              StudentEnrollment.create!(user: student2, course: course2, course_section: section6)
              TaEnrollment.create!(user: ta1, course: course2, course_section: section5)
            end

            it "sorts by section_name ascending" do
              # teacher1 - A Section
              # ta1 - B Section
              # student1 - C Section
              # student2 - D Section
              expect(sort_user_ids("section_name")).to eq [teacher1.id, ta1.id, student1.id, student2.id]
            end

            it "sorts by section_name descending" do
              # student2 - F Section
              # ta1 - E Section
              # student1 - D Section
              # teacher1 - A Section
              expect(sort_user_ids("section_name", "desc")).to eq [student2.id, ta1.id, student1.id, teacher1.id]
            end
          end

          it "raises an error when context is not a course" do
            account = Account.create!
            expect do
              UserSearch.scope_for(account, teacher1, sort: "section_name")
            end.to raise_error(RequestError, "Sorting by section_name is only available within a course context")
          end
        end

        context "role" do
          before do
            # student2 from course to reduce test flakiness (there is no guaranteed order of multiple users with the same role)
            student2.enrollments.first.destroy
            ObserverEnrollment.create!(user: observer1, course: course2)
            DesignerEnrollment.create!(user: designer1, course: course2)
          end

          context "single value per user" do
            it "sorts by role ascending" do
              # teacher1 - teacher role
              # ta1 - ta role
              # student1 - student role
              # observer1 - observer role
              # designer1 - designer role
              expect(sort_user_ids("role")).to eq [teacher1.id, ta1.id, student1.id, observer1.id, designer1.id]
            end

            it "sorts by role descending" do
              # designer1 - designer role
              # observer1 - observer role
              # student1 - student role
              # ta1 - ta role
              # teacher1 - teacher role
              expect(sort_user_ids("role", "desc")).to eq [designer1.id, observer1.id, student1.id, ta1.id, teacher1.id]
            end
          end

          context "multiple values per user" do
            before do
              # teacher1 - teacher role, designer role
              # ta1 - ta role, student role
              # student1 - student role, observer role
              # observer1 - observer role
              # designer1 - designer role
              StudentEnrollment.create!(user: ta1, course: course2, course_section: section5)
              ObserverEnrollment.create!(user: student1, course: course2, course_section: section5)
              DesignerEnrollment.create!(user: teacher1, course: course2, course_section: section5)
            end

            it "sorts by role ascending" do
              # teacher1 - teacher role
              # ta1 - ta role
              # student1 - student role
              # observer1 - observer role
              # designer1 - designer role
              expect(sort_user_ids("role")).to eq [teacher1.id, ta1.id, student1.id, observer1.id, designer1.id]
            end

            it "sorts by role descending" do
              # users with the same role are ordered by their id in the same sort order
              # designer1 - designer role (designer1.id > teacher1.id since designer1 was created after teacher1)
              # teacher1 - designer role
              # observer1 - observer role (observer1.id > student1.id since observer1 was created after student1)
              # student1 - observer role
              # ta1 - student role
              expect(sort_user_ids("role", "desc")).to eq [designer1.id, teacher1.id, observer1.id, student1.id, ta1.id]
            end
          end

          it "raises an error when context is not a course" do
            account = Account.create!
            expect do
              UserSearch.scope_for(account, teacher1, sort: "role")
            end.to raise_error(RequestError, "Sorting by role is only available within a course context")
          end
        end
      end
    end
  end

  describe "Bookmarker" do
    before :once do
      @user1 = Account.default.users.create!
      @user2 = Account.default.users.create!
    end

    describe "with include_bookmark: false" do
      it "works with id ascending by default" do
        bookmarker = UserSearch::Bookmarker.new
        pager = double(current_bookmark: bookmarker.bookmark_for(@user1), include_bookmark: false)
        expect(bookmarker.restrict_scope(Account.default.users, pager).first).to eq @user2
      end

      it "works with id descending" do
        bookmarker = UserSearch::Bookmarker.new(order: "desc")
        pager = double(current_bookmark: bookmarker.bookmark_for(@user2), include_bookmark: false)
        expect(bookmarker.restrict_scope(Account.default.users, pager).first).to eq @user1
      end
    end

    describe "with include_bookmark: true" do
      it "works with id ascending by default" do
        bookmarker = UserSearch::Bookmarker.new
        pager = double(current_bookmark: bookmarker.bookmark_for(@user1), include_bookmark: true)
        expect(bookmarker.restrict_scope(Account.default.users, pager).first(2)).to eq [@user1, @user2]
      end

      it "works with id descending" do
        bookmarker = UserSearch::Bookmarker.new(order: "desc")
        pager = double(current_bookmark: bookmarker.bookmark_for(@user2), include_bookmark: true)
        expect(bookmarker.restrict_scope(Account.default.users, pager).first(2)).to eq [@user2, @user1]
      end
    end
  end
end
