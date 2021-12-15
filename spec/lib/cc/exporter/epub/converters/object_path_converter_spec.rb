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

require_relative "../../../cc_spec_helper"

describe "OjbectPathConverter" do
  let(:klass) do
    Class.new do
      include CC::Exporter::Epub::Converters::ObjectPathConverter
    end
  end

  describe "#convert_object_paths!" do
    subject(:test_instance) { klass.new }

    let(:assignment_id) { "i5f4cd2e04f1089c1c5060e9761400516" }
    let(:wiki_id) { "page-1" }
    let(:doc) do
      Nokogiri::HTML5.fragment(<<~HTML)
        <div>
          <a href="#{klass::OBJECT_TOKEN}/assignments/#{assignment_id}">
            Assignment Link
          </a>
          <a href="#{klass::WIKI_TOKEN}/pages/#{wiki_id}">
            Wiki Link
          </a>
        </div>
      HTML
    end

    it "updates assignment link href" do
      expect(doc.search("a[href*='#{klass::OBJECT_TOKEN}']").any?).to be_truthy,
                                                                      "precondition"

      test_instance.convert_object_paths!(doc)
      expect(doc.search("a[href*='#{klass::OBJECT_TOKEN}']").any?).to be_falsy
      expect(doc.search("a[href='assignments.xhtml##{assignment_id}']").any?).to be_truthy
    end

    it "updates wiki link href" do
      expect(doc.search("a[href*='#{klass::WIKI_TOKEN}']").any?).to be_truthy,
                                                                    "precondition"

      test_instance.convert_object_paths!(doc)
      expect(doc.search("a[href*='#{klass::WIKI_TOKEN}']").any?).to be_falsy
      expect(doc.search("a[href='pages.xhtml##{wiki_id}']").any?).to be_truthy
    end
  end
end
