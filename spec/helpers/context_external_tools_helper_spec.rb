
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'nokogiri'

describe ContextExternalToolsHelper do
  include ContextExternalToolsHelper


  before :once do
    @menu_item_options = {
      show_icon: true,
      settings_key: :course_home_sub_navigation
    }
  end


  shared_examples "#external_tools_menu_items" do

    before :each do
      html = helper.external_tools_menu_items(@mock_tools_hash, @menu_item_options)
      @parsed_html = Nokogiri::HTML::DocumentFragment.parse(html)
    end

    it "returns the right number of tool links" do
      expect(@parsed_html.children.count).to eq 3
    end

    it "should have one .icon-course_home_sub_navigation icon" do
      expect(@parsed_html.css(".icon-course_home_sub_navigation").count).to eq 2
    end

    it "should have one launch-image icon" do
      expect(@parsed_html.css("img[src='http://example.dev/icon.png']").count).to eq 1
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
          canvas_icon_class: "icon-course_home_sub_navigation"
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

    include_examples "#external_tools_menu_items"
  end

  context "With tools" do
    def tool_settings(setting, include_class=false)
      settings_hash = {
        url: "http://example.dev/launch",
        icon_url: "http://example.dev/icon.png",
        enabled: true
      }

      settings_hash[:canvas_icon_class] = "icon-#{setting.to_s}" if include_class
      settings_hash
    end


    before :each do

      @controller = DummyController.new
      @controller.stubs(:external_tool_url).returns("http://stub.dev/tool_url")
      # @controller.stubs(:request).returns(ActionDispatch::TestRequest.new)
      # @controller.instance_variable_set(:@context, @course)

    end

    before :once do

      class DummyController < ApplicationController
        include ContextExternalToolsHelper
      end

      course_model
      @root_account = @course.root_account
      @account = account_model(:root_account => @root_account, :parent_account => @root_account)
      @course.update_attribute(:account, @account)



      tool_1 = @course.context_external_tools.create(
        :name => "Awesome Tool with Icon Class",
        :domain => "example.dev",
        :consumer_key => '12345',
        :shared_secret => 'secret'
      )

      tool_1_settings = tool_settings(:course_home_sub_navigation, true)
      tool_1_settings.delete(:icon_url)
      tool_1.course_home_sub_navigation = tool_1_settings
      tool_1.save!


      tool_2 = @course.context_external_tools.create(
        :name => "Awesome Tool with Icon Class",
        :domain => "example.dev",
        :consumer_key => '12345',
        :shared_secret => 'secret'
      )

      tool_2.course_home_sub_navigation = tool_settings(:course_home_sub_navigation)
      tool_2.save!


      @mock_tools_hash = [tool_1, tool_2, tool_1]


      tool_3 = @course.context_external_tools.create(
        :name => "Awesome Tool with Icon Class",
        :domain => "example.dev",
        :consumer_key => '12345',
        :shared_secret => 'secret'
      )

      tool_3.course_home_sub_navigation = tool_settings(:course_home_sub_navigation, true)
      tool_3.save!

    end

    include_examples "#external_tools_menu_items"
  end
end
