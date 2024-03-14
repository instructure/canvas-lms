# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Types::UserType do
  before(:once) do
    student = student_in_course(active_all: true).user
    course = @course
    teacher = @teacher
    @other_student = student_in_course(active_all: true).user

    @other_course = course_factory
    @random_person = teacher_in_course(active_all: true).user

    @course = course
    @student = student
    @teacher = teacher
    @ta = ta_in_course(active_all: true).user
  end

  let(:user_type) do
    GraphQLTypeTester.new(
      @student,
      current_user: @teacher,
      domain_root_account: @course.account.root_account,
      request: ActionDispatch::TestRequest.create
    )
  end

  context "node" do
    it "works" do
      expect(user_type.resolve("_id")).to eq @student.id.to_s
      expect(user_type.resolve("name")).to eq @student.name
    end

    it "works for users in the same course" do
      expect(user_type.resolve("_id", current_user: @other_student)).to eq @student.id.to_s
    end

    it "works for users without a current enrollment" do
      user = user_model
      type = GraphQLTypeTester.new(user, current_user: user, domain_root_account: user.account, request: ActionDispatch::TestRequest.create)
      expect(type.resolve("_id")).to eq user.id.to_s
      expect(type.resolve("name")).to eq user.name
    end

    it "doesn't work for just anyone" do
      expect(user_type.resolve("_id", current_user: @random_person)).to be_nil
    end

    it "loads inactive and concluded users" do
      @student.enrollments.update_all workflow_state: "inactive"
      expect(user_type.resolve("_id", current_user: @other_student)).to eq @student.id.to_s

      @student.enrollments.update_all workflow_state: "completed"
      expect(user_type.resolve("_id", current_user: @other_student)).to eq @student.id.to_s
    end
  end

  context "shortName" do
    before(:once) do
      @student.update! short_name: "new display name"
    end

    it "is displayed if set" do
      expect(user_type.resolve("shortName")).to eq "new display name"
    end

    it "returns full name if shortname is not set" do
      @student.update! short_name: nil
      expect(user_type.resolve("shortName")).to eq @student.name
    end
  end

  context "uuid" do
    it "is displayed when requested" do
      expect(user_type.resolve("uuid")).to eq @student.uuid.to_s
    end
  end

  context "avatarUrl" do
    before(:once) do
      @student.update! avatar_image_url: "not-a-fallback-avatar.png"
    end

    it "is nil when avatars are not enabled" do
      expect(user_type.resolve("avatarUrl")).to be_nil
    end

    it "returns an avatar url when avatars are enabled" do
      @student.account.enable_service(:avatars)
      expect(user_type.resolve("avatarUrl")).to match(/avatar.*png/)
    end

    it "returns nil when a user has no avatar" do
      @student.account.enable_service(:avatars)
      @student.update! avatar_image_url: nil
      expect(user_type.resolve("avatarUrl")).to be_nil
    end
  end

  context "htmlUrl" do
    it "returns the user's profile url" do
      html_url = user_type.resolve(%|htmlUrl(courseId: "#{@course.id}")|)
      expect(html_url.end_with?("courses/#{@course.id}/users/#{@student.id}")).to be_truthy
    end
  end

  context "pronouns" do
    it "returns user pronouns" do
      @student.account.root_account.settings[:can_add_pronouns] = true
      @student.account.root_account.save!
      @student.pronouns = "Dude/Guy"
      @student.save!
      expect(user_type.resolve("pronouns")).to eq "Dude/Guy"
    end
  end

  context "sisId" do
    before(:once) do
      @student.pseudonyms.create!(
        account: @course.account,
        unique_id: "alex@columbia.edu",
        workflow_state: "active",
        sis_user_id: "a.ham"
      )
    end

    context "as admin" do
      let(:admin) { account_admin_user }
      let(:user_type_as_admin) do
        GraphQLTypeTester.new(@student,
                              current_user: admin,
                              domain_root_account: @course.account.root_account,
                              request: ActionDispatch::TestRequest.create)
      end

      it "returns the sis user id if the user has permissions to read it" do
        expect(user_type_as_admin.resolve("sisId")).to eq "a.ham"
      end

      it "returns nil if the user does not have permission to read the sis user id" do
        account_admin_user_with_role_changes(role_changes: { read_sis: false, manage_sis: false })
        admin_type = GraphQLTypeTester.new(@student,
                                           current_user: @admin,
                                           domain_root_account: @course.account.root_account,
                                           request: ActionDispatch::TestRequest.create)
        expect(admin_type.resolve("sisId")).to be_nil
      end
    end

    context "as teacher" do
      it "returns the sis user id if the user has permissions to read it" do
        expect(user_type.resolve("sisId")).to eq "a.ham"
      end

      it "returns null if the user does not have permission to read the sis user id" do
        @teacher.enrollments.find_by(course: @course).role
                .role_overrides.create!(permission: "read_sis", enabled: false, account: @course.account)
        expect(user_type.resolve("sisId")).to be_nil
      end
    end
  end

  context "integrationId" do
    before(:once) do
      @student.pseudonyms.create!(
        account: @course.account,
        unique_id: "rlands@eab.com",
        workflow_state: "active",
        integration_id: "Rachel.Lands"
      )
    end

    context "as admin" do
      let(:admin) { account_admin_user }
      let(:user_type_as_admin) do
        GraphQLTypeTester.new(@student,
                              current_user: admin,
                              domain_root_account: @course.account.root_account,
                              request: ActionDispatch::TestRequest.create)
      end

      it "returns the integration id if admin user has permissions to read SIS info" do
        expect(user_type_as_admin.resolve("integrationId")).to eq "Rachel.Lands"
      end

      it "returns null for integration id if admin user does not have permission to read SIS info" do
        account_admin_user_with_role_changes(role_changes: { read_sis: false, manage_sis: false })
        admin_type = GraphQLTypeTester.new(@student,
                                           current_user: @admin,
                                           domain_root_account: @course.account.root_account,
                                           request: ActionDispatch::TestRequest.create)
        expect(admin_type.resolve("integrationId")).to be_nil
      end
    end

    context "as teacher" do
      it "returns the integration id if teacher user has permissions to read SIS info" do
        expect(user_type.resolve("integrationId")).to eq "Rachel.Lands"
      end

      it "returns null if teacher user does not have permission to read SIS info" do
        @teacher.enrollments.find_by(course: @course).role
                .role_overrides.create!(permission: "read_sis", enabled: false, account: @course.account)
        expect(user_type.resolve("integrationId")).to be_nil
      end
    end
  end

  context "enrollments" do
    before(:once) do
      @course1 = @course
      @course2 = course_factory
      @course2.enroll_student(@student, enrollment_state: "active")
    end

    it "returns enrollments for a given course" do
      expect(
        user_type.resolve(%|enrollments(courseId: "#{@course1.id}") { _id }|)
      ).to eq [@student.enrollments.first.to_param]
    end

    it "returns all enrollments for a user (that can be read)" do
      @course1.enroll_student(@student, enrollment_state: "active")

      expect(
        user_type.resolve("enrollments { _id }")
      ).to eq [@student.enrollments.first.to_param]

      site_admin_user
      expect(
        user_type.resolve(
          "enrollments { _id }",
          current_user: @admin
        )
      ).to match_array @student.enrollments.map(&:to_param)
    end

    it "excludes deleted course enrollments for a user" do
      @course1.enroll_student(@student, enrollment_state: "active")
      @course2.destroy

      site_admin_user
      expect(
        user_type.resolve(
          "enrollments { _id }",
          current_user: @admin
        )
      ).to eq [@student.enrollments.first.to_param]
    end

    it "excludes unavailable courses when currentOnly is true" do
      @course1.complete

      expect(user_type.resolve("enrollments(currentOnly: true) { _id }")).to eq []
    end

    it "excludes concluded courses when currentOnly is true" do
      @course1.start_at = 2.weeks.ago
      @course1.conclude_at = 1.week.ago
      @course1.restrict_enrollments_to_course_dates = true
      @course1.save!

      expect(user_type.resolve("enrollments(currentOnly: true) { _id }")).to eq []
    end

    it "sorts correctly when orderBy is provided" do
      @course2.start_at = 1.week.ago
      @course2.save!

      expect(user_type.resolve('enrollments(orderBy: ["courses.start_at"]) {
          _id
          course {
            _id
          }
        }',
                               current_user: @student).map(&:to_i)).to eq [@course2.id, @course1.id]
    end

    it "doesn't return enrollments for courses the user doesn't have permission for" do
      expect(
        user_type.resolve(%|enrollments(courseId: "#{@course2.id}") { _id }|)
      ).to eq []
    end

    it "excludes deactivated enrollments when currentOnly is true" do
      @student.enrollments.each(&:deactivate)
      results = user_type.resolve("enrollments(currentOnly: true) { _id }")
      expect(results).to be_empty
    end

    it "includes deactivated enrollments when currentOnly is false" do
      @student.enrollments.each(&:deactivate)
      results = user_type.resolve("enrollments(currentOnly: false) { _id }")
      expect(results).not_to be_empty
    end

    it "excludes concluded enrollments when excludeConcluded is true" do
      expect(user_type.resolve("enrollments(excludeConcluded: true) { _id }").length).to eq 1
      @student.enrollments.update_all workflow_state: "completed"
      expect(user_type.resolve("enrollments(excludeConcluded: true) { _id }")).to eq []
    end

    it "excludes enrollments that have a state of creation_pending" do
      expect(user_type.resolve("enrollments { _id }").length).to eq 1
      @student.enrollments.update(workflow_state: "creation_pending")
      expect(user_type.resolve("enrollments { _id }")).to eq []
    end

    it "excludes enrollments that have a enrollment_state of pending_active" do
      expect(user_type.resolve("enrollments { _id }", current_user: @student).length).to eq @student.enrollments.count

      @course1.update(start_at: 1.week.from_now, restrict_enrollments_to_course_dates: true)

      expect(@student.enrollments.where(course_id: @course1)[0].enrollment_state.state).to eq "pending_active"

      expect(user_type.resolve("enrollments { _id }", current_user: @student)).to eq [@student.enrollments.where(course_id: @course2).first.to_param]
    end
  end

  context "email" do
    let!(:read_email_override) do
      RoleOverride.create!(
        context: @teacher.account,
        permission: "read_email_addresses",
        role: teacher_role,
        enabled: true
      )
    end

    let!(:admin) { account_admin_user }

    before(:once) do
      @student.update! email: "cooldude@example.com"
    end

    it "returns email for admins" do
      admin_tester = GraphQLTypeTester.new(
        @student,
        current_user: admin,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )

      expect(admin_tester.resolve("email")).to eq @student.email

      # this is for the cached branch
      allow(@student).to receive(:email_cached?).and_return(true)
      expect(admin_tester.resolve("email")).to eq @student.email
    end

    it "returns email for teachers" do
      expect(user_type.resolve("email")).to eq @student.email

      # this is for the cached branch
      allow(@student).to receive(:email_cached?).and_return(true)
      expect(user_type.resolve("email")).to eq @student.email
    end

    it "doesn't return email for others" do
      expect(user_type.resolve("email", current_user: nil)).to be_nil
      expect(user_type.resolve("email", current_user: @other_student)).to be_nil
      expect(user_type.resolve("email", current_user: @random_person)).to be_nil
    end

    it "respects :read_email_addresses permission" do
      read_email_override.update!(enabled: false)

      expect(user_type.resolve("email")).to be_nil
    end
  end

  context "groups" do
    before(:once) do
      @user_group_ids = (1..5).map do
        group_with_user({ user: @student, active_all: true }).group_id.to_s
      end
      @deleted_user_group_ids = (1..3).map do
        group = group_with_user({ user: @student, active_all: true })
        group.destroy
        group.group_id.to_s
      end
    end

    it "fetches the groups associated with a user" do
      user_type.resolve("groups { _id }", current_user: @student).all? do |id|
        expect(@user_group_ids.include?(id)).to be true
        expect(@deleted_user_group_ids.include?(id)).to be false
      end
    end

    it "only returns groups for current_user" do
      expect(
        user_type.resolve("groups { _id }", current_user: @teacher)
      ).to be_nil
    end
  end

  context "notificationPreferences" do
    it "returns the users notification preferences" do
      Notification.delete_all
      @student.communication_channels.create!(path: "test@test.com").confirm!
      notification_model(name: "test", category: "Announcement")

      expect(
        user_type.resolve("notificationPreferences { channels { notificationPolicies(contextType: Course) { notification { name } } } }")[0][0]
      ).to eq "test"
    end

    it "only returns active communication channels" do
      Notification.delete_all
      communication_channel = @student.communication_channels.create!(path: "test@test.com")
      communication_channel.confirm!
      notification_model(name: "test", category: "Announcement")

      expect(
        user_type.resolve("notificationPreferences { channels { notificationPolicies(contextType: Course) { notification { name } } } }")[0][0]
      ).to eq "test"

      communication_channel.destroy
      expect(
        user_type.resolve("notificationPreferences { channels { notificationPolicies(contextType: Course) { notification { name } } } }").count
      ).to eq 0
    end

    context "when the requesting user does not have permission to view the communication channels" do
      let(:user_type) do
        GraphQLTypeTester.new(
          @student,
          current_user: @other_student,
          domain_root_account: @course.account.root_account,
          request: ActionDispatch::TestRequest.create
        )
      end

      it "returns nil" do
        expect(
          user_type.resolve("notificationPreferences { channels { notificationPolicies(contextType: Course) { notification { name } } } }")
        ).to be_nil
      end
    end
  end

  context "conversations" do
    it "returns conversations for the user" do
      c = conversation(@student, @teacher)
      type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
      expect(
        type.resolve("conversationsConnection { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }")[0][0]
      ).to eq c.conversation.conversation_messages.first.body
    end

    context "recipient user deleted" do
      def delete_recipient
        # The short issue is CP and CMP are not fk attached to the user, but our code expects an associated user.
        # As a result the below specs give us options to handle when a user is hard deleted without cleanup.
        # The CMP requires that the cmp.workflow_state == deleted;
        # there is no way around this because the loader takes an array of cmps and it would defeat the purpose to check user beforehand.
        # Thus for now we handle this and return null which can be processed.

        conversation(@student, sender: @teacher)

        # delete student
        student_id = @student.id

        # delete enrollments can run in a loop if multiple
        enrollment = @student.enrollments.first
        enrollment_state = enrollment.enrollment_state
        enrollment_state.delete
        enrollment.delete

        # delete stream_item_instances can run in a loop if multiple
        stream_item_instance = @student.stream_item_instances.first
        stream_item_instance.delete

        # delete user_account_associations can run in a loop if multiple
        user_account_association = @student.user_account_associations.first
        user_account_association.delete

        @student.delete

        # deleting the cmp
        # the problem cp:  cp_without_associated_user = ConversationParticipant.where(user_id: student_id).first
        cmp_without_associated_user = ConversationMessageParticipant.where(user_id: student_id).first
        cmp_without_associated_user.workflow_state = "deleted"
        cmp_without_associated_user.save

        student_id
      end

      it "returns empty recipients" do
        delete_recipient
        type = GraphQLTypeTester.new(@teacher, current_user: @teacher, domain_root_account: @teacher.account, request: ActionDispatch::TestRequest.create)

        recipients_ids = type.resolve("
        conversationsConnection(scope: \"sent\") {
          nodes {
            conversation {
              conversationMessagesConnection {
                nodes {
                  recipients {
                    _id
                  }
                }
              }
            }
          }
        }
        ")
        expect(recipients_ids[0][0].empty?).to be true
      end

      context "ConversationMessageParticipant.workflow_state deleted" do
        it "returns nil for user" do
          student_id = delete_recipient
          type = GraphQLTypeTester.new(@teacher, current_user: @teacher, domain_root_account: @teacher.account, request: ActionDispatch::TestRequest.create)
          cmps_ids = type.resolve("
            conversationsConnection(scope: \"sent\") {
              nodes {
                conversation {
                  conversationParticipantsConnection {
                    nodes {
                      user {
                        _id
                      }
                    }
                  }
                }
              }
            }
            ")
          expect(cmps_ids[0].include?(@teacher.id.to_s)).to be true
          expect(cmps_ids[0].include?(student_id.to_s)).to be false
        end
      end
    end

    it "has createdAt field for conversationMessagesConnection" do
      Timecop.freeze do
        c = conversation(@student, @teacher)
        type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
        expect(
          type.resolve("conversationsConnection { nodes { conversation { conversationMessagesConnection { nodes { createdAt } } } } }")[0][0]
        ).to eq c.conversation.conversation_messages.first.created_at.iso8601
      end
    end

    it "has updatedAt field for conversations and conversationParticipants" do
      Timecop.freeze do
        convo = conversation(@student, @teacher)
        type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
        res_node = type.resolve("conversationsConnection { nodes { updatedAt }}")[0]
        expect(res_node).to eq convo.conversation.conversation_participants.first.updated_at.iso8601
      end
    end

    it "has updatedAt field for conversationParticipantsConnection" do
      Timecop.freeze do
        convo = conversation(@student, @teacher)
        type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
        res_node = type.resolve("conversationsConnection { nodes { conversation { conversationParticipantsConnection { nodes { updatedAt } } } } }")[0][0]
        expect(res_node).to eq convo.conversation.conversation_participants.first.updated_at.iso8601
      end
    end

    it "does not return conversations for other users" do
      conversation(@student, @teacher)
      type = GraphQLTypeTester.new(@teacher, current_user: @student, domain_root_account: @teacher.account, request: ActionDispatch::TestRequest.create)
      expect(
        type.resolve("conversationsConnection { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }")
      ).to be_nil
    end

    it "filters the conversations" do
      conversation(@student, @teacher, { body: "Howdy Partner" })
      conversation(@student, @random_person, { body: "Not in course" })
      conversation(@student, @ta, { body: "Hey Im using SimpleTags tagged_scope_handler." })

      type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
      result = type.resolve(
        "conversationsConnection(filter: \"course_#{@course.id}\") { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.count).to eq 2
      expect(result.flatten).to match_array ["Howdy Partner", "Hey Im using SimpleTags tagged_scope_handler."]

      result = type.resolve(
        "conversationsConnection(filter: \"user_#{@ta.id}\") { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.count).to eq 1
      expect(result[0][0]).to eq "Hey Im using SimpleTags tagged_scope_handler."

      result = type.resolve(
        "conversationsConnection { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.count).to eq 3
      expect(result.flatten).to match_array ["Howdy Partner", "Not in course", "Hey Im using SimpleTags tagged_scope_handler."]

      result = type.resolve(
        "conversationsConnection(filter: [\"user_#{@ta.id}\", \"course_#{@course.id}\"]) { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.count).to eq 1
      expect(result[0][0]).to eq "Hey Im using SimpleTags tagged_scope_handler."
    end

    it "scopes the conversations" do
      allow(InstStatsd::Statsd).to receive(:increment)
      conversation(@student, @teacher, { body: "You get that thing I sent ya?" })
      conversation(@teacher, @student, { body: "oh yea =)" })
      conversation(@student, @random_person, { body: "Whats up?", starred: true })

      # used for the sent scope
      conversation(@random_person, @teacher, { body: "Help! Please make me non-random!" })
      type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
      result = type.resolve(
        "conversationsConnection(scope: \"inbox\") { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.flatten.count).to eq 3
      expect(result.flatten).to match_array ["You get that thing I sent ya?", "oh yea =)", "Whats up?"]
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.visit.scope.inbox.pages_loaded.react")

      result = type.resolve(
        "conversationsConnection(scope: \"starred\") { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.count).to eq 1
      expect(result[0][0]).to eq "Whats up?"
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.visit.scope.starred.pages_loaded.react")

      type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
      result = type.resolve(
        "conversationsConnection(scope: \"unread\") { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.flatten.count).to eq 2
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.visit.scope.unread.pages_loaded.react")

      type = GraphQLTypeTester.new(
        @random_person,
        current_user: @random_person,
        domain_root_account: @random_person.account,
        request: ActionDispatch::TestRequest.create
      )
      result = type.resolve("conversationsConnection(scope: \"sent\") { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }")
      expect(result[0][0]).to eq "Help! Please make me non-random!"
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.visit.scope.sent.pages_loaded.react")

      @conversation.update!(workflow_state: "archived")
      type = GraphQLTypeTester.new(
        @random_person,
        current_user: @random_person,
        domain_root_account: @random_person.account,
        request: ActionDispatch::TestRequest.create
      )
      result = type.resolve("conversationsConnection(scope: \"archived\") { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }")
      expect(result[0][0]).to eq "Help! Please make me non-random!"
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.visit.scope.archived.pages_loaded.react")
      @conversation.update!(workflow_state: "read")
    end
  end

  context "recipients" do
    let(:type) do
      GraphQLTypeTester.new(
        @student,
        current_user: @student,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    it "returns nil if the user is not the current user" do
      result = user_type.resolve("recipients { usersConnection { nodes { _id } } }")
      expect(result).to be_nil
    end

    it "returns known users" do
      known_users = @student.address_book.search_users.paginate(per_page: 4)
      result = type.resolve("recipients { usersConnection { nodes { _id } } }")
      expect(result).to match_array(known_users.pluck(:id).map(&:to_s))
    end

    it "returns contexts" do
      result = type.resolve("recipients { contextsConnection { nodes { name } } }")
      expect(result[0]).to eq(@course.name)
    end

    it "returns false for sendMessagesAll if no context is given" do
      result = type.resolve("recipients { sendMessagesAll }")
      expect(result).to be(false)
    end

    it "returns false for sendMessagesAll if not allowed" do
      # Students do not have the sendMessagesAll permission by default
      result = type.resolve("recipients(context: \"course_#{@course.id}_students\") { sendMessagesAll }")
      expect(result).to be(false)
    end

    it "returns true for sendMessagesAll if allowed" do
      @random_person.account.role_overrides.create!(permission: :send_messages_all, role: student_role, enabled: true)

      result = type.resolve("recipients(context: \"course_#{@course.id}_students\") { sendMessagesAll }")
      expect(result).to be(true)
    end

    it "searches users" do
      known_users = @student.address_book.search_users.paginate(per_page: 3)
      User.find(known_users.first.id).update!(name: "Matthew Lemon")
      result = type.resolve('recipients(search: "lemon") { usersConnection { nodes { _id } } }')
      expect(result[0]).to eq(known_users.first.id.to_s)

      result = type.resolve('recipients(search: "morty") { usersConnection { nodes { _id } } }')
      expect(result).to be_empty
    end

    it "searches contexts" do
      result = type.resolve('recipients(search: "unnamed") { contextsConnection { nodes { name } } }')
      expect(result[0]).to eq(@course.name)

      result = type.resolve('recipients(search: "Lemon") { contextsConnection { nodes { name } } }')
      expect(result).to be_empty
    end

    it "filters results based on context" do
      known_users = @student.address_book.search_users(context: "course_#{@course.id}_students").paginate(per_page: 3)
      result = type.resolve("recipients(context: \"course_#{@course.id}_students\") { usersConnection { nodes { _id } } }")
      expect(result).to match_array(known_users.pluck(:id).map(&:to_s))
    end
  end

  context "observerEnrollmentsConnection" do
    specs_require_sharding

    let(:teacher_type) do
      GraphQLTypeTester.new(
        @teacher,
        current_user: @teacher,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    let(:student_type) do
      GraphQLTypeTester.new(
        @student,
        current_user: @student,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    before do
      @shard1.activate do
        @student1 = student_in_course(active_all: true).user
        @student2 = student_in_course(active_all: true).user

        @student1_observer = observer_in_course(active_all: true, associated_user_id: @student1).user
        @student2_observer = observer_in_course(active_all: true, associated_user_id: @student2).user
      end

      @shard2.activate do
        @student2_observer2 = User.create
        enrollment = @course.enroll_user(@student2_observer2, "ObserverEnrollment")
        enrollment.associated_user = @student2
        enrollment.workflow_state = "active"
        enrollment.save
      end
    end

    it "returns associatedUser ids" do
      result = teacher_type.resolve("recipients(context: \"course_#{@course.id}_observers\") { usersConnection { nodes { observerEnrollmentsConnection(contextCode: \"course_#{@course.id}\") { nodes { associatedUser { _id } } } } } }")
      expect(result).to match_array([[@student1.id.to_s], [@student2.id.to_s], [@student2.id.to_s]])
    end

    it "returns empty associatedUser ids" do
      result = teacher_type.resolve("recipients(context: \"course_#{@course.id}_students\") { usersConnection { nodes { observerEnrollmentsConnection(contextCode: \"course_#{@course.id}\") { nodes { associatedUser { _id } } } } } }")
      expect(result).to match_array([[], [], [], []])
    end

    it "returns nil when context is empty" do
      result = teacher_type.resolve("recipients(context: \"course_#{@course.id}_observers\") { usersConnection { nodes { observerEnrollmentsConnection(contextCode: \"\") { nodes { associatedUser { _id } } } } } }")
      expect(result).to match_array([nil, nil, nil])
    end

    it "returns nil when not teacher" do
      result = student_type.resolve("recipients(context: \"course_#{@course.id}_observers\") { usersConnection { nodes { observerEnrollmentsConnection(contextCode: \"\") { nodes { associatedUser { _id } } } } } }")
      expect(result).to match_array([nil, nil])
    end
  end

  context "total_recipients" do
    let(:type) do
      GraphQLTypeTester.new(
        @student,
        current_user: @student,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    it "returns total_recipients for given context (excluding current_user)" do
      result = type.resolve("totalRecipients(context: \"course_#{@course.id}\")")
      expect(result).to eq(@course.enrollments.count - 1)
    end
  end

  context "recipients_observers" do
    let(:student_type) do
      GraphQLTypeTester.new(
        @student,
        current_user: @student,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    let(:teacher_type) do
      GraphQLTypeTester.new(
        @teacher,
        current_user: @teacher,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    before do
      student = @student
      @third_student = student_in_course(active_all: true).user
      @fourth_student = student_in_course(active_all: true).user
      @student = student

      observer = observer_in_course(active_all: true, associated_user_id: @student).user
      observer_enrollment_2 = @course.enroll_user(observer, "ObserverEnrollment", enrollment_state: "active")
      observer_enrollment_2.update_attribute(:associated_user_id, @other_student.id)

      observer_enrollment_3 = @course.enroll_user(observer, "ObserverEnrollment", enrollment_state: "active")
      observer_enrollment_3.update_attribute(:associated_user_id, @third_student.id)

      second_observer = observer_in_course(active_all: true, associated_user_id: @fourth_student).user

      @observer = observer
      @second_observer = second_observer
    end

    it "returns nil if the user is not the current user" do
      result = teacher_type.resolve('recipientsObservers(contextCode: "course_1", recipientIds: ["1"]) { nodes { _id } } ')
      expect(result).to be_nil
    end

    it "returns nil if invalid course is given" do
      result = teacher_type.resolve('recipientsObservers(contextCode: "fake_2", recipientIds: ["1"]) { nodes { _id } } ')
      expect(result).to be_nil
    end

    it "returns a users observers as messageable user" do
      recipients = [@student.id.to_s]
      result = teacher_type.resolve("recipientsObservers(contextCode: \"course_#{@course.id}\", recipientIds: #{recipients}) { nodes { _id } } ", current_user: @teacher)
      expect(result).to eq [@observer.id.to_s]
    end

    it "does not return observers that are not active" do
      inactive_observer = User.create
      inactive_observer_enrollment = @course.enroll_user(inactive_observer, "ObserverEnrollment", enrollment_state: "completed")
      inactive_observer_enrollment.update_attribute(:associated_user_id, @student.id)
      recipients = [@student.id.to_s]
      result = teacher_type.resolve("recipientsObservers(contextCode: \"course_#{@course.id}\", recipientIds: #{recipients}) { nodes { _id } } ", current_user: @teacher)
      expect(result).not_to include(inactive_observer.id.to_s)
    end

    it "does not return duplicate observers if an observer is observing multiple students in the course" do
      recipients = [@student, @other_student, @third_student].map { |u| u.id.to_s }
      result = teacher_type.resolve("recipientsObservers(contextCode: \"course_#{@course.id}\", recipientIds: #{recipients}) { nodes { _id } } ", current_user: @teacher)
      expect(result).to eq [@observer.id.to_s]
    end

    it "returns observers for all students in a course if the entire course is a recipient and current user can send observers messages" do
      recipients = ["course_#{@course.id}"]
      result = teacher_type.resolve("recipientsObservers(contextCode: \"course_#{@course.id}\", recipientIds: #{recipients}) { nodes { _id } } ", current_user: @teacher)
      expect(result.length).to eq 2
      expect(result).to include(@observer.id.to_s, @second_observer.id.to_s)
    end

    it "does not return observers that the current user is unable to message" do
      recipients = ["course_#{@course.id}"]
      result = student_type.resolve("recipientsObservers(contextCode: \"course_#{@course.id}\", recipientIds: #{recipients}) { nodes { _id } } ", current_user: @student)
      expect(result.length).to eq 1
      expect(result).to include(@student.observee_enrollments.first.user.id.to_s)
    end
  end

  context "favorite_courses" do
    before(:once) do
      @course1 = @course
      course_with_user("StudentEnrollment", user: @student, active_all: true)
      @course2 = @course
    end

    let(:type) do
      GraphQLTypeTester.new(
        @student,
        current_user: @student,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    it "returns primary enrollment courses if there are no favorite courses" do
      result = type.resolve("favoriteCoursesConnection { nodes { _id } }")
      expect(result).to match_array([@course1.id.to_s, @course2.id.to_s])
    end

    it "returns favorite courses" do
      @student.favorites.create!(context: @course1)
      result = type.resolve("favoriteCoursesConnection { nodes { _id } }")
      expect(result).to match_array([@course1.id.to_s])
    end
  end

  context "favorite_groups" do
    let(:type) do
      GraphQLTypeTester.new(
        @student,
        current_user: @student,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    it "returns all groups if there are no favorite groups" do
      group_with_user(user: @student, active_all: true)
      result = type.resolve("favoriteGroupsConnection { nodes { _id } }")
      expect(result).to match_array([@group.id.to_s])
    end

    it "return favorite groups" do
      2.times do
        group_with_user(user: @student, active_all: true)
      end
      @student.favorites.create!(context: @group)
      result = type.resolve("favoriteGroupsConnection { nodes { _id } }")
      expect(result).to match_array([@group.id.to_s])
    end
  end

  context "CommentBankItemsConnection" do
    before do
      @comment_bank_item = comment_bank_item_model(user: @teacher, context: @course, comment: "great comment!")
    end

    let(:type) do
      GraphQLTypeTester.new(
        @teacher,
        current_user: @teacher,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    it "returns comment bank items for the queried user" do
      expect(
        type.resolve("commentBankItemsConnection { nodes { _id } }")
      ).to eq [@comment_bank_item.id.to_s]
    end

    describe "cross sharding" do
      specs_require_sharding

      it "returns comments across shards" do
        @shard1.activate do
          account = Account.create!(name: "new shard account")
          @course2 = course_factory(account:)
          @course2.enroll_user(@teacher)
          @comment2 = comment_bank_item_model(user: @teacher, context: @course2, comment: "shard 2 comment")
        end

        expect(
          type.resolve("commentBankItemsConnection { nodes { comment } }").sort
        ).to eq ["great comment!", "shard 2 comment"]
      end
    end

    describe "with the limit argument" do
      it "returns a limited number of results" do
        comment_bank_item_model(user: @teacher, context: @course, comment: "2nd great comment!")
        expect(
          type.resolve("commentBankItemsConnection(limit: 1) { nodes { comment } }").length
        ).to eq 1
      end
    end

    describe "with a search query" do
      before do
        @comment_bank_item2 = comment_bank_item_model(user: @teacher, context: @course, comment: "new comment!")
      end

      it "returns results that match the query" do
        expect(
          type.resolve("commentBankItemsConnection(query: \"new\") { nodes { _id } }").length
        ).to eq 1
      end

      it "strips leading/trailing white space" do
        expect(
          type.resolve("commentBankItemsConnection(query: \"    new   \") { nodes { _id } }").length
        ).to eq 1
      end

      it "does not query results if query.strip is blank" do
        expect(
          type.resolve("commentBankItemsConnection(query: \"  \") { nodes { _id } }").length
        ).to eq 2
      end
    end
  end

  context "courseBuiltInRoles" do
    before do
      @teacher_with_multiple_roles = user_factory(name: "blah")
      @course.enroll_user(@teacher_with_multiple_roles, "TeacherEnrollment")
      @course.enroll_user(@teacher_with_multiple_roles, "TaEnrollment", allow_multiple_enrollments: true)

      @custom_teacher = user_factory(name: "blah")
      role = custom_teacher_role("CustomTeacher", account: @course.account)
      @course.enroll_user(@custom_teacher, "TeacherEnrollment", role:)

      @teacher_with_duplicate_roles = user_factory(name: "blah")
      @course.enroll_user(@teacher_with_duplicate_roles, "TeacherEnrollment")
      @course.enroll_user(@teacher_with_duplicate_roles, "TeacherEnrollment", allow_multiple_enrollments: true)
    end

    let(:user_ta_type) do
      GraphQLTypeTester.new(@ta, current_user: @teacher, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
    end

    let(:user_teacher_type) do
      GraphQLTypeTester.new(@teacher, current_user: @teacher, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
    end

    let(:teacher_ta_type) do
      GraphQLTypeTester.new(@teacher_with_multiple_roles, current_user: @teacher, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
    end

    let(:teacher_with_duplicate_role_types) do
      GraphQLTypeTester.new(@teacher_with_duplicate_roles, current_user: @teacher, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
    end

    let(:custom_teacher_type) do
      GraphQLTypeTester.new(@custom_teacher, current_user: @teacher, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
    end

    it "correctly returns default teacher role" do
      expect(
        user_teacher_type.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to eq ["TeacherEnrollment"]
    end

    it "correctly returns default TA role" do
      expect(
        user_ta_type.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to eq ["TaEnrollment"]
    end

    it "does not return student role" do
      expect(
        user_type.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to be_nil
    end

    it "returns nil when no course id is given" do
      expect(
        user_type.resolve(%|courseRoles(roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to be_nil
    end

    it "returns nil when course id is null" do
      expect(
        user_type.resolve(%|courseRoles(courseId: null, roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to be_nil
    end

    it "does not return custom roles based on teacher" do
      expect(
        custom_teacher_type.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to be_nil
    end

    it "Returns multiple roles when mutiple enrollments exist" do
      expect(
        teacher_ta_type.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to include("TaEnrollment", "TeacherEnrollment")
    end

    it "does not return duplicate roles when mutiple enrollments exist" do
      expect(
        teacher_with_duplicate_role_types.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to eq ["TeacherEnrollment"]
    end

    it "returns all roles if no role types are specified" do
      expect(
        teacher_ta_type.resolve(%|courseRoles(courseId: "#{@course.id}")|)
      ).to include("TaEnrollment", "TeacherEnrollment")
    end

    it "returns only the role specified" do
      expect(
        teacher_ta_type.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TaEnrollment"])|)
      ).to eq ["TaEnrollment"]
    end

    it "returns custom role's base_type if built_in_only is set to false" do
      expect(
        custom_teacher_type.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TeacherEnrollment"], builtInOnly: false)|)
      ).to eq ["TeacherEnrollment"]
    end
  end

  describe "submission comments" do
    before(:once) do
      course = Course.create! name: "TEST"
      course_2 = Course.create! name: "TEST 2"

      # these 'course_with_user' will  reassign @course
      @teacher = course_with_user("TeacherEnrollment", course:, name: "Mr Teacher", active_all: true).user
      @teacher = course_with_user("TeacherEnrollment", course: course_2, user: @teacher, active_all: true).user
      @student = course_with_user("StudentEnrollment", course:, name: "Mr Student 1", active_all: true).user
      @student_2 = course_with_user("StudentEnrollment", course:, name: "Mr Student 2", active_all: true).user
      @student_2 = course_with_user("StudentEnrollment", course: course_2, user: @student_2, active_all: true).user

      @course = course
      @course_2 = course_2
      assignment = @course.assignments.create!(
        name: "Test Assignment",
        moderated_grading: true,
        grader_count: 10,
        final_grader: @teacher
      )
      @assignment2 = @course.assignments.create!(
        name: "Assignment without Comments",
        moderated_grading: true,
        grader_count: 10,
        final_grader: @teacher
      )
      @assignment3 = @course_2.assignments.create!(
        name: "Assignment without Comments 2",
        moderated_grading: true,
        grader_count: 10,
        final_grader: @teacher
      )

      assignment.grade_student(@student, grade: 1, grader: @teacher, provisional: true)
      @assignment2.grade_student(@student, grade: 1, grader: @teacher, provisional: true)
      @assignment2.grade_student(@student_2, grade: 1, grader: @teacher, provisional: true)
      @assignment3.grade_student(@student_2, grade: 1, grader: @teacher, provisional: true)

      @student_submission_1 = assignment.submissions.find_by(user: @student)

      @sc1 = @student_submission_1.add_comment(author: @student, comment: "First comment")
      @sc2 = @student_submission_1.add_comment(author: @teacher, comment: "Second comment")
      @sc3 = @student_submission_1.add_comment(author: @teacher, comment: "Third comment")
    end

    let(:teacher_type) do
      GraphQLTypeTester.new(@teacher, current_user: @teacher, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
    end

    describe "viewableSubmissionsConnection field" do
      it "only gets submissions with comments" do
        query_result = teacher_type.resolve("viewableSubmissionsConnection { nodes { _id }  }")
        expect(query_result.count).to eq 1
        expect(query_result[0].to_i).to eq @student_submission_1.id
      end

      it "gets submissions with comments in order of last_comment_at DESC" do
        student_submission_2 = @assignment2.submissions.find_by(user: @student)
        student_submission_2.add_comment(author: @student, comment: "Fourth comment")
        student_submission_2.add_comment(author: @teacher, comment: "Fifth comment")

        student_submission_2.update_attribute(:last_comment_at, 1.day.ago)
        @student_submission_1.update_attribute(:last_comment_at, 2.days.ago)

        query_result = teacher_type.resolve("viewableSubmissionsConnection { nodes { _id }  }")

        expect(query_result.count).to eq 2
        expect(query_result[0].to_i).to eq student_submission_2.id
      end

      it "gets submissions with comments in order of last submission comment if last_comment_at is nil" do
        student_submission_2 = @assignment2.submissions.find_by(user: @student)
        student_submission_2.add_comment(author: @student, comment: "Fourth comment")
        student_submission_2.add_comment(author: @teacher, comment: "Fifth comment")

        student_submission_2.update_attribute(:last_comment_at, nil)
        @student_submission_1.update_attribute(:last_comment_at, nil)

        query_result = teacher_type.resolve("viewableSubmissionsConnection { nodes { _id }  }")

        expect(query_result.count).to eq 2
        expect(query_result[0].to_i).to eq student_submission_2.id
      end

      it "gets submissions with comments in order of last submission comment over last_comment_at" do
        student_submission_2 = @assignment2.submissions.find_by(user: @student)

        @student_submission_1.submission_comments.last.update_attribute(:created_at, Time.new(2024, 2, 9, 4, 21, 0).utc)
        @student_submission_1.update_attribute(:last_comment_at, nil)

        student_submission_2.add_comment(author: @student, comment: "Fourth comment", created_at: Time.new(2024, 2, 8, 13, 17, 0).utc)
        student_submission_2.add_comment(author: @teacher, comment: "Fifth comment", created_at: Time.new(2024, 2, 10, 5, 11, 0).utc)
        student_submission_2.update_attribute(:last_comment_at, Time.new(2024, 2, 8, 13, 17, 0).utc)

        # Notice: submission 2 is older, but submission 2 has newest submission_comment.
        query_result = teacher_type.resolve("viewableSubmissionsConnection { nodes { _id }  }")

        expect(query_result.count).to eq 2
        expect(query_result[0].to_i).to eq student_submission_2.id
      end

      it "can retrieve submission comments" do
        allow(InstStatsd::Statsd).to receive(:increment)
        query_result = teacher_type.resolve("viewableSubmissionsConnection { nodes { commentsConnection { nodes { comment }} }  }")
        expect(query_result[0].count).to eq 3
        expect(query_result[0]).to match_array ["First comment", "Second comment", "Third comment"]
        expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.visit.scope.submission_comments.pages_loaded.react")
      end

      it "can get createdAt" do
        query_result = teacher_type.resolve("viewableSubmissionsConnection { nodes { commentsConnection { nodes { createdAt }} }  }")
        retrieved_values = query_result[0].map { |string_date| Time.parse(string_date) }
        expect(retrieved_values).to all(be_within(1.minute).of(@sc1.created_at))
      end

      it "can get assignment names" do
        expect(teacher_type.resolve("viewableSubmissionsConnection { nodes { assignment { name }  }  }")[0]).to eq @student_submission_1.assignment.name
      end

      it "can get course names" do
        expect(teacher_type.resolve("viewableSubmissionsConnection { nodes { commentsConnection { nodes { course { name } } }  }  }")[0]).to match_array %w[TEST TEST TEST]
      end

      describe "filter" do
        before(:once) do
          # add_comments by user 2 to course 1 and 2
          student_submission_2 = @assignment2.submissions.find_by(user: @student_2)
          @student_submission_3 = @assignment3.submissions.find_by(user: @student_2)

          student_submission_2.add_comment(author: @student_2, comment: "Fourth comment")
          student_submission_2.add_comment(author: @teacher, comment: "Fifth comment")
          @student_submission_3.add_comment(author: @student_2, comment: "sixth comment")
          @student_submission_3.add_comment(author: @teacher, comment: "seventh comment")
        end

        it "submissions by course" do
          query_result = teacher_type.resolve("viewableSubmissionsConnection(filter: [\"course_#{@course_2.id}\"]) { nodes { _id }  }")
          expect(query_result.count).to eq 1
          expect(query_result[0].to_i).to eq @student_submission_3.id
        end

        it "submissions by user" do
          query_result = teacher_type.resolve("viewableSubmissionsConnection(filter: [\"user_#{@student_2.id}\"]) { nodes { _id }  }")
          expect(query_result.count).to eq 2
          expect(query_result[0].to_i).to eq @student_submission_3.id
        end
      end
    end
  end

  context "with a user" do
    before(:once) do
      @user = user_factory
    end

    let(:user_type) do
      GraphQLTypeTester.new(@user, current_user: @user, domain_root_account: @user.account, request: ActionDispatch::TestRequest.create)
    end

    it "returns the user's inbox labels" do
      @user.preferences[:inbox_labels] = ["Test 1", "Test 2"]
      @user.save!

      expect(user_type.resolve("inboxLabels")).to eq @user.inbox_labels
    end

    it "returns an empty user's inbox labels" do
      expect(user_type.resolve("inboxLabels")).to eq []
    end
  end
end
