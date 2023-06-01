# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require_relative "../spec_helper"

describe BrandAccountChainResolver do
  let(:user) { user_with_pseudonym }

  context "with no associated accounts" do
    it "returns an empty chain" do
      expect(subject(Account.create!(name: "A"))).to be_nil
    end
  end

  #
  # A
  # ^
  #
  context "with no active enrollments and no sub-accounts..." do
    it "chooses the root account" do
      accounts = create_accounts_and_associate(
        [
          [:A]
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("A")
    end

    it "ignores accounts the user is not associated with" do
      a = Account.create!(name: "A")
      b = Account.create!(name: "B")

      user.user_account_associations.create!(account: a, depth: 0)

      expect(subject(a).try(&:name)).to eql("A")
      expect(subject(b).try(&:name)).to be_nil
    end
  end

  #
  # A-B
  #   ^
  #
  context "with no active enrollments and no branches..." do
    it "chooses the node farther from the root" do
      accounts = create_accounts_and_associate(
        [
          [:A],
          [:B, :A]
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("B")
    end
  end

  #
  #     /-C
  # A-B-
  #   ^ \-D
  #
  #
  context "with no active enrollments and a branch..." do
    it "chooses the branch" do
      accounts = create_accounts_and_associate(
        [
          [:A],
          [:B, :A],
          [:C, :B],
          [:D, :B],
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("B")
    end
  end

  #
  #         /-D
  #     /-C-
  # A-B-    \-E
  #   ^ \-F
  #
  context "with no active enrollments and multiple branches..." do
    it "chooses the branch closer to the root" do
      accounts = create_accounts_and_associate(
        [
          [:A],
          [:B, :A],
          [:C, :B],
          [:D, :C],
          [:E, :C],
          [:F, :B]
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("B")
    end
  end

  #       /-D
  #   /-B-
  # A-    \-E
  # ^ \-C
  #
  context "with no active enrollments and an immediate branch..." do
    it "chooses the branch closer to the root" do
      accounts = create_accounts_and_associate(
        [
          [:A],
          [:B, :A],
          [:D, :B],
          [:E, :B],
          [:C, :A]
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("A")
    end
  end

  #
  # A-B-C*-D
  #     ^
  #
  context "with one active enrollment..." do
    it "chooses that node" do
      accounts = create_accounts_and_associate(
        [
          [:A],
          [:B, :A],
          [:C, :B, enroll: true],
          [:D, :C],
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("C")
    end
  end

  #
  #     /-C-E
  # A-B-
  #     \-D*
  #       ^
  #
  context "with one active enrollment in a branch..." do
    it "chooses that node" do
      accounts = create_accounts_and_associate(
        [
          [:A],
          [:B, :A],
          [:C, :B],
          [:D, :B, enroll: true],
          [:E, :C],
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("D")
    end
  end

  #
  #   /-E /-C
  #   /-B-
  # A-    \-D
  #   \-F-G*
  #       ^
  #
  context "with one active enrollment in one of many branches..." do
    it "chooses the path to that point" do
      accounts = create_accounts_and_associate(
        [
          [:A],
          [:B, :A],
          [:C, :B],
          [:D, :B],
          [:E, :A],
          [:F, :A],
          [:G, :F, { enroll: true }],
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("G")
    end
  end

  #
  # A-B*-C*-D*
  #   ^
  #
  context "with multiple active enrollments..." do
    it "chooses the enrollment node closer to the root" do
      accounts = create_accounts_and_associate(
        [
          [:A],
          [:B, :A, { enroll: true }],
          [:C, :B, { enroll: true }],
          [:D, :C, { enroll: true }],
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("B")
    end
  end

  #
  # A*-B*-C*-D*
  # ^
  #
  context "with multiple active enrollments even at the root..." do
    it "chooses the root" do
      accounts = create_accounts_and_associate(
        [
          [:A, nil, { enroll: true }],
          [:B, :A, { enroll: true }],
          [:C, :B, { enroll: true }],
          [:D, :C, { enroll: true }],
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("A")
    end
  end

  # ideally we want it to be D, but it's hard, so we'll stick to "B" since it's
  # a branching point:
  #
  #     /-C-E
  # A-B-
  #   ^ \-D*-F*
  #
  #
  context "with multiple active enrollments in a specific branch..." do
    it "chooses the enrollment branching point closer to the root" do
      accounts = create_accounts_and_associate(
        [
          [:A],
          [:B, :A],
          [:C, :B],
          [:E, :C],
          [:D, :B, { enroll: true }],
          [:F, :D, { enroll: true }],
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("B")
    end
  end

  #
  #      /-C
  # A-B*-
  #   ^  \-D*
  #
  context "with multiple active enrollments starting at a branching point..." do
    it "chooses the branching point" do
      accounts = create_accounts_and_associate(
        [
          [:A],
          [:B, :A, { enroll: true }],
          [:C, :B],
          [:D, :B, { enroll: true }],
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("B")
    end
  end

  #
  #   /-B-D*
  # A-
  # ^ \-C-E*
  #
  context "with multiple active enrollments across different sides of an immediate branch..." do
    it "chooses the branching point" do
      accounts = create_accounts_and_associate(
        [
          [:A],
          [:B, :A],
          [:C, :A],
          [:D, :B, { enroll: true }],
          [:E, :C, { enroll: true }],
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("A")
    end
  end

  #
  #     /-C-D*
  # A-B-
  #   ^ \-E-F-G*
  #
  context "with multiple active enrollments across different sides of a branch..." do
    it "chooses the branching point closer to the root" do
      accounts = create_accounts_and_associate(
        [
          [:A],
          [:B, :A],
          [:C, :B],
          [:D, :C, { enroll: true }],
          [:E, :B],
          [:F, :E],
          [:G, :F, { enroll: true }]
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("B")
    end
  end

  #
  #     /-C-D*
  # A-B-
  #   ^ \-E*-F-G*
  #
  context "with multiple active enrollments across unevenly-weighted sides of a branch..." do
    it "chooses the branching point closer to the root" do
      accounts = create_accounts_and_associate(
        [
          [:A],
          [:B, :A],
          [:C, :B],
          [:D, :C, { enroll: true }],
          [:E, :B, { enroll: true }],
          [:F, :E],
          [:G, :F, { enroll: true }]
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("B")
    end
  end

  # again, ideally it should be D, but it's hard, so we'll stick to the first
  # branching point "B":
  #
  #     /-C
  # A-B-     /-E
  #   ^ \-D*-
  #          \-F-G*
  #
  context "with multiple active enrollments within a single branch..." do
    it "chooses the branching point closer to the root that is also an enrollment node" do
      accounts = create_accounts_and_associate(
        [
          [:A],
          [:B, :A],
          [:C, :B],
          [:D, :B, { enroll: true }],
          [:E, :D],
          [:F, :D],
          [:G, :F, { enroll: true }]
        ]
      )

      expect(subject(accounts[:A]).try(&:name)).to eql("B")
    end
  end

  def subject(account)
    described_class.new(
      user:,
      root_account: account
    ).resolve
  end

  def create_accounts_and_associate(accounts_and_parents)
    accounts_and_parents.each_with_object({}) do |(name, parent, *opts), acc|
      opts = opts.first || {}
      acc[name] = Account.create!(
        name:,
        parent_account: parent ? acc.fetch(parent) : nil
      )

      user.user_account_associations.create!(
        account: acc[name],
        depth: acc[name].account_chain.length - 1
      )

      next unless opts[:enroll] == true

      course_with_student(
        user:,
        account: acc[name],
        active_all: true
      )
    end
  end
end
