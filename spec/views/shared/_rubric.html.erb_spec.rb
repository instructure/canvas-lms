# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe "shared/_rubric" do
  let(:context) { course_model }
  let(:rubric) { rubric_model(context:) }
  let(:rubric_association) { rubric_association_model(context:, rubric:) }
  let(:html) { Nokogiri::HTML5.fragment(response) }

  it "renders" do
    view_context(context)

    render partial: "shared/rubric", locals: { rubric: }
    expect(response).not_to be_nil
  end

  it "renders with points showing" do
    view_context(context)
    render partial: "shared/rubric", locals: { rubric:, rubric_association: }
    expect(html.css(".rubric .toggle_for_hide_points")).not_to be_empty
    expect(html.css(".rubric .toggle_for_hide_points.hidden")).to be_empty
  end

  it "renders some components hidden if hide_points is true" do
    view_context(context)
    rubric_association.update! hide_points: true
    render partial: "shared/rubric", locals: { rubric:, rubric_association: }
    expect(html.css(".rubric .toggle_for_hide_points.hidden")).not_to be_empty
  end

  context "when anonymize_student is false" do
    it "renders the user_id field" do
      view_context(context)
      render partial: "shared/rubric", locals: { rubric:, rubric_association: }
      expect(html.css(".rubric .user_id")).not_to be_empty
    end

    it "does not render the anonymous_id field" do
      view_context(context)
      render partial: "shared/rubric", locals: { rubric:, rubric_association: }
      expect(html.css(".rubric .anonymous_id")).to be_empty
    end
  end

  context "when anonymize_student is true" do
    it "renders the anonymous_id field" do
      view_context(context)
      render partial: "shared/rubric", locals: { rubric:, rubric_association:, anonymize_student: true }
      expect(html.css(".rubric .anonymous_id")).not_to be_empty
    end

    it "does not render the user_id field" do
      view_context(context)
      render partial: "shared/rubric", locals: { rubric:, rubric_association:, anonymize_student: true }
      expect(html.css(".rubric .user_id")).to be_empty
    end
  end
end
