# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe I18nTasks::GenerateJs do
  def provide(translations)
    translations.each do |key, value|
      expect(I18n).to receive(:translate!)
        .with(key.to_sym, { locale: "en", raise: true })
        .and_return(value)
    end
  end

  before do
    I18nTasks::CORE_KEYS.each do |key|
      allow(I18n).to receive(:translate!)
        .with(key.to_sym, { locale: "en", raise: true })
        .and_return({})
    end
  end

  describe "#translations" do
    it "produces a map of fully-qualified keys to their translations" do
      provide("a.some_phrase" => "kek")
      provide("b.some_phrase" => "bur")

      subject = described_class.new(
        index: [
          {
            "key" => "a.some_phrase",
            "scope" => "a"
          },
          {
            "key" => "b.some_phrase",
            "scope" => "b"
          }
        ]
      ).translations("en")

      expect(subject).to eq(
        {
          "a.some_phrase" => "kek",
          "b.some_phrase" => "bur",
        }
      )
    end

    it "conforms with I18n pluralization interface" do
      provide("a.some_phrase.one" => "kek")
      provide("a.some_phrase.other" => "bur")

      subject = described_class.new(
        index: [
          {
            "key" => "a.some_phrase.one",
            "scope" => "a"
          },
          {
            "key" => "a.some_phrase.other",
            "scope" => "a"
          }
        ]
      ).translations("en")

      expect(subject).to eq(
        {
          "a.some_phrase" => {
            "one" => "kek",
            "other" => "bur"
          }
        }
      )
    end

    it "sorts phrases by their keys" do
      provide(
        "date.datepicker.column_headings" => ["1", "2"],
        "scope.a" => "A",
        "scope.b" => "B",
        "scope.c" => "C"
      )

      subject = described_class.new(
        index: [
          {
            "key" => "date.datepicker.column_headings",
            "scope" => "date",
          },

          {
            "key" => "scope.c",
            "scope" => "scope"
          },
          {
            "key" => "scope.a",
            "scope" => "scope"
          },
          {
            "key" => "scope.b",
            "scope" => "scope"
          },
        ]
      ).translations("en")

      expect(subject.keys).to eq(
        %w[
          date.datepicker.column_headings
          scope.a
          scope.b
          scope.c
        ]
      )
    end

    it "omits phrases that have no translation" do
      allow(I18n).to receive(:translate!)
        .with(:"scope.missing_translation", anything)
        .and_raise(I18n::MissingTranslationData.new("", ""))

      subject = described_class.new(
        index: [
          {
            "key" => "scope.missing_translation",
            "scope" => "scope"
          }
        ]
      ).translations("en")

      expect(subject).to eq({})
    end

    it "extracts CORE_KEYS" do
      provide(
        "date" => {
          formats: {
            date_at_time: "%b %-d %k:%M"
          },
          abbr_month_names: %w[Ion Chwe Maw],
          time: {
            event: "%{date} am %{time}",
            formats: {
              tiny: "%k:%M",
              tiny_on_the_hour: "%k:%M",
            }
          }
        }
      )

      subject = described_class.new(index: []).translations("en")
      expect(subject).to eq(
        {
          "date.abbr_month_names" => %w[Ion Chwe Maw],
          "date.formats.date_at_time" => "%b %-d %k:%M",
          "date.time.event" => "%{date} am %{time}",
          "date.time.formats.tiny" => "%k:%M",
          "date.time.formats.tiny_on_the_hour" => "%k:%M",
        }
      )
    end
  end
end
