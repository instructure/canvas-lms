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

require 'nokogiri'

describe ExternalToolsController, type: :request do

  describe "in a course" do
    before(:once) do
      course_with_teacher(:active_all => true, :user => user_with_pseudonym)
      @group = group_model(:context => @course)
    end

    it "should show an external tool" do
      show_call(@course)
    end

    it "should include allow_membership_service_access if feature flag enabled" do
      allow_any_instance_of(Account).to receive(:feature_enabled?).and_return(false)
      allow_any_instance_of(Account).to receive(:feature_enabled?).with(:membership_service_for_lti_tools).and_return(true)
      et = tool_with_everything(@course, allow_membership_service_access: true)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/external_tools/#{et.id}.json",
                    {:controller => 'external_tools', :action => 'show', :format => 'json',
                     :course_id => @course.id.to_s, :external_tool_id => et.id.to_s})
      expect(json['allow_membership_service_access']).to eq true
    end

    it "should return 404 for not found tool" do
      not_found_call(@course)
    end

    it "should return external tools" do
      index_call(@course)
    end

    it "should return filtered external tools" do
      index_call_with_placment(@course, "collaboration")
    end

    it "should search for external tools by name" do
      search_call(@course)
    end

    it "should only find selectable tools" do
      only_selectables(@course)
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

    it "should give authorized response" do
      course_with_student_logged_in(:active_all => true, :course => @course, :name => "student")
      authorized_call(@course)
    end

    it "should paginate" do
      paginate_call(@course)
    end

    if Canvas.redis_enabled?

      describe 'sessionless launch' do

        let(:tool) { tool_with_everything(@course) }

        it 'should allow sessionless launches by url' do
          response = sessionless_launch(@course, 'course', {url: tool.url})
          expect(response.code).to eq '200'

          doc = Nokogiri::HTML(response.body)
          expect(doc.at_css('form')).not_to be_nil
          expect(doc.at_css('form')['action']).to eq tool.url
        end

        it 'should allow sessionless launches by tool id' do
          response = sessionless_launch(@course, 'course', {id: tool.id.to_s})
          expect(response.code).to eq '200'

          doc = Nokogiri::HTML(response.body)
          expect(doc.at_css('form')).not_to be_nil
          expect(doc.at_css('form')['action']).to eq tool.url
        end

        it 'returns 401 if the user is not authorized for the course' do
          user_with_pseudonym
          params = {id: tool.id.to_s}
          code = get_raw_sessionless_launch_url(@course, 'course', params)
          expect(code).to eq 401
        end

        it "returns a service unavailable if redis isn't available" do
          allow(Canvas).to receive(:redis_enabled?).and_return(false)
          params = {id: tool.id.to_s}
          code = get_raw_sessionless_launch_url(@course, 'course', params)
          expect(code).to eq 503
          json = JSON.parse(response.body)
          expect(json["errors"]["redis"].first["message"]).to eq 'Redis is not enabled, but is required for sessionless LTI launch'
        end

        context 'assessment launch' do
          before do
            allow(BasicLTI::Sourcedid).to receive(:encryption_secret) {'encryption-secret-5T14NjaTbcYjc4'}
            allow(BasicLTI::Sourcedid).to receive(:signing_secret) {'signing-secret-vp04BNqApwdwUYPUI'}
          end

          it 'returns a bad request response if there is no assignment_id' do
            params = {id: tool.id.to_s, launch_type: 'assessment'}
            code = get_raw_sessionless_launch_url(@course, 'course', params)
            expect(code).to eq 400
            json = JSON.parse(response.body)
            expect(json["errors"]["assignment_id"].first["message"]).to eq 'An assignment id must be provided for assessment LTI launch'
          end

          it 'returns a not found response if the assignment is not found in the class' do
            params = {id: tool.id.to_s, launch_type: 'assessment', assignment_id: -1}
            code = get_raw_sessionless_launch_url(@course, 'course', params)
            expect(code).to eq 404
            json = JSON.parse(response.body)
            expect(json['errors'].first['message']).to eq 'The specified resource does not exist.'
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
            expect(code).to eq 401
          end

          it "returns a bad request if the assignment doesn't have an external_tool_tag" do
            assignment = @course.assignments.create!(
              :title => "published assignemnt",
              :submission_types => "online_url")
            params = {id: tool.id.to_s, launch_type: 'assessment', assignment_id: assignment.id}
            code = get_raw_sessionless_launch_url(@course, 'course', params)
            expect(code).to eq 400
            json = JSON.parse(response.body)
            expect(json["errors"]["assignment_id"].first["message"]).to eq 'The assignment must have an external tool tag'
          end

          it "returns a sessionless launch url" do
            assignment_model(:course => @course, :name => 'tool assignment', :submission_types => 'external_tool', :points_possible => 20, :grading_type => 'points')
            tag = @assignment.build_external_tool_tag(:url => tool.url)
            tag.content_type = 'ContextExternalTool'
            tag.save!
            params = {id: tool.id.to_s, launch_type: 'assessment', assignment_id: @assignment.id}
            json = get_sessionless_launch_url(@course, 'course', params)
            expect(json).to include('url')

            # remove the user session (it's supposed to be sessionless, after all), and make the request
            remove_user_session

            # request/verify the lti launch page
            get json['url']
            expect(response.code).to eq '200'
          end

          it "returns sessionless launch URL when default URL is not set and placement URL is" do
            tool.update_attributes!(url: nil)
            params = { id: tool.id.to_s, launch_type: 'course_navigation' }
            json = get_sessionless_launch_url(@course, 'course', params)
            expect(json).to include('url')

            # remove the user session (it's supposed to be sessionless, after all), and make the request
            remove_user_session

            # request/verify the lti launch page
            get json['url']
            expect(response.code).to eq '200'
          end

        end

        it "returns a bad request response if there is no tool_id or url" do
          params = {}
          code = get_raw_sessionless_launch_url(@course, 'course', params)
          expect(code).to eq 400
          json = JSON.parse(response.body)
          expect(json["errors"]["id"].first["message"]).to eq 'A tool id, tool url, or module item id must be provided'
          expect(json["errors"]["url"].first["message"]).to eq 'A tool id, tool url, or module item id must be provided'
        end

        it 'redirects if there is no matching tool for the launch_url, and tool id' do
          params = {url: 'http://my_non_esisting_tool_domain.com', id: -1}
          code = get_raw_sessionless_launch_url(@course, 'course', params)
          expect(code).to eq 302
        end

        it 'redirects if there is no matching tool for the and tool id' do
          params = { id: -1}
          code = get_raw_sessionless_launch_url(@course, 'course', params)
          expect(code).to eq 302
        end

        it 'redirects if there is no launch url associated with the tool' do
          no_url_tool = tool.dup
          no_url_tool.update_attributes!(url: nil)
          get_raw_sessionless_launch_url(@course, 'course', {id: no_url_tool.id})
          expect(response).to be_redirect
        end
      end
    end

    describe "in a group" do
      it "should return course level external tools" do
        group_index_call(@group)
      end

      it "should paginate" do
        group_index_paginate_call(@group)
      end
    end
  end

  describe "in an account" do
    before(:once) do
      account_admin_user(:active_all => true, :user => user_with_pseudonym)
      @account = @user.account
      @group = group_model(:context => @account)
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

    it "should only find selectable tools" do
      only_selectables(@account, "account")
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
          expect(response.code).to eq '200'

          doc = Nokogiri::HTML(response.body)
          expect(doc.at_css('form')).not_to be_nil
          expect(doc.at_css('form')['action']).to eq tool.url
        end

        it 'should allow sessionless launches by tool id' do
          response = sessionless_launch(@account, 'account', {id: tool.id.to_s})
          expect(response.code).to eq '200'

          doc = Nokogiri::HTML(response.body)
          expect(doc.at_css('form')).not_to be_nil
          expect(doc.at_css('form')['action']).to eq tool.url
        end
      end
    end

    describe "in a group" do
      it "should return account level external tools" do
        group_index_call(@group)
      end
    end
  end


  def show_call(context, type="course")
    et = tool_with_everything(context)
    json = api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools/#{et.id}.json",
                    {:controller => 'external_tools', :action => 'show', :format => 'json',
                     :"#{type}_id" => context.id.to_s, :external_tool_id => et.id.to_s})
    expect(HashDiff.diff(json, example_json(et))).to eq []
  end

  def not_found_call(context, type="course")
    raw_api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools/0.json",
                 {:controller => 'external_tools', :action => 'show', :format => 'json',
                  :"#{type}_id" => context.id.to_s, :external_tool_id => "0"})
    assert_status(404)
  end

  def group_index_call(group)
    et = tool_with_everything(group.context)

    json = api_call(:get, "/api/v1/groups/#{group.id}/external_tools?include_parents=true",
                    {:controller => 'external_tools', :action => 'index', :format => 'json',
                     :group_id => group.id.to_s, :include_parents => true})

    expect(json.size).to eq 1
    expect(HashDiff.diff(json.first, example_json(et))).to eq []
  end

  def group_index_paginate_call(group)
    7.times { tool_with_everything(group.context) }

    json = api_call(:get, "/api/v1/groups/#{group.id}/external_tools",
                    {:controller => 'external_tools', :action => 'index', :format => 'json',
                     :group_id => group.id.to_s, :include_parents => true, :per_page => '3'})

    expect(json.length).to eq 3
    links = response.headers['Link'].split(",")
    expect(links.all?{ |l| l =~ /api\/v1\/groups\/#{group.id}\/external_tools/ }).to be_truthy
    expect(links.find{ |l| l.match(/rel="next"/)}).to match(/page=2/)
    expect(links.find{ |l| l.match(/rel="first"/)}).to match(/page=1/)
    expect(links.find{ |l| l.match(/rel="last"/)}).to match(/page=3/)

    # get the last page
    json = api_call(:get, "/api/v1/groups/#{group.id}/external_tools",
                    {:controller => 'external_tools', :action => 'index', :format => 'json',
                     :group_id => group.id.to_s, :include_parents => true, :per_page => '3', :page => '3'})

    expect(json.length).to eq 1
    links = response.headers['Link'].split(",")
    expect(links.all?{ |l| l =~ /api\/v1\/groups\/#{group.id}\/external_tools/ }).to be_truthy
    expect(links.find{ |l| l.match(/rel="prev"/)}).to match(/page=2/)
    expect(links.find{ |l| l.match(/rel="first"/)}).to match(/page=1/)
    expect(links.find{ |l| l.match(/rel="last"/)}).to match(/page=3/)
  end

  def index_call(context, type="course")
    et = tool_with_everything(context)

    json = api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools.json",
                    {:controller => 'external_tools', :action => 'index', :format => 'json',
                     :"#{type}_id" => context.id.to_s})

    expect(json.size).to eq 1
    expect(HashDiff.diff(json.first, example_json(et))).to eq []
  end

  def index_call_with_placment(context, placement, type="course")
    tool_with_everything(context)
    et_with_placement = tool_with_everything(context, {:placement => placement})

    json = api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools.json",
                    {:controller => 'external_tools', :action => 'index', :format => 'json', :placement => placement,
                     :"#{type}_id" => context.id.to_s})

    expect(json.size).to eq 1
    expect(HashDiff.diff(json.first, example_json(et_with_placement))).to eq []
  end

  def search_call(context, type="course")
    2.times { |i| context.context_external_tools.create!(:name => "first_#{i}", :consumer_key => "fakefake", :shared_secret => "sofakefake", :url => "http://www.example.com/ims/lti") }
    ids = context.context_external_tools.map(&:id)

    2.times { |i| context.context_external_tools.create!(:name => "second_#{i}", :consumer_key => "fakefake", :shared_secret => "sofakefake", :url => "http://www.example.com/ims/lti") }

    json = api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools.json?search_term=fir",
                    {:controller => 'external_tools', :action => 'index', :format => 'json',
                     :"#{type}_id" => context.id.to_s, :search_term => 'fir'})

    expect(json.map{|h| h['id']}.sort).to eq ids.sort
  end

  def only_selectables(context, type="course")
    context.context_external_tools.create!(:name => "first", :consumer_key => "fakefake", :shared_secret => "sofakefake", :url => "http://www.example.com/ims/lti", :not_selectable => true)
    not_selectable = context.context_external_tools.create!(:name => "second", :consumer_key => "fakefake", :shared_secret => "sofakefake", :url => "http://www.example.com/ims/lti")

    json = api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools.json?selectable=true",
                    {:controller => 'external_tools', :action => 'index', :format => 'json',
                     :"#{type}_id" => context.id.to_s, :selectable => 'true'})

    expect(json.length).to eq 1
    expect(json.first['id']).to eq not_selectable.id
  end

  def create_call(context, type="course")
    json = api_call(:post, "/api/v1/#{type}s/#{context.id}/external_tools.json",
                    {:controller => 'external_tools', :action => 'create', :format => 'json',
                     :"#{type}_id" => context.id.to_s}, post_hash)
    expect(context.context_external_tools.count).to eq 1

    et = context.context_external_tools.last
    expect(HashDiff.diff(json, example_json(et))).to eq []
  end

  def update_call(context, type="course")
    et = context.context_external_tools.create!(:name => "test", :consumer_key => "fakefake", :shared_secret => "sofakefake", :url => "http://www.example.com/ims/lti")

    json = api_call(:put, "/api/v1/#{type}s/#{context.id}/external_tools/#{et.id}.json",
                    {:controller => 'external_tools', :action => 'update', :format => 'json',
                     :"#{type}_id" => context.id.to_s, :external_tool_id => et.id.to_s}, post_hash)
    et.reload
    expect(HashDiff.diff(json, example_json(et))).to eq []
  end

  def destroy_call(context, type="course")
    et = context.context_external_tools.create!(:name => "test", :consumer_key => "fakefake", :shared_secret => "sofakefake", :domain => "example.com")
    api_call(:delete, "/api/v1/#{type}s/#{context.id}/external_tools/#{et.id}.json",
                    {:controller => 'external_tools', :action => 'destroy', :format => 'json',
                     :"#{type}_id" => context.id.to_s, :external_tool_id => et.id.to_s})

    et.reload
    expect(et.workflow_state).to eq 'deleted'
    expect(context.context_external_tools.active.count).to eq 0
  end

  def error_call(context, type="course")
    raw_api_call(:post, "/api/v1/#{type}s/#{context.id}/external_tools.json",
                 {:controller => 'external_tools', :action => 'create', :format => 'json',
                  :"#{type}_id" => context.id.to_s},
                 {})
    json = JSON.parse response.body
    expect(response.code).to eq "400"
    expect(json["errors"]["name"]).not_to be_nil
    expect(json["errors"]["shared_secret"]).not_to be_nil
    expect(json["errors"]["consumer_key"]).not_to be_nil
    expect(json["errors"]["url"].first["message"]).to eq "Either the url or domain should be set."
    expect(json["errors"]["domain"].first["message"]).to eq "Either the url or domain should be set."
  end

  def unauthorized_call(context, type="course")
    raw_api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools.json",
                    {:controller => 'external_tools', :action => 'index',
                     :format => 'json', :"#{type}_id" => context.id.to_s})
    expect(response.code).to eq "401"
  end

  def authorized_call(context, type="course")
    raw_api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools.json",
                    {:controller => 'external_tools', :action => 'index',
                     :format => 'json', :"#{type}_id" => context.id.to_s})
    expect(response.code).to eq "200"
  end

  def paginate_call(context, type="course")
    7.times { |i| context.context_external_tools.create!(:name => "test_#{i}", :consumer_key => "fakefake", :shared_secret => "sofakefake", :url => "http://www.example.com/ims/lti") }
    expect(context.context_external_tools.count).to eq 7
    json = api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools.json?per_page=3",
                    {:controller => 'external_tools', :action => 'index', :format => 'json', :"#{type}_id" => context.id.to_s, :per_page => '3'})

    expect(json.length).to eq 3
    links = response.headers['Link'].split(",")
    expect(links.all?{ |l| l =~ /api\/v1\/#{type}s\/#{context.id}\/external_tools/ }).to be_truthy
    expect(links.find{ |l| l.match(/rel="next"/)}).to match /page=2/
    expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1/
    expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3/

    # get the last page
    json = api_call(:get, "/api/v1/#{type}s/#{context.id}/external_tools.json?page=3&per_page=3",
                    {:controller => 'external_tools', :action => 'index', :format => 'json', :"#{type}_id" => context.id.to_s, :per_page => '3', :page => '3'})
    expect(json.length).to eq 1
    links = response.headers['Link'].split(",")
    expect(links.all?{ |l| l =~ /api\/v1\/#{type}s\/#{context.id}\/external_tools/ }).to be_truthy
    expect(links.find{ |l| l.match(/rel="prev"/)}).to match /page=2/
    expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1/
    expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3/
  end

  def tool_with_everything(context, opts={})
    et = context.context_external_tools.new
    et.name = opts[:name] || "External Tool Eh"
    et.description = "For testing stuff"
    et.consumer_key = "oi"
    et.shared_secret = "hoyt"
    et.not_selectable = true
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
    et.course_settings_sub_navigation = {:url=>"http://www.example.com/ims/lti/resource", :text => "course settings sub navigation", display_type: 'full_width', visibility: 'admins'}
    et.global_navigation = {:url=>"http://www.example.com/ims/lti/resource", :text => "global navigation", display_type: 'full_width', visibility: 'admins'}
    et.assignment_menu = {:url=>"http://www.example.com/ims/lti/resource", :text => "assignment menu", display_type: 'full_width', visibility: 'admins'}
    et.discussion_topic_menu = {:url=>"http://www.example.com/ims/lti/resource", :text => "discussion topic menu", display_type: 'full_width', visibility: 'admins'}
    et.file_menu = {:url=>"http://www.example.com/ims/lti/resource", :text => "module menu", display_type: 'full_width', visibility: 'admins'}
    et.module_menu = {:url=>"http://www.example.com/ims/lti/resource", :text => "module menu", display_type: 'full_width', visibility: 'admins'}
    et.quiz_menu = {:url=>"http://www.example.com/ims/lti/resource", :text => "quiz menu", display_type: 'full_width', visibility: 'admins'}
    et.wiki_page_menu = {:url=>"http://www.example.com/ims/lti/resource", :text => "wiki page menu", display_type: 'full_width', visibility: 'admins'}
    if context.is_a? Course
      et.course_assignments_menu = { url: 'http://www.example.com/ims/lti/resource', text: 'course assignments menu' }
    end
    et.context_external_tool_placements.new(:placement_type => opts[:placement]) if opts[:placement]
    et.allow_membership_service_access = opts[:allow_membership_service_access] if opts[:allow_membership_service_access]
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
    expect(json).to include('url')

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
     "tool_configuration"=>nil,
     "id"=>et ? et.id : nil,
     "not_selectable"=> et ? et.not_selectable : nil,
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
              "selection_width"=>800},
     "course_settings_sub_navigation"=>
             {"text"=>"course settings sub navigation",
              "label"=>"course settings sub navigation",
              "url"=>"http://www.example.com/ims/lti/resource",
              "visibility"=>'admins',
              "display_type"=>'full_width',
              "selection_height"=>400,
              "selection_width"=>800},
     "global_navigation"=>
         {"text"=>"global navigation",
          "label"=>"global navigation",
          "url"=>"http://www.example.com/ims/lti/resource",
          "visibility"=>'admins',
          "display_type"=>'full_width',
          "selection_height"=>400,
          "selection_width"=>800},
     "assignment_menu"=>
         {"text"=>"assignment menu",
          "label"=>"assignment menu",
          "url"=>"http://www.example.com/ims/lti/resource",
          "visibility"=>'admins',
          "display_type"=>'full_width',
          "selection_height"=>400,
          "selection_width"=>800},
     "discussion_topic_menu"=>
         {"text"=>"discussion topic menu",
          "label"=>"discussion topic menu",
          "url"=>"http://www.example.com/ims/lti/resource",
          "visibility"=>'admins',
          "display_type"=>'full_width',
          "selection_height"=>400,
          "selection_width"=>800},
     "file_menu"=>
         {"text"=>"module menu",
          "label"=>"module menu",
          "url"=>"http://www.example.com/ims/lti/resource",
          "visibility"=>'admins',
          "display_type"=>'full_width',
          "selection_height"=>400,
          "selection_width"=>800},
     "module_menu"=>
         {"text"=>"module menu",
          "label"=>"module menu",
          "url"=>"http://www.example.com/ims/lti/resource",
          "visibility"=>'admins',
          "display_type"=>'full_width',
          "selection_height"=>400,
          "selection_width"=>800},
     "quiz_menu"=>
         {"text"=>"quiz menu",
          "label"=>"quiz menu",
          "url"=>"http://www.example.com/ims/lti/resource",
          "visibility"=>'admins',
          "display_type"=>'full_width',
          "selection_height"=>400,
          "selection_width"=>800},
     "wiki_page_menu"=>
         {"text"=>"wiki page menu",
          "label"=>"wiki page menu",
          "url"=>"http://www.example.com/ims/lti/resource",
          "visibility"=>'admins',
          "display_type"=>'full_width',
          "selection_height"=>400,
          "selection_width"=>800},
     "link_selection"=>nil,
     "assignment_selection"=>nil,
     "post_grades"=>nil,
     "collaboration"=>nil,
     "similarity_detection"=>nil,
     "course_assignments_menu" => begin
       if et && et.course_assignments_menu
         {
           "text" => "course assignments menu",
           "url" => "http://www.example.com/ims/lti/resource",
           "label" => "course assignments menu",
           "selection_width" => 800,
           "selection_height" => 400
         }
       end
     end
    }
  end
end
