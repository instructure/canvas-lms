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

describe "context_modules/module_html" do
  subject do
    render "context_modules/module_html"
    Nokogiri("<document>" + response.body + "</document>")
  end

  let(:context_module) { @course.context_modules.create! }
  let(:non_call_render_params) do
    {
      object: anything,
      as: anything
    }
  end

  before do
    course_factory
    view_context(@course, @user)

    allow(view).to receive(:render).and_call_original
  end

  context "when @modules is populated" do
    before do
      assign(:modules, [context_module])
    end

    it "renders" do
      expect(subject.css("#context_module_#{context_module.id}").length).to eq 1
    end

    context "when @module_show_setting is given" do
      context "when @module_show_setting is the same id as provided @module id's" do
        before do
          assign(:module_show_setting, context_module.id)
        end

        it "renders" do
          expect(subject.css("#context_module_#{context_module.id}").length).to eq 1
        end
      end

      context "when @module_show_setting is not the same id as provided @module id's" do
        before do
          assign(:module_show_setting, "not_the_same")
        end

        it "should not call module item rendering" do
          expect(view)
            .to_not receive(:render)
            .with(partial: "context_modules/context_module_next", **non_call_render_params)

          subject
        end
      end
    end
  end

  context "when @modules is nil" do
    before do
      assign(:modules, nil)
    end

    it "should not call module item rendering" do
      expect(view)
        .to_not receive(:render)
        .with(partial: "context_modules/context_module_next", **non_call_render_params)

      subject
    end
  end

  context "when @modules is empty" do
    before do
      assign(:modules, [])
    end

    it "should not call module item rendering" do
      expect(view)
        .to_not receive(:render)
        .with(partial: "context_modules/context_module_next", **non_call_render_params)

      subject
    end
  end
end
