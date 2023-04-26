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

shared_examples "allow Quiz LTI placement when the correct Feature Flags are enabled" do
  let(:available_section_tabs) do
    SectionTabHelperSpec::AvailableSectionTabs.new(
      context, current_user, domain_root_account, session
    )
  end

  it "includes Quiz LTI placement if new_quizzes_account_course_level_item_banks and quizzes_next are enabled" do
    Account.site_admin.enable_feature!(:new_quizzes_account_course_level_item_banks)
    allow(context).to receive(:feature_enabled?).and_call_original
    allow(context).to receive(:feature_enabled?).with(:quizzes_next).and_return(true)

    expect(Account.site_admin.feature_enabled?(:new_quizzes_account_course_level_item_banks)).to be(true)
    expect(context.feature_enabled?(:quizzes_next)).to be(true)
    expect(quiz_lti_tool.quiz_lti?).to be(true)
    expect(available_section_tabs.to_a.pluck(:id)).to include("context_external_tool_#{quiz_lti_tool.id}")
  end

  it "does not include Quiz LTI placement if new_quizzes_account_course_level_item_banks is not enabled" do
    allow(context).to receive(:feature_enabled?).and_call_original
    allow(context).to receive(:feature_enabled?).with(:quizzes_next).and_return(true)

    expect(context.feature_enabled?(:quizzes_next)).to be(true)
    expect(Account.site_admin.feature_enabled?(:new_quizzes_account_course_level_item_banks)).to be(false)
    expect(quiz_lti_tool.quiz_lti?).to be(true)
    expect(available_section_tabs.to_a.pluck(:id)).not_to include("context_external_tool_#{quiz_lti_tool.id}")
  end

  it "does not include Quiz LTI placement if next_quizzes is not enabled" do
    Account.site_admin.enable_feature!(:new_quizzes_account_course_level_item_banks)

    expect(Account.site_admin.feature_enabled?(:new_quizzes_account_course_level_item_banks)).to be(true)
    expect(domain_root_account.feature_enabled?(:quizzes_next)).to be(false)
    expect(quiz_lti_tool.quiz_lti?).to be(true)
    expect(available_section_tabs.to_a.pluck(:id)).not_to include("context_external_tool_#{quiz_lti_tool.id}")
  end
end

describe SectionTabHelper do
  before do
    stub_const("SectionTabHelperSpec", Class.new { include SectionTabHelper })
  end

  let_once(:course) { course_model }

  describe "AvailableSectionTabs" do
    let_once(:current_user) { course.users.first }
    let_once(:domain_root_account) { LoadAccount.default_domain_root_account }
    let(:session) { user_session(current_user) }

    let_once(:quiz_lti_tool) do
      ContextExternalTool.create!(
        context: domain_root_account,
        consumer_key: "key",
        shared_secret: "secret",
        name: "Quizzes 2",
        tool_id: "Quizzes 2",
        url: "http://www.tool.com/launch",
        developer_key: DeveloperKey.create!,
        root_account: domain_root_account
      )
    end

    describe "#to_a" do
      context "when context !tabs_available" do
        let(:available_section_tabs) do
          SectionTabHelperSpec::AvailableSectionTabs.new(
            Object.new, current_user, domain_root_account, session
          )
        end

        it "returns an empty array" do
          a = available_section_tabs.to_a
          expect(a).to be_a Array
          expect(a).to be_empty
        end
      end

      context "when context has tabs_available" do
        let(:bad_tab) { { label: "bad tab" } }
        before do
          tabs = Course.default_tabs + [bad_tab]
          allow(course).to receive(:tabs_available).and_return(tabs)
        end

        let(:available_section_tabs) do
          SectionTabHelperSpec::AvailableSectionTabs.new(
            course, current_user, domain_root_account, session
          )
        end

        it "returns a non-empty array" do
          expect(available_section_tabs.to_a).to be_a Array
          expect(available_section_tabs.to_a).to_not be_empty
        end

        it "excludes tabs without label & href elements" do
          expect(available_section_tabs.to_a).to_not include(bad_tab)
        end

        context "and tabs include TAB_CONFERENCES" do
          it "includes TAB_CONFERENCES if WebConference.config" do
            allow(WebConference).to receive(:config).and_return({})
            expect(available_section_tabs.to_a.pluck(:id)).to include(Course::TAB_CONFERENCES)
          end

          it "does not include TAB_CONFERENCES if !WebConference.config" do
            expect(available_section_tabs.to_a.pluck(:id)).to_not include(Course::TAB_CONFERENCES)
          end
        end

        context "template course" do
          let_once(:template_current_user) { account_admin_user }
          let_once(:template_course) { Course.create!(account: domain_root_account, template: true) }
          let(:tabs_available) do
            SectionTabHelperSpec::AvailableSectionTabs.new(
              template_course, template_current_user, domain_root_account, session
            )
          end

          it "does not include TAB_PEOPLE if template?" do
            template_course.update!(template: true)
            expect(tabs_available.to_a.pluck(:id)).to_not include(Course::TAB_PEOPLE)
          end
        end

        context "and tabs include TAB_COLLABORATIONS" do
          it "includes TAB_COLLABORATIONS if Collaboration.any_collaborations_configured?" do
            allow(Collaboration).to receive(:any_collaborations_configured?).and_return(true)
            expect(available_section_tabs.to_a.pluck(:id)).to include(Course::TAB_COLLABORATIONS)
          end

          it "does not include TAB_COLLABORATIONS if !Collaboration.any_collaborations_configured?" do
            expect(available_section_tabs.to_a.pluck(:id)).to_not include(Course::TAB_COLLABORATIONS)
          end

          it "does not include TAB_COLLABORATIONS when new_collaborations feature flag has been enabled" do
            domain_root_account.set_feature_flag!(:new_collaborations, "on")
            allow(Collaboration).to receive(:any_collaborations_configured?).and_return(true)
            expect(available_section_tabs.to_a.pluck(:id)).not_to include(Course::TAB_COLLABORATIONS)
          end
        end

        context "and tabs include TAB_COLLABORATIONS_NEW" do
          it "includes TAB_COLLABORATIONS_NEW if new_collaborations feature flag has been enabled" do
            domain_root_account.set_feature_flag!(:new_collaborations, "on")
            expect(available_section_tabs.to_a.pluck(:id)).to include(Course::TAB_COLLABORATIONS_NEW)
            domain_root_account.set_feature_flag!(:new_collaborations, "off")
          end

          it "does not include TAB_COLLABORATIONS if new_collaborations feature flas has been disabled" do
            domain_root_account.set_feature_flag!(:new_collaborations, "off")
            expect(available_section_tabs.to_a.pluck(:id)).not_to include(Course::TAB_COLLABORATIONS_NEW)
          end
        end

        context "the root account has an account_navigation Quiz LTI placement and @context is an Account" do
          let_once(:context) { domain_root_account }

          before do
            tabs = [
              {
                id: "context_external_tool_#{quiz_lti_tool.id}",
                label: "Quizzes 2",
                css_class: "context_external_tool_#{quiz_lti_tool.id}",
                visibility: nil,
                href: :account_external_tool_path,
                external: true,
                hidden: false,
                args: [context.id, quiz_lti_tool.id]
              },
              {
                id: 9,
                label: "Settings",
                css_class: "settings",
                href: :account_settings_path
              }
            ]
            allow(context).to receive(:tabs_available).and_return(tabs)
          end

          include_examples "allow Quiz LTI placement when the correct Feature Flags are enabled"
        end

        context "the root account has a course_navigation Quiz LTI placement and @context is a Course" do
          let_once(:context) { course }

          before do
            course_placement = {
              id: "context_external_tool_#{quiz_lti_tool.id}",
              label: "Item Banks",
              css_class: "context_external_tool_#{quiz_lti_tool.id}",
              visibility: nil,
              href: :course_external_tool_path,
              external: true,
              hidden: false,
              args: [context.id, quiz_lti_tool.id]
            }
            tabs = Course.default_tabs + [course_placement]
            allow(context).to receive(:tabs_available).and_return(tabs)
          end

          include_examples "allow Quiz LTI placement when the correct Feature Flags are enabled"
        end

        context "the root account has non-Quiz_LTI navigation placements" do
          before do
            non_quiz_lti_course_placement = {
              id: "context_external_tool_0",
              label: "Other LTI",
              css_class: "context_external_tool_0",
              visibility: nil,
              href: :some_path,
              external: true,
              hidden: false,
              args: [course.id, 0]
            }
            tabs = Course.default_tabs + [non_quiz_lti_course_placement]
            allow(course).to receive(:tabs_available).and_return(tabs)
          end

          let(:available_section_tabs) do
            SectionTabHelperSpec::AvailableSectionTabs.new(
              course, current_user, domain_root_account, session
            )
          end

          it "includes non-Quiz_LTI placement ignoring quizzes FFs" do
            expect(Account.site_admin.feature_enabled?(:new_quizzes_account_course_level_item_banks)).to be(false)
            expect(domain_root_account.feature_enabled?(:quizzes_next)).to be(false)
            expect(available_section_tabs.to_a.pluck(:id)).to include("context_external_tool_0")
          end
        end
      end
    end
  end

  describe "SectionTabTag" do
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
        external: true,
        target: "_blank",
        args: [1, 1]
      }
    end

    describe "#a_classes" do
      it "is an array including tab css_class" do
        tag = SectionTabHelperSpec::SectionTabTag.new(
          tab_assignments, course
        )
        expect(tag.a_classes).to be_a Array
        expect(tag.a_classes).to include tab_assignments[:css_class]
        expect(tag.a_classes).not_to include "active"
      end

      it "includes `active` class if tab is active" do
        tag = SectionTabHelperSpec::SectionTabTag.new(
          tab_assignments, course, tab_assignments[:css_class]
        )

        expect(tag.a_classes).to include "active"
      end
    end

    describe "#a_attributes" do
      it "includes keys href & class" do
        tag = SectionTabHelperSpec::SectionTabTag.new(
          tab_pages, course
        )

        expect(tag.a_attributes.keys).to include(:href, :class)
      end

      it "includes a target if tab has the target attribute" do
        tag = SectionTabHelperSpec::SectionTabTag.new(new_window_tab, course)
        expect(tag.a_attributes[:target]).to eq "_blank"
      end

      it "does not include aria-current if tab is not active" do
        tag = SectionTabHelperSpec::SectionTabTag.new(new_window_tab, course)
        expect(tag.a_attributes[:"aria-current"]).to be_nil
      end

      it "includes aria-current if tab is active" do
        tag = SectionTabHelperSpec::SectionTabTag.new(new_window_tab, course, new_window_tab[:css_class])
        expect(tag.a_attributes[:"aria-current"]).to eq "page"
      end
    end

    describe "#a_tag" do
      context "when tab is not hidden" do
        let(:string) do
          SectionTabHelperSpec::SectionTabTag.new(
            tab_assignments, course
          ).a_tag
        end
        let(:html) { Nokogiri::HTML5.fragment(string).children[0] }

        it "is an a tag" do
          expect(html.name).to eq "a"
        end

        it "includes text from tab label" do
          expect(html.text).to eq tab_assignments[:label]
        end

        it "does not include icon indicating it is off" do
          icon = html.xpath("i")
          expect(icon).to be_empty
        end
      end

      context "when tab is unused" do
        let(:string) do
          SectionTabHelperSpec::SectionTabTag.new(
            tab_assignments.merge(hidden_unused: true), course
          ).a_tag
        end
        let(:html) { Nokogiri::HTML5.fragment(string).children[0] }

        it "has a tooltip" do
          expect(html.attributes).to include("data-tooltip")
          expect(html.attributes).to include("title")
          expect(html.attributes["title"].value).to eq "No content. Not visible to students"
        end

        it "includes icon indicating it is not visible to students" do
          icon = html.xpath('i[contains(@class, "nav-icon")]')[0]
          expect(icon.attributes["class"].value).to include("icon-off")
        end
      end

      context "when tab is hidden" do
        let(:string) do
          SectionTabHelperSpec::SectionTabTag.new(
            tab_assignments.merge(hidden: true), course
          ).a_tag
        end
        let(:html) { Nokogiri::HTML5.fragment(string).children[0] }

        it "has a tooltip" do
          expect(html.attributes).to include("data-tooltip")
          expect(html.attributes).to include("title")
          expect(html.attributes["title"].value).to eq "Disabled. Not visible to students"
        end

        it "includes icon indicating it is not visible to students" do
          icon = html.xpath('i[contains(@class, "nav-icon")]')[0]
          expect(icon.attributes["class"].value).to include("icon-off")
        end
      end

      context "when tab is neither hidden nor unused" do
        let(:string) do
          SectionTabHelperSpec::SectionTabTag.new(
            tab_assignments.merge, course
          ).a_tag
        end
        let(:html) { Nokogiri::HTML5.fragment(string).children[0] }

        it "does not have a title attribute" do
          expect(html.attributes).not_to include("title")
        end
      end

      context "new tabs" do
        let(:string) do
          SectionTabHelperSpec::SectionTabTag.new(
            tab_assignments.merge, course
          ).a_tag
        end

        it "includes a new-tab-indicator span for new tabs" do
          stub_const("SectionTabHelper::SectionTabTag::NEW_TABS", %w[assignments])
          expect(string).to include("new-tab-indicator")
        end

        it "does not include the new-tab-indicator for tabs not marked as new" do
          stub_const("SectionTabHelper::SectionTabTag::NEW_TABS", %w[other_stuff])
          expect(string).not_to include("new-tab-indicator")
        end
      end
    end

    describe "#li_classes" do
      it "returns an array including element `section`" do
        tag = SectionTabHelperSpec::SectionTabTag.new(
          tab_assignments, course
        )
        expect(tag.li_classes).to be_a Array
        expect(tag.li_classes).to include("section")
      end

      it "includes `section-hidden` if tab is hidden" do
        tag = SectionTabHelperSpec::SectionTabTag.new(
          tab_assignments.merge(hidden: true), course
        )

        expect(tag.li_classes).to include("section-hidden")
      end
    end

    describe "#to_html" do
      let(:string) do
        SectionTabHelperSpec::SectionTabTag.new(
          tab_assignments, course
        ).to_html
      end
      let(:html) { Nokogiri::HTML5.fragment(string).children[0] }

      it "is an li tag" do
        expect(html.name).to eq "li"
      end

      it "includes a nested a tag" do
        expect(html.children.any? do |child|
          child.name == "a"
        end).to be_truthy
      end
    end
  end
end
