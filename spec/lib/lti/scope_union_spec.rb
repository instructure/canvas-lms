# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe Lti::ScopeUnion do
  subject { described_class.new(scopes) }

  let(:course) { course_model }
  let(:course2) { course_model }

  let(:scopes) do
    course # create this first so order(:id) will find this first
    course2
    [
      Course.where(id: course2.id),
      Course.where(id: -1),
      Course.where(id: [course.id, course2.id]).order(:id)
    ]
  end

  describe "#exists?" do
    it "returns true if exists? is true in any scope" do
      s1 = Course.where(id: -1)
      s2 = Course.where(id: course.id)
      s3 = Course.where(id: -2)
      expect(described_class.new([s1, s2, s3]).exists?).to be(true)
      expect(described_class.new([s1, s3]).exists?).to be(false)
    end
  end

  describe "#to_unsorted_array" do
    let(:scopes) { [Course.where(id: course.id), Account.where(id: course.account_id)] }

    it "concatenates the results of to_a of all the scopes" do
      expect(subject.to_unsorted_array).to eq([course, course.account])
    end
  end

  describe "#take" do
    let(:scopes) do
      course
      course2
      [
        Course.where(id: -1),
        Course.where(id: course2.id),
        Course.where(id: course.id)
      ]
    end

    it "takes the first matching item" do
      expect(subject.take).to eq(course2)
    end

    it "stops taking once it found an item" do
      allow(scopes[1]).to receive(:take).and_return("abc")
      allow(scopes[2]).to receive(:take).and_raise("boom")
      expect(subject.take).to eq("abc")
    end
  end

  describe "#each" do
    it "runs the block on each result of each scope" do
      results = []
      subject.each { |obj| results << obj } # rubocop:disable Style/MapIntoArray
      expect(results).to eq([course2, course, course2])
    end
  end

  describe "#pluck" do
    it "concatenates the results of pluck from each scope" do
      expect(subject.pluck(:name, :id)).to eq([
                                                [course2.name, course2.id],
                                                [course.name, course.id],
                                                [course2.name, course2.id]
                                              ])
    end
  end
end
