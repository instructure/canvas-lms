# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require "spec_helper"

describe NewQuizzesHelper do
  include NewQuizzesHelper

  let_once(:account) { Account.default }
  let_once(:course) { course_factory(account:) }

  before do
    @context = course
    allow(Services::NewQuizzes).to receive(:launch_url).and_return("https://newquizzes.example.com/remoteEntry.js")
  end

  describe "#add_new_quizzes_bundle" do
    context "when context does not respond to feature_enabled?" do
      before do
        @context = Object.new
      end

      it "does not add the new quizzes bundle" do
        expect(self).not_to receive(:js_bundle)
        expect(self).not_to receive(:css_bundle)
        expect(self).not_to receive(:remote_env)

        add_new_quizzes_bundle
      end
    end

    context "when new_quizzes_native_experience feature is disabled" do
      before do
        course.disable_feature!(:new_quizzes_native_experience)
      end

      it "does not add the new quizzes bundle" do
        expect(self).not_to receive(:js_bundle)
        expect(self).not_to receive(:css_bundle)
        expect(self).not_to receive(:remote_env)

        add_new_quizzes_bundle
      end
    end

    context "when new_quizzes_native_experience feature is enabled" do
      before do
        course.enable_feature!(:new_quizzes_native_experience)
      end

      it "adds the new quizzes bundle and remote env" do
        expect(self).to receive(:js_bundle).with(:new_quizzes)
        expect(self).to receive(:css_bundle).with(:native_new_quizzes)
        expect(self).to receive(:remote_env).with(
          new_quizzes: {
            launch_url: "https://newquizzes.example.com/remoteEntry.js"
          }
        )

        add_new_quizzes_bundle
      end
    end
  end

  describe ".override_item_banks_tab" do
    let(:tabs) do
      [
        { id: "home", label: "Home", css_class: "home", href: :course_path },
        { id: "item_banks", label: "Item Banks", css_class: "item_banks", href: :some_original_path },
        { id: "assignments", label: "Assignments", css_class: "assignments", href: :course_assignments_path }
      ]
    end

    context "when Item Banks tab exists" do
      it "overrides the Item Banks tab with new href" do
        NewQuizzesHelper.override_item_banks_tab(
          tabs:,
          href: :course_new_quizzes_banks_path,
          context: course
        )

        item_banks_tab = tabs.find { |t| t[:id] == Course::TAB_ITEM_BANKS }
        expect(item_banks_tab).to be_present
        expect(item_banks_tab[:href]).to eq(:course_new_quizzes_banks_path)
        expect(item_banks_tab[:label]).to eq("Item Banks")
        expect(item_banks_tab[:css_class]).to eq("item_banks")
      end

      it "maintains the position of the Item Banks tab" do
        NewQuizzesHelper.override_item_banks_tab(
          tabs:,
          href: :course_new_quizzes_banks_path,
          context: course
        )

        item_banks_index = tabs.find_index { |t| t[:id] == Course::TAB_ITEM_BANKS }
        expect(item_banks_index).to eq(1)
      end

      it "uses account path for account context" do
        account = Account.default
        NewQuizzesHelper.override_item_banks_tab(
          tabs:,
          href: :account_new_quizzes_banks_path,
          context: account
        )

        item_banks_tab = tabs.find { |t| t[:id] == Course::TAB_ITEM_BANKS }
        expect(item_banks_tab[:href]).to eq(:account_new_quizzes_banks_path)
      end
    end

    context "when Item Banks tab does not exist" do
      let(:tabs_without_item_banks) do
        [
          { id: "home", label: "Home", css_class: "home", href: :course_path },
          { id: "assignments", label: "Assignments", css_class: "assignments", href: :course_assignments_path }
        ]
      end

      it "does not modify the tabs" do
        original_tabs = tabs_without_item_banks.dup
        NewQuizzesHelper.override_item_banks_tab(
          tabs: tabs_without_item_banks,
          href: :course_new_quizzes_banks_path,
          context: course
        )
        expect(tabs_without_item_banks).to eq(original_tabs)
      end
    end
  end
end
