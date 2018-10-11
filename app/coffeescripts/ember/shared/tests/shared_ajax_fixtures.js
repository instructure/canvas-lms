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

define [
  'ic-ajax'
  'ember'
], (ajax, Ember) ->

  clone = (obj) ->
    Ember.copy obj, true

  data = {
    attachment:
      file_state: '0'
      workflow_state: 'to_be_zipped'
      readable_size: '73 KB'
  }

  numbers = [1, 2, 3]

  create: ->
    window.ENV =
      {
        submission_zip_url: '/courses/1/assignments/1/submissions?zip=1'
        numbers_url: '/courses/1/numbers'
      }

    ajax.defineFixture window.ENV.submission_zip_url,
      response: clone data
      jqXHR: { getResponseHeader: -> {} }
      textStatus: 'success'

    ajax.defineFixture window.ENV.numbers_url,
      response: clone numbers
      jqXHR: { getResponseHeader: -> {} }
      textStatus: 'success'

  makeAvailable: ->
    data.attachment.file_state = 100
    data.attachment.workflow_state = 'available'
