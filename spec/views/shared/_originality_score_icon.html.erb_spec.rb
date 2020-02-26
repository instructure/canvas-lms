#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative '../../spec_helper'
require_relative '../views_helper'

describe "/shared/_originality_score_icon" do
  let(:error_data) { { status: "error" } }
  let(:pending_data) { {  status: "pending" } }
  let(:high_score_data) { { status: "scored", similarity_score: 75 } }
  let(:middling_score_data) { { status: "scored", similarity_score: 50 } }
  let(:low_score_data) { { status: "scored", similarity_score: 10 } }

  def render_element(data:, additional_params: {})
    params = { plagiarism_data: data }.merge(additional_params)
    render partial: "shared/originality_score_icon", locals: params
    Nokogiri::HTML(response.body)
  end

  describe "similarity icon" do
    it "renders a warning icon if given data in 'error' status" do
      doc = render_element(data: error_data)
      expect(doc.css('i.icon-warning')).to be_present
    end

    it "renders a clock icon if given data in 'pending' status" do
      doc = render_element(data: pending_data)
      expect(doc.css('i.icon-clock')).to be_present
    end

    it "renders an 'empty' icon if given scored data with a score above 60%" do
      doc = render_element(data: high_score_data)
      expect(doc.css('i.icon-empty')).to be_present
    end

    it "renders a half oval icon if given scored data with a score between 20% and 60%" do
      doc = render_element(data: middling_score_data)
      expect(doc.css('i.icon-oval-half')).to be_present
    end

    it "renders a certified icon if given scored data with a score below 20%" do
      doc = render_element(data: low_score_data)
      expect(doc.css('i.icon-certified')).to be_present
    end

    it "renders no icon if given data without a status" do
      doc = render_element(data: {})
      expect(doc.css('i')).not_to be_present
    end
  end

  describe "report linking" do
    it "renders the containing element as a link if given a report URL" do
      doc = render_element(data: high_score_data, additional_params: { report_url: "http://my-report/" })
      expect(doc.css('a.turnitin_score_container')).to be_present
    end

    it "links to the supplied report URL if given one" do
      doc = render_element(data: high_score_data, additional_params: { report_url: "http://my-report/" })
      expect(doc.at_css('a.turnitin_score_container')['href']).to eq "http://my-report/"
    end

    it "renders the containing element as a plain old span if no report URL is given" do
      doc = render_element(data: high_score_data)
      expect(doc.css('span.turnitin_score_container')).to be_present
    end

    it "sets the containing element's title attribute to report_title if given" do
      doc = render_element(data: high_score_data, additional_params: { report_title: "exciting report" })
      expect(doc.at_css('.turnitin_score_container')['title']).to eq "exciting report"
    end

    it "sets no title on the containing element if report_title is not given" do
      doc = render_element(data: high_score_data, additional_params: { report_url: "http://my-report/" })
      expect(doc.at_css('.turnitin_score_container')['title']).not_to be_present
    end
  end

  describe "score display" do
    it "renders a score if given scored data and hide_score is not passed" do
      doc = render_element(data: high_score_data)
      expect(doc.at_css('.turnitin_similarity_score').text).to eq "75%"
    end

    it "does not render a score if the data without a score is given" do
      doc = render_element(data: error_data)
      expect(doc.css('.turnitin_similarity_score')).not_to be_present
    end

    it "does not render a score if hide_score is passed" do
      doc = render_element(data: high_score_data, additional_params: { hide_score: true })
      expect(doc.css('.turnitin_similarity_score')).not_to be_present
    end
  end

  describe "tooltip" do
    it "adds a tooltip element with the supplied text if tooltip_text is passed" do
      doc = render_element(data: high_score_data, additional_params: { tooltip_text: "I am a tooltip!" })
      expect(doc.at_css('.tooltip_text').text).to eq "I am a tooltip!"
    end

    it "does not add a tooltip element if tooltip_text is not passed" do
      doc = render_element(data: high_score_data)
      expect(doc.css('.tooltip_text')).not_to be_present
    end
  end
end
