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

describe FeatureFlags::OakPredicate do
  let(:context) { double("Context") }

  describe "#call" do
    context "when Rails environment is local" do
      before do
        allow(Rails.env).to receive(:local?).and_return(true)
      end

      it "returns true for us-east-1 region" do
        predicate = described_class.new(context, "us-east-1")

        expect(predicate.call).to be true
      end

      it "returns true for us-west-2 region" do
        predicate = described_class.new(context, "us-west-2")

        expect(predicate.call).to be true
      end

      it "returns true for non-approved region" do
        predicate = described_class.new(context, "eu-west-1")

        expect(predicate.call).to be true
      end

      it "returns true for nil region" do
        predicate = described_class.new(context, nil)

        expect(predicate.call).to be true
      end
    end

    context "when Rails environment is not local" do
      before do
        allow(Rails.env).to receive(:local?).and_return(false)
      end

      context "with approved US AWS regions" do
        it "returns true for us-east-1" do
          predicate = described_class.new(context, "us-east-1")

          expect(predicate.call).to be true
        end

        it "returns true for us-west-2" do
          predicate = described_class.new(context, "us-west-2")

          expect(predicate.call).to be true
        end
      end

      context "with non-approved regions" do
        it "returns false for a valid but non-approved region" do
          predicate = described_class.new(context, "eu-west-1")

          expect(predicate.call).to be false
        end

        it "returns false for nil region" do
          predicate = described_class.new(context, nil)

          expect(predicate.call).to be false
        end

        it "returns false for empty string region" do
          predicate = described_class.new(context, "")

          expect(predicate.call).to be false
        end
      end
    end
  end
end
