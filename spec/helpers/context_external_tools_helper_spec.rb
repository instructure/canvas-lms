# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require "nokogiri"

describe ContextExternalToolsHelper do
  include ContextExternalToolsHelper

  before :once do
    @menu_item_options = {
      show_icon: true,
      settings_key: :course_home_sub_navigation
    }
  end

  shared_examples "#external_tools_menu_items" do
    before do
      html = helper.external_tools_menu_items(@mock_tools_hash, @menu_item_options)
      @parsed_html = Nokogiri::HTML5.fragment(html)
    end

    it "returns the right number of tool links" do
      expect(@parsed_html.children.count).to eq 3
    end

    it "has one .icon-course_home_sub_navigation icon" do
      expect(@parsed_html.css(".icon-course_home_sub_navigation").count).to eq 2
    end

    it "has one launch-image icon" do
      expect(@parsed_html.css("img[src='http://example.dev/icon.png']").count).to eq 1
    end
  end

  shared_examples "#external_tools_menu_items_raw" do
    before do
      @menu_item_options[:raw_output] = true
      @items = helper.external_tools_menu_items(@mock_tools_hash, @menu_item_options)
    end

    it "returns the right number of tool links" do
      expect(@items.count).to eq 3
    end

    it "returns the right object type" do
      expect(@items[0]).to be_a Hash
    end
  end

  context "With hashes" do
    before :once do
      @mock_tools_hash = [
        {
          title: "Awesome Tool with Icon Class",
          base_url: "http://example.dev/launch",
          is_new: false,
          url_params: {
            id: 1,
            launch_type: :awesome_type
          },
          canvas_icon_class: "icon-course_home_sub_navigation",
          launch_method: "tray"
        },

        {
          title: "Awesome Tool with Icon URL",
          base_url: "http://example.dev/launch",
          is_new: false,
          url_params: {
            id: 2,
            launch_type: :awesome_type
          },
          icon_url: "http://example.dev/icon.png"
        },

        {
          title: "Awesome Tool with both Icon Class and URL",
          base_url: "http://example.dev/launch",
          is_new: false,
          url_params: {
            id: 2,
            launch_type: :awesome_type
          },
          canvas_icon_class: "icon-course_home_sub_navigation",
          icon_url: "http://example.com/icon.png"
        }
      ]
    end

    it "includes data-tool-launch-method" do
      expect(@parsed_html.css("[data-tool-launch-method='tray']").count).to eq 1
    end

    include_examples "#external_tools_menu_items"
    include_examples "#external_tools_menu_items_raw"
  end

  context "With tools" do
    def tool_settings(setting, include_class = false)
      settings_hash = {
        url: "http://example.dev/launch",
        icon_url: "http://example.dev/icon.png",
        enabled: true
      }

      settings_hash[:canvas_icon_class] = "icon-#{setting}" if include_class
      settings_hash
    end

    before do
      klass = Class.new(ApplicationController) do
        include ContextExternalToolsHelper
      end
      @controller = klass.new
      allow(@controller).to receive(:external_tool_url).and_return("http://stub.dev/tool_url")
      # allow(@controller).to receive(:request).and_return(ActionDispatch::TestRequest.new)
      # @controller.instance_variable_set(:@context, @course)
    end

    before :once do
      course_model
      @root_account = @course.root_account
      @account = account_model(root_account: @root_account, parent_account: @root_account)
      @course.update_attribute(:account, @account)

      tool_1 = @course.context_external_tools.create(
        name: "Awesome Tool with Icon Class",
        domain: "example.dev",
        consumer_key: "12345",
        shared_secret: "secret"
      )

      tool_1_settings = tool_settings(:course_home_sub_navigation, true)
      tool_1_settings.delete(:icon_url)
      tool_1.course_home_sub_navigation = tool_1_settings
      tool_1.save!

      tool_2 = @course.context_external_tools.create(
        name: "Awesome Tool with Icon Class",
        domain: "example.dev",
        consumer_key: "12345",
        shared_secret: "secret"
      )

      tool_2.course_home_sub_navigation = tool_settings(:course_home_sub_navigation)
      tool_2.save!

      @mock_tools_hash = [tool_1, tool_2, tool_1]

      tool_3 = @course.context_external_tools.create(
        name: "Awesome Tool with Icon Class",
        domain: "example.dev",
        consumer_key: "12345",
        shared_secret: "secret"
      )

      tool_3.course_home_sub_navigation = tool_settings(:course_home_sub_navigation, true)
      tool_3.save!
    end

    include_examples "#external_tools_menu_items"
    include_examples "#external_tools_menu_items_raw"
  end

  context "external_tools_menu_items_grouped_json" do
    let(:tools_hash) do
      {
        module_menu: [
          {
            id: 101,
            title: "Tool A",
            base_url: "http://example.com/launch",
            launch_method: "modal"
          }
        ],
        module_group_menu: [
          {
            id: 102,
            title: "Tool B",
            base_url: "http://example.com/launch?foo=bar",
            launch_method: "tray"
          }
        ]
      }
    end

    let(:url_params_by_group) do
      {
        module_menu: { modules: [1] },
        module_group_menu: { modules: [2], bar: "baz" }
      }
    end

    before(:once) do
      Account.site_admin.enable_feature!(:create_external_apps_side_tray_overrides)
    end

    it "returns grouped JSON with merged query params and tool data" do
      result = external_tools_menu_items_grouped_json(tools_hash, url_params_by_group)

      expect(result.keys).to contain_exactly("module_menu", "module_group_menu")

      tool_a = result["module_menu"].first[:context_external_tool]
      expect(tool_a[:id]).to eq 101
      expect(URI(tool_a[:base_url]).query).to include("modules%5B%5D=1")

      tool_b = result["module_group_menu"].first[:context_external_tool]
      expect(tool_b[:id]).to eq 102
      parsed_query = Rack::Utils.parse_nested_query(URI(tool_b[:base_url]).query)
      expect(parsed_query).to include("foo" => "bar", "modules" => ["2"], "bar" => "baz")
    end

    it "skips empty tool groups" do
      tools_hash[:module_index_menu] = []
      result = external_tools_menu_items_grouped_json(tools_hash, url_params_by_group)
      expect(result).not_to have_key("module_index_menu")
    end
  end
end
