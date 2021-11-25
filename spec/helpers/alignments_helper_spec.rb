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

require "nokogiri"

describe AlignmentsHelper do
  include AlignmentsHelper
  include ApplicationHelper
  include Rails.application.routes.url_helpers

  before(:once) do
    account_model
    assignment_model
  end

  let_once(:outcome) do
    @course.created_learning_outcomes.create!(title: "outcome")
  end

  let_once(:account_outcome) do
    @account.created_learning_outcomes.create!(title: "account outcome!")
  end

  let_once(:alignment) do
    tag = ContentTag.create(
      content: outcome,
      context: outcome.context,
      tag_type: "learning_outcome"
    )
    outcome.alignments << tag
    tag
  end

  let_once(:graded_alignment) do
    tag = ContentTag.create(
      content: @assignment,
      context: outcome.context,
      tag_type: "learning_outcome"
    )
    outcome.alignments << tag
    tag
  end

  describe "outcome_alignment_url" do
    context "without an alignment" do
      it "returns nil if context is an account" do
        expect(outcome_alignment_url(@account, account_outcome)).to be_nil
      end
    end

    context "with an alignment" do
      it "returns a url path" do
        expect(outcome_alignment_url(@account, account_outcome, alignment)).to be_truthy
      end
    end
  end

  describe "link_to_outcome_alignment" do
    context "without an alignment" do
      let(:string) { link_to_outcome_alignment(@course, outcome) }

      it "does not include an icon-* html class" do
        expect(string.include?("icon-")).to be_falsey
      end

      it "is a blank link tag" do
        html = Nokogiri::HTML5.fragment(string)
        expect(html.text).to be_blank
      end
    end

    context "with an alignment" do
      let(:string) do
        link_to_outcome_alignment(@course, outcome, alignment)
      end

      it "does not include an icon-* html class" do
        expect(string.include?("icon-")).to be_truthy
      end

      it "is a blank link tag" do
        html = Nokogiri::HTML5.fragment(string)
        expect(html.text).to eq(alignment.title)
      end
    end
  end

  describe "outcome_alignment_tag" do
    context "without an alignment" do
      let(:string) { outcome_alignment_tag(@course, outcome) { nil } }
      let(:html) { Nokogiri::HTML5.fragment(string).children[0] }

      it "includes an id of 'alignment_blank'" do
        expect(string.include?("alignment_blank")).to be_truthy
      end

      it "includes class alignment" do
        expect(html["class"].split).to include("alignment")
      end

      it "includes 1 data-* attribute" do
        expect(html.keys.select do |k|
          k.include?("data-")
        end).to include("data-url")
      end

      it "is hidden" do
        expect(html["style"]).to match(/display:\ none/)
      end
    end

    context "with an alignment" do
      let(:string) { outcome_alignment_tag(@course, outcome, alignment) { nil } }
      let(:html) { Nokogiri::HTML5.fragment(string).children[0] }

      it "includes an id of 'alignment_{id}'" do
        expect(string.match(/alignment_#{alignment.id}/)).to be_truthy
      end

      it "has classes alignment & its content_type_class" do
        classes = html["class"].split
        expect(classes).to include("alignment", alignment.content_type_class)
      end

      it "data-ids & data-url attributes" do
        expect(html.keys.select do |k|
          k.include?("data-")
        end).to include("data-id", "data-url")
      end

      it "is not hidden" do
        expect(html["style"]).not_to match(/display:\ none/)
      end
    end

    context "with a graded alignment" do
      let(:string) { outcome_alignment_tag(@course, outcome, graded_alignment) { nil } }
      let(:html) { Nokogiri::HTML5.fragment(string).children[0] }

      it "includes html class 'also_assignment'" do
        classes = html["class"].split
        expect(classes).to include("also_assignment")
      end
    end

    context "with a rubric association" do
      before(:once) do
        rubric_association_model({
                                   purpose: "grading"
                                 })
      end

      let(:string) { outcome_alignment_tag(@course, outcome, graded_alignment) { nil } }
      let(:html) { Nokogiri::HTML5.fragment(string).children[0] }

      it "has html 'data-has-rubric-association' data attritbute" do
        expect(html.keys.find do |k|
          k.include?("data-has-rubric-association")
        end).to be_truthy
      end
    end
  end
end
