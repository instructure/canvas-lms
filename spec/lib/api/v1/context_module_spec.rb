#
# Copyright (C) 2015 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Api::V1::ContextModule do
  class Dummy
    include Api::V1::ContextModule

    def request
      @request
    end

    def initialize
      @request = Mocha::Mock.new('request')
      @request.stubs(params: {frame_external_urls: 'http://www.instructure.com'})
    end

    def value_to_boolean(object)
      return true if object
    end

    def course_context_modules_item_redirect_url(opts = {})
      "course_context_modules_item_redirect_url(:course_id => #{opts[:course_id]}, :id => #{opts[:id]}, :host => HostUrl.context_host(Course.find(#{opts[:course_id]}))"
    end

    def api_v1_course_external_tool_sessionless_launch_url(context)
      if context.context_module_tags != [] && context.context_module_tags.first.url
        return context.context_module_tags.first.url
      end
      context.context_external_tools.first.url
    end
  end

  describe "#module_item_json" do
    subject {Dummy.new}

    before do
      course_with_teacher(account: Account.default)
      course_with_student_logged_in(course: @course)

      @cm = ContextModule.new(context: @course)
      @cm.prerequisites = {:type=>"context_module", :name=>'test', :id=>1}
      @cm.save!

      @tool = @course.context_external_tools.create(name: "a", domain: "instructure.com", consumer_key: '12345', shared_secret: 'secret', url: 'http://www.toolurl.com')
      @tool.save!

      @content = @tool
      @content.stubs(tool_id: 1)
      @content.save!

      @tg = ContentTag.new(context: @course, context_module: @cm, content_type: 'ContextExternalTool', content: @content)
      @tg.save!
    end

    it "should use the content tag's content url when the tag's url is not defined" do
      json = subject.module_item_json(@tg, @user, @session, @cm)
      expect(json[:url]).to eq "http://www.toolurl.com?id=#{@tool.id}&url=http%3A%2F%2Fwww.toolurl.com"
    end

    it "should use the content tag's url when the tag's url is defined" do
      @tool.url = nil
      @tool.save!

      @tg.url = 'http://www.tagurl.com'
      @tg.save!

      @cm = ContextModule.new(context: @course)
      @cm.context.context_module_tags = [@tg]
      @cm.save!

      json = subject.module_item_json(@tg, @user, @session, @cm)
      expect(json[:url]).to eq "http://www.tagurl.com?id=#{@tool.id}&url=http%3A%2F%2Fwww.tagurl.com"
    end
  end
end
