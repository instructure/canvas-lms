# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe NotificationFinder do
  let(:notification){ Notification.create!(name: "test notification")}
  let(:finder){ NotificationFinder.new([notification])}

  describe "#find_by_name and #by_name" do
    it 'finds a notification by name' do
      expect(finder.find_by_name(notification.name)).to eq(notification)
      expect(finder.by_name(notification.name)).to eq(notification)
    end

    it 'loads notifications from the cache' do
      expect(finder.notifications.length).to eq(1)
      expect(Notification).to receive(:connection).never
      finder.by_name(notification.name)
      finder.find_by_name(notification.name)
    end

    it 'freezes notifications so they cannot be modified' do
      expect(finder.find_by_name(notification.name).frozen?).to be(true)
    end
  end

  describe "#reset_cache" do
    it 'empties the cache' do
      expect(finder.notifications.count).to eq(1)
      finder.reset_cache
      expect(finder.notifications.count).to eq(0)
    end
  end
end
