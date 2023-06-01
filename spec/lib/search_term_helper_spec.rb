# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe "search_term_helper" do
  describe "#search_by_attribute" do
    subject do
      Attachment.search_by_attribute(
        scope,
        attr,
        search_term,
        normalize_unicode:
      )
    end

    let_once(:matching_record) { attachment_model(display_name: "something_#{search_term}") }
    let_once(:non_matching_record) { attachment_model(display_name: "banana") }
    let_once(:nfc_record) { attachment_model(display_name: "café".unicode_normalize) }
    let_once(:nfd_record) { attachment_model(display_name: "café".unicode_normalize(:nfd)) }

    let(:search_term) { "foo" }
    let(:normalize_unicode) { false }

    shared_examples_for "methods that filter by search term" do
      it "returns records that match the search term" do
        expect(subject).to match_array([matching_record])
      end

      it "has a return value of the same type as scope" do
        expect(subject.class).to eq scope.class
      end
    end

    shared_examples_for "search methods that do basic unicode normalization" do
      let(:normalize_unicode) { true }

      context "with an NFC search term" do
        let(:search_term) { "café".unicode_normalize }

        it "returns matching NFC and NFD records" do
          expect(subject).to match_array [
            nfc_record,
            nfd_record
          ]
        end
      end

      context "with an NFD search term" do
        let(:search_term) { "café".unicode_normalize(:nfd) }

        it "returns matching NFC and NFD records" do
          expect(subject).to match_array [
            nfc_record,
            nfd_record
          ]
        end
      end
    end

    context "when the scope responds to 'where'" do
      let(:scope) { Attachment.active }
      let(:attr) { :display_name }

      it_behaves_like "methods that filter by search term"
      it_behaves_like "search methods that do basic unicode normalization"
    end

    context "when the scope does not respond to 'where'" do
      let(:scope) { Attachment.active.to_a }
      let(:attr) { :display_name }

      it_behaves_like "methods that filter by search term"
      it_behaves_like "search methods that do basic unicode normalization"
    end
  end
end
