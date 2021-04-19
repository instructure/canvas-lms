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

import ajax from 'ic-ajax'
import Ember from 'ember'

const clone = obj => Ember.copy(obj, true)

const data = {
  attachment: {
    file_state: '0',
    workflow_state: 'to_be_zipped',
    readable_size: '73 KB'
  }
}

const numbers = [1, 2, 3]

export default {
  create() {
    window.ENV = {
      submission_zip_url: '/courses/1/assignments/1/submissions?zip=1',
      numbers_url: '/courses/1/numbers'
    }

    ajax.defineFixture(window.ENV.submission_zip_url, {
      response: clone(data),
      jqXHR: {
        getResponseHeader() {
          return {}
        }
      },
      textStatus: 'success'
    })

    return ajax.defineFixture(window.ENV.numbers_url, {
      response: clone(numbers),
      jqXHR: {
        getResponseHeader() {
          return {}
        }
      },
      textStatus: 'success'
    })
  },

  makeAvailable() {
    data.attachment.file_state = 100
    return (data.attachment.workflow_state = 'available')
  }
}
