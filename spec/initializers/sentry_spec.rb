# frozen_string_literal: true

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

describe "sentry" do
  it "initializes with a default config so that methods may be safely called" do
    expect do
      Sentry.set_tags(tag1: "value1")
      Sentry.set_user(id: 5)
      Sentry.set_extras(debug: true)
      Sentry.set_context("exta", { key1: "value1" })
    end.not_to raise_error
  end

  context "on Canvas reload" do
    before do
      Sentry.configuration.sample_rate = 1.0
    end

    it "sets the new errors sample rate" do
      Setting.set("sentry_backend_errors_sample_rate", "0.5")

      expect(Sentry.configuration.sample_rate).to eq(1.0)
      Canvas::Reloader.reload!
      expect(Sentry.configuration.sample_rate).to eq(0.5)
    end
  end
end
