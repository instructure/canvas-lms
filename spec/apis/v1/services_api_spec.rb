# frozen_string_literal: true

#
# Copyright (C) 2011 Instructure, Inc.
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

require_relative "../api_spec_helper"

describe "Services API", type: :request do
  before :once do
    user_with_pseudonym(active_all: true)
  end

  before do
    stub_kaltura
  end

  it "checks for auth" do
    get("/api/v1/services/kaltura")
    assert_status(401)
  end

  it "checks for auth on session" do
    post("/api/v1/services/kaltura_session")
    assert_status(401)
    expect(response.body).to include("must be logged in to use Kaltura")
  end

  it "returns the config information for kaltura" do
    json = api_call(:get,
                    "/api/v1/services/kaltura",
                    controller: "services_api",
                    action: "show_kaltura_config",
                    format: "json")
    expect(json).to eq({
                         "enabled" => true,
                         "domain" => "kaltura.example.com",
                         "resource_domain" => "cdn.kaltura.example.com",
                         "rtmp_domain" => "rtmp.kaltura.example.com",
                         "partner_id" => "100",
                       })
  end

  it "degrades gracefully if kaltura is disabled or not configured" do
    allow(CanvasKaltura::ClientV3).to receive(:config).and_return(nil)
    json = api_call(:get,
                    "/api/v1/services/kaltura",
                    controller: "services_api",
                    action: "show_kaltura_config",
                    format: "json")
    expect(json).to eq({
                         "enabled" => false,
                       })
  end

  it "returns a new kaltura session" do
    kal = double("CanvasKaltura::ClientV3")
    expect(kal).to receive(:startSession).and_return "new_session_id_here"
    allow(CanvasKaltura::ClientV3).to receive(:new).and_return(kal)
    json = api_call(:post,
                    "/api/v1/services/kaltura_session",
                    controller: "services_api",
                    action: "start_kaltura_session",
                    format: "json")
    expect(json.delete_if { |k| %w[serverTime].include?(k) }).to eq({
                                                                      "ks" => "new_session_id_here",
                                                                      "subp_id" => "10000",
                                                                      "partner_id" => "100",
                                                                      "uid" => "#{@user.id}_#{Account.default.id}",
                                                                    })
  end

  it "returns a new kaltura session with upload config if param provided" do
    kal = double("CanvasKaltura::ClientV3")
    expect(kal).to receive(:startSession).and_return "new_session_id_here"
    allow(CanvasKaltura::ClientV3).to receive(:new).and_return(kal)
    json = api_call(:post,
                    "/api/v1/services/kaltura_session",
                    controller: "services_api",
                    action: "start_kaltura_session",
                    format: "json",
                    include_upload_config: 1)
    expect(json.delete_if { |k| %w[serverTime].include?(k) }).to eq({
                                                                      "ks" => "new_session_id_here",
                                                                      "subp_id" => "10000",
                                                                      "partner_id" => "100",
                                                                      "uid" => "#{@user.id}_#{Account.default.id}",
                                                                      "kaltura_setting" => {
                                                                        "domain" => "kaltura.example.com",
                                                                        "hide_rte_button" => false,
                                                                        "kcw_ui_conf" => "1",
                                                                        "max_file_size_bytes" => 534_773_760,
                                                                        "partner_id" => "100",
                                                                        "player_ui_conf" => "1",
                                                                        "resource_domain" => "cdn.kaltura.example.com",
                                                                        "rtmp_domain" => "rtmp.kaltura.example.com",
                                                                        "subpartner_id" => "10000",
                                                                        "upload_ui_conf" => "1",
                                                                        "entryUrl" => "http://kaltura.example.com/index.php/partnerservices2/addEntry",
                                                                        "uiconfUrl" => "http://kaltura.example.com/index.php/partnerservices2/getuiconf",
                                                                        "uploadUrl" => "http://kaltura.example.com/index.php/partnerservices2/upload",
                                                                        "partner_data" => {
                                                                          "root_account_id" => @user.account.root_account.id,
                                                                          "sis_source_id" => nil,
                                                                          "sis_user_id" => nil
                                                                        },
                                                                      },
                                                                    })
  end

  describe "#rce_config" do
    let(:register_a_tool_to_course) do
      url = "http://example.com"
      tool_params = { name: "bob", consumer_key: "test", shared_secret: "secret", url:, description: "description" }
      tool = @course.context_external_tools.new(tool_params)
      tool.editor_button = { url:, icon_url: url, canvas_icon_class: "icon" }
      tool.save!
    end
    let(:rce_config_api_call) do
      course_with_student(active_all: true)
      register_a_tool_to_course
      api_call_as_user(@student,
                       :get,
                       "/api/v1/services/rce_config",
                       {
                         controller: "services_api",
                         action: "rce_config",
                         format: "json",
                         course_id: @course.to_param
                       },
                       { expected_status: 200 }).deep_symbolize_keys
    end

    it "checks for auth" do
      get("/api/v1/services/rce_config")
      assert_status(401)
    end

    it "test if all the nil values are converted to false in FEATURES hash" do
      expect_any_instance_of(ApplicationController).to receive(:cached_js_env_account_features)
        .and_return({ test_feature_flag: nil })

      json = rce_config_api_call

      expect(json[:FEATURES][:test_feature_flag]).to an_instance_of(FalseClass)
    end

    it "test the urls are enhanced with the base url when CDN is not configured" do
      json = rce_config_api_call

      expected_starting = "http://localhost/dist"
      expect(json[:url_for_high_contrast_tinymce_editor_css]).to all(starting_with(expected_starting))
      expect(json[:url_to_what_gets_loaded_inside_the_tinymce_editor_css]).to all(starting_with(expected_starting))
      expect(json[:active_brand_config_json_url]).to starting_with(expected_starting)
    end

    it "test the urls use the CDN if it is configured" do
      cdn_url = "http://cdn"
      allow(Canvas::Cdn.config).to receive(:host).and_return(cdn_url)

      json = rce_config_api_call

      expected_starting = "#{cdn_url}/dist"
      expect(json[:url_for_high_contrast_tinymce_editor_css]).to all(starting_with(expected_starting))
      expect(json[:url_to_what_gets_loaded_inside_the_tinymce_editor_css]).to all(starting_with(expected_starting))
      expect(json[:active_brand_config_json_url]).to starting_with(expected_starting)
    end

    it "test the default values" do
      expect_any_instance_of(ApplicationController).to receive(:rce_js_env).and_return(nil)
      expect_any_instance_of(ApplicationController).to receive(:inst_env).and_return(nil)

      json = api_call(:get,
                      "/api/v1/services/rce_config",
                      controller: "services_api",
                      action: "rce_config",
                      format: "json")
      expect(json.deep_symbolize_keys).to eq({
                                               RICH_CONTENT_CAN_UPLOAD_FILES: nil,
                                               RICH_CONTENT_INST_RECORD_TAB_DISABLED: nil,
                                               RICH_CONTENT_FILES_TAB_DISABLED: nil,
                                               RICH_CONTENT_CAN_EDIT_FILES: nil,
                                               K5_SUBJECT_COURSE: nil,
                                               K5_HOMEROOM_COURSE: nil,
                                               context_asset_string: nil,
                                               DEEP_LINKING_POST_MESSAGE_ORIGIN: nil,
                                               current_user_id: nil,
                                               disable_keyboard_shortcuts: nil,
                                               rce_auto_save_max_age_ms: nil,
                                               editorButtons: [],
                                               kalturaSettings: { hide_rte_button: false },
                                               LOCALES: ["en"],
                                               LOCALE: "en",
                                               active_brand_config_json_url: nil,
                                               url_for_high_contrast_tinymce_editor_css: [],
                                               url_to_what_gets_loaded_inside_the_tinymce_editor_css: [],
                                               FEATURES: nil,
                                               LTI_LAUNCH_FRAME_ALLOWANCES: Lti::Launch.iframe_allowances,
                                             })
    end

    it "test the contract of the RCE configuration" do
      a_bool_value = be_in([true, false])
      a_hash_with_only_bool_values = satisfy { |hash| hash.values.all? { |value| value.in? [true, false] } }
      a_not_empty_string_array = have_at_least(1).items & all(an_instance_of(String))
      an_instance_of_string = an_instance_of(String)
      an_instance_of_integer = an_instance_of(Integer)

      editor_buttons_matcher = have_at_least(1).items &
                               all(include({
                                             canvas_icon_class: an_instance_of_string,
                                             description: an_instance_of_string,
                                             icon_url: an_instance_of_string,
                                             url: an_instance_of_string,
                                             name: an_instance_of_string,
                                             favorite: a_bool_value,
                                             use_tray: a_bool_value,
                                             height: an_instance_of_integer,
                                             width: an_instance_of_integer,
                                             id: an_instance_of_integer
                                           }))

      json = rce_config_api_call

      expect(json).to include({
                                kalturaSettings: { hide_rte_button: a_bool_value },
                                RICH_CONTENT_CAN_UPLOAD_FILES: a_bool_value,
                                RICH_CONTENT_INST_RECORD_TAB_DISABLED: a_bool_value,
                                RICH_CONTENT_FILES_TAB_DISABLED: a_bool_value,
                                RICH_CONTENT_CAN_EDIT_FILES: a_bool_value,
                                LOCALE: an_instance_of_string,
                                LOCALES: a_not_empty_string_array,
                                rce_auto_save_max_age_ms: an_instance_of_integer,
                                active_brand_config_json_url: an_instance_of_string,
                                url_for_high_contrast_tinymce_editor_css: a_not_empty_string_array,
                                url_to_what_gets_loaded_inside_the_tinymce_editor_css: a_not_empty_string_array,
                                FEATURES: a_hash_with_only_bool_values,
                                K5_SUBJECT_COURSE: a_bool_value,
                                K5_HOMEROOM_COURSE: a_bool_value,
                                context_asset_string: an_instance_of_string,
                                DEEP_LINKING_POST_MESSAGE_ORIGIN: an_instance_of_string,
                                current_user_id: an_instance_of_integer,
                                disable_keyboard_shortcuts: a_bool_value,
                                editorButtons: editor_buttons_matcher,
                                LTI_LAUNCH_FRAME_ALLOWANCES: a_not_empty_string_array
                              })
    end
  end
end
