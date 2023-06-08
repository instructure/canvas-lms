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

  describe "#initialize" do
    it "sets tab as an ostruct" do
      expect(presenter.tab).to be_a OpenStruct
    end
  end

  describe "#active?" do
    it "is true when active_tab is tab css_class" do
      expect(presenter.active?(tab[:css_class])).to be_truthy
      expect(presenter.active?("wooper")).to be_falsey
    end
  end

  describe "#target?" do
    it "returns true if the tab has a target attribute" do
      expect(SectionTabPresenter.new(tab.merge(target: "_blank"), course).target?).to be true
    end

    it "returns false if the tab does not contain a target" do
      expect(SectionTabPresenter.new(tab, course).target?).to be false
    end

    it "returns false if the tab target is nil" do
      expect(SectionTabPresenter.new(tab.merge(target: nil), course).target?).to be false
    end
  end

  describe "#hide?" do
    it "returns true if tab has element hidden or hidden_unused" do
      expect(SectionTabPresenter.new(tab.merge(hidden: true), course).hide?).to be_truthy
    end

    it "returns false if tab does not have element hidden or hidden_unused" do
      expect(presenter.hide?).to be_falsey
    end
  end

  describe "#unused?" do
    it "returns true if tab has element hidden or hidden_unused" do
      expect(SectionTabPresenter.new(tab.merge(hidden_unused: true), course).unused?).to be_truthy
    end

    it "returns false if tab does not have element hidden or hidden_unused" do
      expect(presenter.unused?).to be_falsey
    end
  end

  describe "#path" do
    it "returns path associated with course and tab" do
      path = SectionTabPresenter.new(assignments_tab, course).path
      expect(path).to match(/courses/)
      expect(path).to match(/assignments/)
    end

    it "returns path associated with course and tab when given args as a hash" do
      assignments_tab[:args] = { message_handler_id: 1, resource_link_fragment: :nav, course_id: 1 }
      path = SectionTabPresenter.new(assignments_tab, course).path
      expect(path).to eq "/courses/1/assignments?message_handler_id=1&resource_link_fragment=nav"
    end

    context "with lti 2 tab" do
      let(:tab) do
        {
          href: :course_basic_lti_launch_request_path,
          args:
        }
      end

      context "with keys as symbols" do
        let(:args) { { message_handler_id: 5, resource_link_fragment: "nav", course_id: 1 } }

        it "handles the tab correctly" do
          expect(SectionTabPresenter.new(tab, course).path).to eq(
            "/courses/1/lti/basic_lti_launch_request/5?resource_link_fragment=nav"
          )
        end
      end

      context "with keys as strings" do
        let(:args) { { "message_handler_id" => 5, "resource_link_fragment" => "nav", "course_id" => 1 }.with_indifferent_access }

        it "handles the tab correctly" do
          expect(SectionTabPresenter.new(tab, course).path).to eq(
            "/courses/1/lti/basic_lti_launch_request/5?resource_link_fragment=nav"
          )
        end
      end

      context "with indifferent access hash" do
        let(:args) { { "message_handler_id" => 5, "resource_link_fragment" => "nav", "course_id" => 1 } }

        it "handles the tab correctly" do
          expect(SectionTabPresenter.new(tab, course).path).to eq(
            "/courses/1/lti/basic_lti_launch_request/5?resource_link_fragment=nav"
          )
        end
      end
    end
  end

  describe "#path_args" do
    it "returns tab args if present" do
      string_arg = "blah"
      path_args = SectionTabPresenter.new(assignments_tab.merge({
                                                                  args: string_arg
                                                                }),
                                          course).path_args
      expect(path_args).to eq string_arg
    end

    it "returns empty array if tab no_args is present" do
      path_args = SectionTabPresenter.new(assignments_tab.merge({
                                                                  no_args: true
                                                                }),
                                          course).path_args
      expect(path_args).to be_a Array
      expect(path_args).to be_empty
    end

    it "returns course if neither args nor no_args is present" do
      expect(presenter.path_args).to eq course
    end
  end

  describe "#to_h" do
    it "includes icon, path & label" do
      h = SectionTabPresenter.new(tab.merge({
                                              icon: "icon-home"
                                            }),
                                  course).to_h
      expect(h.keys).to include(:icon, :hidden, :path, :label)
    end
  end
end
