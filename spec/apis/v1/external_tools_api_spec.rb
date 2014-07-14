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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe ExternalToolsController, type: :request do

  describe "in a course" do
    before(:each) do
      course_with_teacher(:active_all => true, :user => user_with_pseudonym)
    end

    it "should show an external tool" do
      show_call(@course)
    end

    it "should return 404 for not found tool" do
      not_found_call(@course)
    end

    it "should return external tools" do
      index_call(@course)
    end

    it "should search for external tools by name" do
      search_call(@course)
    end

    it "should create an external tool" do
      create_call(@course)
    end

    it "should update an external tool" do
      update_call(@course)
    end

    it "should destroy an external tool" do
      destroy_call(@course)
    end

    it "should give errors for required properties that aren't included" do
      error_call(@course)
    end

    it "should give unauthorized response" do
      course_with_student_logged_in(:active_all => true, :course => @course, :name => "student")
      unauthorized_call(@course)
    end

    it "should paginate" do
      paginate_call(@course)
    end

    if Canvas.redis_enabled?

      describe 'sessionless launch' do

        let(:tool) { tool_with_everything(@course) }

        it 'should allow sessionless launches by url' do
          response = sessionless_launch(@course, 'course', {url: tool.url})
          response.code.should == '200'

          doc = Nokogiri::HTML(response.body)
          doc.at_css('form').should_not be_nil
          doc.at_css('form')['action'].should == tool.url
        end

        it 'should allow sessionless launches by tool id' do
          response = sessionless_launch(@course, 'course', {id: tool.id.to_s})
          response.code.should == '200'

          doc = Nokogiri::HTML(response.body)
          doc.at_css('form').should_not be_nil
          doc.at_css('form')['action'].should == tool.url
        end

        it 'returns 401 if the user is not authorized for the course' do
          user_with_pseudonym
          params = {id: tool.id.to_s}
          code = get_raw_sessionless_launch_url(@course, 'course', params)
          code.should == 401
        end

        it "returns a service unavailible if redis isn't availiable" do
          Canvas.stubs(:redis_enabled?).returns(false)
          params = {id: tool.id.to_s}
          code = get_raw_sessionless_launch_url(@course, 'course', params)
          code.should == 503
          json = JSON.parse(response.body)
          json["errors"]["redis"].first["message"].should == 'Redis is not enabled, but is required for sessionless LTI launch'
        end

        context 'assessment launch' do
          it 'returns a bad request response if there is no assignment_id' do
            params = {id: tool.id.to_s, launch_type: 'assessment'}
            code = get_raw_sessionless_launch_url(@course, 'course', params)
            code.should == 400
            json = JSON.parse(response.body)
            json["errors"]["assignment_id"].first["message"].should == 'An assignment id must be provided for assessment LTI launch'
          end

          it 'returns a bad request response if the assignment is not found in the class' do
            params = {id: tool.id.to_s, launch_type: 'assessment', assignment_id: -1}
            code = get_raw_sessionless_launch_url(@course, 'course', params)
            code.should == 400
            json = JSON.parse(response.body)
            json["errors"]["assignment_id"].first["message"].should == 'The assignment was not found in this course'
          end

          it "returns an unauthorized response if the user can't read the assignment" do
            assignment_model(:course => @course, :name => 'tool assignment', :submission_types => 'external_tool', :points_possible => 20, :grading_type => 'points')
            tag = @assignment.build_external_tool_tag(:url => tool.url)
            tag.content_type = 'ContextExternalTool'
            tag.save!
            @assignment.unpublish
            student_in_course(course: @course)
            params = {id: tool.id.to_s, launch_type: 'assessment', assignment_id: @assignment.id}
            code = get_raw_sessionless_launch_url(@course, 'course', params)
            code.should == 401
          end

          it "returns a bad request if the assignment doesn't have an external_tool_tag" do
            assignment = @course.assignments.create!(
              :title => "published assignemnt",
              :submission_types => "online_url")
            params = {id: tool.id.to_s, launch_type: 'assessment', assignment_id: assignment.id}
            code = get_raw_sessionless_launch_url(@course, 'course', params)
            code.should == 400
            json = JSON.parse(response.body)
            json["errors"]["assignment_id"].first["message"].should == 'The assignment must have an external tool tag'
          end

          it "returns a sessionless launch url" do
            assignment_model(:course => @course, :name => 'tool assignment', :submission_types => 'external_tool', :points_possible => 20, :grading_type => 'points')
            tag = @assignment.build_external_tool_tag(:url => tool.url)
            tag.content_type = 'ContextExternalTool'
            tag.save!
            params = {id: tool.id.to_s, launch_type: 'assessment', assignment_id: @assignment.id}
            json = get_sessionless_launch_url(@course, 'course', params)
            json.should include('url')

            # remove the user session (it's supposed to be sessionless, after all), and make the request
            remove_user_session

            # request/verify the lti launch page
            get json['url']
            response.code.should == '200'

          end

        end

        it "returns a bad request response if there is no tool_id or url" do
          params = {}
          code = get_raw_sessionless_launch_url(@course, 'course', params)
          code.should == 400
          json = JSON.parse(response.body)
          json["errors"]["id"].first["message"].should == 'An id or a url must be provided'
          json["errors"]["url"].first["message"].should == 'An id or a url must be provided'
        end

        it 'redirects if there is no matching tool for the launch_url, and tool id' do
          params = {url: 'http://my_non_esisting_tool_domain.com', id: -1}
          code = get_raw_sessionless_launch_url(@course, 'course', params)
          code.should == 302
        end

        it 'redirects if there is no matching tool for the and tool id' do
          params = { id: -1}
          code = get_raw_sessionless_launch_url(@course, 'course', params)
          code.should == 302
        end


      end
    end
  end

  describe "in an account" do
    before(:each) do
      account_admin_user(:active_all => true, :user => user_with_pseudonym)
      @account = @user.account
    end

    it "should show an external tool" do
      show_call(@account, "account")
    end

    it "should return 404 for not found tool" do
      not_found_call(@account, "account")
    end

    it "should return external tools" do
      index_call(@account, "account")
    end

    it "should search for external tools by name" do
      search_call(@account, "account")
    end

    it "should create an external tool" do
      create_call(@account, "account")
    end

    it "should update an external tool" do
      update_call(@account, "account")
    end

    it "should destroy an external tool" do
      destroy_call(@account, "account")
    end

    it "should give unauthorized response" do
      course_with_student_logged_in(:active_all => true, :name => "student")
      unauthorized_call(@account, "account")
    end

    it "should paginate" do
      paginate_call(@account, "account")
    end

    if Canvas.redis_enabled?
      describe 'sessionless launch' do
        let(:tool) { tool_with_everything(@account) }

        it 'should allow sessionless launches by url' do
          response = sessionless_launch(@account, 'account', {url: tool.url})
          response.code.should == '200'

          doc = Nokogiri::HTML(response.body)
          doc.at_css('form').should_not be_nil
          doc.at_css('form')['action'].should == tool.url
        end

        it 'should allow sessionless launches by tool id' do
          response = sessionless_launch(@account, 'account', {id: tool.id.to_s})
          response.code.should == '200'

          doc = Nokogiri::HTML(response.body)
          doc.at_css('form').should_not be_nil
          doc.at_css('form')['action'].should == tool.url
        end
      end
    end
  end


  def show_call(context, type="course")
    et = tool_with_everything(context)

    json = api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools/#{et.id}.json",
                    {:controller => 'external_tools', :action => 'show', :format => 'json',
                     :"#{type}_id" => context.id.to_s, :external_tool_id => et.id.to_s})
    HashDiff.diff(json, example_json(et)).should == []
  end

  def not_found_call(context, type="course")
    raw_api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools/0.json",
                 {:controller => 'external_tools', :action => 'show', :format => 'json',
                  :"#{type}_id" => context.id.to_s, :external_tool_id => "0"})
    assert_status(404)
  end

  def index_call(context, type="course")
    et = tool_with_everything(context)

    json = api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools.json",
                    {:controller => 'external_tools', :action => 'index', :format => 'json',
                     :"#{type}_id" => context.id.to_s})

    json.size.should == 1
    HashDiff.diff(json.first, example_json(et)).should == []
  end

  def search_call(context, type="course")
    2.times { |i| context.context_external_tools.create!(:name => "first_#{i}", :consumer_key => "fakefake", :shared_secret => "sofakefake", :url => "http://www.example.com/ims/lti") }
    ids = context.context_external_tools.map(&:id)

    2.times { |i| context.context_external_tools.create!(:name => "second_#{i}", :consumer_key => "fakefake", :shared_secret => "sofakefake", :url => "http://www.example.com/ims/lti") }

    json = api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools.json?search_term=fir",
                    {:controller => 'external_tools', :action => 'index', :format => 'json',
                     :"#{type}_id" => context.id.to_s, :search_term => 'fir'})

    json.map{|h| h['id']}.sort.should == ids.sort
  end

  def create_call(context, type="course")
    json = api_call(:post, "/api/v1/#{type}s/#{context.id}/external_tools.json",
                    {:controller => 'external_tools', :action => 'create', :format => 'json',
                     :"#{type}_id" => context.id.to_s}, post_hash)
    context.context_external_tools.count.should == 1

    et = context.context_external_tools.last
    HashDiff.diff(json, example_json(et)).should == []
  end

  def update_call(context, type="course")
    et = context.context_external_tools.create!(:name => "test", :consumer_key => "fakefake", :shared_secret => "sofakefake", :url => "http://www.example.com/ims/lti")

    json = api_call(:put, "/api/v1/#{type}s/#{context.id}/external_tools/#{et.id}.json",
                    {:controller => 'external_tools', :action => 'update', :format => 'json',
                     :"#{type}_id" => context.id.to_s, :external_tool_id => et.id.to_s}, post_hash)
    et.reload
    HashDiff.diff(json, example_json(et)).should == []
  end

  def destroy_call(context, type="course")
    et = context.context_external_tools.create!(:name => "test", :consumer_key => "fakefake", :shared_secret => "sofakefake", :domain => "example.com")
    api_call(:delete, "/api/v1/#{type}s/#{context.id}/external_tools/#{et.id}.json",
                    {:controller => 'external_tools', :action => 'destroy', :format => 'json',
                     :"#{type}_id" => context.id.to_s, :external_tool_id => et.id.to_s})

    et.reload
    et.workflow_state.should == 'deleted'
    context.context_external_tools.active.count.should == 0
  end

  def error_call(context, type="course")
    raw_api_call(:post, "/api/v1/#{type}s/#{context.id}/external_tools.json",
                 {:controller => 'external_tools', :action => 'create', :format => 'json',
                  :"#{type}_id" => context.id.to_s},
                 {})
    json = JSON.parse response.body
    response.code.should == "400"
    json["errors"]["name"].should_not be_nil
    json["errors"]["shared_secret"].should_not be_nil
    json["errors"]["consumer_key"].should_not be_nil
    json["errors"]["url"].first["message"].should == "Either the url or domain should be set."
    json["errors"]["domain"].first["message"].should == "Either the url or domain should be set."
  end

  def unauthorized_call(context, type="course")
    raw_api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools.json",
                    {:controller => 'external_tools', :action => 'index',
                     :format => 'json', :"#{type}_id" => context.id.to_s})
    response.code.should == "401"
  end

  def paginate_call(context, type="course")
    7.times { |i| context.context_external_tools.create!(:name => "test_#{i}", :consumer_key => "fakefake", :shared_secret => "sofakefake", :url => "http://www.example.com/ims/lti") }
    context.context_external_tools.count.should == 7
    json = api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools.json?per_page=3",
                    {:controller => 'external_tools', :action => 'index', :format => 'json', :"#{type}_id" => context.id.to_s, :per_page => '3'})

    json.length.should == 3
    links = response.headers['Link'].split(",")
    links.all?{ |l| l =~ /api\/v1\/#{type}s\/#{context.id}\/external_tools/ }.should be_true
    links.find{ |l| l.match(/rel="next"/)}.should =~ /page=2/
    links.find{ |l| l.match(/rel="first"/)}.should =~ /page=1/
    links.find{ |l| l.match(/rel="last"/)}.should =~ /page=3/

    # get the last page
    json = api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools.json?page=3&per_page=3",
                    {:controller => 'external_tools', :action => 'index', :format => 'json', :"#{type}_id" => context.id.to_s, :per_page => '3', :page => '3'})
    json.length.should == 1
    links = response.headers['Link'].split(",")
    links.all?{ |l| l =~ /api\/v1\/#{type}s\/#{context.id}\/external_tools/ }.should be_true
    links.find{ |l| l.match(/rel="prev"/)}.should =~ /page=2/
    links.find{ |l| l.match(/rel="first"/)}.should =~ /page=1/
    links.find{ |l| l.match(/rel="last"/)}.should =~ /page=3/
  end

  def tool_with_everything(context, opts={})
    et = context.context_external_tools.new
    et.name = opts[:name] || "External Tool Eh"
    et.description = "For testing stuff"
    et.consumer_key = "oi"
    et.shared_secret = "hoyt"
    et.url = "http://www.example.com/ims/lti"
    et.workflow_state = 'public'
    et.custom_fields = {:key1 => 'val1', :key2 => 'val2'}
    et.course_navigation = {:url=>"http://www.example.com/ims/lti/course", :visibility=>"admins", :text=>"Course nav", "default"=>"disabled"}
    et.account_navigation = {:url=>"http://www.example.com/ims/lti/account", :text=>"Account nav", :custom_fields=>{"key"=>"value"}}
    et.user_navigation = {:url=>"http://www.example.com/ims/lti/user", :text=>"User nav"}
    et.editor_button = {:url=>"http://www.example.com/ims/lti/editor", :icon_url=>"/images/delete.png", :selection_width=>50, :selection_height=>50, :text=>"editor button"}
    et.homework_submission = {:url=>"http://www.example.com/ims/lti/editor", :selection_width=>50, :selection_height=>50, :text=>"homework submission"}
    et.resource_selection = {:url=>"http://www.example.com/ims/lti/resource", :text => "", :selection_width=>50, :selection_height=>50}
    et.migration_selection = {:url=>"http://www.example.com/ims/lti/resource", :text => "migration selection", :selection_width=>42, :selection_height=>24}
    et.course_home_sub_navigation = {:url=>"http://www.example.com/ims/lti/resource", :text => "course home sub navigation", display_type: 'full_width', visibility: 'admins'}
    et.save!
    et
  end

  def post_hash
    hash = example_json
    hash["shared_secret"] = "I will kill you if you tell"
    hash.delete "created_at"
    hash.delete "updated_at"
    hash.delete "id"
    hash.keys.each do |key|
      val = hash[key]
      next unless val.is_a?(Hash)
      val.each_pair do |sub_key, sub_val|
        hash["#{key}[#{sub_key}]"] = sub_val
      end
      hash.delete key
    end
    hash
  end

  def sessionless_launch(context, type, params)
    # initial api call
    json = get_sessionless_launch_url(context, type, params)
    json.should include('url')

    # remove the user session (it's supposed to be sessionless, after all), and make the request
    remove_user_session

    # request/verify the lti launch page
    get json['url']
    response
  end

  def get_sessionless_launch_url(context, type, params)
    api_call(
      :get,
      "/api/v1/#{type}s/#{context.id}/external_tools/sessionless_launch?#{params.map{|k,v| "#{k}=#{v}" }.join('&')}",
      {:controller => 'external_tools', :action => 'generate_sessionless_launch', :format => 'json', :"#{type}_id" => context.id.to_s}.merge(params)
    )
  end

  def get_raw_sessionless_launch_url(context, type, params)
    raw_api_call(
      :get,
      "/api/v1/#{type}s/#{@course.id}/external_tools/sessionless_launch?#{params.map { |k, v| "#{k}=#{v}" }.join('&')}",
      {:controller => 'external_tools', :action => 'generate_sessionless_launch', :format => 'json', :"#{type}_id" => context.id.to_s}.merge(params)
    )
  end

  def example_json(et=nil)
    {"name"=>"External Tool Eh",
     "created_at"=>et ? et.created_at.as_json : "",
     "updated_at"=>et ? et.updated_at.as_json : "",
     "consumer_key"=>"oi",
     "domain"=>nil,
     "url"=>"http://www.example.com/ims/lti",
     "id"=>et ? et.id : nil,
     "workflow_state"=>"public",
     "vendor_help_link"=>nil,
     "resource_selection"=>
             {"text"=>"",
              "url"=>"http://www.example.com/ims/lti/resource",
              "selection_height"=>50,
              "selection_width"=>50,
              "label"=>""},
     "privacy_level"=>"public",
     "editor_button"=>
             {"icon_url"=>"/images/delete.png",
              "text"=>"editor button",
              "url"=>"http://www.example.com/ims/lti/editor",
              "selection_height"=>50,
              "selection_width"=>50,
              "label"=>"editor button"},
     "homework_submission"=>
             {"text"=>"homework submission",
              "url"=>"http://www.example.com/ims/lti/editor",
              "selection_height"=>50,
              "selection_width"=>50,
              "label"=>"homework submission"},
     "custom_fields"=>{"key1"=>"val1", "key2"=>"val2"},
     "description"=>"For testing stuff",
     "user_navigation"=>
             {"text"=>"User nav",
              "url"=>"http://www.example.com/ims/lti/user",
              "label"=>"User nav",
              "selection_height"=>400,
              "selection_width"=>800},
     "course_navigation" =>
             {"text"=>"Course nav",
              "url"=>"http://www.example.com/ims/lti/course",
              "visibility"=>"admins",
              "default"=> "disabled",
              "label"=>"Course nav",
              "selection_height"=>400,
              "selection_width"=>800},
     "account_navigation"=>
             {"text"=>"Account nav",
              "url"=>"http://www.example.com/ims/lti/account",
              "custom_fields"=>{"key"=>"value"},
              "label"=>"Account nav",
              "selection_height"=>400,
              "selection_width"=>800},
     "migration_selection"=>
             {"text"=>"migration selection",
              "label"=>"migration selection",
              "url"=>"http://www.example.com/ims/lti/resource",
              "selection_height"=>24,
              "selection_width"=>42},
     "course_home_sub_navigation"=>
             {"text"=>"course home sub navigation",
              "label"=>"course home sub navigation",
              "url"=>"http://www.example.com/ims/lti/resource",
              "visibility"=>'admins',
              "display_type"=>'full_width',
              "selection_height"=>400,
              "selection_width"=>800}}
  end
end
