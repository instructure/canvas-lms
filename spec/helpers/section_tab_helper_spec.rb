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

describe SectionTabHelper do
  class SectionTabHelperSpec
    include SectionTabHelper
  end
  let_once(:course) { course_model }

  describe 'AvailableSectionTabs' do
    let_once(:current_user) { course.users.first }
    let_once(:domain_root_account) { LoadAccount.default_domain_root_account }
    let(:session) { user_session(current_user) }

    describe '#to_a' do
      context 'when context !tabs_available' do
        let(:available_section_tabs) do
          SectionTabHelperSpec::AvailableSectionTabs.new(
            Object.new, current_user, domain_root_account, session
          )
        end

        it 'returns an empty array' do
          a = available_section_tabs.to_a
          expect(a).to be_a Array
          expect(a).to be_empty
        end
      end

      context 'when context has tabs_available' do
        let(:bad_tab) { { label: 'bad tab' } }
        before(:each) do
          tabs = Course.default_tabs + [bad_tab]
          course.stubs(:tabs_available).returns(tabs)
        end
        let(:available_section_tabs) do
          SectionTabHelperSpec::AvailableSectionTabs.new(
            course, current_user, domain_root_account, session
          )
        end

        it 'returns a non-empty array' do
          expect(available_section_tabs.to_a).to be_a Array
          expect(available_section_tabs.to_a).to_not be_empty
        end

        it 'excludes tabs without label & href elements' do
          expect(available_section_tabs.to_a).to_not include(bad_tab)
        end

        context 'and tabs include TAB_CONFERENCES' do
          it 'should include TAB_CONFERENCES if WebConference.config' do
            WebConference.stubs(:config).returns({})
            expect(available_section_tabs.to_a.map do |tab|
              tab[:id]
            end).to include(Course::TAB_CONFERENCES)
          end

          it 'should not include TAB_CONFERENCES if !WebConference.config' do
            expect(available_section_tabs.to_a.map do |tab|
              tab[:id]
            end).to_not include(Course::TAB_CONFERENCES)
          end
        end

        context 'and tabs include TAB_COLLABORATIONS' do
          it 'should include TAB_COLLABORATIONS if Collaboration.any_collaborations_configured?' do
            Collaboration.stubs(:any_collaborations_configured?).returns(true)
            expect(available_section_tabs.to_a.map do |tab|
              tab[:id]
            end).to include(Course::TAB_COLLABORATIONS)
          end

          it 'should not include TAB_COLLABORATIONS if !Collaboration.any_collaborations_configured?' do
            expect(available_section_tabs.to_a.map do |tab|
              tab[:id]
            end).to_not include(Course::TAB_COLLABORATIONS)
          end

          it 'should not include TAB_COLLABORATIONS when new_collaborations feature flag has been enabled' do
            domain_root_account.set_feature_flag!(:new_collaborations, "on")
            Collaboration.stubs(:any_collaborations_configured?).returns(true)
            expect(available_section_tabs.to_a.map { |tab| tab[:id] }).not_to include(Course::TAB_COLLABORATIONS)
          end
        end

        context 'and tabs include TAB_COLLABORATIONS_NEW' do
          it 'should include TAB_COLLABORATIONS_NEW if new_collaborations feature flag has been enabled' do
            domain_root_account.set_feature_flag!(:new_collaborations, "on")
            expect(available_section_tabs.to_a.map { |tab| tab[:id] }).to include(Course::TAB_COLLABORATIONS_NEW)
            domain_root_account.set_feature_flag!(:new_collaborations, "off")
          end


          it 'should not include TAB_COLLABORATIONS if new_collaborations feature flas has been disabled' do
            domain_root_account.set_feature_flag!(:new_collaborations, "off")
            expect(available_section_tabs.to_a.map { |tab| tab[:id] }).not_to include(Course::TAB_COLLABORATIONS_NEW)
          end
        end
      end
    end
  end

  describe 'SectionTabTag' do
    # has screenreader
    let_once(:tab_assignments) do
      Course.default_tabs.find do |tab|
        tab[:id] == Course::TAB_ASSIGNMENTS
      end
    end
    # does not have screenreader
    let_once(:tab_pages) do
      Course.default_tabs.find do |tab|
        tab[:id] == Course::TAB_PAGES
      end
    end
    let(:new_window_tab) do
      {
        id: 1,
        label: "my_tab",
        css_class: "my_class",
        href: :course_external_tool_path,
        external:  true,
        target: "_blank",
        args: [1, 1]
      }
    end

    describe '#a_classes' do
      it 'should be an array including tab css_class' do
        tag = SectionTabHelperSpec::SectionTabTag.new(
          tab_assignments, course
        )
        expect(tag.a_classes).to be_a Array
        expect(tag.a_classes).to include tab_assignments[:css_class]
        expect(tag.a_classes).to_not include 'active'
      end

      it 'should include `active` class if tab is active' do
        tag = SectionTabHelperSpec::SectionTabTag.new(
          tab_assignments, course, tab_assignments[:css_class]
        )

        expect(tag.a_classes).to include 'active'
      end
    end

    describe '#a_attributes' do
      it 'should include keys href & class' do
        tag = SectionTabHelperSpec::SectionTabTag.new(
          tab_pages, course
        )

        expect(tag.a_attributes.keys).to include(:href, :class)
        expect(tag.a_attributes.keys).to_not include(:'aria-label')
      end

      it 'should include key aria-label if tab has screenreader text' do
        tag = SectionTabHelperSpec::SectionTabTag.new(
          tab_assignments, course
        )

        expect(tag.a_attributes.keys).to include(:'aria-label')
      end

      it 'includes a target if tab has the target attribute' do
        tag = SectionTabHelperSpec::SectionTabTag.new(new_window_tab, course)
        expect(tag.a_attributes[:target]).to  eq '_blank'
      end

    end

    describe '#a_tag' do
      context 'when tab is not hidden' do
        let(:string) do
          SectionTabHelperSpec::SectionTabTag.new(
            tab_assignments, course
          ).a_tag
        end
        let(:html) { Nokogiri::HTML.fragment(string).children[0] }

        it 'should be an a tag' do
          expect(html.name).to eq 'a'
        end

        it 'should include text from tab label' do
          expect(html.text).to eq tab_assignments[:label]
        end
      end

      context 'when tab is hidden' do
        let(:string) do
          SectionTabHelperSpec::SectionTabTag.new(
            tab_assignments.merge(hidden: true), course
          ).a_tag
        end
        let(:html) { Nokogiri::HTML.fragment(string).children[0] }

        it 'should include a nested span tag' do
          expect(html.children.any? do |child|
            child.name == 'span'
          end).to be_truthy
        end
      end
    end

    describe '#li_classess' do
      it 'should return an array including element `section`' do
        tag = SectionTabHelperSpec::SectionTabTag.new(
          tab_assignments, course
        )
        expect(tag.li_classes).to be_a Array
        expect(tag.li_classes).to include('section')
      end

      it 'should include `section-tab-hidden` if tab is hidden' do
        tag = SectionTabHelperSpec::SectionTabTag.new(
          tab_assignments.merge(hidden: true), course
        )

        expect(tag.li_classes).to include('section-tab-hidden')
      end
    end


    describe '#to_html' do
      let(:string) do
        SectionTabHelperSpec::SectionTabTag.new(
          tab_assignments, course
        ).to_html
      end
      let(:html) { Nokogiri::HTML.fragment(string).children[0] }

      it 'should be an li tag' do
        expect(html.name).to eq 'li'
      end

      it 'should include a nested a tag' do
        expect(html.children.any? do |child|
          child.name == 'a'
        end).to be_truthy
      end
    end
  end
end
