//
// Copyright (C) 2014 - present Instructure, Inc.
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

import {Model, Collection} from '@canvas/backbone'
import natcompare from '@canvas/util/natcompare'

export default class Group extends Model {
  initialize() {
    return this.set('outcomes', new Collection([], {comparator: natcompare.byGet('friendly_name')}))
  }

  count() {
    return this.get('outcomes').length
  }

  statusCount(status) {
    return this.get('outcomes').filter(x => x.status() === status).length
  }

  mastery_count() {
    return this.statusCount('mastery') + this.statusCount('exceeds')
  }

  remedialCount() {
    return this.statusCount('remedial')
  }

  undefinedCount() {
    return this.statusCount('undefined')
  }

  status() {
    if (this.remedialCount() > 0) {
      return 'remedial'
    } else if (this.mastery_count() === this.count()) {
      return 'mastery'
    } else if (this.undefinedCount() === this.count()) {
      return 'undefined'
    } else {
      return 'near'
    }
  }

  started() {
    return true
  }

  toJSON() {
    return {
      ...super.toJSON(...arguments),
      count: this.count(),
      mastery_count: this.mastery_count(),
      started: this.started(),
      status: this.status(),
    }
  }
}
