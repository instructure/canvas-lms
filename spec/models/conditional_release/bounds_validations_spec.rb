# frozen_string_literal: true

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
#

require_relative "../../spec_helper"

module ConditionalRelease
  describe BoundsValidations do
    subject do
      Class.new do
        include ActiveModel::Validations
        include BoundsValidations
        attr_accessor :upper_bound, :lower_bound
      end.new
    end

    it "has to have a bound" do
      subject.upper_bound = subject.lower_bound = nil
      expect(subject.valid?).to be false
      expect(subject.errors).to include(:base)
    end

    it "can have a single lower bound" do
      subject.upper_bound = nil
      subject.lower_bound = 2
      expect(subject.valid?).to be true
    end

    it "can have a single upper bound" do
      subject.upper_bound = 10
      subject.lower_bound = nil
      expect(subject.valid?).to be true
    end

    it "has to have numbers for bounds" do
      subject.upper_bound = "foo"
      subject.lower_bound = { bar: :baz }
      expect(subject.valid?).to be false
      expect(subject.errors).to include(:upper_bound, :lower_bound)
    end

    it "has to have upper_bound > lower_bound" do
      subject.upper_bound = 10
      subject.lower_bound = 90
      expect(subject.valid?).to be false
      expect(subject.errors).to include(:base)
    end

    it "has to have non-negative bounds" do
      subject.upper_bound = -1
      subject.lower_bound = -3
      expect(subject.valid?).to be false
      expect(subject.errors).to include(:upper_bound, :lower_bound)
    end
  end
end
