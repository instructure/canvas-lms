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

require File.expand_path(File.dirname(__FILE__) + "/../../../spec_helper.rb")

describe Canvas::Cdn::Registry do
  subject do
    described_class.new(
      cache: Canvas::Cdn::Registry::StaticCache.new(
        gulp: @gulp_manifest || {},
        webpack: @webpack_manifest || {}
      )
    )
  end

  describe ".statics_available?" do
    it "is true when the gulp manifest is available" do
      @gulp_manifest = { "foo" => "bar" }

      expect(subject.statics_available?).to be(true)
    end

    it "is false otherwise" do
      expect(subject.statics_available?).to be(false)
    end
  end

  describe ".scripts_available?" do
    it "is true when the webpack manifest is available" do
      @webpack_manifest = { "foo" => "bar" }

      expect(subject.scripts_available?).to be(true)
    end

    it "is false otherwise" do
      expect(subject.scripts_available?).to be(false)
    end
  end

  describe ".url_for" do
    it "works for gulp assets" do
      @gulp_manifest = { "images/foo.png" => "images/foo-1234.png" }

      expect(subject.url_for("/images/foo.png")).to eq(
        "/dist/images/foo-1234.png"
      )
    end
  end

  describe ".include?" do
    it "is true given the path to an asset processed by gulp" do
      @gulp_manifest = { "images/foo.png" => "images/foo-1234.png" }

      expect(subject.include?("/dist/images/foo-1234.png")).to be(true)
      expect(subject.include?("images/foo-1234.png")).to be(false)
      expect(subject.include?("images/foo.png")).to be(false)
    end

    it "is true given the path to a javascript produced by webpack" do
      @webpack_manifest = { "main" => "a-1234.js" }

      expect(subject.include?("/dist/webpack-dev/a-1234.js")).to be(true)
      expect(subject.include?("a-1234.js")).to be(false)
      expect(subject.include?("main")).to be(false)
    end
  end

  describe ".scripts_for" do
    it "returns realpaths to files within the bundle" do
      @webpack_manifest = { "main" => "a-1234.js" }

      expect(subject.scripts_for("main")).to eq(
        [
          "/dist/webpack-dev/a-1234.js"
        ]
      )
    end
  end

  describe ".entries" do
    it "returns realpaths to entries within the bundle" do
      @webpack_manifest = { "main" => "a-entry-1234.js" }

      expect(subject.entries).to eq(
        [
          "/dist/webpack-dev/a-entry-1234.js"
        ]
      )
    end

    it "does not include .map.js files" do
      @webpack_manifest = {
        "main" => "a-entry-1234.js",
        "foo" => "a-entry-1234.map.js",
        "bar" => "a-entry-1234.js.map.js"
      }

      expect(subject.entries).to eq(
        [
          "/dist/webpack-dev/a-entry-1234.js"
        ]
      )
    end
  end
end
