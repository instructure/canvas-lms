//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import _ from 'underscore'

import PaginatedCollection from '../collections/PaginatedCollection'
import Message from '../models/Message'

export default class MessageCollection extends PaginatedCollection {
  comparator(a, b) {
    const dates = _.map([a, b], message => message.timestamp().getTime())
    if (dates[0] > dates[1]) {
      return -1
    }
    if (dates[1] > dates[0]) {
      return 1
    }
    return 0
  }

  selectRange(model) {
    const newPos = this.indexOf(model)
    const lastSelected = _.last(this.view.selectedMessages)
    this.each(x => x.set('selected', false))
    const lastPos = this.indexOf(lastSelected)
    const range = this.slice(Math.min(newPos, lastPos), Math.max(newPos, lastPos) + 1)
    // the anchor needs to stay at the end
    if (newPos > lastPos) {
      range.reverse()
    }
    return _.each(range, x => x.set('selected', true))
  }
}
MessageCollection.prototype.model = Message

MessageCollection.prototype.url = '/api/v1/conversations'

MessageCollection.prototype.params = {scope: 'inbox'}
