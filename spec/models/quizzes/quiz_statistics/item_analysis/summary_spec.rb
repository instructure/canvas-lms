# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require_relative "common"

describe Quizzes::QuizStatistics::ItemAnalysis::Summary do
  let(:quiz) do
    simple_quiz_with_submissions %w[T T A], %w[T T A], %w[T T B], %w[T F B], %w[T F B]
  end

  let(:summary_options) { {} }

  let(:summary) do
    Quizzes::QuizStatistics::ItemAnalysis::Summary.new(quiz, summary_options)
  end

  describe "#aggregate_data" do
    it "groups items by question" do
      simple_quiz_with_shuffled_answers %w[T T A], %w[T T A]
      expect(summary.size).to eq 3
    end
  end

  describe "#buckets" do
    context "with distributed submissions" do
      let(:quiz) do
        simple_quiz_with_submissions %w[T T A],
                                     %w[T T A],
                                     %w[T T A],
                                     %w[T T B], # top
                                     %w[T F B],
                                     %w[T F B],
                                     %w[F T C],
                                     %w[F T D],
                                     %w[F T B], # middle
                                     %w[F F B],
                                     %w[F F C],
                                     %w[F F D] # bottom
      end

      it "distributes the students accordingly" do
        buckets = summary.buckets
        total = buckets.values.sum(&:size)
        top, middle, bottom = buckets[:top].size / total.to_f, buckets[:middle].size / total.to_f, buckets[:bottom].size / total.to_f

        # because of the small sample size, this is slightly off, but close enough for gvt work
        expect(top).to be_approximately 0.27, 0.03
        expect(middle).to be_approximately 0.46, 0.06
        expect(bottom).to be_approximately 0.27, 0.03
      end
    end

    context "with tied submissions" do
      let(:quiz) do
        simple_quiz_with_submissions %w[T T A],
                                     %w[T T A],
                                     %w[T T A],
                                     %w[F F B],
                                     %w[F F B]
      end

      let(:summary_options) do
        {
          buckets: [
            [:top, 0.75],
            [:middle, 0.25],
            [:bottom, 0]
          ]
        }
      end

      it "moves them to a higher bucket" do
        # non-ties would result in 1, 2, 1
        buckets = summary.buckets
        expect(buckets[:top].length).to eq 2
        expect(buckets[:middle].length).to eq 2
        expect(buckets[:bottom].length).to eq 0
      end
    end

    context "with perfect submissions" do
      let(:quiz) do
        simple_quiz_with_submissions %w[T T A],
                                     %w[T T A],
                                     %w[T T A]
      end

      it "does not choke" do
        buckets = summary.buckets
        expect(buckets[:top].length).to eq 2
        expect(buckets[:middle].length).to eq 0
        expect(buckets[:bottom].length).to eq 0
      end
    end
  end

  describe "#add_response" do
    it "does not add unsupported response types" do
      summary.add_response({ question_type: "foo", answers: [] }, 0, 0)
      expect(summary.size).to eq 3
    end
  end

  describe "#each" do
    it "yields each item" do
      count = 0
      summary.each do |item|
        expect(item).to be_a Quizzes::QuizStatistics::ItemAnalysis::Item
        count += 1
      end
      expect(count).to eq 3
    end
  end

  describe "#alpha" do
    context "with valid data" do
      it "matches R's output" do
        # > mdat <- matrix(c(1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0), nrow=4)
        # > cronbach.alpha(mdat)
        #
        # Cronbach's alpha for the 'mdat' data-set
        #
        # Items: 3
        # Sample units: 4
        # alpha: 0.545
        expect(summary.alpha).to be_approximately 0.545
      end
    end

    context "with less than 2 items" do
      let(:quiz) do
        simple_quiz_with_submissions %w[T], %w[F], %w[T], %w[T], %w[T]
      end

      it "is nil" do
        allow(summary).to receive(:size).and_return(1)
        expect(summary.alpha).to be_nil
      end
    end

    context "with a #variance of 0" do
      let(:quiz) do
        simple_quiz_with_submissions %w[T T F], %w[T T T], %w[T T T], %w[T T T], %w[T T T]
      end

      it "is nil" do
        expect(summary.alpha).to be_nil
      end
    end
  end

  describe "#variance" do
    it "matches R's output" do
      # population variance, not sample variance (thus the adjustment)
      # > v <- c(3, 2, 1, 1)
      # > var(v)*3/4
      # [1] 0.6875
      expect(summary.variance).to be_approximately 0.6875
    end
  end

  describe "#standard_deviation" do
    it "matches R's output" do
      # population sd, not sample sd (thus the adjustment)
      # > v <- c(3, 2, 1, 1)
      # > sqrt(var(v)*3/4)
      # [1] 0.8291562
      expect(summary.standard_deviation).to be_approximately 0.8291562
    end
  end
end
