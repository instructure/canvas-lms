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

require "spec_helper"

describe I18nTasks::Extract do
  def subject(rb: {}, js: {})
    described_class.new(
      rb_translations: rb.with_indifferent_access,
      js_translations: js
    ).apply
  end

  it "combines Ruby and JavaScript translations into a hierarchical dict" do
    expect(
      subject(
        rb: { from_ruby: { a: "A" } },
        js: { from_js: { a: "A" } }
      )
    ).to eq(
      {
        "from_ruby" => { "a" => "A" },
        "from_js" => { "a" => "A" }
      }
    )
  end

  it "sorts keys alphabetically" do
    expect(
      subject(
        rb: { c: "C" },
        js: { "b" => "B", "a" => "A" }
      ).keys
    ).to eq(%w[a b c])
  end

  it "removes date.order" do
    expect(
      subject(rb: { date: { order: %w[year month day] } })
    ).to eq({ "date" => {} })
  end

  it "removes Proc-like values" do
    expect(
      subject(rb: { date: { nth: proc { "1st" } } })
    ).to eq({ "date" => {} })
  end

  it "removes meta non-translation keys" do
    meta = [
      { bigeasy_locale: "ar_SA" },
      { crowdsourced: true },
      { custom: "???" },
      { fullcalendar_locale: "da" },
      { locales: { "da-x-k12": "Dansk GR/GY" } },
      { moment_locale: "da" },
    ]

    meta.each do |entry|
      expect(subject(rb: entry)).to eq({})
    end
  end
end
