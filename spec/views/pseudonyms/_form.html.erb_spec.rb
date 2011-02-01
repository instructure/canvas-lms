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

# <%= form.label :unique_id, "Login" %><br />
# <%= form.text_field :unique_id %><br />
# <br/>
# <%= label :user, :time_zone, "Time Zone" %><br/>
# <%= time_zone_select :user, :time_zone, TimeZone.us_zones, :default => "Mountain Time (US & Canada)" %><br/>
# <br />
# <%= form.label :password, form.object.new_record? ? nil : "Change password" %><br />
# <%= form.password_field :password %><br />
# <br />
# <%= form.label :password_confirmation%><br />
# <%= form.password_field :password_confirmation %><br />
# <br />