# encoding: utf-8
#
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

require File.expand_path( '../sharding_spec_helper' , File.dirname(__FILE__))

describe UserSearch do

  describe '.for_user_in_context' do
    let(:search_names) { ['Rose Tyler', 'Martha Jones', 'Rosemary Giver', 'Martha Stewart', 'Tyler Pickett', 'Jon Stewart', 'Stewart Little', 'Ĭńşŧřůćƭǜȑȩ Person'] }
    let(:course) { Course.create!(workflow_state: "available") }
    let(:users) { UserSearch.for_user_in_context('Stewart', course, user, nil, sort: "username", order: "asc").to_a }
    let(:names) { users.map(&:name) }
    let(:user) { User.last }
    let(:student) { User.where(name: search_names.last).first }

    before do
      teacher = User.create!(:name => 'Tyler Teacher')
      TeacherEnrollment.create!(:user => teacher, :course => course, :workflow_state => 'active')
      search_names.each do |name|
        student = User.create!(:name => name)
        StudentEnrollment.create!(:user => student, :course => course, :workflow_state => 'active')
      end
      User.create!(:name => "admin")
      TeacherEnrollment.create!(:user => user, :course => course, :workflow_state => 'active')
    end

    describe 'with complex search enabled' do

      before { Setting.set('user_search_with_full_complexity', 'true') }

      describe 'with gist setting enabled' do
        before { Setting.set('user_search_with_gist', 'true') }

        it "searches case-insensitively" do
          expect(UserSearch.for_user_in_context("steWArt", course, user).size).to eq 3
        end

        it "uses postgres lower(), not ruby downcase()" do
          # ruby 1.9 downcase doesn't handle the downcasing of many multi-byte characters correctly
          expect(UserSearch.for_user_in_context('Ĭńşŧřůćƭǜȑȩ', course, user).size).to eq 1
        end

        it 'returns an enumerable' do
          expect(users.size).to eq 3
        end

        it 'contains the matching users' do
          expect(names).to include('Martha Stewart')
          expect(names).to include('Stewart Little')
          expect(names).to include('Jon Stewart')
        end

        it 'does not contain users I am not allowed to see' do
          unenrolled_user = User.create!(:name => 'Unenrolled User')
          search_results = UserSearch.for_user_in_context('Stewart', course, unenrolled_user).map(&:name)
          expect(search_results).to eq []
        end

        it 'will not pickup students outside the course' do
          out_of_course_student = User.create!(:name => 'Stewart Stewart')
          # names is evaluated lazily from the 'let' block so ^ user is still being
          # created before the query executes
          expect(names).not_to include('Stewart Stewart')
        end

        it 'will find teachers' do
          results = UserSearch.for_user_in_context('Tyler', course, user)
          expect(results.map(&:name)).to include('Tyler Teacher')
        end

        it "sorts by name" do
          expect(names.size).to eq 3
          expect(names[0]).to eq "Stewart Little"
          expect(names[1]).to eq "Jon Stewart"
          expect(names[2]).to eq "Martha Stewart"
        end

        describe 'filtering by role' do
          subject { names }
          describe 'to a single role' do
            let(:users) { UserSearch.for_user_in_context('Tyler', course, user, nil, :enrollment_type => 'student').to_a }

            it { is_expected.to include('Rose Tyler') }
            it { is_expected.to include('Tyler Pickett') }
            it { is_expected.not_to include('Tyler Teacher') }
          end

          describe 'to multiple roles' do
            let(:users) { UserSearch.for_user_in_context('Tyler', course, student, nil, :enrollment_type => ['ta', 'teacher'] ).to_a }
            before do
              ta = User.create!(:name => 'Tyler TA')
              TaEnrollment.create!(:user => ta, :course => course, :workflow_state => 'active')
            end

            it { is_expected.to include('Tyler TA') }
            it { is_expected.to include('Tyler Teacher') }
            it { is_expected.not_to include('Rose Tyler') }
          end

          describe 'with the broader role parameter' do

            let(:users) { UserSearch.for_user_in_context('Tyler', course, student, nil, :enrollment_role => 'ObserverEnrollment' ).to_a }

            before do
              ta = User.create!(:name => 'Tyler Observer')
              ObserverEnrollment.create!(:user => ta, :course => course, :workflow_state => 'active')
              ta2 = User.create!(:name => 'Tyler Observer 2')
              ObserverEnrollment.create!(:user => ta2, :course => course, :workflow_state => 'active')
              student.linked_observers << ta2
            end

            it { is_expected.not_to include('Tyler Observer 2') }
            it { is_expected.not_to include('Tyler Observer') }
            it { is_expected.not_to include('Tyler Teacher') }
            it { is_expected.not_to include('Rose Tyler') }
          end

          describe 'with the role name parameter' do
            let(:users) { UserSearch.for_user_in_context('Tyler', course, user, nil, :enrollment_role => 'StudentEnrollment' ).to_a }

            before do
              newstudent = User.create!(:name => 'Tyler Student')
              e = StudentEnrollment.create!(:user => newstudent, :course => course, :workflow_state => 'active')
            end

            it { should include('Rose Tyler') }
            it { should include('Tyler Pickett') }
            it { should include('Tyler Student') }
            it { should_not include('Tyler Teacher') }
          end

          describe 'with the role id parameter' do

            let(:users) { UserSearch.for_user_in_context('Tyler', course, student, nil, :enrollment_role_id => student_role.id ).to_a }

            before do
              newstudent = User.create!(:name => 'Tyler Student')
              e = StudentEnrollment.create!(:user => newstudent, :course => course, :workflow_state => 'active')
            end

            it { should include('Rose Tyler') }
            it { should include('Tyler Pickett') }
            it { should include('Tyler Student') }
            it { should_not include('Tyler Teacher') }
          end
        end

        describe 'searching on logins' do
          let(:pseudonym) { user.pseudonyms.build }

          before do
            pseudonym.sis_user_id = "SOME_SIS_ID"
            pseudonym.unique_id = "SOME_UNIQUE_ID@example.com"
            pseudonym.save!
          end

          it 'will match against an sis id' do
            expect(UserSearch.for_user_in_context("SOME_SIS", course, user)).to eq [user]
          end

          it 'will not match against a sis id without :read_sis permission' do
            RoleOverride.create!(context: Account.default, role: Role.get_built_in_role('TeacherEnrollment'),
              permission: 'read_sis', enabled: false)
            expect(UserSearch.for_user_in_context("SOME_SIS", course, user)).to eq []
          end

          it 'will match against an sis id and regular id' do
            user2 = User.create(name: 'user two')
            pseudonym.sis_user_id = user2.id.to_s
            pseudonym.save!
            course.enroll_user(user2)
            expect(UserSearch.for_user_in_context(user2.id.to_s, course, user)).to eq [user, user2]
          end

          it 'will match against a login id' do
            expect(UserSearch.for_user_in_context("UNIQUE_ID", course, user)).to eq [user]
          end

          it 'will not search login id without permission' do
            RoleOverride.create!(context: Account.default, role: Role.get_built_in_role('TeacherEnrollment'),
              permission: 'view_user_logins', enabled: false)
            expect(UserSearch.for_user_in_context("UNIQUE_ID", course, user)).to eq []
          end

          it 'can match an SIS id and a user name in the same query' do
            pseudonym.sis_user_id = "MARTHA_SIS_ID"
            pseudonym.save!
            other_user = User.where(name: 'Martha Stewart').first
            results = UserSearch.for_user_in_context("martha", course, user)
            expect(results).to include(user)
            expect(results).to include(other_user)
          end

        end

        describe 'searching on emails' do
          let(:user1) {user_with_pseudonym(user: user)}
          let(:cc) {user1.communication_channels.create!(path: 'the.giver@example.com')}

          before do
            cc.confirm!
          end

          it 'matches against an email' do
            expect(UserSearch.for_user_in_context("the.giver", course, user)).to eq [user]
          end

          it 'requires :read_email_addresses permission' do
            RoleOverride.create!(context: Account.default, role: Role.get_built_in_role('TeacherEnrollment'),
              permission: 'read_email_addresses', enabled: false)
            expect(UserSearch.for_user_in_context("the.giver", course, user)).to eq []
          end

          it 'can match an email and a name in the same query' do
            results = UserSearch.for_user_in_context("giver", course, user)
            expect(results).to include(user)
            expect(results).to include(User.where(name: 'Rosemary Giver').first)
          end

          it 'will not match channels where the type is not email' do
            cc.update_attributes!(:path_type => CommunicationChannel::TYPE_TWITTER)
            expect(UserSearch.for_user_in_context("the.giver", course, user)).to eq []
          end

          it "doesn't match retired channels" do
            cc.retire!
            expect(UserSearch.for_user_in_context("the.giver", course, user)).to eq []
          end

          it 'matches unconfirmed channels', priority: 1, test_id: 3010726 do
            user.communication_channels.create!(path: 'unconfirmed@example.com')
            expect(UserSearch.for_user_in_context("unconfirmed", course, user)).to eq [user]
          end
        end

        describe 'searching by a DB ID' do
          it 'matches against the database id' do
            expect(UserSearch.for_user_in_context(user.id, course, user)).to eq [user]
          end

          it 'matches against a database id and a user simultaneously' do
            other_user = student_in_course(course: course, name: user.id.to_s).user
            expect(UserSearch.for_user_in_context(user.id, course, user)).to match_array [user, other_user]
          end

          describe "cross-shard users" do
            specs_require_sharding

            it 'matches against the database id of a cross-shard user' do
              user = @shard1.activate { user_model }
              course.enroll_student(user)
              expect(UserSearch.for_user_in_context(user.global_id, course, user)).to eq [user]
              expect(UserSearch.for_user_in_context(user.global_id, course.account, user)).to eq [user]
            end
          end
        end
      end

      describe 'with gist setting disabled' do
        before { Setting.set('user_search_with_gist', 'false') }

        it 'returns a list of matching users using a prefix search' do
          expect(names).to eq ['Stewart Little']
        end
      end
    end

    describe 'with complex search disabled' do
      before do
        Setting.set('user_search_with_full_complexity', 'false')
        Setting.set('user_search_with_gist', 'true')
      end

      it 'matches against the display name' do
        expect(users.size).to eq 3
      end

      it 'does not match against sis ids' do
        pseudonym = user.pseudonyms.build
        pseudonym.sis_user_id = "SOME_SIS_ID"
        pseudonym.unique_id = "SOME_UNIQUE_ID@example.com"
        pseudonym.save!
        expect(UserSearch.for_user_in_context("SOME_SIS", course, user)).to eq []
      end

      it 'does not match against emails' do
        user.communication_channels.create!(:path => 'the.giver@example.com', :path_type => CommunicationChannel::TYPE_EMAIL)
        expect(UserSearch.for_user_in_context("the.giver", course, user)).to eq []
      end
    end
  end

  describe '.like_string_for' do
    it 'uses a prefix if gist is not configured' do
      Setting.set('user_search_with_gist', 'false')
      expect(UserSearch.like_string_for("word")).to eq 'word%'
    end

    it 'modulos both sides if gist is configured' do
      Setting.set('user_search_with_gist', 'true')
      expect(UserSearch.like_string_for("word")).to eq '%word%'
    end
  end

  describe '.scope_for' do

    let(:search_names) do
      ['Rose Tyler',
       'Martha Jones',
       'Rosemary Giver',
       'Martha Stewart',
       'Tyler Pickett',
       'Jon Stewart',
       'Stewart Little',
       'Ĭńşŧřůćƭǜȑȩ Person']
    end

    let(:course) { Course.create!(workflow_state: "available") }
    let(:users) { UserSearch.scope_for(course, user, sort: "username", order: "desc").to_a }
    let(:names) { users.map(&:name) }
    let(:user) { User.last }
    let(:student) { User.where(name: search_names.last).first }

    before do
      search_names.each do |name|
        student = User.create!(:name => name)
        StudentEnrollment.create!(:user => student, :course => course, :workflow_state => 'active')
      end
    end

    it 'sorts by name desc' do
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

    it 'raises an error if there is a bad enrollment type' do
      course = Course.create!
      student = User.create!
      bad_scope = lambda { UserSearch.scope_for(course, student, :enrollment_type => 'all') }
      expect(bad_scope).to raise_error(ArgumentError, 'Invalid Enrollment Type')
    end

    it "doesn't explode with group context" do
      course_with_student
      group = @course.groups.create!
      group.add_user(@student)
      account_admin_user
      expect(UserSearch.scope_for(group, @admin, :enrollment_type => ['student']).to_a).to eq [@student]
      expect(UserSearch.scope_for(group, @admin, :enrollment_type => ['teacher']).to_a).to be_empty
    end
  end
end
