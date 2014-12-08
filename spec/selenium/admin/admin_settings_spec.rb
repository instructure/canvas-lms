require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/external_tools_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/basic/settings_specs')

describe "settings tabs" do
  describe "admin" do
    include_examples "external tools tests"
    before(:each) do
      course_with_admin_logged_in
      get "/accounts/#{Account.default.id}/settings"
    end

    context "external tools tab" do
      it "should add a manual external tool with an url and a work-flow state of public " do
        add_external_tool :manual_url, :public
      end

      it "should add a manual external tool with work-flow state of name_only " do
        add_external_tool :name_only
      end

      it "should add xml external tool" do
        add_external_tool :xml
      end

      it "should add url external tool" do
        mocked_bti_response = {
          :description          => "Search publicly available YouTube videos. A new icon will show up in your course rich editor letting you search YouTube and click to embed videos in your course material.",
          :title                => "YouTube",
          :url                  => "http://www.edu-apps.org/tool_redirect?id=youtube",
          :custom_fields        => {},
          :extensions           => [],
          :privacy_level        => "anonymous",
          :domain               => nil,
          :consumer_key         => nil,
          :shared_secret        => nil,
          :tool_id              => "youtube",
          :assignment_points_possible => nil,
          :settings => {
            :editor_button => {
              :url              => "http://www.edu-apps.org/tool_redirect?id=youtube",
              :icon_url         => "http://www.edu-apps.org/tools/youtube/icon.png",
              :text             => "YouTube",
              :selection_width  => 690,
              :selection_height => 530,
              :enabled          => true
            },
            :resource_selection => {
              :url              => "http://www.edu-apps.org/tool_redirect?id=youtube",
              :icon_url         => "http://www.edu-apps.org/tools/youtube/icon.png",
              :text             => "YouTube",
              :selection_width  => 690,
              :selection_height => 530,
              :enabled          => true
            },
            :icon_url=>"http://www.edu-apps.org/tools/youtube/icon.png"
          }
        }
        CC::Importer::BLTIConverter.any_instance.stubs(:retrieve_and_convert_blti_url).returns(mocked_bti_response)
        add_external_tool :url
      end

      it "should delete an external tool" do
        add_external_tool
        hover_and_click(".delete_tool_link:visible")
        fj('.ui-dialog button:contains(Delete):visible').click
        wait_for_ajax_requests
        tool = ContextExternalTool.last
        expect(tool.workflow_state).to eq "deleted"
        expect(f("#external_tool#{tool.id} .name")).to be_nil
      end

      it "should add and edit an external tool" do
        add_external_tool
        new_description = "a different description"
        hover_and_click(".edit_tool_link:visible")
        replace_content(f("#external_tool_description"), new_description)
        fj('.ui-dialog button:contains(Submit):visible').click
        wait_for_ajax_requests
        tool = ContextExternalTool.last
        expect(tool.description).to eq new_description
      end
    end
  end
end

describe 'shared settings specs' do
  describe "settings" do
    let(:account) { Account.default }
    let(:account_settings_url) { "/accounts/#{Account.default.id}/settings" }
    let(:admin_tab_url) { "/accounts/#{Account.default.id}/settings#tab-users" }
    include_examples "settings basic tests"
  end
end