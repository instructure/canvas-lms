# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe MarkDonePresenter do
  before do
    course_with_student(active_all: true)
  end

  let(:the_module) { @course.context_modules.create(name: "mark_as_done_module") }
  let(:wiki_page) { @course.wiki_pages.create(title: "mark_as_done page", body: "") }

  def add_wiki_page_to_module
    the_module.add_item(id: wiki_page.id, type: "wiki_page")
  end

  def create_presenter(tag)
    ctrl = double("Controller", session: true)
    context = double("Context", "grants_any_right?" => true)
    MarkDonePresenter.new(ctrl, context, tag.id, @user, nil)
  end

  def add_mark_done_requirement(tag)
    the_module.completion_requirements = {
      tag.id => { type: "must_mark_done" },
    }
    the_module.save!
  end

  def mark_page_as_done(tag)
    tag.context_module_action(@user, :done)
  end

  describe "#initialize" do
    it "doesn't blow up trying to coerce a garbage receiver into an integer" do
      ctrl = double("Controller", session: true)
      context = double("Context", "grants_any_right?" => true)
      garbage_item_id = { "'": nil }
      mdp = MarkDonePresenter.new(ctrl, context, garbage_item_id, @user, nil)
      expect(mdp.item).to be_nil
    end

    it "is happy setting item attr with a valid module item id" do
      ctrl = double("Controller", session: true)
      context = double("Context", "grants_any_right?" => true)
      tag = add_wiki_page_to_module
      mdp = MarkDonePresenter.new(ctrl, context, tag.id, @user, nil)
      expect(mdp.item).to eq tag
    end

    it "ignores invalid module item ids" do
      ctrl = double("Controller", session: true)
      context = double("Context", "grants_any_right?" => true)
      mdp = MarkDonePresenter.new(ctrl, context, "string", @user, nil)
      expect(mdp.item).to be_nil
    end
  end

  describe "#has_requirement?" do
    it "is false when there is no mark as done requirement" do
      tag = add_wiki_page_to_module
      subject = create_presenter tag
      expect(subject).not_to have_requirement
    end

    it "is true when there is a mark as done requirement" do
      tag = add_wiki_page_to_module
      add_mark_done_requirement tag
      subject = create_presenter tag
      expect(subject).to have_requirement
    end
  end

  describe "#checked?" do
    it "is true when the mark as done requirement is fulfilled" do
      tag = add_wiki_page_to_module
      add_mark_done_requirement tag
      mark_page_as_done tag
      subject = create_presenter tag
      expect(subject).to be_checked
    end

    it "is false when the mark as done requirement is not fulfilled" do
      tag = add_wiki_page_to_module
      add_mark_done_requirement tag
      subject = create_presenter tag

      expect(subject).not_to be_checked
    end
  end
end
