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

require "spec_helper"

RSpec.describe Accessibility::Rules::HasLangEntryRule, type: :feature do
  def find_issues(elem, id)
    rule_class = self.class.described_class
    if rule_class.test(elem)
      []
    else
      [{
        rule_id: rule_class.id,
        message: rule_class.message,
        why: rule_class.why,
        link: rule_class.link,
        link_text: rule_class.link_text,
        data: {
          id:
        }
      }]
    end
  end

  let(:element_id) { "pdf-123" }
  let(:elem) { double("pdf_element") }
  let(:issues) { find_issues(elem, element_id) }

  before do
    allow(elem).to receive(:info).and_return(info_data)
  end

  context "when testing PDF language entry" do
    context "when language info is missing or invalid" do
      describe "identifies a PDF without language specified" do
        let(:info_data) { {} }

        it "flags the issue" do
          expect(issues).not_to be_empty
          expect(issues.first[:rule_id]).to eq("has-lang-entry")
          expect(issues.first[:data][:id]).to eq(element_id)
        end
      end

      describe "handles nil info hash" do
        let(:info_data) { nil }

        it "flags the issue" do
          expect(issues).not_to be_empty
          expect(issues.first[:rule_id]).to eq("has-lang-entry")
        end
      end
    end

    context "when language info is specified" do
      describe "does not flag an issue when language is specified" do
        context "in Lang field (symbol key)" do
          let(:info_data) { { Lang: "en" } }

          it "does not flag an issue because test returns true" do
            expect(issues).to be_empty
          end
        end

        context "in Language field (symbol key)" do
          let(:info_data) { { Language: "fr" } }

          it "does not flag an issue because test returns true" do
            expect(issues).to be_empty
          end
        end

        context "in Lang field (string key)" do
          let(:info_data) { { "Lang" => "es" } }

          it "does not flag an issue because test returns true" do
            expect(issues).to be_empty
          end
        end

        context "in Language field (string key)" do
          let(:info_data) { { "Language" => "de" } }

          it "does not flag an issue because test returns true" do
            expect(issues).to be_empty
          end
        end
      end
    end
  end
end
