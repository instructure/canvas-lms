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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Canvas::Migration::Helpers::SelectiveContentFormatter do
  context "overview json data" do
    before do
      @migration = mock()
      @migration.stubs(:migration_type).returns('common_cartridge_importer')
      @migration.stubs(:overview_attachment).returns(@migration)
      @migration.stubs(:open).returns(@migration)
      @migration.stubs(:shard).returns('1')
      @migration.stubs(:cache_key).returns('1')
      @migration.stubs(:close)
      @migration.stubs(:read).returns({
                                             'assessments' => [{'title' => 'a1', 'migration_id' => 'a1'}],
                                             'modules' => [{'title' => 'a1', 'migration_id' => 'a1'}],
                                             'wikis' => [{'title' => 'a1', 'migration_id' => 'a1'}],
                                             'external_tools' => [{'title' => 'a1', 'migration_id' => 'a1'}],
                                             'outcomes' => [{'title' => 'a1', 'migration_id' => 'a1'}],
                                             'file_map' => {'oi' => {'title' => 'a1', 'migration_id' => 'a1'}},
                                             'assignments' => [{'title' => 'a1', 'migration_id' => 'a1'},{'title' => 'a2', 'migration_id' => 'a2', 'assignment_group_migration_id' => 'a1'}],
                                             'assignment_groups' => [{'title' => 'a1', 'migration_id' => 'a1'}],
                                             'calendar_events' => [],
                                             "course" => {
                                                     "migration_id" => "i953adbb6769c915260623f0928fcd527",
                                                     "title" => "1 graded quiz/discussion",
                                                     "syllabus_body"=>"oh, hi there."
                                             }
                                     }.to_json)
      @formatter = Canvas::Migration::Helpers::SelectiveContentFormatter.new(@migration, "https://example.com")
    end

    it "should list top-level items" do
      @formatter.get_content_list.should == [{:type=>"course_settings", :property=>"copy[all_course_settings]", :title=>"Course Settings"},
                                             {:type=>"syllabus_body", :property=>"copy[all_syllabus_body]", :title=>"Syllabus Body"},
                                             {:type=>"context_modules", :property=>"copy[all_context_modules]", :title=>"Modules", :count=>1, :sub_items_url=>"https://example.com?type=context_modules"},
                                             {:type=>"assignments", :property=>"copy[all_assignments]", :title=>"Assignments", :count=>2, :sub_items_url=>"https://example.com?type=assignments"},
                                             {:type=>"quizzes", :property=>"copy[all_quizzes]", :title=>"Quizzes", :count=>1, :sub_items_url=>"https://example.com?type=quizzes"},
                                             {:type=>"wiki_pages", :property=>"copy[all_wiki_pages]", :title=>"Wiki Pages", :count=>1, :sub_items_url=>"https://example.com?type=wiki_pages"},
                                             {:type=>"context_external_tools", :property=>"copy[all_context_external_tools]", :title=>"External Tools", :count=>1, :sub_items_url=>"https://example.com?type=context_external_tools"},
                                             {:type=>"learning_outcomes", :property=>"copy[all_learning_outcomes]", :title=>"Learning Outcomes", :count=>1},
                                             {:type=>"attachments", :property=>"copy[all_attachments]", :title=>"Files", :count=>1, :sub_items_url=>"https://example.com?type=attachments"}]
    end

    it "should rename deprecated hash keys" do
      @formatter.get_content_list('quizzes').length.should == 1
      @formatter.get_content_list('context_modules').length.should == 1
      @formatter.get_content_list('wiki_pages').length.should == 1
      @formatter.get_content_list('context_external_tools').length.should == 1
      @formatter.get_content_list('learning_outcomes').length.should == 1
      @formatter.get_content_list('attachments').length.should == 1
    end

    it "should group assignments into assignment groups" do
      @formatter.get_content_list('assignments').should == [
              {:type => "assignment_groups", :property => "copy[assignment_groups][id_a1]", :title => "a1", :migration_id => "a1",
                 "sub_items" => [{:type => "assignments", :property => "copy[assignments][id_a2]", :title => "a2", :migration_id => "a2"}]
              },
              {:type => "assignments", :property => "copy[assignments][id_a1]", :title => "a1", :migration_id => "a1"}
      ]
    end

    it "should group attachments by folder" do
      @migration.stubs(:read).returns({
                                        'file_map' => {
                                                'a1' => {'path_name' => 'a/a1.html', 'file_name' => 'a1.html', 'migration_id' => 'a1'},
                                                'a2' => {'path_name' => 'a/a2.html', 'file_name' => 'a2.html', 'migration_id' => 'a2'},
                                                'a3' => {'path_name' => 'a/b/a3.html', 'file_name' => 'a3.html', 'migration_id' => 'a3'},
                                                'a4' => {'path_name' => 'a/b/c/a4.html', 'file_name' => 'a4.html', 'migration_id' => 'a4'},
                                                'a5' => {'path_name' => 'a5.html', 'file_name' => 'a5.html', 'migration_id' => 'a5'},
                                      }}.to_json)
      @formatter.get_content_list('attachments').should == [{:type => "folders",
                                                             :property => "copy[folders][id_0cc175b9c0f1b6a831c399e269772661]",
                                                             :title => "a",
                                                             :migration_id => "0cc175b9c0f1b6a831c399e269772661",
                                                             :sub_items =>
                                                                     [{:type => "attachments",
                                                                       :property => "copy[attachments][id_a1]",
                                                                       :title => "a1.html",
                                                                       :migration_id => "a1",
                                                                       :path => "a"},
                                                                      {:type => "attachments",
                                                                       :property => "copy[attachments][id_a2]",
                                                                       :title => "a2.html",
                                                                       :migration_id => "a2",
                                                                       :path => "a"}]},
                                                            {:type => "folders",
                                                             :property => "copy[folders][id_a7e86136543b019d72468ceebf71fb8e]",
                                                             :title => "a/b",
                                                             :migration_id => "a7e86136543b019d72468ceebf71fb8e",
                                                             :sub_items =>
                                                                     [{:type => "attachments",
                                                                       :property => "copy[attachments][id_a3]",
                                                                       :title => "a3.html",
                                                                       :migration_id => "a3",
                                                                       :path => "a/b"}]},
                                                            {:type => "folders",
                                                             :property => "copy[folders][id_cff49f359f080f71548fcee824af6ad3]",
                                                             :title => "a/b/c",
                                                             :migration_id => "cff49f359f080f71548fcee824af6ad3",
                                                             :sub_items =>
                                                                     [{:type => "attachments",
                                                                       :property => "copy[attachments][id_a4]",
                                                                       :title => "a4.html",
                                                                       :migration_id => "a4",
                                                                       :path => "a/b/c"}]},
                                                            {:type => "attachments",
                                                             :property => "copy[attachments][id_a5]",
                                                             :title => "a5.html",
                                                             :migration_id => "a5",
                                                             :path => "a5.html"}]

    end

    it "should show announcements separate from discussion topics" do
      @migration.stubs(:read).returns({
                                          'discussion_topics' => [
                                              {'title' => 'a1', 'migration_id' => 'a1'},
                                              {'title' => 'a2', 'migration_id' => 'a1', 'type' => 'announcement'},
                                          ]}.to_json)
      @formatter.get_content_list('discussion_topics').count.should == 1
      @formatter.get_content_list('discussion_topics').first[:title].should == 'a1'
      @formatter.get_content_list('announcements').count.should == 1
      @formatter.get_content_list('announcements').first[:title].should == 'a2'
    end

  end

  context "course copy" do
    before do
      course_model
      @topic = @course.discussion_topics.create!(:message => "hi", :title => "discussion title")
      @cm = @course.context_modules.create!(:name => "some module")
      attachment_model(:context => @course, :filename => 'a5.html')
      @wiki = @course.wiki.wiki_pages.create!(:title => "wiki", :body => "ohai")
      @category = @course.group_categories.create(:name => "other category")
      @group = Group.create!(:name=>"group1", :group_category => @category, :context => @course)
      @announcement = announcement_model
      @migration = mock()
      @migration.stubs(:migration_type).returns('course_copy_importer')
      @migration.stubs(:source_course).returns(@course)
      @formatter = Canvas::Migration::Helpers::SelectiveContentFormatter.new(@migration)
    end

    it "should list top-level items" do
      #groups should not show up even though there are some
      @formatter.get_content_list.should == [{:type=>"course_settings", :property=>"copy[all_course_settings]", :title=>"Course Settings"},
                                             {:type=>"syllabus_body", :property=>"copy[all_syllabus_body]", :title=>"Syllabus Body"},
                                             {:type=>"context_modules", :property=>"copy[all_context_modules]", :title=>"Modules", :count=>1},
                                             {:type=>"discussion_topics", :property=>"copy[all_discussion_topics]", :title=>"Discussion Topics", :count=>1},
                                             {:type=>"wiki_pages", :property=>"copy[all_wiki_pages]", :title=>"Wiki Pages", :count=>1},
                                             {:type=>"announcements", :property=>"copy[all_announcements]", :title=>"Announcements", :count=>1},
                                             {:type=>"attachments", :property=>"copy[all_attachments]", :title=>"Files", :count=>1}]
    end

    it "should list individual types" do
      @formatter.get_content_list('wiki_pages').length.should == 1
      @formatter.get_content_list('context_modules').length.should == 1
      @formatter.get_content_list('attachments').length.should == 1
      @formatter.get_content_list('discussion_topics').length.should == 1
      @formatter.get_content_list('announcements').length.should == 1
    end

    context "deleted objects" do
      append_before do
        @cm.destroy
        @attachment.destroy
        @wiki.destroy
        @announcement.destroy
        @topic.destroy
        assignment_model.destroy
        quiz_model.destroy
        calendar_event_model.destroy
        rubric_model.destroy
      end

      it "should ignore in top-level list" do
        @formatter.get_content_list.should == [{:type=>"course_settings", :property=>"copy[all_course_settings]", :title=>"Course Settings"},
                                             {:type=>"syllabus_body", :property=>"copy[all_syllabus_body]", :title=>"Syllabus Body"}]
      end

      it "should ignore in specific item request" do
        @formatter.get_content_list('wiki_pages').length.should == 0
        @formatter.get_content_list('context_modules').length.should == 0
        @formatter.get_content_list('attachments').length.should == 0
        @formatter.get_content_list('discussion_topics').length.should == 0
        @formatter.get_content_list('announcements').length.should == 0
        @formatter.get_content_list('assignments').length.should == 0
        @formatter.get_content_list('quizzes').length.should == 0
        @formatter.get_content_list('calendar_events').length.should == 0
        @formatter.get_content_list('rubrics').length.should == 0
      end
    end

    it "should group files by folders" do
      root = Folder.root_folders(@course).first
      a = Folder.create!(:name => 'a', :parent_folder => root, :context => @course)
      ab = Folder.create!(:name => 'b', :parent_folder => a, :context => @course)
      abc = Folder.create!(:name => 'c', :parent_folder => ab, :context => @course)

      attachment_model(:context => @course, :filename => 'a1.html', :folder => a)
      attachment_model(:context => @course, :filename => 'a2.html', :folder => a)
      attachment_model(:context => @course, :filename => 'a3.html', :folder => ab)
      attachment_model(:context => @course, :filename => 'a4.html', :folder => abc)
      @course.reload

      res = @formatter.get_content_list('attachments')
      res.length.should == 4
      res[0][:title].should == 'course files'
      res[0][:sub_items][0][:title].should == 'a5.html'
      res[1][:title].should == 'course files/a'
      res[1][:sub_items].map{|item| item[:title]}.sort.should == ['a1.html', 'a2.html']
      res[2][:title].should == 'course files/a/b'
      res[2][:sub_items][0][:title].should == 'a3.html'
      res[3][:title].should == 'course files/a/b/c'
      res[3][:sub_items][0][:title].should == 'a4.html'
    end

  end
end
