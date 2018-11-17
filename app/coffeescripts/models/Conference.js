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

import _ from 'underscore'
import {Model} from 'Backbone'

export default class Conference extends Model {
  urlRoot() {
    const url = this.get('url')
    return url.replace(/([^\/]*$)/, '')
  }

  special_urls() {
    return {
      join_url: `${this.get('url')}/join`,
      close_url: `${this.get('url')}/close`
    }
  }

  recordings_data() {
    return {
      recording: this.get('recordings')[0],
      recordingCount: this.get('recordings').length,
      multipleRecordings: this.get('recordings').length > 1
    }
  }

  permissions_data() {
    return {
      has_actions: this.get('permissions').update || this.get('permissions').delete,
      show_end: this.get('permissions').close && this.get('started_at') && !this.get('ended_at')
    }
  }

  schedule_data() {
    return {
      scheduled: 'scheduled_date' in this.get('user_settings'),
      scheduled_at: this.get('user_settings').scheduled_date
    }
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    for (const attr of ['special_urls', 'recordings_data', 'schedule_data', 'permissions_data']) {
      _.extend(json, this[attr]())
    }
    json.isAdobeConnect = json.conference_type === 'AdobeConnect'
    return json
  }
}
