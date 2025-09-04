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

describe TokensController do
  describe "developer keys" do
    context "not logged in" do
      it "requires being logged in to create an access token" do
        post "create", params: { user_id: "self", token: { purpose: "test" } }
        expect(response).to be_redirect
        expect(assigns[:token]).to be_nil
      end

      it "requires being logged in to delete an access token" do
        delete "destroy", params: { user_id: "self", id: 5 }
        expect(response).to be_redirect
      end

      it "requires being logged in to retrieve an access token" do
        get "show", params: { user_id: "self", id: 5 }
        expect(response).to be_redirect
      end

      it "requires being logged in to list manually generated access tokens" do
        get :user_generated_tokens, params: { user_id: "self" }
        expect(response).to be_redirect
      end
    end

    describe "#user_generated_tokens" do
      let_once(:admin_user) { account_admin_user }
      let_once(:target_user) { user_factory(active_user: true) }
      let_once(:other_user) { user_factory(active_user: true) }

      context "with admin privileges" do
        before do
          user_session(admin_user)
        end

        it "returns manually generated tokens for the specified user" do
          token1 = target_user.access_tokens.create!(purpose: "test token 1", developer_key: DeveloperKey.default)
          token2 = target_user.access_tokens.create!(purpose: "test token 2", developer_key: DeveloperKey.default)

          get :user_generated_tokens, params: { user_id: target_user.id }

          expect(response).to be_successful
          json = response.parsed_body
          expect(json.length).to eq 2
          expect(json.pluck("id")).to contain_exactly(token1.id, token2.id)
          expect(json.pluck("purpose")).to contain_exactly("test token 1", "test token 2")
        end

        it "excludes non-manually generated tokens" do
          manual_token = target_user.access_tokens.create!(purpose: "manual token", developer_key: DeveloperKey.default)
          external_key = DeveloperKey.create!(name: "external_app")
          target_user.access_tokens.create!(developer_key: external_key)

          get :user_generated_tokens, params: { user_id: target_user.id }

          expect(response).to be_successful
          json = response.parsed_body
          expect(json.length).to eq 1
          expect(json.first["id"]).to eq manual_token.id
        end

        it "supports pagination" do
          (1..15).map do |i|
            target_user.access_tokens.create!(purpose: "token #{i}", developer_key: DeveloperKey.default)
          end

          get :user_generated_tokens, params: { user_id: target_user.id, per_page: 10 }

          expect(response).to be_successful
          json = response.parsed_body
          expect(json.length).to eq 10

          # Check that pagination headers are present
          expect(response.headers["Link"]).to be_present
          expect(response.headers["Link"]).to include("next")
        end

        it "orders tokens by created_at and id" do
          Timecop.freeze(1.hour.ago) do
            @token1 = target_user.access_tokens.create!(purpose: "older token", developer_key: DeveloperKey.default)
          end
          @token2 = target_user.access_tokens.create!(purpose: "newer token", developer_key: DeveloperKey.default)

          get :user_generated_tokens, params: { user_id: target_user.id }

          expect(response).to be_successful
          json = response.parsed_body
          expect(json.length).to eq 2
          expect(json.first["id"]).to eq @token1.id
          expect(json.second["id"]).to eq @token2.id
        end

        it "includes proper token attributes in response" do
          token = target_user.access_tokens.create!(
            purpose: "test token",
            developer_key: DeveloperKey.default,
            permanent_expires_at: 1.week.from_now
          )

          get :user_generated_tokens, params: { user_id: target_user.id }

          expect(response).to be_successful
          json = response.parsed_body
          token_json = json.first

          expect(token_json).to include(
            "id" => token.id,
            "purpose" => "test token",
            "user_id" => target_user.id,
            "created_at" => token.created_at.iso8601,
            "expires_at" => token.permanent_expires_at.iso8601,
            "workflow_state" => "active",
            "scopes" => []
          )
        end

        context "with cross-shard tokens" do
          specs_require_sharding

          it "returns tokens from all shards" do
            target_user.associate_with_shard(@shard1)
            target_user.associate_with_shard(@shard2)
            @shard1.activate do
              AccessToken.create!(user: target_user, developer_key: DeveloperKey.default, purpose: "shard 1 token")
            end

            @shard2.activate do
              AccessToken.create!(user: target_user, developer_key: DeveloperKey.default, purpose: "shard 2 token")
            end

            get :user_generated_tokens, params: { user_id: target_user.id }

            expect(response).to be_successful
            json = response.parsed_body
            expect(json.length).to eq 2
            expect(json.pluck("purpose").sort).to contain_exactly("shard 1 token",
                                                                  "shard 2 token")
          end
        end
      end

      context "without admin privileges" do
        before do
          user_session(other_user)
        end

        it "returns unauthorized when user lacks permission" do
          get :user_generated_tokens, params: { user_id: target_user.id }

          expect(response).to have_http_status(:unauthorized)
        end

        it "allows users to view their own tokens when they have appropriate permissions" do
          user_session(target_user)

          get :user_generated_tokens, params: { user_id: target_user.id }

          expect(response).to have_http_status(:ok)
        end
      end

      context "with teacher privileges" do
        let_once(:course) { course_model }
        let_once(:teacher) { teacher_in_course(course:, active_all: true).user }
        let_once(:student) { student_in_course(course:, active_all: true).user }

        before do
          user_session(teacher)
        end

        it "returns unauthorized when teacher tries to view student tokens" do
          student.access_tokens.create!(purpose: "student token", developer_key: DeveloperKey.default)

          get :user_generated_tokens, params: { user_id: student.id }

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "with student privileges" do
        let_once(:course) { course_model }
        let_once(:student1) { student_in_course(course:, active_all: true).user }
        let_once(:student2) { student_in_course(course:, active_all: true).user }

        before do
          user_session(student1)
        end

        it "returns unauthorized when student tries to view other student tokens" do
          student2.access_tokens.create!(purpose: "other student token", developer_key: DeveloperKey.default)

          get :user_generated_tokens, params: { user_id: student2.id }

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context "logged in" do
      before :once do
        user_factory(active_user: true)
      end

      before do
        user_session(@user)
      end

      it "allows creating an access token" do
        post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "jun 1 2011" } }
        expect(response).to be_successful
        expect(assigns[:token]).not_to be_nil
        expect(assigns[:token].developer_key).to eq DeveloperKey.default
        expect(assigns[:token].purpose).to eq "test"
        expect(assigns[:token].permanent_expires_at.to_date).to eq Time.zone.parse("jun 1 2011").to_date
        expect(assigns[:token]).to be_active
      end

      it "does not allow creating an access token while masquerading" do
        Account.site_admin.account_users.create!(user: @user)
        session[:become_user_id] = user_with_pseudonym(active_all: true).id

        post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "jun 1 2011" } }
        assert_status(401)
      end

      it "does not allow explicitly setting the token value" do
        post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "jun 1 2011", token: "mytoken" } }
        expect(response).to be_successful
        expect(response.body).not_to match(/mytoken/)
        expect(assigns[:token]).not_to be_nil
        expect(assigns[:token].full_token).not_to match(/mytoken/)
        expect(response.body).to match(/#{assigns[:token].full_token}/)
        expect(assigns[:token].developer_key).to eq DeveloperKey.default
        expect(assigns[:token].purpose).to eq "test"
        expect(assigns[:token].permanent_expires_at.to_date).to eq Time.zone.parse("jun 1 2011").to_date
      end

      it "does not allow creating a token without a purpose param" do
        post "create", params: { user_id: "self", token: { expires_at: "jun 1 2011" } }
        assert_status(400)
        expect(response.body).to match(/purpose/)
      end

      it "allows deleting an access token" do
        token = @user.access_tokens.create!(purpose: "test")
        expect(token.user_id).to eq @user.id
        delete "destroy", params: { user_id: "self", id: token.id }
        expect(response).to be_successful
        expect(token.reload).to be_deleted
      end

      context "with student_access_token_management disabled" do
        before { Account.site_admin.disable_feature!(:student_access_token_management) }

        it "does not allow deleting an access token while masquerading" do
          Account.site_admin.account_users.create!(user: @user)
          session[:become_user_id] = user_with_pseudonym(active_all: true).id
          token = @user.access_tokens.create!(purpose: "test")
          expect(token.user_id).to eq @user.id

          delete "destroy", params: { user_id: "self", id: token.id }
          assert_status(401)
        end
      end

      it "does not allow deleting someone else's access token" do
        user2 = User.create!
        token = user2.access_tokens.create!(purpose: "test")
        expect(token.user_id).to eq user2.id
        delete "destroy", params: { user_id: "self", id: token.id }
        assert_status(404)
      end

      it "allows retrieving an access token, but not give the full token string" do
        token = @user.access_tokens.new
        token.developer_key = DeveloperKey.default
        token.purpose = "test"
        token.save!
        expect(token.user_id).to eq @user.id
        expect(token.manually_created?).to be true
        get "show", params: { user_id: "self", id: token.id }
        expect(response).to be_successful
        expect(assigns[:token]).to eq token
        expect(response.body).to match(/#{assigns[:token].token_hint}/)
      end

      it "does not include token for non-manually-generated tokens" do
        key = DeveloperKey.create!(name: "test_key_#{SecureRandom.hex(4)}")
        token = @user.access_tokens.create!(developer_key: key)
        expect(token.user_id).to eq @user.id
        expect(token.manually_created?).to be false
        get "show", params: { user_id: "self", id: token.id }
        expect(response).to be_successful
        expect(assigns[:token]).to eq token
        expect(response.body).not_to match(/#{assigns[:token].token_hint}/)
      end

      it "does not allow retrieving someone else's access token" do
        user2 = User.create!
        token = user2.access_tokens.create!(purpose: "test")
        expect(token.user_id).to eq user2.id
        get "show", params: { user_id: "self", id: token.id }
        assert_status(404)
      end

      it "allows updating a token" do
        token = @user.access_tokens.new
        token.developer_key = DeveloperKey.default
        token.purpose = "test"
        token.save!
        expect(token.user_id).to eq @user.id
        expect(token.manually_created?).to be true
        put "update", params: { user_id: "self", id: token.id, token: { purpose: "new purpose" } }
        expect(response).to be_successful
        expect(assigns[:token]).to eq token
        expect(assigns[:token].purpose).to eq "new purpose"
        expect(response.body).to match(/#{assigns[:token].token_hint}/)
        expect(assigns[:token]).to be_active
      end

      it "does not overwrite the token's permanent_expires_at on update if expires_at not provided" do
        token = @user.access_tokens.create!(permanent_expires_at: 1.day.from_now, purpose: "test")
        put "update", params: { user_id: "self", id: token.id, token: { purpose: "test" } }
        expect(assigns[:token].purpose).to eq "test"
        expect(assigns[:token].permanent_expires_at).to eq token.permanent_expires_at
      end

      it "allows regenerating a manually generated token" do
        token = @user.access_tokens.new
        token.developer_key = DeveloperKey.default
        token.purpose = "test"
        token.save!
        expect(token.user_id).to eq @user.id
        expect(token.manually_created?).to be true
        put "update", params: { user_id: "self", id: token.id, token: { regenerate: "1" } }
        expect(response).to be_successful
        expect(assigns[:token]).to eq token
        expect(assigns[:token].crypted_token).not_to eq token.crypted_token
        expect(response.body).to match(/#{assigns[:token].full_token}/)
        expect(assigns[:token]).to be_active
      end

      it "does not allow regenerating a token while masquerading" do
        Account.site_admin.account_users.create!(user: @user)
        session[:become_user_id] = user_with_pseudonym(active_all: true).id
        token = @user.access_tokens.new
        token.developer_key = DeveloperKey.default
        token.purpose = "test"
        token.save!
        expect(token.user_id).to eq @user.id
        expect(token.manually_created?).to be true
        put "update", params: { user_id: "self", id: token.id, token: { regenerate: "1" } }
        assert_status(401)
      end

      it "does not allow regenerating a non-manually-generated token" do
        key = DeveloperKey.create!(name: "test_key_#{SecureRandom.hex(4)}")
        token = @user.access_tokens.create!(developer_key: key)
        expect(token.user_id).to eq @user.id
        expect(token.manually_created?).to be false
        put "update", params: { user_id: "self", id: token.id, token: { regenerate: "1" } }
        expect(response).to be_successful
        expect(assigns[:token]).to eq token
        expect(assigns[:token].crypted_token).to eq token.crypted_token
        expect(response.body).not_to match(/#{assigns[:token].token_hint}/)
      end

      it "does not allow regenerating an expired token without a new expiration date" do
        token = @user.access_tokens.create!(permanent_expires_at: 1.day.ago, purpose: "test")
        put "update", params: { user_id: "self", id: token.id, token: { regenerate: "1" } }
        assert_status(400)
      end

      it "allows regenerating an expired token with a new expiration date" do
        token = @user.access_tokens.create!(permanent_expires_at: 1.day.ago, purpose: "test")
        put "update", params: { user_id: "self", id: token.id, token: { regenerate: "1", expires_at: 1.day.from_now } }
        assert_status(200)
      end

      it "does not allow updating someone else's token" do
        user2 = User.create!
        token = user2.access_tokens.create!(purpose: "test")
        expect(token.user_id).to eq user2.id
        put "update", params: { user_id: user2.id, id: token.id, token: { regenerate: "1" } }
        assert_status(404)
      end

      it "allows activating a pending token" do
        token = @user.access_tokens.new(workflow_state: "pending")
        token.developer_key = DeveloperKey.default
        token.purpose = "test"
        token.save!
        expect(token.user_id).to eq @user.id
        expect(token.manually_created?).to be true
        post "activate", params: { id: token.id, token: { purpose: "new purpose" } }
        expect(response).to be_successful
        expect(assigns[:token]).to eq token
        expect(assigns[:token]).to be_active
      end

      it "does not allow activating an active token" do
        token = @user.access_tokens.new
        token.developer_key = DeveloperKey.default
        token.purpose = "test"
        token.save!
        expect(token.user_id).to eq @user.id
        expect(token.manually_created?).to be true
        post "activate", params: { id: token.id, token: { purpose: "new purpose" } }
        assert_status(400)
      end

      it "does not allow activating a pending token while masquerading" do
        Account.site_admin.account_users.create!(user: @user)
        session[:become_user_id] = user_with_pseudonym(active_all: true).id
        token = @user.access_tokens.new(workflow_state: "pending")
        token.developer_key = DeveloperKey.default
        token.purpose = "test"
        token.save!
        expect(token.user_id).to eq @user.id
        expect(token.manually_created?).to be true
        put "update", params: { user_id: "self", id: token.id, token: { regenerate: "1" } }
        assert_status(401)
      end

      context "with admin manage access tokens feature flag on" do
        before(:once) { Account.default.root_account.enable_feature!(:admin_manage_access_tokens) }

        context "with limit_personal_access_tokens setting on" do
          before(:once) do
            Account.default.change_root_account_setting!(:limit_personal_access_tokens, true)
            Account.site_admin.disable_feature!(:student_access_token_management)
          end

          context "as non-admin" do
            it "does not allow creating an access token" do
              post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "" } }
              assert_status(401)
            end

            it "does not allow updating an access token" do
              token = @user.access_tokens.create!(purpose: "test")
              put "update", params: { user_id: "self", id: token.id, token: { regenerate: "1" } }
              assert_status(401)
            end
          end

          context "as admin" do
            before(:once) { @admin = account_admin_user }

            before { user_session(@admin) }

            it "allows creating an access token" do
              post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "" } }
              assert_status(200)
              expect(assigns[:token]).to be_active
            end

            it "allows updating an access token" do
              token = @admin.access_tokens.create!(purpose: "test")
              put "update", params: { user_id: "self", id: token.id, token: { regenerate: "1" } }
              assert_status(200)
              expect(assigns[:token]).to be_active
            end

            context "for another user" do
              before(:once) do
                @other_user = user_with_pseudonym(active_all: true)
              end

              it "allows creating an access token" do
                post "create", params: { user_id: @other_user.id, token: { purpose: "test", expires_at: "jun 1 2011" } }
                expect(response).to be_successful
                expect(assigns[:token]).not_to be_nil
                expect(assigns[:token].developer_key).to eq DeveloperKey.default
                expect(assigns[:token].purpose).to eq "test"
                expect(assigns[:token].permanent_expires_at.to_date).to eq Time.zone.parse("jun 1 2011").to_date
                expect(assigns[:token].user).to eq @other_user
                expect(assigns[:token]).to be_pending
              end

              it "does not allow creating an access token without proper permissions" do
                account_with_role_changes(role_changes: { create_access_tokens: false })
                session[:become_user_id] = user_with_pseudonym(active_all: true).id

                post "create", params: { user_id: @other_user.id, token: { purpose: "test", expires_at: "jun 1 2011" } }
                assert_status(401)
              end

              it "allows updating an access token" do
                token = @other_user.access_tokens.create!(purpose: "test")
                expect(token).to be_active
                put "update", params: { user_id: @other_user.id, id: token.id, token: { regenerate: "1" } }

                assert_status(200)
                expect(assigns[:token]).to be_pending
              end

              context "while masquerading" do
                before do
                  session[:become_user_id] = @other_user.id
                end

                it "allows creating an access token" do
                  post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "jun 1 2011" } }
                  expect(response).to be_successful
                  expect(assigns[:token]).not_to be_nil
                  expect(assigns[:token].developer_key).to eq DeveloperKey.default
                  expect(assigns[:token].purpose).to eq "test"
                  expect(assigns[:token].permanent_expires_at.to_date).to eq Time.zone.parse("jun 1 2011").to_date
                  expect(assigns[:token].user).to eq @other_user
                  expect(assigns[:token]).to be_pending
                end

                it "does not allow creating an access token without proper permissions" do
                  account_with_role_changes(role_changes: { create_access_tokens: false })

                  post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "jun 1 2011" } }
                  assert_status(401)
                end

                it "allows updating an access token" do
                  token = @other_user.access_tokens.create!(purpose: "test")
                  expect(token).to be_active
                  put "update", params: { user_id: "self", id: token.id, token: { regenerate: "1" } }

                  assert_status(200)
                  expect(assigns[:token]).to be_pending
                end
              end
            end
          end
        end

        context "with restrict_personal_access_tokens_from_students setting on" do
          before(:once) do
            Account.default.change_root_account_setting!(:restrict_personal_access_tokens_from_students, true)
            Account.site_admin.disable_feature!(:student_access_token_management)
          end

          shared_examples_for "access token creation and update denied" do
            it "does not allow creating an access token" do
              post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "" } }
              assert_status(401)
            end

            it "does not allow updating an access token" do
              token = @user.access_tokens.create!(purpose: "test")
              put "update", params: { user_id: "self", id: token.id, token: { regenerate: "1" } }
              assert_status(401)
            end
          end

          context "as a 'nobody'" do
            it_behaves_like "access token creation and update denied"
          end

          context "as a student" do
            before do
              course_with_student(active_all: true, user: @user)
            end

            it_behaves_like "access token creation and update denied"
          end

          context "as a teacher" do
            before do
              course_with_teacher(active_all: true, user: @user)
            end

            it "does allows creating an access token" do
              post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "" } }
              assert_status(200)
            end

            it "does allows updating an access token" do
              token = @user.access_tokens.create!(purpose: "test")
              put "update", params: { user_id: "self", id: token.id, token: { regenerate: "1" } }
              assert_status(200)
            end
          end
        end

        context "with both limit_personal_access_tokens and restrict_personal_access_tokens_from_students setting off" do
          before(:once) { Account.default.change_root_account_setting!(:limit_personal_access_tokens, false) }

          context "as non-admin" do
            it "allows creating an access token" do
              post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "" } }
              assert_status(200)
            end

            it "allows updating an access token" do
              token = @user.access_tokens.create!(purpose: "test")
              put "update", params: { user_id: "self", id: token.id, token: { regenerate: "1" } }
              assert_status(200)
            end
          end
        end

        context "with student_access_token_management flag" do
          context "when flag is off" do
            before(:once) { Account.site_admin.disable_feature!(:student_access_token_management) }

            it "doesn't enforce expiry for any user" do
              post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "" } }
              expect(response).to be_successful
              expect(assigns[:token].permanent_expires_at).to be_nil
            end
          end

          context "when flag is on" do
            before(:once) { Account.site_admin.enable_feature!(:student_access_token_management) }

            context "as an admin" do
              before(:once) { @admin = account_admin_user }
              before { user_session(@admin) }

              it "doesn't enforce expiry for an admin" do
                post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "" } }
                expect(response).to be_successful
                expect(assigns[:token].permanent_expires_at).to be_nil
              end
            end

            context "as a teacher" do
              before do
                course_with_teacher(active_all: true, user: @user)
              end

              it "doesn't enforce expiry for a teacher" do
                post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "" } }
                expect(response).to be_successful
                expect(assigns[:token].permanent_expires_at).to be_nil
              end
            end

            context "as a teacher with student enrollments" do
              before do
                course_with_teacher(active_all: true, user: @user)
                course_with_student(active_all: true, user: @user)
              end

              it "doesn't enforce expiry for a teacher with some student enrollments" do
                post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "" } }
                expect(response).to be_successful
                expect(assigns[:token].permanent_expires_at).to be_nil
              end
            end

            context "as a user with only student enrollments" do
              before do
                course_with_student(active_all: true, user: @user)
              end

              it "rejects tokens without expiry" do
                post "create", params: { user_id: "self", token: { purpose: "test", expires_at: "" } }
                # expect response to not be successful
                expect(response).not_to be_successful
              end

              it "rejects tokens with an expiry past the maximum" do
                expires_at = (TokensController::MAXIMUM_EXPIRATION_DURATION + 1.day).from_now
                post "create", params: { user_id: "self", token: { purpose: "test", expires_at: } }
                expect(response).not_to be_successful
              end

              it "allows tokens with an expiry" do
                expires_at = (TokensController::MAXIMUM_EXPIRATION_DURATION - 1.day).from_now
                post "create", params: { user_id: "self", token: { purpose: "test", expires_at: } }
                expect(response).to be_successful
              end
            end
          end
        end
      end
    end
  end
end
