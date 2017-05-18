#
# Copyright (C) 2016 - present Instructure, Inc.
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

define [
  'compiled/notifications/NotificationPreferences'
], (NotificationPreferences) ->

  QUnit.module "NotificationPreferences"

  test 'tooltip instance was added', ->
    options = { update_url: "/profile/communication_update" }
    nps = new NotificationPreferences(options)
    $np = $('#notification-preferences')
    freq = $np.find('.frequency')
    inst = $(freq).tooltip('instance')
    notEqual(inst, undefined)

  test 'policyCellProps with email', ->
    options = { update_url: "/profile/communication_update" }
    nps = new NotificationPreferences(options)
    category = {category: "helloworld"}
    channel = {type: "email", id: 42}
    props = nps.policyCellProps(category, channel)
    equal(props.buttonData.length, 4)

  test 'policyCellProps with sms', ->
    options = { update_url: "/profile/communication_update" }
    nps = new NotificationPreferences(options)
    category = {category: "helloworld"}
    channel = {type: "sms", id: 42}
    props = nps.policyCellProps(category, channel)
    equal(props.buttonData.length, 2)

  test 'policyCellProps with twitter', ->
    options = { update_url: "/profile/communication_update" }
    nps = new NotificationPreferences(options)
    category = {category: "helloworld"}
    channel = {type: "twitter", id: 42}
    props = nps.policyCellProps(category, channel)
    equal(props.buttonData.length, 2)

  test 'policyCellProps with sms', ->
    options = { update_url: "/profile/communication_update" }
    nps = new NotificationPreferences(options)
    category = {category: "helloworld"}
    channel = {type: "sms", id: 42}
    props = nps.policyCellProps(category, channel)
    equal(props.buttonData.length, 2)
