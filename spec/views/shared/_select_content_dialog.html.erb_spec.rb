#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/shared/_select_content_dialog" do

  it "should include unpublished wiki pages" do
    course_with_teacher
    published_page = @course.wiki_pages.build title: 'published_page'
    published_page.workflow_state = 'active'
    published_page.save!
    unpublished_page = @course.wiki_pages.build title: 'unpublished_page'
    unpublished_page.workflow_state = 'unpublished'
    unpublished_page.save!
    view_context
    render partial: 'shared/select_content_dialog'
    page = Nokogiri(response.body)
    options = page.css("#wiki_pages_select .module_item_select option")
    expect(%w(unpublished_page published_page) - options.map(&:text)).to be_empty
  end

  it "should not offer to create assignments or quizzes if the user doesn't have permission" do
    @account = Account.default
    course_with_ta account: @account, active_all: true
    existing_quiz = @course.quizzes.create! title: 'existing quiz'
    @account.role_overrides.create! role: ta_role, permission: 'manage_assignments', enabled: false
    view_context
    render partial: 'shared/select_content_dialog'
    page = Nokogiri(response.body)
    expect(page.css(%Q{#quizs_select .module_item_select option[value="#{existing_quiz.id}"]})).not_to be_empty
    expect(page.css(%Q{#quizs_select .module_item_select option[value="new"]})).to be_empty
    expect(page.css(%Q{#assignments_select .module_item_select option[value="new"]})).to be_empty
  end

  it "should offer to create assignments if the user has permission" do
    @account = Account.default
    course_with_ta account: @account, active_all: true
    view_context
    render partial: 'shared/select_content_dialog'
    page = Nokogiri(response.body)
    expect(page.css(%Q{#assignments_select .module_item_select option[value="new"]})).not_to be_empty
  end

  it "should create new topics in unpublished state if draft state is enabled" do
    course_with_teacher(active_all: true)
    view_context
    render partial: 'shared/select_content_dialog'
    page = Nokogiri(response.body)
    expect(page.at_css(%Q{#discussion_topics_select .new input[name="published"][value="false"]})).not_to be_nil
  end

  describe "sorting" do
    before(:once) do
      course_with_teacher(active_all: true)
      @groupB = @course.assignment_groups.create!(name: 'group B')
      @groupA = @course.assignment_groups.create!(name: 'group A')
      view_context
    end

    it "sorts wiki pages by name" do
      a = @course.wiki_pages.create!(title: 'A')
      c = @course.wiki_pages.create!(title: 'C')
      b = @course.wiki_pages.create!(title: 'B')
      render partial: 'shared/select_content_dialog'
      page = Nokogiri(response.body)
      options = page.css('#wiki_pages_select option').map { |option| [option.text, option.attribute('value').to_s] }
      expect(options).to eq([["[ New Page ]", "new"], ["A", a.id.to_s], ["B", b.id.to_s], ["C", c.id.to_s]])
    end

    it "sorts quizzes and the quiz assignment group selector by name" do
      a = @course.quizzes.create!(title: 'A')
      c = @course.quizzes.create!(title: 'C')
      b = @course.quizzes.create!(title: 'B')
      render partial: 'shared/select_content_dialog'
      page = Nokogiri(response.body)
      options = page.css('#quizs_select .module_item_select option').map { |option| [option.text, option.attribute('value').to_s] }
      expect(options).to eq([["[ New Quiz ]", "new"], ["A", a.id.to_s], ["B", b.id.to_s], ["C", c.id.to_s]])
      groups = page.css('select[name="quiz[assignment_group_id]"] option').map { |option| [option.text, option.attribute('value').to_s] }
      expect(groups).to eq([["group A", @groupA.id.to_s], ["group B", @groupB.id.to_s]])
    end

    it "sorts assignments by name within assignment groups, which are also sorted by name" do
      bb = @course.assignments.create!(title: 'B', assignment_group: @groupB)
      aa = @course.assignments.create!(title: 'A', assignment_group: @groupA)
      ac = @course.assignments.create!(title: 'C', assignment_group: @groupA)
      ba = @course.assignments.create!(title: 'A', assignment_group: @groupB)
      ab = @course.assignments.create!(title: 'B', assignment_group: @groupA)
      bc = @course.assignments.create!(title: 'C', assignment_group: @groupB)
      render partial: 'shared/select_content_dialog'
      page = Nokogiri(response.body)
      optgroups = page.css('#assignments_select .module_item_select optgroup')
      expect(optgroups.map { |optgroup| optgroup.attribute('label').to_s }).to eq(['group A', 'group B'])
      aga = page.css('optgroup[label="group A"] option').map { |option| [option.text, option.attribute('value').to_s] }
      expect(aga).to eq([['A', aa.id.to_s], ['B', ab.id.to_s], ['C', ac.id.to_s]])
      agb = page.css('optgroup[label="group B"] option').map { |option| [option.text, option.attribute('value').to_s] }
      expect(agb).to eq([['A', ba.id.to_s], ['B', bb.id.to_s], ['C', bc.id.to_s]])
    end

    it "sorts discussion topics by name" do
      a = @course.discussion_topics.create!(title: 'A')
      c = @course.discussion_topics.create!(title: 'C')
      b = @course.discussion_topics.create!(title: 'B')
      render partial: 'shared/select_content_dialog'
      page = Nokogiri(response.body)
      options = page.css('#discussion_topics_select option').map { |option| [option.text, option.attribute('value').to_s] }
      expect(options).to eq([["[ New Topic ]", "new"], ["A", a.id.to_s], ["B", b.id.to_s], ["C", c.id.to_s]])
    end
  end

end

