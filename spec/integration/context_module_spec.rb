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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContextModule do
  def course_module
    course_with_student_logged_in
    @module = @course.context_modules.create!(:name => "some module")
  end

  describe "index" do
    it "should require manage_content permission before showing add controls" do
      course_with_teacher_logged_in active_all: true
      get "/courses/#{@course.id}/modules"
      doc = Nokogiri::HTML(response.body)
      doc.at_css('.context-modules-main-toolbar .add_module_link').should_not be_nil

      @course.account.role_overrides.create! enrollment_type: 'TaEnrollment', permission: 'manage_content', enabled: false
      course_with_ta course: @course
      user_session(@ta)
      get "/courses/#{@course.id}/modules"
      doc = Nokogiri::HTML(response.body)
      doc.at_css('.context-modules-main-toolbar .add_module_link').should be_nil
    end
  end

  it "should clear the page cache on individual tag change" do
    enable_cache do
      course_with_teacher_logged_in(:active_all => true)
      context_module = @course.context_modules.create!
      content_tag = context_module.add_item :type => 'context_module_sub_header', :title => "My Sub Header Title"
      ContextModule.where(:id => context_module).update_all(:updated_at => 1.hour.ago)
      get "/courses/#{@course.id}/modules"
      response.body.should match(/My Sub Header Title/)

      content_tag.update_attributes(:title => "My New Title")

      get "/courses/#{@course.id}/modules"
      response.body.should match(/My New Title/)
    end
  end

  describe "must_contribute" do
    before do
      course_module
      @module.require_sequential_progress = true
      @module.save!
    end

    def before_after
      @module.completion_requirements = { @tag.id => { :type => 'must_contribute' } }
      @module.save!

      @progression = @module.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should_not be_completed
      @progression.should be_unlocked
      @progression.current_position.should eql(@tag.position)
      yield
      @progression = @module.evaluate_for(@user, true)
      @progression.should be_completed
      @progression.current_position.should eql(@tag.position)
    end

    it "should progress for discussions" do
      @discussion = @course.discussion_topics.create!(:title => "talk")
      @tag = @module.add_item(:type => 'discussion_topic', :id => @discussion.id)
      before_after do
        post "/courses/#{@course.id}/discussion_entries", :discussion_entry => { :message => 'ohai', :discussion_topic_id => @discussion.id }
        response.should be_redirect
      end
    end

    it "should progress for wiki pages" do
      @page = @course.wiki.wiki_pages.create!(:title => "talk page", :body => 'ohai', :editing_roles => 'teachers,students')
      @tag = @module.add_item(:type => 'wiki_page', :id => @page.id)
      before_after do
        put "/courses/#{@course.id}/wiki/#{@page.url}", :wiki_page => { :body => 'i agree', :title => 'talk page' }
        response.should be_redirect
      end
    end

    it "should progress for assignment discussions" do
      @assignment = @course.assignments.create!(:title => 'talk assn', :submission_types => 'discussion_topic')
      @tag = @module.add_item(:type => 'assignment', :id => @assignment.id)
      before_after do
        post "/courses/#{@course.id}/discussion_entries", :discussion_entry => { :message => 'ohai', :discussion_topic_id => @assignment.discussion_topic.id }
        response.should be_redirect
      end
    end
  end
  
  describe "progressing before job is run" do
    def progression_testing(progress_by_item_link)
      enable_cache do
        @is_attachment = false
        course_with_student_logged_in(:active_all => true)
        @quiz = @course.quizzes.create!(:title => "new quiz", :shuffle_answers => true)
        @quiz.publish!

        # separate timestamps so touch_context will actually invalidate caches
        Timecop.freeze(4.seconds.ago) do
          @mod1 = @course.context_modules.create!(:name => "some module")
          @mod1.require_sequential_progress = true
          @mod1.save!
          @tag1 = @mod1.add_item(:type => 'quiz', :id => @quiz.id)
          @mod1.completion_requirements = {@tag1.id => {:type => 'min_score', :min_score => 1}}
          @mod1.save!
        end

        Timecop.freeze(2.second.ago) do
          @mod2 = @course.context_modules.create!(:name => "dependant module")
          @mod2.prerequisites = "module_#{@mod1.id}"
          @mod2.save!
        end

        # all modules, tags, etc need to be published
        @mod1.should be_published
        @mod2.should be_published
        @quiz.should be_published
        @tag1.should be_published

        yield '<div id="test_content">yay!</div>'
        @tag2.should be_published

        # verify the second item is locked (doesn't display)
        get @test_url
        response.should be_success
        html = Nokogiri::HTML(response.body)
        html.css('#test_content').length.should == (@test_content_length || 0)

        # complete first module's requirements
        p1 = @mod1.evaluate_for(@student, true)
        p1.workflow_state.should == 'unlocked'

        @quiz_submission = @quiz.generate_submission(@student)
        @quiz_submission.grade_submission
        @quiz_submission.workflow_state = 'completed'
        @quiz_submission.kept_score = 1
        @quiz_submission.save!

        #emulate settings on progression if the user took the quiz but background jobs haven't run yet
        p1.requirements_met = [{:type=>"min_score", :min_score=>"1", :max_score=>nil, :id=>@quiz.id}]
        p1.save!

        # navigate to the second item (forcing update to progression)
        next_link = progress_by_item_link ? 
          "/courses/#{@course.id}/modules/items/#{@tag2.id}" :
          "/courses/#{@course.id}/modules/#{@mod2.id}/items/first"
        get next_link
        response.should be_redirect
        response.location.ends_with?(@test_url + "?module_item_id=#{@tag2.id}").should be_true

        # verify the second item is no accessible
        get @test_url
        response.should be_success
        html = Nokogiri::HTML(response.body)
        if @is_attachment
          html.at_css('#file_content')['src'].should =~ %r{#{@test_url}}
        else
          html.css('#test_content').length.should == 1
        end
      end
    end
    
    it "should progress to assignment" do
      [true, false].each do |progress_type|
        progression_testing(progress_type) do |content|
          asmnt = @course.assignments.create!(:title => 'assignment', :description => content)
          @test_url = "/courses/#{@course.id}/assignments/#{asmnt.id}"
          @tag2 = @mod2.add_item(:type => 'assignment', :id => asmnt.id)
          @tag2.should be_published
        end
      end
    end
    
    it "should progress to discussion topic" do
      [true, false].each do |progress_type|
        progression_testing(progress_type) do |content|
          discussion = @course.discussion_topics.create!(:title => "topic", :message => content)
          @test_url = "/courses/#{@course.id}/discussion_topics/#{discussion.id}"
          @tag2 = @mod2.add_item(:type => 'discussion_topic', :id => discussion.id)
          @tag2.should be_published
          @test_content_length = 1
        end
      end
    end
    
    it "should progress to a quiz" do
      [true, false].each do |progress_type|
        progression_testing(progress_type) do |content|
          quiz = @course.quizzes.create!(:title => "quiz", :description => content)
          quiz.publish!
          @test_url = "/courses/#{@course.id}/quizzes/#{quiz.id}"
          @tag2 = @mod2.add_item(:type => 'quiz', :id => quiz.id)
          @tag2.should be_published
        end
      end
    end
    
    it "should progress to a wiki page" do
      [true, false].each do |progress_type|
        progression_testing(progress_type) do |content|
          page = @course.wiki.wiki_pages.create!(:title => "wiki", :body => content)
          @test_url = "/courses/#{@course.id}/wiki/#{page.url}"
          @tag2 = @mod2.add_item(:type => 'wiki_page', :id => page.id)
          @tag2.should be_published
        end
      end
    end
    
    it "should progress to an attachment" do
      [true, false].each do |progress_type|
        progression_testing(progress_type) do |content|
          @is_attachment = true
          att = Attachment.create!(:filename => 'test.html', :display_name => "test.html", :uploaded_data => StringIO.new(content), :folder => Folder.unfiled_folder(@course), :context => @course)
          @test_url = "/courses/#{@course.id}/files/#{att.id}"
          @tag2 = @mod2.add_item(:type => 'attachment', :id => att.id)
          @tag2.should be_published
        end
      end
    end
  end
end
