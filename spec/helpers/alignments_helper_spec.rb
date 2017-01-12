#
# Copyright (C) 2014 Instructure, Inc.
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

require 'nokogiri'

describe AlignmentsHelper do
  include AlignmentsHelper
  include ApplicationHelper
  include Rails.application.routes.url_helpers

  before(:once) do
    account_model
    assignment_model
  end

  let_once(:outcome) {
    @course.created_learning_outcomes.create!(title: 'outcome')
  }

  let_once(:account_outcome) {
    @account.created_learning_outcomes.create!(title: 'account outcome!')
  }

  let_once(:alignment) {
    tag = ContentTag.create(
      content: outcome,
      context: outcome.context,
      tag_type: 'learning_outcome')
    outcome.alignments << tag
    tag
  }

  let_once(:graded_alignment) {
    tag = ContentTag.create(
        content: @assignment,
        context: outcome.context,
        tag_type: 'learning_outcome')
    outcome.alignments << tag
    tag
  }

  describe "outcome_alignment_url" do
    context "without an alignment" do
      it "should return nil if context is an account" do
        expect(outcome_alignment_url(@account, account_outcome)).to be_nil
      end
    end

    context "with an alignment" do
      it "should return a url path" do
        expect(outcome_alignment_url(@account, account_outcome, alignment)).to be_truthy
      end
    end
  end

  describe "link_to_outcome_alignment" do
    context "without an alignment" do
      let(:string) { link_to_outcome_alignment(@course, outcome) }

      it "should not include an icon-* html class" do
        expect(string.match(/icon\-/)).to be_falsey
      end

      it "should be a blank link tag" do
        html = Nokogiri::HTML.fragment(string)
        expect(html.text).to be_blank
      end
    end

    context "with an alignment" do
      let(:string) {
        link_to_outcome_alignment(@course, outcome, alignment)
      }

      it "should not include an icon-* html class" do
        expect(string.match(/icon\-/)).to be_truthy
      end

      it "should be a blank link tag" do
        html = Nokogiri::HTML.fragment(string)
        expect(html.text).to eq(alignment.title)
      end
    end
  end

  describe "outcome_alignment_tag" do
    context "without an alignment" do
      let(:string) { outcome_alignment_tag(@course, outcome) {} }
      let(:html) { Nokogiri::HTML.fragment(string).children[0] }

      it "should include an id of 'alignment_blank'" do
        expect(string.match(/alignment\_blank/)).to be_truthy
      end

      it "should include class alignment" do
        expect(html['class'].split(' ')).to include('alignment')
      end

      it "should include 1 data-* attribute" do
        expect(html.keys.select { |k|
          k.match(/data\-/)
        }).to include('data-url')
      end

      it "should be hidden" do
        expect(html['style']).to match(/display\:\ none/)
      end
    end

    context "with an alignment" do
      let(:string) { outcome_alignment_tag(@course, outcome, alignment) {} }
      let(:html) { Nokogiri::HTML.fragment(string).children[0] }

      it "should include an id of 'alignment_{id}'" do
        expect(string.match(/alignment\_#{alignment.id}/)).to be_truthy
      end

      it "should have classes alignment & its content_type_class" do
        classes = html['class'].split(' ')
        expect(classes).to include('alignment', alignment.content_type_class)
      end

      it "should data-id & data-url attributes" do
        expect(html.keys.select { |k|
          k.match(/data\-/)
        }).to include('data-id', 'data-url')
      end

      it "should not be hidden" do
        expect(html['style']).not_to match(/display\:\ none/)
      end
    end

    context "with a graded alignment" do
      let(:string) { outcome_alignment_tag(@course, outcome, graded_alignment) {} }
      let(:html) { Nokogiri::HTML.fragment(string).children[0] }

      it "should include html class 'also_assignment'" do
        classes = html['class'].split(' ')
        expect(classes).to include('also_assignment')
      end
    end

    context "with a rubric association" do
      before(:once) {
        rubric_association_model({
          purpose: "grading"
        })
      }
      let(:string) { outcome_alignment_tag(@course, outcome, graded_alignment) {} }
      let(:html) { Nokogiri::HTML.fragment(string).children[0] }

      it "should have html 'data-has-rubric-association' data attritbute" do
        expect(html.keys.find { |k|
          k.match(/data\-has\-rubric\-association/)
        }).to be_truthy
      end
    end
  end
end
