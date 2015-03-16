#
# Copyright (C) 2011 Instructure, Inc.
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

def external_feed_model(opts={}, do_save=true)
  factory_with_protected_attributes(ExternalFeed, valid_external_feed_attributes.merge(opts), do_save)
end

def valid_external_feed_attributes
  {
    :context => @course || Account.default.courses.create!,
    :title => "some feed",
    :url => "http://www.nowhere.com",
    :created_at => Time.parse("Jan 1 2000"),
  }
end
