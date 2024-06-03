# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

BYROLE_FIXTURE_BASE = File.expand_path("fixtures/by_role_linter/__tests__/", __dir__)
VALID_FILES = %w[valid.js valid.ts valid.tsx valid.jsx].map { |f| BYROLE_FIXTURE_BASE + "/" + f }
CHANGE_LINE_NUMBERS = [25, 29, 33, 37, 41, 45].freeze

describe TatlTael::Linters::ByRoleLinter do
  let(:config) do
    config = TatlTael::Linters.config_for_linter(described_class)
    config[:precondition][:allowlist] = {}
    config
  end
  let(:status) { "added" }
  let(:raw_changes) do
    VALID_FILES.map do |fixture_path|
      { path: fixture_path, path_from_root: fixture_path, status: }
    end
  end
  let(:changes) { raw_changes.map { |c| double(c) } }
  let(:diff) do
    diff = {}
    VALID_FILES.map do |file|
      diff[file] = { context: [], change: CHANGE_LINE_NUMBERS }
    end
    diff
  end
  let(:linter) { described_class.new(changes:, config:, diff:) }

  it "comments on lines with by_role" do
    expect(linter.run).to eq(
      VALID_FILES.map do |file|
        CHANGE_LINE_NUMBERS.map do |line_number|
          {
            path: file,
            message: config[:message],
            severity: config[:severity],
            position: line_number,
            ignore_boyscout_severity_change: true
          }
        end
      end.flatten
    )
  end

  context "when files are deleted" do
    let(:status) { "deleted" }

    it "does not comment" do
      expect(linter.run).to be_empty
    end
  end

  context "when there are no changes" do
    let(:raw_changes) { {} }

    it "does not comment" do
      expect(linter.run).to be_empty
    end
  end

  context "when there are no by_role lines" do
    let(:diff) do
      diff = {}
      VALID_FILES.map do |file|
        diff[file] = { context: [], change: CHANGE_LINE_NUMBERS.map { |n| n + 1 } }
      end
      diff
    end

    it "does not comment" do
      expect(linter.run).to be_empty
    end
  end

  context "when files are modified" do
    let(:status) { "modified" }

    it "does comment" do
      expect(linter.run).to eq(
        VALID_FILES.map do |file|
          CHANGE_LINE_NUMBERS.map do |line_number|
            {
              path: file,
              message: config[:message],
              severity: config[:severity],
              position: line_number,
              ignore_boyscout_severity_change: true
            }
          end
        end.flatten
      )
    end
  end

  context "when files are outside of __tests__" do
    let(:raw_changes) do
      VALID_FILES.map do |fixture_path|
        {
          path: fixture_path.gsub("__tests__", "not_tests"),
          path_from_root: fixture_path,
          status:
        }
      end
    end

    it "does not comment" do
      expect(linter.run).to be_empty
    end
  end

  context "when diff includes lines without byRole" do
    let(:diff) do
      diff = {}
      VALID_FILES.map do |file|
        diff[file] = { context: [], change: CHANGE_LINE_NUMBERS + [CHANGE_LINE_NUMBERS.last + 1] }
      end
      diff
    end

    it "comments only on lines with by_role" do
      expect(linter.run).to eq(
        VALID_FILES.map do |file|
          CHANGE_LINE_NUMBERS.map do |line_number|
            {
              path: file,
              message: config[:message],
              severity: config[:severity],
              position: line_number,
              ignore_boyscout_severity_change: true
            }
          end
        end.flatten
      )
    end
  end

  context "when files are both added and modified" do
    let(:raw_changes) do
      VALID_FILES.map.with_index do |fixture_path, index|
        {
          path: fixture_path,
          path_from_root: fixture_path,
          status: index.even? ? "added" : "modified"
        }
      end
    end

    it "does comment on added and modified files" do
      expect(linter.run).to eq(
        VALID_FILES.map do |file|
          CHANGE_LINE_NUMBERS.map do |line_number|
            {
              path: file,
              message: config[:message],
              severity: config[:severity],
              position: line_number,
              ignore_boyscout_severity_change: true
            }
          end
        end.flatten
      )
    end
  end
end
