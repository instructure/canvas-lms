#
# Copyright (C) 2012 Instructure, Inc.
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

describe TabsController, type: :request do
  describe 'index' do
    it "should require read permissions on the context" do
      course_factory(active_all: true)
      user_factory(active_all: true)
      api_call(:get, "/api/v1/courses/#{@course.id}/tabs",
                      { :controller => 'tabs', :action => 'index', :course_id => @course.to_param, :format => 'json'},
                      { :include => ['external']},
                      {},
                      { :expected_status => 401 })
    end

    it 'should list navigation tabs for a course' do
      course_with_teacher(:active_all => true)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs",
                      { :controller => 'tabs', :action => 'index', :course_id => @course.to_param, :format => 'json'},
                      { :include => ['external']})
      expect(json).to eq [
        {
          "id" => "home",
          "html_url" => "/courses/#{@course.id}",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}",
          "position" => 1,
          "visibility" => "public",
          "label" => "Home",
          "type" => "internal"
        },
        {
          "id" => "announcements",
          "html_url" => "/courses/#{@course.id}/announcements",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/announcements",
          "position" => 2,
          "unused" => true,
          "visibility" => "admins",
          "label" => "Announcements",
          "type" => "internal"
        },
        {
          "id" => "assignments",
          "html_url" => "/courses/#{@course.id}/assignments",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/assignments",
          "position" => 3,
          "unused" => true,
          "visibility" => "admins",
          "label" => "Assignments",
          "type" => "internal"
        },
        {
          "id" => "discussions",
          "html_url" => "/courses/#{@course.id}/discussion_topics",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/discussion_topics",
          "position" => 4,
          "visibility" => "public",
          "label" => "Discussions",
          "type" => "internal"
        },
        {
          "id" => "grades",
          "html_url" => "/courses/#{@course.id}/grades",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/grades",
          "position" => 5,
          "visibility" => "public",
          "label" => "Grades",
          "type" => "internal"
        },
        {
          "id" => "people",
          "html_url" => "/courses/#{@course.id}/users",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/users",
          "position" => 6,
          "visibility" => "public",
          "label" => "People",
          "type" => "internal"
        },
        {
          "id" => "pages",
          "html_url" => "/courses/#{@course.id}/wiki",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/wiki",
          "position" => 7,
          "unused" => true,
          "visibility" => "admins",
          "label" => "Pages",
          "type" => "internal"
        },
        {
          "id" => "files",
          "html_url" => "/courses/#{@course.id}/files",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/files",
          "position" => 8,
          "unused" => true,
          "visibility" => "admins",
          "label" => "Files",
          "type" => "internal"
        },
        {
          "id" => "syllabus",
          "html_url" => "/courses/#{@course.id}/assignments/syllabus",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/assignments/syllabus",
          "position" => 9,
          "visibility" => "public",
          "label" => "Syllabus",
          "type" => "internal"
        },
        {
          "id" => "outcomes",
          "html_url" => "/courses/#{@course.id}/outcomes",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/outcomes",
          "position" => 10,
          "unused" => true,
          "visibility" => "admins",
          "label" => "Outcomes",
          "type" => "internal"
        },
        {
          "id" => "quizzes",
          "html_url" => "/courses/#{@course.id}/quizzes",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/quizzes",
          "position" => 11,
          "unused" => true,
          "visibility" => "admins",
          "label" => "Quizzes",
          "type" => "internal"
        },
        {
          "id" => "modules",
          "html_url" => "/courses/#{@course.id}/modules",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/modules",
          "position" => 12,
          "unused" => true,
          "visibility" => "admins",
          "label" => "Modules",
          "type" => "internal"
        },
        {
          "id" => "settings",
          "html_url" => "/courses/#{@course.id}/settings",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/settings",
          "position" => 13,
          "visibility" => "admins",
          "label" => "Settings",
          "type" => "internal"
        }
      ]
    end

    it 'should include external tools' do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.new({
        :name => 'Example',
        :url => 'http://www.example.com',
        :consumer_key => 'key',
        :shared_secret => 'secret',
      })
      @tool.settings.merge!({
        :course_navigation => {
          :enabled => 'true',
          :url => 'http://www.example.com',
        },
      })
      @tool.save!

      json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs",
                      { :controller => 'tabs', :action => 'index', :course_id => @course.to_param, :format => 'json'},
                      { :include => ['external']})

      external_tabs = json.select {|tab| tab['type'] == 'external'}
      expect(external_tabs.length).to eq 1
      external_tabs.each do |tab|
        expect(tab).to include('url')
        uri = URI(tab['url'])
        expect(uri.path).to eq "/api/v1/courses/#{@course.id}/external_tools/sessionless_launch"
        expect(uri.query).to include('id=')
      end
    end

    it "includes collaboration tab if configured" do
      course_with_teacher :active_all => true
      @course.enable_feature! 'new_collaborations'
      json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs",
                      { :controller => 'tabs', :action => 'index', :course_id => @course.to_param, :format => 'json'},
                      { :include => ['external']})
      expect(json.map { |el| el['id'] }).to include 'collaborations'
    end

    it "includes webconferences tab if configured" do
      course_with_teacher :active_all => true
      allow_any_instance_of(ApplicationController).to receive(:feature_enabled?).with(:web_conferences).and_return(true)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs",
                      { :controller => 'tabs', :action => 'index', :course_id => @course.to_param, :format => 'json'},
                      { :include => ['external']})
      expect(json.map { |el| el['id'] }).to include 'conferences'
    end

    it 'should list navigation tabs for a group' do
      group_with_user(:active_all => true)
      json = api_call(:get, "/api/v1/groups/#{@group.id}/tabs",
                      { :controller => 'tabs', :action => 'index', :group_id => @group.to_param, :format => 'json'})
      expect(json).to eq [
        {
          "id" => "home",
          "html_url" => "/groups/#{@group.id}",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@group)}/groups/#{@group.id}",
          "type" => "internal",
          "label" => "Home",
          "position"=>1,
          "visibility"=>"public"
        },
        {
          "id" => "announcements",
          "label" => "Announcements",
          "html_url" => "/groups/#{@group.id}/announcements",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@group)}/groups/#{@group.id}/announcements",
          "position"=>2,
          "visibility"=>"public",
          "type" => "internal"
        },
        {
          "id" => "pages",
          "html_url" => "/groups/#{@group.id}/wiki",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@group)}/groups/#{@group.id}/wiki",
          "label" => "Pages",
          "position"=>3,
          "visibility"=>"public",
          "type" => "internal"
        },
        {
          "id" => "people",
          "html_url" => "/groups/#{@group.id}/users",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@group)}/groups/#{@group.id}/users",
          "label" => "People",
          "position"=>4,
          "visibility"=>"public",
          "type" => "internal"
        },
        {
          "id" => "discussions",
          "html_url" => "/groups/#{@group.id}/discussion_topics",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@group)}/groups/#{@group.id}/discussion_topics",
          "label" => "Discussions",
          "position"=>5,
          "visibility"=>"public",
          "type" => "internal"
        },
        {
          "id" => "files",
          "html_url" => "/groups/#{@group.id}/files",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@group)}/groups/#{@group.id}/files",
          "label" => "Files",
          "position"=>6,
          "visibility"=>"public",
          "type" => "internal"
        }
      ]
    end

    it "doesn't include hidden tabs for student" do
      course_with_student(active_all: true)
      tab_ids = [
        Course::TAB_HOME,
        Course::TAB_SYLLABUS,
        Course::TAB_ASSIGNMENTS,
        Course::TAB_DISCUSSIONS,
        Course::TAB_GRADES,
        Course::TAB_PEOPLE,
        Course::TAB_ANNOUNCEMENTS,
        Course::TAB_PAGES,
        Course::TAB_FILES,
        Course::TAB_OUTCOMES,
        Course::TAB_QUIZZES,
        Course::TAB_MODULES,
        Course::TAB_OUTCOMES
      ]
      hidden_tabs = [Course::TAB_ASSIGNMENTS, Course::TAB_DISCUSSIONS, Course::TAB_GRADES]

      @course.tab_configuration = tab_ids.map do |n|
        hash = {'id' => n}
        hash['hidden'] = true if hidden_tabs.include?(n)
        hash
      end
      @course.save
      json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs", { :controller => 'tabs', :action => 'index',
                                                                    :course_id => @course.to_param, :format => 'json'})
      expect(json).to match_array([
        a_hash_including({"id" => "home"}),
        a_hash_including({"id" => "syllabus"}),
        a_hash_including({"id" => "people"}),
      ])
    end

    describe "teacher in a course" do
      before :once do
        course_with_teacher(active_all: true)
        @tab_ids = [0, 1, 3, 8, 5, 6, 14, 2, 11, 15, 4, 10, 13]
        @tab_lookup = {}.with_indifferent_access
        @course.tabs_available(@teacher, :api => true).each do |t|
          t = t.with_indifferent_access
          @tab_lookup[t['css_class']] = t['id']
        end
      end


      it 'should have the correct position' do
        tab_order = [0, 1, 3, 8, 5, 6, 14, 2, 11, 15, 4, 10, 13]
        @course.tab_configuration = tab_order.map { |n| {'id' => n} }
        @course.save
        json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs", {:controller => 'tabs', :action => 'index',
                                                                     :course_id => @course.to_param, :format => 'json'})
        json.each { |t| expect(t['position']).to eq tab_order.find_index(@tab_lookup[t['id']]) + 1 }
      end

      it 'should correctly label navigation items as unused' do
        unused_tabs = %w{announcements assignments pages files outcomes quizzes modules}
        json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs", {:controller => 'tabs', :action => 'index',
                                                                     :course_id => @course.to_param, :format => 'json'})
        json.each do |t|
          if unused_tabs.include? t['id']
            expect(t['unused']).to be_truthy
          else
            expect(t['unused']).to be_falsey
          end
        end
      end

      it 'should label hidden items correctly' do
        hidden_tabs = [3, 8, 5]
        @course.tab_configuration = @tab_ids.map do |n|
          hash = {'id' => n}
          hash['hidden'] = true if hidden_tabs.include?(n)
          hash
        end
        @course.save
        json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs", {:controller => 'tabs', :action => 'index',
                                                                     :course_id => @course.to_param, :format => 'json'})
        json.each do |t|
          if hidden_tabs.include? @tab_lookup[t['id']]
            expect(t['hidden']).to be_truthy
          else
            expect(t['hidden']).to be_falsey
          end
        end
      end

      it 'correctly sets visibility' do
        hidden_tabs = [3, 8, 5]
        public_visibility = %w{home people syllabus}
        admins_visibility = %w{announcements assignments pages files outcomes quizzes modules settings discussions grades}
        @course.tab_configuration = @tab_ids.map do |n|
          hash = {'id' => n}
          hash['hidden'] = true if hidden_tabs.include?(n)
          hash
        end
        @course.save
        json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs", {:controller => 'tabs', :action => 'index',
                                                                     :course_id => @course.to_param, :format => 'json'})
        json.each do |t|
          if t['visibility'] == 'public'
            expect(public_visibility).to include(t['id'])
          elsif t['visibility'] == 'admins'
            expect(admins_visibility).to include(t['id'])
          else
            expect(true).to be_falsey
          end
        end
      end

      it 'sorts tabs correctly' do
        course_with_teacher(active_all: true)
        tab_order = [0, 1, 3, 8, 5, 6, 14, 2, 11, 15, 4, 10, 13]
        @course.tab_configuration = tab_order.map { |n| {'id' => n} }
        @course.save
        json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs", {:controller => 'tabs', :action => 'index',
                                                                     :course_id => @course.to_param, :format => 'json'})
        json.each_with_index { |t, i| expect(t['position']).to eq i+1 }
      end

    end

  end

  describe 'update' do
    it 'sets the people tab to hidden' do
      tab_id = 'people'
      course_with_teacher(active_all: true)
      json = api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", {:controller => 'tabs', :action => 'update',
                                                                   :course_id => @course.to_param, :tab_id => tab_id,
                                                                   :format => 'json', :hidden => true})
      expect(json['hidden']).to eq true
      expect(@course.reload.tab_configuration[json['position'] - 1]['hidden']).to eq true
    end

    it 'only unhides one tab and not all when first updating' do
      course_with_teacher(:active_all => true)
      tools = []

      3.times do |i|
        tool = @course.context_external_tools.new({
                                                     :name => "Example #{i}",
                                                     :url => 'http://www.example.com',
                                                     :consumer_key => 'key',
                                                     :shared_secret => 'secret'
                                                 })
        tool.settings.merge!({
                                  :course_navigation => {
                                      :default => 'disabled',
                                      :url => 'http://www.example.com',
                                  },
                              })
        tool.save!
        tools << tool.reload
      end

      tab_id = "context_external_tool_#{tools.first.id}"
      json = api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", {:controller => 'tabs', :action => 'update',
                                                                             :course_id => @course.to_param, :tab_id => tab_id,
                                                                             :format => 'json', :hidden => false})
      expect(json['hidden']).to be_nil
      expect(@course.reload.tab_configuration[json['position'] - 1]['hidden']).to be_nil
      expect(@course.reload.tab_configuration.select { |t| t['hidden'] }.count).to eql(tools.count - 1)
    end

    it 'allows updating new tabs not in the configuration yet' do
      course_with_teacher(:active_all => true)
      tab_ids = [0, 1, 3, 8, 5, 6, 14, 2, 11, 15, 4, 10, 13]
      @course.tab_configuration = tab_ids.map {|id| hash = {'id' => id} }
      @course.save!

      @tool = @course.context_external_tools.new({
          :name => 'Example',
          :url => 'http://www.example.com',
          :consumer_key => 'key',
          :shared_secret => 'secret',
        })
      @tool.settings.merge!({
          :course_navigation => {
            :enabled => 'true',
            :url => 'http://www.example.com',
          },
        })
      @tool.save!
      tab_id = "context_external_tool_#{@tool.id}"

      json = api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", {:controller => 'tabs', :action => 'update',
          :course_id => @course.to_param, :tab_id => tab_id,
          :format => 'json', :hidden => true})
      expect(json['hidden']).to eq true
      expect(@course.reload.tab_configuration[json['position'] - 1]['hidden']).to eq true
    end

    it 'changes the position of the people tab to 2' do
      tab_id = 'people'
      course_with_teacher(active_all: true)
      json = api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", {:controller => 'tabs', :action => 'update',
                                                                             :course_id => @course.to_param, :tab_id => tab_id,
                                                                             :format => 'json', :position => 2})
      expect(json['position']).to eq 2
      expect(@course.reload.tab_configuration[1]['id']).to eq @course.class::TAB_PEOPLE
    end

    it "won't allow you to hide the home tab" do
      tab_id = 'home'
      course_with_teacher(active_all: true)
      result = raw_api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", {:controller => 'tabs', :action => 'update',
                                                                             :course_id => @course.to_param, :tab_id => tab_id,
                                                                             :format => 'json', :hidden => true})
      expect(result).to eq 400
    end

    it "won't allow you to move a tab to the first position" do
      tab_id = 'people'
      course_with_teacher(active_all: true)
      result = raw_api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", {:controller => 'tabs', :action => 'update',
                                                                             :course_id => @course.to_param, :tab_id => tab_id,
                                                                             :format => 'json', :position => 1})
      expect(result).to eq 400
    end

    it "won't allow you to move a tab to an invalid position" do
      tab_id = 'people'
      course_with_teacher(active_all: true)
      result = raw_api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", {:controller => 'tabs', :action => 'update',
                                                                                   :course_id => @course.to_param, :tab_id => tab_id,
                                                                                   :format => 'json', :position => 400})
      expect(result).to eq 400
    end

    it "doesn't allow a student to modify a tab" do
      course_with_student(active_all: true)
      tab_id = 'people'
      result = raw_api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", {:controller => 'tabs', :action => 'update',
                                                                                   :course_id => @course.to_param, :tab_id => tab_id,
                                                                                   :format => 'json', :position => 4})
      expect(result).to eq 401
    end

  end

end
