# frozen_string_literal: true

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

require_relative "../views_helper"

describe "context_modules/items_html" do
  subject do
    render "context_modules/items_html"
    Nokogiri("<document>" + response.body + "</document>")
  end

  let(:can_view) { true }
  let(:is_student) { true }
  let(:session_mock) { double("session_mock") }
  let(:context_module) { @course.context_modules.create! }
  let(:non_call_render_params) do
    {
      object: anything,
      as: anything,
      locals: anything
    }
  end

  before do
    course_factory
    view_context(@course, @user)
    assign(:can_view, can_view)
    assign(:is_student, is_student)
    assign(:session, session_mock)

    allow(view).to receive(:render).and_call_original
  end

  it "renders" do
    expect(subject.css(".context_module_items").length).to eq 1
  end

  describe "manageable css class rendering" do
    context "when can_view true" do
      let(:can_view) { true }

      it "should render" do
        expect(subject.css(".manageable").length).to eq 1
      end
    end

    context "when can_view false" do
      let(:can_view) { false }

      it "should not render" do
        expect(subject.css(".manageable").length).to eq 0
      end
    end
  end

  context "when module is not given" do
    it "should not call module item rendering" do
      expect(view)
        .to_not receive(:render)
        .with(partial: "context_modules/module_item_next", **non_call_render_params)

      subject
    end

    it "should not call module item conditional next rendering" do
      expect(view)
        .to_not receive(:render)
        .with(partial: "context_modules/module_item_conditional_next", **non_call_render_params)

      subject
    end

    it "should not call process_module_items_data" do
      expect_any_instance_of(ContextModulesHelper).to_not receive(:process_module_items_data)

      subject
    end
  end

  context "when module is given" do
    let(:items_restrictions_mock) { [true] }
    let(:item_mock) { double("item_mock", id: 1) }
    let(:item_data_mock) { { show_cyoe_placeholder: false } }
    let(:mock_module_data) do
      {
        items: [item_mock],
        items_data: {
          item_mock.id => item_data_mock
        },
        items_restrictions: {
          item_mock.id => items_restrictions_mock
        }
      }
    end
    let(:expected_params) do
      {
        object: item_mock,
        as: :module_item,
        locals: {
          item_restrictions: items_restrictions_mock,
          completion_criteria: context_module.completion_requirements,
          item_data: item_data_mock,
          viewable: can_view
        }
      }
    end

    before do
      assign(:module, context_module)
      assign(:can_view, can_view)
      assign(:items, item_mock)
      allow_any_instance_of(ContextModulesHelper).to receive(:process_module_items_data).and_return(mock_module_data)
      allow(view).to receive(:render).with(partial: "context_modules/module_item_next", **non_call_render_params)
    end

    it "should call process_module_items_data" do
      expect_any_instance_of(ContextModulesHelper)
        .to receive(:process_module_items_data)
        .with(item_mock, context_module, @user, session_mock, { student: is_student })
        .and_return(mock_module_data)

      subject
    end

    it "should call module item rendering with proper params" do
      expect(view)
        .to receive(:render)
        .with(partial: "context_modules/module_item_next", **expected_params)
        .and_return("")

      subject
    end

    context "when the module_data[:items] is empty" do
      let(:mock_module_data) { { items: [], items_data: {}, items_restrictions: {} } }

      it "should not call module item rendering" do
        expect(view).to_not receive(:render).with(partial: "context_modules/module_item_next", **non_call_render_params)

        subject
      end
    end

    it "should not call module item conditional next rendering" do
      expect(view)
        .to_not receive(:render)
        .with(partial: "context_modules/module_item_conditional_next", **non_call_render_params)

      subject
    end

    context "when the item_data[:show_cyoe_placeholder] is true in item_data" do
      let(:item_data_mock) { { show_cyoe_placeholder: true } }

      it "should call module item rendering with proper params" do
        expect(view)
          .to receive(:render)
          .with(partial: "context_modules/module_item_conditional_next", **expected_params)
          .and_return("")

        subject
      end
    end
  end
end
