require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe SisApiController, type: :request do
  def enable_bulk_grade_export
    context.root_account.enable_feature!(:bulk_sis_grade_export)
  end

  def install_post_grades_tool
    context.context_external_tools.create!(
      name: 'test post grades tool',
      domain: 'http://example.com/lti',
      consumer_key: 'key',
      shared_secret: 'secret',
      settings: { post_grades: { url: 'http://example.com/lti/post_grades' } }
    ).tap do |tool|
      tool.context_external_tool_placements.create!(placement_type: 'post_grades')
    end
  end

  describe '#sis_assignments' do
    context 'for an account' do
      before :once do
        account_model
        account_admin_user(account: @account, active_all: true)
      end

      # courses
      let_once(:course1) { course(account: @account) } # unpublished
      let_once(:course2) { course(account: @account, active_all: true) }
      let_once(:course3) { course(account: @account, active_all: true) }

      # non-postable assignments
      let_once(:assignment1)  { course1.assignments.create!(post_to_sis: true) } # unpublished course
      let_once(:assignment2)  { course1.assignments.create!(post_to_sis: false) } # unpublished course
      let_once(:assignment3)  { course2.assignments.create!(post_to_sis: false) } # post_to_sis: false
      let_once(:assignment4)  { course3.assignments.create!(post_to_sis: false) } # post_to_sis: false
      let_once(:assignment5)  { course1.assignments.create!(post_to_sis: true).tap(&:unpublish!) } # unpublished
      let_once(:assignment6)  { course2.assignments.create!(post_to_sis: true).tap(&:unpublish!) } # unpublished
      let_once(:assignment7)  { course3.assignments.create!(post_to_sis: true).tap(&:unpublish!) } # unpublished

      # postable assignments
      let_once(:assignment8)  { course2.assignments.create!(post_to_sis: true) }
      let_once(:assignment9)  { course2.assignments.create!(post_to_sis: true) }
      let_once(:assignment10) { course3.assignments.create!(post_to_sis: true) }
      let_once(:assignment11) { course3.assignments.create!(post_to_sis: true) }

      let(:context) { @account }

      before do
        user_session(@user)
      end

      it 'requires :bulk_sis_grade_export feature to be enabled or post_grades tool to be installed' do
        get "/api/sis/accounts/#{@account.id}/assignments", account_id: @account.id
        expect(response.status).to eq 400
      end

      shared_examples 'account sis assignments api' do
        it 'requires :view_all_grades permission' do
          @account.role_overrides.create!(permission: :view_all_grades, enabled: false, role: admin_role)
          get "/api/sis/accounts/#{@account.id}/assignments", account_id: @account.id
          assert_unauthorized
        end

        it 'returns paginated assignment list' do
          # first page
          get "/api/sis/accounts/#{@account.id}/assignments", account_id: @account.id, per_page: 2
          expect(response).to be_success
          result_json = json_parse
          expect(result_json.length).to eq(2)
          expect(result_json[0]).to include('id' => assignment8.id)
          expect(result_json[1]).to include('id' => assignment9.id)

          # second page
          get "/api/sis/accounts/#{@account.id}/assignments", account_id: @account.id, per_page: 2, page: 2
          expect(response).to be_success
          result_json = json_parse
          expect(result_json.length).to eq(2)
          expect(result_json[0]).to include('id' => assignment10.id)
          expect(result_json[1]).to include('id' => assignment11.id)

          # third page
          get "/api/sis/accounts/#{@account.id}/assignments", account_id: @account.id, per_page: 2, page: 3
          expect(json_parse.length).to eq(0)
        end
      end

      context 'with :bulk_sis_grade_export feature enabled' do
        before do
          enable_bulk_grade_export
        end

        include_examples 'account sis assignments api'
      end

      context 'with a post_grades tool installed' do
        before do
          install_post_grades_tool
        end

        include_examples 'account sis assignments api'
      end
    end

    context 'for a published course' do
      before :once do
        course(active_all: true)
        account_admin_user(account: @course.root_account, active_all: true)
      end

      # non-postable assignments
      let_once(:assignment1) { @course.assignments.create!(post_to_sis: false) } # post_to_sis: false
      let_once(:assignment2) { @course.assignments.create!(post_to_sis: false) } # post_to_sis: false
      let_once(:assignment3) { @course.assignments.create!(post_to_sis: true).tap(&:unpublish!) } # unpublished

      # postable assignments
      let_once(:assignment4) { @course.assignments.create!(post_to_sis: true) }
      let_once(:assignment5) { @course.assignments.create!(post_to_sis: true) }
      let_once(:assignment6) { @course.assignments.create!(post_to_sis: true) }
      let_once(:assignment7) { @course.assignments.create!(post_to_sis: true) }

      let(:context) { @course }

      before do
        user_session(@user)
      end

      it 'requires :bulk_sis_grade_export feature to be enabled or post_grades tool to be installed' do
        get "/api/sis/courses/#{@course.id}/assignments", course_id: @course.id
        expect(response.status).to eq 400
      end

      shared_examples 'course sis assignments api' do
        it 'requires :view_all_grades permission' do
          @course.root_account.role_overrides.create!(permission: :view_all_grades, enabled: false, role: admin_role)
          get "/api/sis/courses/#{@course.id}/assignments", course_id: @course.id
          assert_unauthorized
        end

        it 'returns paginated assignment list' do
          # first page
          get "/api/sis/courses/#{@course.id}/assignments", course_id: @course.id, per_page: 2
          expect(response).to be_success
          result_json = json_parse
          expect(result_json.length).to eq(2)
          expect(result_json[0]).to include('id' => assignment4.id)
          expect(result_json[1]).to include('id' => assignment5.id)

          # second page
          get "/api/sis/courses/#{@course.id}/assignments", course_id: @course.id, per_page: 2, page: 2
          expect(response).to be_success
          result_json = json_parse
          expect(result_json.length).to eq(2)
          expect(result_json[0]).to include('id' => assignment6.id)
          expect(result_json[1]).to include('id' => assignment7.id)

          # third page
          get "/api/sis/courses/#{@course.id}/assignments", course_id: @course.id, per_page: 2, page: 3
          expect(json_parse.length).to eq(0)
        end
      end

      context 'with :bulk_sis_grade_export feature enabled' do
        before do
          enable_bulk_grade_export
        end

        include_examples 'course sis assignments api'
      end

      context 'with a post_grades tool installed' do
        before do
          install_post_grades_tool
        end

        include_examples 'course sis assignments api'
      end
    end
  end
end
