require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe SisApiController, type: :request do
  describe '#assignments' do
    before :once do
      account_model
      account_admin_user(:account => @account, :active_all => true)
      @account.enable_feature!(:bulk_sis_grade_export)
    end

    def create_post_grades_tool(opts = {})
      post_grades_tool = @account.context_external_tools.create!(
        name: opts[:name] || 'test tool',
        domain: 'example.com',
        url: 'http://example.com/lti',
        consumer_key: 'key',
        shared_secret: 'secret',
        settings: {
          post_grades: {
            url: 'http://example.com/lti/post_grades'
          }
        }
      )
      post_grades_tool.context_external_tool_placements.create!(placement_type: 'post_grades')
      post_grades_tool
    end

    before :each do
      user_session(@user)
    end

    it "should require :view_all_grades permission" do
      @account.role_overrides.create!(:permission => :view_all_grades, :enabled => false, :role => admin_role)

      get "/api/sis/grade_export/accounts/#{@account.id}/assignments", :account_id => @account.id

      assert_unauthorized
    end

    it "should require :bulk_sis_grade_export feature" do
      @account.disable_feature!(:bulk_sis_grade_export)

      get "/api/sis/grade_export/accounts/#{@account.id}/assignments", :account_id => @account.id

      expect(response.status).to eq 400
      expect(json_parse['error']).to include("feature not on")
    end

    it "should be allowed if post_grades lti tool installed" do
      @account.disable_feature!(:bulk_sis_grade_export)
      create_post_grades_tool

      get "/api/sis/grade_export/accounts/#{@account.id}/assignments", :account_id => @account.id
      expect(response).to be_success
    end

    it "should return assignments with post_to_sis marked" do
      course1 = course(:account => @account)
      expect(Assignment.show_sis_grade_export_option?(course1)).to be_truthy

      asmt1 = course1.assignments.create!(:post_to_sis => true)
      asmt2 = course1.assignments.create!(:post_to_sis => false)
      course2 = course(:account => @account)
      asmt3 = course2.assignments.create!(:post_to_sis => true)
      asmt4 = course2.assignments.create!(:post_to_sis => true)
      asmt5 = course2.assignments.create!(:post_to_sis => false)
      course3 = course(:account => @account)

      get "/api/sis/grade_export/accounts/#{@account.id}/assignments", :account_id => @account.id
      expect(response).to be_success

      result = json_parse
      expect(result.length).to eq 2

      course1_hash = result.detect{|h| h['course_id'] == course1.id}
      expect(course1_hash['assignment_ids']).to eq [asmt1.id]

      course2_hash = result.detect{|h| h['course_id'] == course2.id}
      expect(course2_hash['assignment_ids']).to match_array [asmt3.id, asmt4.id]
    end
  end
end
