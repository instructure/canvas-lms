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
  describe ".valid_search_term?" do
    it "returns false for terms shorter than MIN_SEARCH_TERM_LENGTH" do
      expect(SearchTermHelper.valid_search_term?("a")).to be false
    end

    it "returns true for terms at least MIN_SEARCH_TERM_LENGTH" do
      expect(SearchTermHelper.valid_search_term?("ab")).to be true
    end

    context "with min_length: 1" do
      it "returns true for a single character" do
        expect(SearchTermHelper.valid_search_term?("a", min_length: 1)).to be true
      end

      it "returns false for an empty string" do
        expect(SearchTermHelper.valid_search_term?("", min_length: 1)).to be false
      end
    end
  end

  describe ".validate_search_term" do
    it "raises SearchTermTooShortError for terms below default minimum" do
      expect { SearchTermHelper.validate_search_term("a") }
        .to raise_error(SearchTermHelper::SearchTermTooShortError)
    end

    context "with min_length: 1" do
      it "does not raise for a single character" do
        expect { SearchTermHelper.validate_search_term("a", min_length: 1) }
          .not_to raise_error
      end

      it "raises SearchTermTooShortError for an empty string" do
        expect { SearchTermHelper.validate_search_term("", min_length: 1) }
          .to raise_error(SearchTermHelper::SearchTermTooShortError)
      end
    end

    it "includes min_length in the error message when provided" do
      error = SearchTermHelper::SearchTermTooShortError.new(1)
      expect(error.error_json["errors"].first["message"]).to eq("1 or more characters is required")
    end

    it "uses default MIN_SEARCH_TERM_LENGTH in the error message when min_length is not provided" do
      error = SearchTermHelper::SearchTermTooShortError.new
      expect(error.error_json["errors"].first["message"]).to eq("2 or more characters is required")
    end
  end

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

    context "with min_length: 1" do
      let(:scope) { Attachment.active }
      let(:attr) { :display_name }

      it "returns matching records for a single-character search term" do
        results = Attachment.search_by_attribute(scope, attr, "f", min_length: 1)
        expect(results).to include(matching_record)
        expect(results).not_to include(non_matching_record)
      end

      it "returns scope for an empty search term" do
        expect(Attachment.search_by_attribute(scope, attr, "", min_length: 1)).to eq scope
      end

      it "returns scope for a whitespace-only search term" do
        expect(Attachment.search_by_attribute(scope, attr, "   ", min_length: 1)).to eq scope
      end

      it "returns scope when search_term is nil" do
        expect(Attachment.search_by_attribute(scope, attr, nil, min_length: 1)).to eq scope
      end

      it "raises ArgumentError for invalid min_length values" do
        expect do
          Attachment.search_by_attribute(scope, attr, "test", min_length: 0)
        end.to raise_error(ArgumentError, "min_length must be a positive integer")

        expect do
          Attachment.search_by_attribute(scope, attr, "test", min_length: -1)
        end.to raise_error(ArgumentError, "min_length must be a positive integer")

        expect do
          Attachment.search_by_attribute(scope, attr, "test", min_length: "banana")
        end.to raise_error(ArgumentError, "min_length must be a positive integer")
      end

      it "raises SearchTermTooShortError when term is below min_length with min_length in the message" do
        expect do
          Attachment.search_by_attribute(scope, attr, "a", min_length: 2)
        end.to raise_error(SearchTermHelper::SearchTermTooShortError) { |error|
          expect(error.error_json["errors"].first["message"]).to eq("2 or more characters is required")
        }
      end
    end
  end
end
