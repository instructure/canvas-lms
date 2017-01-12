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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SectionTabPresenter do
  let_once(:tab) { Course.default_tabs[0] }
  let_once(:assignments_tab) do
    Course.default_tabs.find do |tab|
      tab[:id] == Course::TAB_ASSIGNMENTS
    end
  end
  let_once(:course) { course_model }
  let_once(:presenter) do
    SectionTabPresenter.new(Course.default_tabs[0], course)
  end

  describe '#initialize' do
    it 'should set tab as an ostruct' do
      expect(presenter.tab).to be_a OpenStruct
    end
  end

  describe '#active?' do
    it 'should be true when active_tab is tab css_class' do
      expect(presenter.active?(tab[:css_class])).to be_truthy
      expect(presenter.active?('wooper')).to be_falsey
    end
  end

  describe '#screenreader?' do
    it 'should return false if tab has no screenreader element' do
      expect(presenter.screenreader?).to be_falsey
    end

    it 'should return true when tab has screenreader element' do
      new_presenter = SectionTabPresenter.new(
        assignments_tab, course
      )
      expect(new_presenter.screenreader?).to be_truthy
    end
  end

  describe '#hide?' do
    it 'should return true if tab has element hidden or hidden_unused' do
      expect(SectionTabPresenter.new(tab.merge(hidden: true), course).hide?).to be_truthy
      expect(SectionTabPresenter.new(tab.merge(hidden_unused: true), course).hide?).to be_truthy
    end

    it 'should return false if tab does not have element hidden or hidden_unused' do
      expect(presenter.hide?).to be_falsey
    end
  end

  describe '#path' do
    it 'should return path associated with course and tab' do
      path = SectionTabPresenter.new(assignments_tab, course).path
      expect(path).to match(/courses/)
      expect(path).to match(/assignments/)
    end

    it 'should return path associated with course and tab when given args as a hash' do
      assignments_tab[:args] = {message_handler_id: 1, :resource_link_fragment => :nav, course_id: 1 }
      path = SectionTabPresenter.new(assignments_tab, course).path
      expect(path).to eq "/courses/1/assignments?message_handler_id=1&resource_link_fragment=nav"
    end
  end

  describe '#path_args' do
    it 'should return tab args if present' do
      string_arg = 'blah'
      path_args = SectionTabPresenter.new(assignments_tab.merge({
        args: string_arg
      }), course).path_args
      expect(path_args).to eq string_arg
    end

    it 'should return empty array if tab no_args is present' do
      path_args = SectionTabPresenter.new(assignments_tab.merge({
        no_args: true
      }), course).path_args
      expect(path_args).to be_a Array
      expect(path_args).to be_empty
    end

    it 'should return course if neither args nor no_args is present' do
      expect(presenter.path_args).to eq course
    end
  end

  describe '#to_h' do
    it 'should include icon & path' do
      h = SectionTabPresenter.new(tab.merge({
        icon: 'icon-home'
      }), course).to_h
      expect(h.keys).to include(:icon, :hidden, :path)
      expect(h).to_not have_key(:screenreader)
    end

    it 'should include screenreader text if present' do
      h = SectionTabPresenter.new(assignments_tab, course).to_h
      expect(h).to have_key(:screenreader)
    end
  end
end
