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

describe EportfolioEntriesController do
  def eportfolio_category
    @category = @portfolio.eportfolio_categories.create
  end

  def eportfolio_entry(category = nil)
    @entry = @portfolio.eportfolio_entries.new
    @entry.eportfolio_category_id = category.id if category
    @entry.save!
  end

  before :once do
    eportfolio_with_user(active_all: true)
    @user.account_users.create!(account: Account.default, role: student_role)
    eportfolio_category
  end

  describe "GET 'show'" do
    before(:once) { eportfolio_entry(@category) }

    it "requires authorization" do
      get "show", params: { eportfolio_id: @portfolio.id, id: @entry.id }
      assert_unauthorized
    end

    it "assigns variables" do
      user_session(@user)
      attachment = @portfolio.user.attachments.build(filename: "some_file.pdf")
      attachment.content_type = ""
      attachment.save!
      @entry.content = [{ section_type: "attachment", attachment_id: attachment.id }]
      @entry.save!
      get "show", params: { eportfolio_id: @portfolio.id, id: @entry.id }
      expect(response).to be_successful
      expect(assigns[:category]).to eql(@category)
      expect(assigns[:page]).to eql(@entry)
      expect(assigns[:entries]).not_to be_nil
      expect(assigns[:entries]).not_to be_empty
      expect(assigns[:attachments]).not_to be_nil
      expect(assigns[:attachments]).not_to be_empty
    end

    it "works off of category and entry names" do
      user_session(@user)
      @category.name = "some category"
      @category.save!
      @entry.name = "some entry"
      @entry.save!
      get "show", params: { eportfolio_id: @portfolio.id, category_name: @category.slug, entry_name: @entry.slug }
      expect(assigns[:category]).to eql(@category)
      expect(assigns[:page]).to eql(@entry)
      expect(assigns[:entries]).not_to be_nil
      expect(assigns[:entries]).not_to be_empty
    end

    describe "js_env" do
      before do
        user_session(@user)
        @category.name = "some category"
        @category.save!
        @entry.name = "some entry"
        @entry.save!
      end

      it "sets SKIP_ENHANCING_USER_CONTENT to true" do
        get "show", params: { eportfolio_id: @portfolio.id, category_name: @category.slug, entry_name: @entry.slug }
        expect(assigns.dig(:js_env, :SKIP_ENHANCING_USER_CONTENT)).to be true
      end

      it "sets SECTION_COUNT_IDX before layout and templates are rendered" do
        @entry.content = [
          { section_type: "rich_text", content: "<p>1</p>" },
          { section_type: "rich_text", content: "<p>2</p>" },
          { section_type: "rich_text", content: "<p>3</p>" }
        ]
        @entry.save!
        get "show", params: { eportfolio_id: @portfolio.id, category_name: @category.slug, entry_name: @entry.slug }
        expect(assigns.dig(:js_env, :SECTION_COUNT_IDX)).to eq 3
      end
    end

    context "spam eportfolios" do
      before(:once) do
        @portfolio.update!(public: true)
        @category = eportfolio_category
        eportfolio_entry(@category)
      end

      context "when the user is the author of the eportfolio" do
        it "renders the entry when the eportfolio is spam" do
          @portfolio.update!(spam_status: "marked_as_spam")
          user_session(@user)
          get :show, params: { eportfolio_id: @portfolio.id, id: @entry.id }

          expect(response).to have_http_status(:ok)
        end
      end

      context "when the user is a non-admin, non-author of the eportfolio" do
        before(:once) do
          @other_user = user_model
          @other_user.account_users.create!(account: Account.default, role: student_role)
        end

        it "is unauthorized when the eportfolio is spam" do
          @portfolio.update!(spam_status: "marked_as_spam")
          user_session(@other_user)
          get :show, params: { eportfolio_id: @portfolio.id, id: @entry.id }

          assert_unauthorized
        end
      end

      context "when the user is an admin" do
        before(:once) do
          @admin = account_admin_user
        end

        it "renders the entry when the eportfolio is spam and the admin has :moderate_user_content permissions" do
          @portfolio.update!(spam_status: "marked_as_spam")
          Account.default.role_overrides.create!(role: admin_role, enabled: true, permission: :moderate_user_content)
          user_session(@admin)
          get :show, params: { eportfolio_id: @portfolio.id, id: @entry.id }

          expect(response).to have_http_status(:ok)
        end

        it "is unauthorized when the eportfolio is spam and the admin does not have :moderate_user_content permissions" do
          @portfolio.update!(spam_status: "marked_as_spam")
          Account.default.role_overrides.create!(role: admin_role, enabled: false, permission: :moderate_user_content)
          user_session(@admin)
          get :show, params: { eportfolio_id: @portfolio.id, id: @entry.id }

          assert_unauthorized
        end
      end
    end
  end

  describe "POST 'create'" do
    it "requires authorization" do
      post "create", params: { eportfolio_id: @portfolio.id }
      assert_unauthorized
    end

    it "creates entry" do
      user_session(@user)
      post "create", params: { eportfolio_id: @portfolio.id, eportfolio_entry: { eportfolio_category_id: @category.id, name: "some entry" } }
      expect(response).to be_redirect
      expect(assigns[:category]).to eql(@category)
      expect(assigns[:page]).not_to be_nil
      expect(assigns[:page].name).to eql("some entry")
    end
  end

  describe "PUT 'update'" do
    before(:once) { eportfolio_entry(@category) }

    it "requires authorization" do
      put "update", params: { eportfolio_id: @portfolio.id, id: @entry.id }
      assert_unauthorized
    end

    it "updates entry" do
      user_session(@user)
      put "update", params: { eportfolio_id: @portfolio.id, id: @entry.id, eportfolio_entry: { name: "new name" } }
      expect(response).to be_redirect
      expect(assigns[:entry]).not_to be_nil
      expect(assigns[:entry].name).to eql("new name")
    end
  end

  describe "DELETE 'destroy'" do
    before(:once) { eportfolio_entry(@category) }

    it "requires authorization" do
      delete "destroy", params: { eportfolio_id: @portfolio.id, id: @entry.id }
      assert_unauthorized
    end

    it "deletes entry" do
      user_session(@user)
      delete "destroy", params: { eportfolio_id: @portfolio.id, id: @entry.id }
      expect(response).to be_redirect
      expect(assigns[:entry]).not_to be_nil
      expect(assigns[:entry]).to be_frozen
    end
  end

  describe "GET 'attachment'" do
    before(:once) { eportfolio_entry(@category) }

    it "requires authorization" do
      get "attachment", params: { eportfolio_id: @portfolio.id, entry_id: @entry.id, attachment_id: 1 }
      assert_unauthorized
    end

    it "will 404 for bad IDs" do
      user_session(@user)
      get "attachment", params: { eportfolio_id: @portfolio.id, entry_id: @entry.id, attachment_id: SecureRandom.uuid }
      expect(response).to have_http_status(:not_found)
    end

    describe "with sharding" do
      specs_require_sharding

      it "finds attachments on all shards associated with user" do
        user_session(@user)
        @shard1.activate do
          @user.associate_with_shard(@shard1)
          @a1 = Attachment.create!(user: @user, context: @user, filename: "test.jpg", uploaded_data: StringIO.new("first"))
        end
        get "attachment", params: { eportfolio_id: @portfolio.id, entry_id: @entry.id, attachment_id: @a1.uuid }
      end
    end
  end

  describe "GET 'submission'" do
    before(:once) do
      eportfolio_entry(@category)
      @student = @user
      course = Course.create!
      course.enroll_student(@student).accept(true)
      teacher = teacher_in_course(course:, active_all: true).user
      @assignment = course.assignments.create!
      @submission = @assignment.submissions.find_by(user: @student)
      @assignment.grade_student(@student, grader: teacher, score: 5)
    end

    it "requires authorization" do
      get "submission", params: { eportfolio_id: @portfolio.id, entry_id: @entry.id, submission_id: @submission.id }
      assert_unauthorized
    end

    it "passes anonymize_students: false to the template if the assignment is not anonymous" do
      user_session(@student)
      expect(controller).to receive(:render).with({
                                                    template: "submissions/show_preview",
                                                    locals: { anonymize_students: false }
                                                  }).and_call_original

      get "submission", params: { eportfolio_id: @portfolio.id, entry_id: @entry.id, submission_id: @submission.id }
    end

    it "passes anonymize_students: false to the template if the assignment is anonymous and grades are posted" do
      user_session(@student)
      @assignment.update!(anonymous_grading: true)
      @assignment.post_submissions
      expect(controller).to receive(:render).with({
                                                    template: "submissions/show_preview",
                                                    locals: { anonymize_students: false }
                                                  }).and_call_original

      get "submission", params: { eportfolio_id: @portfolio.id, entry_id: @entry.id, submission_id: @submission.id }
    end

    it "passes anonymize_students: true to the template if the assignment is anonymous and grades are unposted" do
      user_session(@student)
      @assignment.update!(anonymous_grading: true)
      @assignment.hide_submissions
      expect(controller).to receive(:render).with({
                                                    template: "submissions/show_preview",
                                                    locals: { anonymize_students: true }
                                                  }).and_call_original

      get "submission", params: { eportfolio_id: @portfolio.id, entry_id: @entry.id, submission_id: @submission.id }
    end
  end
end
