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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe "Modules API", type: :request do
  before :once do
    course_factory.offer!

    @module1 = @course.context_modules.create!(:name => "module1")
    @assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"], :points_possible => 42)
    @assignment.publish! if @assignment.unpublished?

    @assignment_tag = @module1.add_item(:id => @assignment.id, :type => 'assignment')
    @quiz = @course.quizzes.create!(:title => "score 10")
    @quiz.publish! if @quiz.unpublished?

    @quiz_tag = @module1.add_item(:id => @quiz.id, :type => 'quiz')
    @topic = @course.discussion_topics.create!(:message => 'pls contribute')
    @topic.publish! if @topic.unpublished?

    @topic_tag = @module1.add_item(:id => @topic.id, :type => 'discussion_topic')
    @subheader_tag = @module1.add_item(:type => 'context_module_sub_header', :title => 'external resources')
    @external_url_tag = @module1.add_item(:type => 'external_url', :url => 'http://example.com/lolcats',
                                          :title => 'pls view', :indent => 1)
    @external_url_tag.publish! if @external_url_tag.unpublished?

    @module1.completion_requirements = {
        @assignment_tag.id => { :type => 'must_submit' },
        @quiz_tag.id => { :type => 'min_score', :min_score => 10 },
        @topic_tag.id => { :type => 'must_contribute' },
        @external_url_tag.id => { :type => 'must_view' } }
    @module1.save!

    @christmas = Time.zone.local(Time.now.year + 1, 12, 25, 7, 0)
    @module2 = @course.context_modules.create!(:name => "do not open until christmas",
                                               :unlock_at => @christmas,
                                               :require_sequential_progress => true)
    @module2.prerequisites = "module_#{@module1.id}"
    @wiki_page = @course.wiki.wiki_pages.create!(:title => "Front Page", :body => "")
    @wiki_page.workflow_state = 'active'; @wiki_page.save!
    @wiki_page_tag = @module2.add_item(:id => @wiki_page.id, :type => 'wiki_page')

    @attachment = attachment_model(:context => @course, :usage_rights => @course.usage_rights.create!(legal_copyright: '(C) 2012 Initrode', use_justification: 'creative_commons', license: 'cc_by_sa'), :uploaded_data => stub_file_data("test_image.jpg", File.read(Rails.root+"spec/fixtures/test_image.jpg"), "image/jpeg"))

    @attachment_tag = @module2.add_item(:id => @attachment.id, :type => 'attachment')
    @module2.save!

    @module3 = @course.context_modules.create(:name => "module3")
    @module3.workflow_state = 'unpublished'
    @module3.save!
  end

  context "as a teacher" do
    before :once do
      course_with_teacher(:course => @course, :active_all => true)
    end

    describe "index" do
      it "should list published and unpublished modules" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/modules",
                        :controller => "context_modules_api", :action => "index", :format => "json",
                        :course_id => "#{@course.id}")
        expect(json).to eq [
            {
               "name" => @module1.name,
               "unlock_at" => nil,
               "position" => 1,
               "require_sequential_progress" => false,
               "prerequisite_module_ids" => [],
               "id" => @module1.id,
               "published" => true,
               "items_count" => 5,
               "items_url" => "http://www.example.com/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
               "publish_final_grade" => false,
            },
            {
               "name" => @module2.name,
               "unlock_at" => @christmas.as_json,
               "position" => 2,
               "require_sequential_progress" => true,
               "prerequisite_module_ids" => [@module1.id],
               "id" => @module2.id,
               "published" => true,
               "items_count" => 2,
               "items_url" => "http://www.example.com/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items",
               "publish_final_grade" => false,
            },
            {
               "name" => @module3.name,
               "unlock_at" => nil,
               "position" => 3,
               "require_sequential_progress" => false,
               "prerequisite_module_ids" => [],
               "id" => @module3.id,
               "published" => false,
               "items_count" => 0,
               "items_url" => "http://www.example.com/api/v1/courses/#{@course.id}/modules/#{@module3.id}/items",
               "publish_final_grade" => false,
            }
        ]
      end

      it "should include items if requested" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/modules?include[]=items",
                        :controller => "context_modules_api", :action => "index", :format => "json",
                        :course_id => "#{@course.id}", :include => %w(items))
        expect(json.map { |mod| mod['items'].size }).to eq [5, 2, 0]
      end

      context 'index including content details' do
        let(:json) do
          api_call(:get, "/api/v1/courses/#{@course.id}/modules?include[]=items&include[]=content_details",
            :controller => "context_modules_api", :action => "index", :format => "json",
            :course_id => "#{@course.id}", :include => %w(items content_details))
        end
        let(:assignment_details) { json.find{|mod| mod['id'] == @module1.id}['items'].find{|item| item['id'] == @assignment_tag.id}['content_details'] }
        let(:wiki_page_details) { json.find{|mod| mod['id'] == @module2.id}['items'].find{|item| item['id'] == @wiki_page_tag.id}['content_details'] }
        let(:attachment_details) { json.find{|mod| mod['id'] == @module2.id}['items'].find{|item| item['id'] == @attachment_tag.id}['content_details'] }

        it 'should include user specific details' do
          expect(assignment_details).to include(
            'points_possible' => @assignment.points_possible,
          )
        end

        it 'should include thumbnail_url' do
          expect(attachment_details).to include(
            'thumbnail_url' => @attachment.thumbnail_url
          )
        end

        it 'should include usage_rights information' do
          expect(attachment_details).to include(
            'usage_rights' => @attachment.usage_rights.as_json
          )
        end

        it 'should include lock information' do
          expect(assignment_details).to include(
            'locked_for_user' => false,
          )

          expect(wiki_page_details).to include(
            'locked_for_user' => false,
          )
        end
      end

      it "should skip items for modules that have too many" do
        Setting.set('api_max_per_page', '3')
        json = api_call(:get, "/api/v1/courses/#{@course.id}/modules?include[]=items",
                        :controller => "context_modules_api", :action => "index", :format => "json",
                        :course_id => "#{@course.id}", :include => %w(items))
        expect(json.map { |mod| mod['items'].try(:size) }).to eq [nil, 2, 0]
      end

      it "should paginate the module list" do
        # 3 modules already exist
        2.times { |i| @course.context_modules.create!(:name => "spurious module #{i}") }
        json = api_call(:get, "/api/v1/courses/#{@course.id}/modules?per_page=3",
                        :controller => "context_modules_api", :action => "index", :format => "json",
                        :course_id => "#{@course.id}", :per_page => "3")
        expect(response.headers["Link"]).to be_present
        expect(json.size).to eq 3
        ids = json.collect{ |mod| mod['id'] }

        json = api_call(:get, "/api/v1/courses/#{@course.id}/modules?per_page=3&page=2",
                        :controller => "context_modules_api", :action => "index", :format => "json",
                        :course_id => "#{@course.id}", :page => "2", :per_page => "3")
        expect(json.size).to eq 2
        ids += json.collect{ |mod| mod['id'] }

        expect(ids).to eq @course.context_modules.not_deleted.sort_by(&:position).collect(&:id)
      end

      it "should search for modules by name" do
        mods = []
        2.times { |i| mods << @course.context_modules.create!(:name => "spurious module #{i}") }
        json = api_call(:get, "/api/v1/courses/#{@course.id}/modules?search_term=spur",
                        :controller => "context_modules_api", :action => "index", :format => "json",
                        :course_id => "#{@course.id}", :search_term => "spur")
        expect(json.size).to eq 2
        expect(json.map{ |mod| mod['id'] }.sort).to eq mods.map(&:id).sort
      end

      it "should search for modules and items by name" do
        matching_mods = []
        nonmatching_mods = []
        # modules to include because their name matches
        # which means that all their (non-matching) items should be returned
        2.times do |i|
          mod = @course.context_modules.create!(:name => "spurious module #{i}")
          mod.add_item(:type => 'context_module_sub_header', :title => 'non-matching item')
          matching_mods << mod
        end
        # modules to include because they have a matching item
        # which means that their non-matching items should *not* be included
        2.times do |i|
          mod = @course.context_modules.create!(:name => "non-matching module #{i}")
          mod.add_item(:type => 'context_module_sub_header', :title => 'spurious item')
          mod.add_item(:type => 'context_module_sub_header', :title => 'non-matching item to ignore')
          nonmatching_mods << mod
        end

        json = api_call(:get, "/api/v1/courses/#{@course.id}/modules?include[]=items&search_term=spur",
                        :controller => "context_modules_api", :action => "index", :format => "json",
                        :course_id => "#{@course.id}", :include => %w{items}, :search_term => "spur")
        expect(json.size).to eq 4
        expect(json.map{ |mod| mod['id'] }.sort).to eq (matching_mods + nonmatching_mods).map(&:id).sort

        json.each do |mod|
          expect(mod['items'].count).to eq 1
          expect(mod['items'].first['title']).not_to include('ignore')
        end
      end
    end

    describe "show" do
      it "should show a single module" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}",
                        :controller => "context_modules_api", :action => "show", :format => "json",
                        :course_id => "#{@course.id}", :id => "#{@module2.id}")
        expect(json).to eq({
          "name" => @module2.name,
          "unlock_at" => @christmas.as_json,
          "position" => 2,
          "require_sequential_progress" => true,
          "prerequisite_module_ids" => [@module1.id],
          "id" => @module2.id,
          "published" => true,
          "items_count" => 2,
          "items_url" => "http://www.example.com/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items",
          "publish_final_grade" => false,
        })
      end

      context 'show including content details' do
        let(:module1_json) do
          api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}?include[]=items&include[]=content_details",
            :controller => "context_modules_api", :action => "show", :format => "json",
            :course_id => "#{@course.id}", :include => %w(items content_details), :id => "#{@module1.id}")
        end
        let(:module2_json) do
          api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}?include[]=items&include[]=content_details",
            :controller => "context_modules_api", :action => "show", :format => "json",
            :course_id => "#{@course.id}", :include => %w(items content_details), :id => "#{@module2.id}")
        end
        let(:assignment_details) { module1_json['items'].find{|item| item['id'] == @assignment_tag.id}['content_details'] }
        let(:wiki_page_details) { module2_json['items'].find{|item| item['id'] == @wiki_page_tag.id}['content_details'] }

        it 'should include user specific details' do
          expect(assignment_details).to include(
            'points_possible' => @assignment.points_possible,
          )
        end

        it 'sould include lock information' do
          expect(assignment_details).to include(
            'locked_for_user' => false,
          )

          expect(wiki_page_details).to include(
            'locked_for_user' => false,
          )
        end
      end

      it "should show a single unpublished module" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module3.id}",
                        :controller => "context_modules_api", :action => "show", :format => "json",
                        :course_id => "#{@course.id}", :id => @module3.id.to_param)
        expect(json).to eq({
          "name" => @module3.name,
          "unlock_at" => nil,
          "position" => 3,
          "require_sequential_progress" => false,
          "prerequisite_module_ids" => [],
          "id" => @module3.id,
          "published" => false,
          "items_count" => 0,
          "items_url" => "http://www.example.com/api/v1/courses/#{@course.id}/modules/#{@module3.id}/items",
          "publish_final_grade" => false,
        })
      end

      it "should include items if requested" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}?include[]=items",
                        :controller => "context_modules_api", :action => "show", :format => "json",
                        :course_id => "#{@course.id}", :id => @module1.id.to_param, :include => %w(items))
        expect(json['items'].map{|item|item['type']}).to eq %w(Assignment Quiz Discussion SubHeader ExternalUrl)
      end

      it "should not include items if there are too many" do
        Setting.set('api_max_per_page', '3')
        json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}?include[]=items",
                        :controller => "context_modules_api", :action => "show", :format => "json",
                        :course_id => "#{@course.id}", :id => @module1.id.to_param, :include => %w(items))
        expect(json['items']).to be_nil
      end
    end

    describe "batch update" do
      before :once do
        @path = "/api/v1/courses/#{@course.id}/modules"
        @path_opts = { :controller => "context_modules_api", :action => "batch_update", :format => "json",
                       :course_id => @course.to_param }
        @test_modules = (1..4).map { |x| @course.context_modules.create! :name => "test module #{x}" }
        @test_modules[2..3].each { |m| m.update_attribute(:workflow_state , 'unpublished') }
        expect(@test_modules.map { |tm| tm.workflow_state }).to eq %w(active active unpublished unpublished)
        @modules_to_update = [@test_modules[1], @test_modules[3]]

        @wiki_page = @course.wiki.wiki_pages.create(:title => 'Wiki Page Title')
        @wiki_page.unpublish!
        @wiki_page_tag = @test_modules[3].add_item(:id => @wiki_page.id, :type => 'wiki_page')

        @ids_to_update = @modules_to_update.map(&:id)
      end

      it "should publish modules (and their tags)" do
        json = api_call(:put, @path, @path_opts, { :event => 'publish', :module_ids => @ids_to_update })
        expect(json['completed'].sort).to eq @ids_to_update
        expect(@test_modules.map { |tm| tm.reload.workflow_state }).to eq %w(active active unpublished active)

        @wiki_page_tag.reload
        expect(@wiki_page_tag.active?).to eq true
        @wiki_page.reload
        expect(@wiki_page.active?).to eq true
      end

      it "should unpublish modules" do
        json = api_call(:put, @path, @path_opts, { :event => 'unpublish', :module_ids => @ids_to_update })
        expect(json['completed'].sort).to eq @ids_to_update
        expect(@test_modules.map { |tm| tm.reload.workflow_state }).to eq %w(active unpublished unpublished unpublished)
      end

      it "should delete modules" do
        json = api_call(:put, @path, @path_opts, { :event => 'delete', :module_ids => @ids_to_update })
        expect(json['completed'].sort).to eq @ids_to_update
        expect(@test_modules.map { |tm| tm.reload.workflow_state }).to eq %w(active deleted unpublished deleted)
      end

      it "should convert module ids to integer and ignore non-numeric ones" do
        json = api_call(:put, @path, @path_opts, { :event => 'publish', :module_ids => %w(lolcats abc123) + @ids_to_update.map(&:to_s) })
        expect(json['completed'].sort).to eq @ids_to_update
        expect(@test_modules.map { |tm| tm.reload.workflow_state }).to eq %w(active active unpublished active)
      end

      it "should not update soft-deleted modules" do
        @modules_to_update.each { |m| m.destroy }
        api_call(:put, @path, @path_opts, { :event => 'delete', :module_ids => @ids_to_update },
                 {}, { :expected_status => 404 })
      end

      it "should 404 if no modules exist with the given ids" do
        @modules_to_update.each do |m|
          m.content_tags.scope.delete_all
          m.destroy_permanently!
        end
        api_call(:put, @path, @path_opts, { :event => 'publish', :module_ids => @ids_to_update },
                 {}, { :expected_status => 404 })
      end

      it "should 404 if only non-numeric ids are given" do
        api_call(:put, @path, @path_opts, { :event => 'publish', :module_ids => @ids_to_update.map { |id| id.to_s + "abc" } },
                 {}, { :expected_status => 404})
      end

      it "should succeed if only some ids don't exist" do
        @modules_to_update.first.destroy_permanently!
        json = api_call(:put, @path, @path_opts, { :event => 'publish', :module_ids => @ids_to_update })
        expect(json['completed']).to eq [@modules_to_update.last.id]
        expect(@modules_to_update.last.reload).to be_active
      end

      it "should 400 if :module_ids is missing" do
        api_call(:put, @path, @path_opts, { :event => 'publish' }, {}, { :expected_status => 400 })
      end

      it "should 400 if :event is missing" do
        api_call(:put, @path, @path_opts, { :module_ids => @ids_to_update }, {}, { :expected_status => 400 })
      end

      it "should 400 if :event is invalid" do
        api_call(:put, @path, @path_opts, { :event => 'burninate', :module_ids => @ids_to_update },
                 {}, { :expected_status => 400 })
      end

      it "should scope to the course" do
        other_course = Course.create! :name => "Other Course"
        other_module = other_course.context_modules.create! :name => "Other Module"

        json = api_call(:put, @path, @path_opts, { :event => 'unpublish',
          :module_ids => [@test_modules[1].id, other_module.id] })
        expect(json['completed']).to eq [@test_modules[1].id]

        expect(@test_modules[1].reload).to be_unpublished
        expect(other_module.reload).to be_active
      end
    end

    describe "update" do
      before :once do
        course_with_teacher(:active_all => true)

        @module1 = @course.context_modules.create(:name => "unpublished")
        @module1.workflow_state = 'unpublished'
        @module1.save!

        @wiki_page = @course.wiki.wiki_pages.create(:title => 'Wiki Page Title')
        @wiki_page.unpublish!
        @wiki_page_tag = @module1.add_item(:id => @wiki_page.id, :type => 'wiki_page')

        @module2 = @course.context_modules.create!(:name => "published")
      end

      it "should update the attributes" do
        unlock_at = 1.day.from_now
        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
                        {:controller => "context_modules_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :id => "#{@module1.id}"},
                        {:module => {:name => 'new name', :unlock_at => unlock_at,
                                     :require_sequential_progress => true}}
        )

        expect(json['id']).to eq @module1.id
        expect(json['name']).to eq "new name"
        expect(json['unlock_at']).to eq unlock_at.as_json
        expect(json['require_sequential_progress']).to eq true

        @module1.reload
        expect(@module1.name).to eq "new name"
        expect(@module1.unlock_at.as_json).to eq unlock_at.as_json
        expect(@module1.require_sequential_progress).to eq true
      end

      it "should update the position" do
        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
                        {:controller => "context_modules_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :id => "#{@module1.id}"},
                        {:module => {:position => '2'}}
        )

        expect(json['position']).to eq 2
        @module1.reload
        @module2.reload
        expect(@module1.position).to eq 2
        expect(@module2.position).to eq 1

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
                        {:controller => "context_modules_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :id => "#{@module1.id}"},
                        {:module => {:position => '1'}}
        )

        expect(json['position']).to eq 1
        @module1.reload
        @module2.reload
        expect(@module1.position).to eq 1
        expect(@module2.position).to eq 2
      end

      it "should publish modules (and their tags)" do
        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
                        {:controller => "context_modules_api", :action => "update", :format => "json",
                        :course_id => "#{@course.id}", :id => "#{@module1.id}"},
                        {:module => {:published => '1'}}
        )
        expect(json['published']).to eq true
        @module1.reload
        expect(@module1.active?).to eq true

        @wiki_page_tag.reload
        expect(@wiki_page_tag.active?).to eq true
        @wiki_page.reload
        expect(@wiki_page.active?).to eq true
      end

      it "should publish module tag items even if the tag itself is already published" do
        # surreptitiously set up a terrible pre-DS => post-DS transition state
        ContentTag.where(:id => @wiki_page_tag.id).update_all(:workflow_state => 'active')

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
                        {:controller => "context_modules_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :id => "#{@module1.id}"},
                        {:module => {:published => '1'}}
        )

        @wiki_page.reload
        expect(@wiki_page.active?).to eq true
      end

      it "should unpublish modules" do
        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}",
                        {:controller => "context_modules_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :id => "#{@module2.id}"},
                        {:module => {:published => '0'}}
        )
        expect(json['published']).to eq false
        @module2.reload
        expect(@module2.unpublished?).to eq true
      end

      it "should set prerequisites" do
        new_module = @course.context_modules.create!(:name => "published")

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{new_module.id}",
                        {:controller => "context_modules_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :id => "#{new_module.id}"},
                        {:module => {:name => 'name', :prerequisite_module_ids => [@module1.id, @module2.id]}}
        )

        expect(json['prerequisite_module_ids'].sort).to eq [@module1.id, @module2.id].sort
        new_module.reload
        expect(new_module.prerequisites.map{|m| m[:id]}.sort).to eq [@module1.id, @module2.id].sort
      end

      it "should only reset prerequisites if parameter is included and is blank" do
        new_module = @course.context_modules.create!(:name => "published")
        new_module.prerequisites = "module_#{@module1.id},module_#{@module2.id}"
        new_module.save!

        new_module.reload
        expect(new_module.prerequisites.map{|m| m[:id]}.sort).to eq [@module1.id, @module2.id].sort

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{new_module.id}",
                        {:controller => "context_modules_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :id => "#{new_module.id}"},
                        {:module => {:name => 'new name',
                                     :require_sequential_progress => true}}
        )
        new_module.reload
        expect(new_module.prerequisites.map{|m| m[:id]}.sort).to eq [@module1.id, @module2.id].sort

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{new_module.id}",
                        {:controller => "context_modules_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :id => "#{new_module.id}"},
                        {:module => {:name => 'new name',
                                     :prerequisite_module_ids => ''}}
        )
        new_module.reload
        expect(new_module.prerequisites.map{|m| m[:id]}.sort).to be_empty
      end

    end

    describe "create" do
      before :once do
        course_with_teacher(:active_all => true)
      end

      it "should create a module with attributes" do
        unlock_at = 1.day.from_now
        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules",
                        {:controller => "context_modules_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}"},
                        {:module => {:name => 'new name', :unlock_at => unlock_at,
                                     :require_sequential_progress => true}}
        )

        expect(@course.context_modules.count).to eq 1

        expect(json['name']).to eq "new name"
        expect(json['unlock_at']).to eq unlock_at.as_json
        expect(json['require_sequential_progress']).to eq true

        new_module = @course.context_modules.find(json['id'])
        expect(new_module.name).to eq "new name"
        expect(new_module.unlock_at.as_json).to eq unlock_at.as_json
        expect(new_module.require_sequential_progress).to eq true
      end

      it "should require a name" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules",
                        {:controller => "context_modules_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}"},
                        {:module => {:name => ''}}, {}, {:expected_status => 400}
        )

        expect(@course.context_modules.count).to eq 0
      end

      it "should insert new module into specified position" do
        deleted_mod = @course.context_modules.create(:name => "deleted")
        deleted_mod.destroy
        module1 = @course.context_modules.create(:name => "unpublished")
        module2 = @course.context_modules.create!(:name => "published")

        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules",
                        {:controller => "context_modules_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}"},
                        {:module => {:name => 'new name', :position => '2'}}
        )

        expect(@course.context_modules.not_deleted.count).to eq 3

        expect(json['position']).to eq 2

        module1.reload
        expect(module1.position).to eq 1
        new_module = @course.context_modules.find(json['id'])
        expect(new_module.position).to eq 2

        module2.reload
        expect(module2.position).to eq 3
      end

      it "should set prerequisites" do
        module1 = @course.context_modules.create(:name => "unpublished")
        module2 = @course.context_modules.create!(:name => "published")

        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules",
                        {:controller => "context_modules_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}"},
                        {:module => {:name => 'name', :prerequisite_module_ids => [module1.id, module2.id]}}
        )

        expect(@course.context_modules.count).to eq 3

        expect(json['prerequisite_module_ids'].sort).to eq [module1.id, module2.id].sort

        new_module = @course.context_modules.find(json['id'])
        expect(new_module.prerequisites.map{|m| m[:id]}.sort).to eq [module1.id, module2.id].sort
      end
    end

    it "should delete a module" do
      json = api_call(:delete, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
               {:controller => "context_modules_api", :action => "destroy", :format => "json",
                :course_id => "#{@course.id}", :id => "#{@module1.id}"},
               {}, {}
      )
      expect(json['id']).to eq @module1.id
      @module1.reload
      expect(@module1.workflow_state).to eq 'deleted'
    end

    it "should show module progress for a student" do
      student = User.create!
      @course.enroll_student(student).accept!

      # to simplify things, eliminate the other requirements
      @module1.completion_requirements.reject! {|r| [@quiz_tag.id, @topic_tag.id, @external_url_tag.id].include? r[:id]}
      @module1.save!
      @assignment.submit_homework(student, :body => "done!")

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules?include[]=items&student_id=#{student.id}",
                      :controller => "context_modules_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :student_id => "#{student.id}", :include => ["items"])
      h = json.find{|m| m["id"] == @module1.id}
      expect(h['state']).to eq 'completed'
      expect(h['completed_at']).not_to be_nil
      expect(h['items'].find{|i| i["id"] == @assignment_tag.id}["completion_requirement"]["completed"]).to eq true

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}?include[]=items&student_id=#{student.id}",
                      :controller => "context_modules_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :id => "#{@module1.id}", :student_id => "#{student.id}", :include => ["items"])
      expect(json['state']).to eq 'completed'
      expect(json['completed_at']).not_to be_nil
      expect(json['items'].find{|i| i["id"] == @assignment_tag.id}["completion_requirement"]["completed"]).to eq true
    end
  end

  context "as a student" do
    before :once do
      course_with_student(:course => @course, :active_all => true)
    end

    it "should show locked state" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}",
                      :controller => "context_modules_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :id => "#{@module2.id}")
      expect(json['state']).to eq 'locked'
    end

    it "should show module progress" do
      # to simplify things, eliminate the requirements on the quiz and discussion topic for this test
      @module1.completion_requirements.reject! {|r| [@quiz_tag.id, @topic_tag.id].include? r[:id]}
      @module1.save!

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
                      :controller => "context_modules_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :id => "#{@module1.id}")
      expect(json['state']).to eq 'unlocked'

      @assignment.submit_homework(@user, :body => "done!")
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
                      :controller => "context_modules_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :id => "#{@module1.id}")
      expect(json['state']).to eq 'started'
      expect(json['completed_at']).to be_nil

      @external_url_tag.context_module_action(@user, :read)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
                      :controller => "context_modules_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :id => "#{@module1.id}")
      expect(json['state']).to eq 'completed'
      expect(json['completed_at']).not_to be_nil
    end

    context 'show including content details' do
      let(:module1_json) do
        api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}?include[]=items&include[]=content_details",
          :controller => "context_modules_api", :action => "show", :format => "json",
          :course_id => "#{@course.id}", :include => %w(items content_details), :id => "#{@module1.id}")
      end
      let(:module2_json) do
        api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}?include[]=items&include[]=content_details",
          :controller => "context_modules_api", :action => "show", :format => "json",
          :course_id => "#{@course.id}", :include => %w(items content_details), :id => "#{@module2.id}")
      end
      let(:assignment_details) { module1_json['items'].find{|item| item['id'] == @assignment_tag.id}['content_details'] }
      let(:wiki_page_details) { module2_json['items'].find{|item| item['id'] == @wiki_page_tag.id}['content_details'] }

      it 'should include user specific details' do
        expect(assignment_details).to include(
          'points_possible' => @assignment.points_possible,
        )
      end

      it 'sould include lock information' do
        expect(assignment_details).to include(
          'locked_for_user' => false,
        )

        expect(wiki_page_details).to include(
          'lock_info',
          'lock_explanation',
          'locked_for_user' => true,
        )
        expect(wiki_page_details['lock_info']).to include(
          'asset_string' => @wiki_page.asset_string,
          'unlock_at' => @christmas.as_json,
        )
      end
    end

    it "should not list unpublished modules" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules",
                      :controller => "context_modules_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}")
      expect(json.length).to eq 2
      json.each{|cm| expect(@course.context_modules.find(cm['id']).workflow_state).to eq 'active'}
    end

    it "should not show a single unpublished module" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module3.id}",
                      {:controller => "context_modules_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :id => @module3.id.to_param},{},{}, {:expected_status => 404})
    end

    describe "batch update" do
      it "should disallow deleting" do
        api_call(:put, "/api/v1/courses/#{@course.id}/modules?event=delete&module_ids[]=#{@module1.id}",
                 { :controller => "context_modules_api", :action => "batch_update", :event => 'delete',
                   :module_ids => [@module1.to_param], :format => "json", :course_id => "#{@course.id}"},
                 {}, {}, { :expected_status => 401 })
      end

      it "should disallow publishing" do
        api_call(:put, "/api/v1/courses/#{@course.id}/modules?event=publish&module_ids[]=#{@module1.id}",
                 { :controller => "context_modules_api", :action => "batch_update", :event => 'publish',
                   :module_ids => [@module1.to_param], :format => "json", :course_id => "#{@course.id}"},
                 {}, {}, { :expected_status => 401 })
      end

      it "should disallow unpublishing" do
        api_call(:put, "/api/v1/courses/#{@course.id}/modules?event=unpublish&module_ids[]=#{@module1.id}",
                 { :controller => "context_modules_api", :action => "batch_update", :event => 'unpublish',
                   :module_ids => [@module1.to_param], :format => "json", :course_id => "#{@course.id}"},
                 {}, {}, { :expected_status => 401 })
      end
    end

    it "should disallow update" do
      @module1 = @course.context_modules.create(:name => "module")
      api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
                      {:controller => "context_modules_api", :action => "update", :format => "json",
                       :course_id => "#{@course.id}", :id => "#{@module1.id}"},
                      {:module => {:name => 'new name'}}, {},
                      {:expected_status => 401}
      )
    end

    it "should disallow create" do
      api_call(:post, "/api/v1/courses/#{@course.id}/modules",
                      {:controller => "context_modules_api", :action => "create", :format => "json",
                       :course_id => "#{@course.id}"},
                      {:module => {:name => 'new name'}}, {},
                      {:expected_status => 401}
      )
    end

    it "should disallow destroy" do
      api_call(:delete, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
               {:controller => "context_modules_api", :action => "destroy", :format => "json",
                :course_id => "#{@course.id}", :id => "#{@module1.id}"},
               {}, {},
               {:expected_status => 401}
      )
    end

    it "should not show progress for other students" do
      student = User.create!
      @course.enroll_student(student).accept!

      api_call(:get, "/api/v1/courses/#{@course.id}/modules?student_id=#{student.id}",
               {:controller => "context_modules_api", :action => "index", :format => "json",
                :course_id => "#{@course.id}", :student_id => "#{student.id}"},
               {}, {},
               {:expected_status => 401}
      )

      api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}?student_id=#{student.id}",
              {:controller => "context_modules_api", :action => "show", :format => "json",
               :course_id => "#{@course.id}", :id => "#{@module1.id}", :student_id => "#{student.id}"},
              {}, {},
              {:expected_status => 401}
      )
    end
  end

  context "differentiated assignments" do
    before(:once) do
      @assignment.only_visible_to_overrides = true; @assignment.save!
      @other_section = @course.course_sections.create! name: "other section"
      create_section_override_for_assignment(@assignment, {course_section: @other_section})
    end

    it "should exclude unassigned assignments" do
      student_in_course(:active_all => true)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules?include[]=items",
               { :controller => "context_modules_api", :action => "index", :format => "json",
                 :course_id => "#{@course.id}", :include => ['items'] })
      mod1_items = json.find { |m| m['id'] == @module1.id }['items'].map { |item| item['id'] }
      expect(mod1_items).not_to include(@assignment_tag.id)
    end

    it "should include override assignments" do
      student_in_course(:active_all => true, :section => @other_section)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules?include[]=items",
                      { :controller => "context_modules_api", :action => "index", :format => "json",
                        :course_id => "#{@course.id}", :include => ['items'] })
      mod1_items = json.find { |m| m['id'] == @module1.id }['items'].map { |item| item['id'] }
      expect(mod1_items).to include(@assignment_tag.id)
    end

    it "should include observed students' assigned assignment items" do
      student_in_course(:active_all => true, :section => @other_section)
      course_with_observer(:course => @course, :associated_user_id => @student.id)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules?include[]=items",
                      { :controller => "context_modules_api", :action => "index", :format => "json",
                        :course_id => "#{@course.id}", :include => ['items'] })
      mod1_items = json.find { |m| m['id'] == @module1.id }['items'].map { |item| item['id'] }
      expect(mod1_items).to include(@assignment_tag.id)
    end
  end

  context "unauthorized user" do
    before do
      user_factory
    end

    it "should check permissions" do
      api_call(:get, "/api/v1/courses/#{@course.id}/modules",
               { :controller => "context_modules_api", :action => "index", :format => "json",
                 :course_id => "#{@course.id}"}, {}, {}, {:expected_status => 401})
      api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}",
               { :controller => "context_modules_api", :action => "show", :format => "json",
                 :course_id => "#{@course.id}", :id => "#{@module2.id}"},
               {}, {}, {:expected_status => 401})
      api_call(:put, "/api/v1/courses/#{@course.id}/modules?event=publish&module_ids[]=1",
               { :controller => "context_modules_api", :action => "batch_update", :event => 'publish',
                 :module_ids => %w(1), :format => "json", :course_id => "#{@course.id}"},
               {}, {}, { :expected_status => 401 })
      api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
               {:controller => "context_modules_api", :action => "update", :format => "json",
                :course_id => "#{@course.id}", :id => "#{@module1.id}"},
               {:module => {:name => 'new name'}}, {},
               {:expected_status => 401}
      )
      api_call(:delete, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
               {:controller => "context_modules_api", :action => "destroy", :format => "json",
                :course_id => "#{@course.id}", :id => "#{@module1.id}"},
               {}, {},
               {:expected_status => 401}
      )
      api_call(:post, "/api/v1/courses/#{@course.id}/modules",
               {:controller => "context_modules_api", :action => "create", :format => "json",
                :course_id => "#{@course.id}"},
               {:module => {:name => 'new name'}}, {},
               {:expected_status => 401}
      )
    end
  end
end
