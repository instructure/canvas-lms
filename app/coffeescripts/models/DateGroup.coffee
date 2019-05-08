#
# Copyright (C) 2013 - present Instructure, Inc.
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

import Backbone from 'Backbone'
import I18n from 'i18n!models_DateGroup'
import tz from 'timezone'

export default class DateGroup extends Backbone.Model

  defaults:
    title: I18n.t('everyone_else', 'Everyone else')
    due_at: null
    unlock_at: null
    lock_at: null

  dueAt: ->
    dueAt = @get("due_at")
    if dueAt then tz.parse(dueAt) else null

  unlockAt: ->
    unlockAt = @get("unlock_at")
    if unlockAt then tz.parse(unlockAt) else null

  lockAt: ->
    lockAt = @get("lock_at")
    if lockAt then tz.parse(lockAt) else null

  now: ->
    now = @get("now")
    if now then tz.parse(now) else new Date()


  # no lock/unlock dates
  alwaysAvailable: ->
    !@unlockAt() && !@lockAt()

  # not unlocked yet
  pending: ->
    unlockAt = @unlockAt()
    unlockAt && unlockAt > @now()

  # available and won't ever lock
  available: ->
    @alwaysAvailable() || (!@lockAt() && @unlockAt() < @now())

  # available, but will lock at some point
  open: ->
    @lockAt() && !@pending() && !@closed()

  # locked
  closed: ->
    lockAt = @lockAt()
    lockAt && lockAt < @now()


  toJSON: ->
    dueFor: @get("title")
    dueAt: @dueAt()
    unlockAt: @unlockAt()
    lockAt: @lockAt()
    available: @available()
    pending: @pending()
    open: @open()
    closed: @closed()
