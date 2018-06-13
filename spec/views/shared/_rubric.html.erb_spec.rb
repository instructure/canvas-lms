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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/shared/_rubric" do
  let(:context) { course_model }
  let(:rubric) { rubric_model(context: context) }
  let(:rubric_association) { rubric_association_model(context: context, rubric: rubric) }
  let(:html) { Nokogiri::HTML.fragment(response) }

  it "should render" do
    view_context(context)

    render partial: "shared/rubric", locals: { rubric: rubric }
    expect(response).not_to be_nil
  end

  it "should render with points showing" do
    view_context(context)
    render partial: "shared/rubric", locals: { rubric: rubric, rubric_association: rubric_association }
    expect(html.css('.rubric .toggle_for_hide_points')).not_to be_empty
    expect(html.css('.rubric .toggle_for_hide_points.hidden')).to be_empty
  end

  it "should render some components hidden if hide_points is true" do
    view_context(context)
    rubric_association.update! hide_points: true
    render partial: "shared/rubric", locals: { rubric: rubric, rubric_association: rubric_association }
    expect(html.css('.rubric .toggle_for_hide_points.hidden')).not_to be_empty
  end
end
