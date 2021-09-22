# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../../../lti2_course_spec_helper')

describe Canvas::Migration::Helpers::SelectiveContentFormatter do
  context "overview json data" do
    before do
      @overview = {
        'assessments' => [{'title' => 'a1', 'migration_id' => 'a1'}],
        'modules' => [{'title' => 'a1', 'migration_id' => 'a1'}],
        'wikis' => [{'title' => 'a1', 'migration_id' => 'a1'}],
        'external_tools' => [{'title' => 'a1', 'migration_id' => 'a1'}],
        'tool_profiles' => [{'title' => 'a1', 'migration_id' => 'a1'}],
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
      }
      @migration = double()
      allow(@migration).to receive(:migration_type).and_return('common_cartridge_importer')
      allow(@migration).to receive(:overview_attachment).and_return(@migration)
      allow(@migration).to receive(:open).and_return(@migration)
      allow(@migration).to receive(:shard).and_return('1')
      allow(@migration).to receive(:cache_key).and_return('1')
      allow(@migration).to receive(:close)
      allow(@migration).to receive(:read).and_return(@overview.to_json)
      allow(@migration).to receive(:context).and_return(course_model)
      @formatter = Canvas::Migration::Helpers::SelectiveContentFormatter.new(@migration, "https://example.com", global_identifiers: true)
    end

    it "should list top-level items" do
      expect(@formatter.get_content_list).to eq [{:type=>"course_settings", :property=>"copy[all_course_settings]", :title=>"Course Settings"},
                                             {:type=>"syllabus_body", :property=>"copy[all_syllabus_body]", :title=>"Syllabus Body"},
                                             {:type=>"context_modules", :property=>"copy[all_context_modules]", :title=>"Modules", :count=>1, :sub_items_url=>"https://example.com?type=context_modules"},
                                             {:type=>"assignments", :property=>"copy[all_assignments]", :title=>"Assignments", :count=>2, :sub_items_url=>"https://example.com?type=assignments"},
                                             {:type=>"quizzes", :property=>"copy[all_quizzes]", :title=>"Quizzes", :count=>1, :sub_items_url=>"https://example.com?type=quizzes"},
                                             {:type=>"wiki_pages", :property=>"copy[all_wiki_pages]", :title=>"Pages", :count=>1, :sub_items_url=>"https://example.com?type=wiki_pages"},
                                             {:type=>"context_external_tools", :property=>"copy[all_context_external_tools]", :title=>"External Tools", :count=>1, :sub_items_url=>"https://example.com?type=context_external_tools"},
                                             {:type=>"tool_profiles", :property=>"copy[all_tool_profiles]", :title=>"Tool Profiles", :count=>1, :sub_items_url=>"https://example.com?type=tool_profiles"},
                                             {:type=>"learning_outcomes", :property=>"copy[all_learning_outcomes]", :title=>"Learning Outcomes", :count=>1},
                                             {:type=>"attachments", :property=>"copy[all_attachments]", :title=>"Files", :count=>1, :sub_items_url=>"https://example.com?type=attachments"}]
    end

    it "should rename deprecated hash keys" do
      expect(@formatter.get_content_list('quizzes').length).to eq 1
      expect(@formatter.get_content_list('context_modules').length).to eq 1
      expect(@formatter.get_content_list('wiki_pages').length).to eq 1
      expect(@formatter.get_content_list('context_external_tools').length).to eq 1
      expect(@formatter.get_content_list('learning_outcomes').length).to eq 1
      expect(@formatter.get_content_list('attachments').length).to eq 1
    end

    context 'selectable_outcomes_in_course_copy enabled' do
      before(:example) do
        @migration.context.root_account.enable_feature!(:selectable_outcomes_in_course_copy)
      end

      after(:example) do
        @migration.context.root_account.disable_feature!(:selectable_outcomes_in_course_copy)
      end

      context 'with learning_outcome_groups course data' do
        before do
          @overview['learning_outcome_groups'] = [{
            'title' => 'my group',
            'migration_id' => 'g1',
            'child_groups' => []
          }]
          @overview['outcomes'].first['parent_migration_id'] = 'g1'
          allow(@migration).to receive(:read).and_return(@overview.to_json)
        end

        it 'should arrange an outcome hiearchy' do
          expect(@formatter.get_content_list('learning_outcomes')).to eq [
            {
              type: 'learning_outcome_groups',
              property: 'copy[learning_outcome_groups][id_g1]',
              title: 'my group',
              migration_id: 'g1',
              sub_items: [{
                type: 'learning_outcomes',
                property: 'copy[learning_outcomes][id_a1]',
                title: 'a1',
                migration_id: 'a1'
              }]
            }
          ]
        end
      end

      it 'should return standard outcomes without learning_outcome_groups course data' do
        expect(@formatter.get_content_list('learning_outcomes').length).to eq 1
      end
    end

    it "should group assignments into assignment groups" do
      expect(@formatter.get_content_list('assignments')).to eq [
              {:type => "assignment_groups", :property => "copy[assignment_groups][id_a1]", :title => "a1", :migration_id => "a1",
                 "sub_items" => [{:type => "assignments", :property => "copy[assignments][id_a2]", :title => "a2", :migration_id => "a2"}]
              },
              {:type => "assignments", :property => "copy[assignments][id_a1]", :title => "a1", :migration_id => "a1"}
      ]
    end

    it "should group attachments by folder" do
      allow(@migration).to receive(:read).and_return({
                                        'file_map' => {
                                                'a1' => {'path_name' => 'a/a1.html', 'file_name' => 'a1.html', 'migration_id' => 'a1'},
                                                'a2' => {'path_name' => 'a/a2.html', 'file_name' => 'a2.html', 'migration_id' => 'a2'},
                                                'a3' => {'path_name' => 'a/b/a3.html', 'file_name' => 'a3.html', 'migration_id' => 'a3'},
                                                'a4' => {'path_name' => 'a/b/c/a4.html', 'file_name' => 'a4.html', 'migration_id' => 'a4'},
                                                'a5' => {'path_name' => 'a5.html', 'file_name' => 'a5.html', 'migration_id' => 'a5'},
                                      }}.to_json)
      expect(@formatter.get_content_list('attachments')).to eq [{:type => "folders",
                                                             :property => "copy[folders][id_ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb]",
                                                             :title => "a",
                                                             :migration_id => "ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb",
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
                                                             :property => "copy[folders][id_c14cddc033f64b9dea80ea675cf280a015e672516090a5626781153dc68fea11]",
                                                             :title => "a/b",
                                                             :migration_id => "c14cddc033f64b9dea80ea675cf280a015e672516090a5626781153dc68fea11",
                                                             :sub_items =>
                                                                     [{:type => "attachments",
                                                                       :property => "copy[attachments][id_a3]",
                                                                       :title => "a3.html",
                                                                       :migration_id => "a3",
                                                                       :path => "a/b"}]},
                                                            {:type => "folders",
                                                             :property => "copy[folders][id_d76a7b72669c9cec266b566bdec68efbc8d4f22d1f2689bbf0146bf0b88fdbe9]",
                                                             :title => "a/b/c",
                                                             :migration_id => "d76a7b72669c9cec266b566bdec68efbc8d4f22d1f2689bbf0146bf0b88fdbe9",
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
      allow(@migration).to receive(:read).and_return({
                                          'discussion_topics' => [
                                              {'title' => 'a1', 'migration_id' => 'a1'},
                                              {'title' => 'a2', 'migration_id' => 'a1', 'type' => 'announcement'},
                                          ]}.to_json)
      expect(@formatter.get_content_list('discussion_topics').count).to eq 1
      expect(@formatter.get_content_list('discussion_topics').first[:title]).to eq 'a1'
      expect(@formatter.get_content_list('announcements').count).to eq 1
      expect(@formatter.get_content_list('announcements').first[:title]).to eq 'a2'
    end

    it "should link resources for quizzes and submittables" do
      allow(@migration).to receive(:read).and_return(@overview.merge({
        'assessments' => [{'title' => 'q1', 'migration_id' => 'q1', 'assignment_migration_id' => 'a5'}],
        'wikis' => [{'title' => 'w1', 'migration_id' => 'w1', 'assignment_migration_id' => 'a3'}],
        'discussion_topics' => [{'title' => 'd1', 'migration_id' => 'd1', 'assignment_migration_id' => 'a4'}],
        'assignments' => [
          {'title' => 'a1', 'migration_id' => 'a1'},
          {'title' => 'a2', 'migration_id' => 'a2', 'assignment_group_migration_id' => 'a1'},
          {'title' => 'w1', 'migration_id' => 'a3', 'page_migration_id' => 'w1', 'assignment_group_migration_id' => 'a2'},
          {'title' => 'd1', 'migration_id' => 'a4', 'topic_migration_id' => 'd1', 'assignment_group_migration_id' => 'a2'},
          {'title' => 'q1', 'migration_id' => 'a5', 'quiz_migration_id' => 'q1', 'assignment_group_migration_id' => 'a2'}
        ],
        'assignment_groups' => [{'title' => 'a1', 'migration_id' => 'a1'}, {'title' => 'a2', 'migration_id' => 'a2'}]
      }).to_json)

      asgs = @formatter.get_content_list('assignments').second['sub_items']
      expect(asgs.map{ |a| a[:linked_resource][:type] }).to eq ['wiki_pages', 'discussion_topics', 'quizzes']
      asgs.each do |a|
        asg_mig_id = a[:migration_id]
        linked_mig_id = a[:linked_resource][:migration_id]
        linked_type = a[:linked_resource][:type]

        linked_item = @formatter.get_content_list(linked_type).find { |i| i[:migration_id] == linked_mig_id }
        expect(linked_item[:linked_resource][:migration_id]).to eq asg_mig_id
      end
    end
  end

  context "course copy" do
    include_context "lti2_course_spec_helper"
    let(:formatter) { Canvas::Migration::Helpers::SelectiveContentFormatter.new(@migration, "https://example.com", global_identifiers: true) }
    let(:top_level_items) do
      [{:type=>"course_settings", :property=>"copy[all_course_settings]", :title=>"Course Settings"},
       {:type=>"syllabus_body", :property=>"copy[all_syllabus_body]", :title=>"Syllabus Body"},
       {:type=>"context_modules", :property=>"copy[all_context_modules]", :title=>"Modules", :count=>1, :sub_items_url=>"https://example.com?type=context_modules"},
       {:type=>"tool_profiles", :property=>"copy[all_tool_profiles]", :title=>"Tool Profiles", :count=>1, :sub_items_url=>"https://example.com?type=tool_profiles"},
       {:type=>"discussion_topics", :property=>"copy[all_discussion_topics]", :title=>"Discussion Topics", :count=>1, :sub_items_url=>"https://example.com?type=discussion_topics"},
       {:type=>"wiki_pages", :property=>"copy[all_wiki_pages]", :title=>"Pages", :count=>1, :sub_items_url=>"https://example.com?type=wiki_pages"},
       {:type=>"announcements", :property=>"copy[all_announcements]", :title=>"Announcements", :count=>1, :sub_items_url=>"https://example.com?type=announcements"},
       {:type=>"learning_outcomes", :property=>"copy[all_learning_outcomes]", :title=>"Learning Outcomes", :count=>4},
       {:type=>"attachments", :property=>"copy[all_attachments]", :title=>"Files", :count=>1, :sub_items_url=>"https://example.com?type=attachments"}]
    end

    before do
      course_model
      tool_proxy.context = @course
      tool_proxy.save!
      @topic = @course.discussion_topics.create!(:message => "hi", :title => "discussion title")
      @cm = @course.context_modules.create!(:name => "some module")
      attachment_model(:context => @course, :filename => 'a5.html')
      @wiki = @course.wiki_pages.create!(:title => "wiki", :body => "ohai")
      @category = @course.group_categories.create(:name => "other category")
      @group = Group.create!(:name=>"group1", :group_category => @category, :context => @course)
      @announcement = announcement_model
      @migration = double()
      allow(@migration).to receive(:migration_type).and_return('course_copy_importer')
      allow(@migration).to receive(:source_course).and_return(@course)
      export = @course.content_exports.create!(:export_type => ContentExport::COURSE_COPY)
      allow(@migration).to receive(:content_export).and_return(export)
      @course_outcome = outcome_model(title: 'zebra')
      @account_outcome = outcome_model(outcome_context: @course.account, title: 'alpaca')
      @out_group1 = outcome_group_model(title: 'striker')
      @outcome1_in_group = outcome_model(outcome_group: @out_group1, title: 'speakeasy')
      @outcome2_in_group = outcome_model(outcome_group: @out_group1, title: 'moonshine')
      @out_group2 = outcome_group_model(title: 'beta')
    end

    it "should list individual types" do
      expect(formatter.get_content_list('wiki_pages').length).to eq 1
      expect(formatter.get_content_list('context_modules').length).to eq 1
      expect(formatter.get_content_list('attachments').length).to eq 1
      expect(formatter.get_content_list('discussion_topics').length).to eq 1
      expect(formatter.get_content_list('announcements').length).to eq 1
    end

    context 'with selectable_outcomes_in_course_copy disabled' do
      before do
        @course.root_account.disable_feature!(:selectable_outcomes_in_course_copy)
      end

      it "should list top-level items" do
        # groups should not show up even though there are some
        expect(formatter.get_content_list).to match_array top_level_items
      end

      it "should list learning outcomes" do
        outcomes = formatter.get_content_list('learning_outcomes')
        expect(outcomes.map {|o| o[:title]}).to match_array(
          [
            'alpaca',
            'moonshine',
            'speakeasy',
            'zebra'
          ]
        )
      end
    end

    context 'with selectable_outcomes_in_course_copy enabled' do
      before do
        @course.root_account.enable_feature!(:selectable_outcomes_in_course_copy)
      end

      it "should list top-level items" do
        # groups should not show up even though there are some
        copy = top_level_items.clone
        copy.find {|item| item[:type] == 'learning_outcomes' }[:sub_items_url] = "https://example.com?type=learning_outcomes"
        expect(formatter.get_content_list).to match_array copy
      end

      it "should list individual types in expected order" do
        outcomes = formatter.get_content_list('learning_outcomes')
        expect(outcomes.map {|o| o[:title]}).to eq [
          'beta',
          'striker',
          'alpaca',
          'zebra'
        ]
      end

      it "should list outcomes in outcome group" do
        outcomes = formatter.get_content_list("learning_outcome_groups_#{@out_group1.id}")
        expect(outcomes.map {|o| o[:title]}).to eq [
          'moonshine',
          'speakeasy'
        ]
      end
    end

    it "should link resources for quizzes and submittables" do
      wiki_page_assignment_model(course: @course, title: 'sekrit page')
      assignment_model(course: @course, submission_types: 'discussion_topic', title: 'graded discussion')
      assignment_quiz([], course: @course, name: "blah").assignment

      asgs = formatter.get_content_list('assignments').first[:sub_items]
      expect(asgs.map{ |a| a[:linked_resource][:type] }).to eq ['wiki_pages', 'discussion_topics', 'quizzes']
      asgs.each do |a|
        asg_mig_id = a[:migration_id]
        linked_mig_id = a[:linked_resource][:migration_id]
        linked_type = a[:linked_resource][:type]

        linked_item = formatter.get_content_list(linked_type).find { |i| i[:migration_id] == linked_mig_id }
        expect(linked_item[:linked_resource][:migration_id]).to eq asg_mig_id
      end
    end

    context "deleted objects" do
      append_before do
        @cm.destroy
        @attachment.destroy
        @wiki.destroy
        @announcement.destroy
        @topic.destroy
        @course_outcome.destroy
        @account_outcome.destroy
        @outcome1_in_group.destroy
        @outcome2_in_group.destroy
        @out_group1.destroy
        @out_group2.destroy
        tool_proxy.destroy

        @course.require_assignment_group
        @course.assignments.create!.destroy
        @course.assignment_groups.create!(:name => "blah").destroy
        @course.quizzes.create!.destroy
        @course.calendar_events.create!.destroy
        @course.rubrics.create!.destroy
      end

      it "should ignore in top-level list" do
        expect(formatter.get_content_list).to eq [{:type=>"course_settings", :property=>"copy[all_course_settings]", :title=>"Course Settings"},
                                             {:type=>"syllabus_body", :property=>"copy[all_syllabus_body]", :title=>"Syllabus Body"}]
      end

      it "should ignore in specific item request" do
        expect(formatter.get_content_list('wiki_pages').length).to eq 0
        expect(formatter.get_content_list('context_modules').length).to eq 0
        expect(formatter.get_content_list('attachments').length).to eq 0
        expect(formatter.get_content_list('discussion_topics').length).to eq 0
        expect(formatter.get_content_list('announcements').length).to eq 0

        expect(formatter.get_content_list('assignments').length).to eq 1 # the default assignment group
        expect(formatter.get_content_list('assignments').first[:sub_items]).to be_blank

        expect(formatter.get_content_list('quizzes').length).to eq 0
        expect(formatter.get_content_list('calendar_events').length).to eq 0
        expect(formatter.get_content_list('rubrics').length).to eq 0
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

      res = formatter.get_content_list('attachments')
      expect(res.length).to eq 4
      expect(res[0][:title]).to eq 'course files'
      expect(res[0][:sub_items][0][:title]).to eq 'a5.html'
      expect(res[1][:title]).to eq 'course files/a'
      expect(res[1][:sub_items].map{|item| item[:title]}.sort).to eq ['a1.html', 'a2.html']
      expect(res[2][:title]).to eq 'course files/a/b'
      expect(res[2][:sub_items][0][:title]).to eq 'a3.html'
      expect(res[3][:title]).to eq 'course files/a/b/c'
      expect(res[3][:sub_items][0][:title]).to eq 'a4.html'
    end
  end
end
