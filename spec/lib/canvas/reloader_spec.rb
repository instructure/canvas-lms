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

describe Canvas::Reloader do
  it "calls registered callbacks" do
    callback_count = 0
    Canvas::Reloader.on_reload { callback_count += 1 }
    Canvas::Reloader.reload!
    expect(callback_count).to eq 1
  end

  describe ".reload" do
    after do
      Canvas::Reloader.instance_variable_set(:@reload_at, nil)
    end

    it "defers reloading until reload_at has passed" do
      expect(Canvas::Reloader).not_to receive(:reload!)
      Canvas::Reloader.instance_variable_set(:@reload_at, Process.clock_gettime(Process::CLOCK_MONOTONIC) + 60)

      Canvas::Reloader.reload
    end

    it "reloads once reload_at has passed" do
      expect(Canvas::Reloader).to receive(:reload!)
      Canvas::Reloader.instance_variable_set(:@reload_at, Process.clock_gettime(Process::CLOCK_MONOTONIC) - 10)

      Canvas::Reloader.reload
    end

    it "does not reload when no reload is pending" do
      expect(Canvas::Reloader).not_to receive(:reload!)

      Canvas::Reloader.reload
    end
  end
end
