# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe EportfolioCategory do
  let(:user) { User.create! }
  let(:eportfolio) { Eportfolio.create!(name: "my file", user:) }
  let(:spam_status) { eportfolio.reload.spam_status }
  let(:category) { eportfolio.eportfolio_categories.create!(name: "my category") }

  describe "validation" do
    it "generates a URL-friendly slug" do
      expect(category.slug).to eq "my-category"
    end

    it "recalculates the slug only if the name changes" do
      cat = eportfolio.eportfolio_categories.create!(name: "Frog and Toad")
      EportfolioCategory.where(id: cat).update_all(slug: "something-else")
      cat.reload

      cat.update! position: 10
      expect(cat.reload.slug).to eq "something-else"

      cat.update! name: "Toad and Frog"
      expect(cat.reload.slug).to eq "toad-and-frog"
    end

    it "uniquifies the slug" do
      category
      dup = eportfolio.eportfolio_categories.create!(name: "my category")
      expect(dup.slug).to eq "my-category_2"
    end

    it "generates a non-empty slug when given non-ASCII alphanumeric characters" do
      cat = eportfolio.eportfolio_categories.create!(name: "ページ名")
      expect(cat.slug).to eq "peziming"
    end

    it "generates a non-empty slug when given non-alphanumeric characters" do
      expect(CanvasSlug).to receive(:generate).and_return("41fe")
      cat = eportfolio.eportfolio_categories.create!(name: "☃")
      expect(cat.slug).to eq "41fe"
    end
  end

  describe "callbacks" do
    describe "#check_for_spam" do
      context "when the setting has a value" do
        before do
          Setting.set("eportfolio_title_spam_keywords", "bad, verybad, worse")
        end

        it "marks the owning portfolio as possible spam when the title matches one or more keywords" do
          category.update!(name: "my bad category")
          expect(spam_status).to eq "flagged_as_possible_spam"
        end

        it "does not mark as spam when the title matches no keywords" do
          expect do
            category.update!(name: "my great and notbad category")
          end.not_to change { spam_status }
        end

        it "does not mark as spam if a spam_status already exists" do
          eportfolio.update!(spam_status: "marked_as_safe")

          expect do
            category.update!(name: "actually a bad category")
          end.not_to change { spam_status }
        end
      end

      it "does not attempt to mark as spam when the setting is empty" do
        expect do
          category.update!(name: "actually a bad category")
        end.not_to change { spam_status }
      end
    end
  end
end
