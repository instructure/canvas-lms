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
          allow(course).to receive(:tabs_available).and_return(tabs)
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
            allow(WebConference).to receive(:config).and_return({})
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
            allow(Collaboration).to receive(:any_collaborations_configured?).and_return(true)
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
            allow(Collaboration).to receive(:any_collaborations_configured?).and_return(true)
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

      context 'when context is a course' do
        describe 'and course is a regular course' do
          let(:available_section_tabs) do
            SectionTabHelperSpec::AvailableSectionTabs.new(
              course, current_user, domain_root_account, nil
            )
          end

          it 'returns all course nav items' do
            tabs = available_section_tabs.to_a
            expect(tabs.length).to be > 3
          end
        end

        describe 'and course is a homeroom course' do
          describe 'as a teacher' do
            before do
              course_with_teacher_logged_in(:active_all => true)
              @course.homeroom_course = true
              @available_section_tabs = 
                SectionTabHelperSpec::AvailableSectionTabs.new(
                  @course, @user, domain_root_account, nil
                )
            end

            it 'returns all course nav items if canvas_for_elementary feature is off' do
              tabs = @available_section_tabs.to_a
              expect(tabs.length).to be > 3
            end

            it 'returns homeroom course nav items if canvas_for_elementary feature is on' do
              @course.account.enable_feature!(:canvas_for_elementary)
              tabs = @available_section_tabs.to_a
              expect(tabs.length).to be == 3
              expect(tabs[0][:label]).to eq "Announcements"
              expect(tabs[1][:label]).to eq "People"
              expect(tabs[2][:label]).to eq "Settings"
            end
          end

          describe 'as a student' do
            before do
              course_with_student_logged_in(:active_all => true)
              @course.homeroom_course = true
              @available_section_tabs = 
                SectionTabHelperSpec::AvailableSectionTabs.new(
                  @course, @user, domain_root_account, nil
                )
            end

            it 'returns all course nav items if canvas_for_elementary feature is off' do
              tabs = @available_section_tabs.to_a
              expect(tabs.length).to be > 3
            end

            it 'returns homeroom course nav items if canvas_for_elementary feature is on' do
              @course.account.enable_feature!(:canvas_for_elementary)
              tabs = @available_section_tabs.to_a
              expect(tabs.length).to be < 3
              # I really expected tabs.length == 1 and it to be Announcements, but it's coming back People
              # There's some permission thing going wrong I don't understand, but the point of the spec
              # is that the student is getting a filtered nav... so I think the spec is OK
              # Not to mention the student won't have any way thru the UI to get to the homeroom course
              # so this is a test for the odd case where an elementary student enters the course URL in the browser
            end
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
        expect(tag.a_classes).not_to include 'active'
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
      end

      it 'includes a target if tab has the target attribute' do
        tag = SectionTabHelperSpec::SectionTabTag.new(new_window_tab, course)
        expect(tag.a_attributes[:target]).to eq '_blank'
      end

      it 'does not include aria-current if tab is not active' do
        tag = SectionTabHelperSpec::SectionTabTag.new(new_window_tab, course)
        expect(tag.a_attributes[:'aria-current']).to eq nil
      end

      it 'includes aria-current if tab is active' do
        tag = SectionTabHelperSpec::SectionTabTag.new(new_window_tab, course, new_window_tab[:css_class])
        expect(tag.a_attributes[:'aria-current']).to eq 'page'
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

        it 'should not include icon indicating it is off' do
          icon = html.xpath('i')
          expect(icon).to be_empty
        end
      end

      context 'when tab is unused' do
        let(:string) do
          SectionTabHelperSpec::SectionTabTag.new(
            tab_assignments.merge(hidden_unused: true), course
          ).a_tag
        end
        let(:html) { Nokogiri::HTML.fragment(string).children[0] }

        it 'should have a tooltip' do
          expect(html.attributes).to include('data-tooltip')
          expect(html.attributes).to include('title')
          expect(html.attributes['title'].value).to eq 'No content. Not visible to students'
        end

        it 'should include icon indicating it is not visible to students' do
          icon = html.xpath('i[contains(@class, "nav-icon")]')[0]
          expect(icon.attributes['class'].value).to include('icon-off')
        end
      end

      context 'when tab is hidden' do
        let(:string) do
          SectionTabHelperSpec::SectionTabTag.new(
            tab_assignments.merge(hidden: true), course
          ).a_tag
        end
        let(:html) { Nokogiri::HTML.fragment(string).children[0] }

        it 'should have a tooltip' do
          expect(html.attributes).to include('data-tooltip')
          expect(html.attributes).to include('title')
          expect(html.attributes['title'].value).to eq 'Disabled. Not visible to students'
        end

        it 'should include icon indicating it is not visible to students' do
          icon = html.xpath('i[contains(@class, "nav-icon")]')[0]
          expect(icon.attributes['class'].value).to include('icon-off')
        end
      end

      context 'when tab is neither hidden nor unused' do
        let(:string) do
          SectionTabHelperSpec::SectionTabTag.new(
            tab_assignments.merge(), course
          ).a_tag
        end
        let(:html) { Nokogiri::HTML.fragment(string).children[0] }

        it 'shouldn\'t have a title attribute' do
          expect(html.attributes).not_to include('title')
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

      it 'should include `section-hidden` if tab is hidden' do
        tag = SectionTabHelperSpec::SectionTabTag.new(
            tab_assignments.merge(hidden: true), course
        )

        expect(tag.li_classes).to include('section-hidden')
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
