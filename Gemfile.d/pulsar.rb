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

# this group is only necessary if you're going to be sending
# and consuming messages through pulsar as a message bus.
# Right now some areas of canvas like AssetUserAccess log compaction
# do this, but no critical/required areas, so you could
# opt out by not flipping the config that would enable code
# paths that use "Bundler.require(:pulsar)"
#
# If you're looking here because you're having trouble installing
# this gem and you don't think you need pulsar, then you should actually
# be running `bundle install --without pulsar` to just skip it.
group :pulsar do
  gem "pulsar-client", "2.6.1.pre.beta.2"
end