/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Backbone from '@canvas/backbone'
import ExternalContentFileSubmissionView from '../ExternalContentFileSubmissionView'
import $ from 'jquery'
import '@canvas/jquery/jquery.disableWhileLoading'
import '@canvas/rails-flash-notifications'
import fakeENV from '@canvas/test-utils/fakeENV'
import axios from '@canvas/axios'

jest.mock('@canvas/util/globalUtils', () => ({
  windowAlert: jest.fn(),
  reloadWindow: jest.fn(),
}))

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const contentItem = {
  '@type': 'FileItem',
  url: 'http://lti.example.com/content/launch/42',
  name: 'FileDude',
  comment: 'Foo all the bars!',
  eula_agreement_timestamp: 1522419910,
}

let model
let view

describe('ExternalContentFileSubmissionView#uploadFileFromUrl', () => {
  beforeEach(() => {
    fakeENV.setup()
    window.ENV.COURSE_ID = 42
    window.ENV.current_user_id = 5
    window.ENV.SUBMIT_ASSIGNMENT = {
      ID: 24,
    }
    model = new Backbone.Model(contentItem)
    const el = $('<div><button class="submit_button">Submit</button></div>')
    $('#fixtures').append(el)
    view = new ExternalContentFileSubmissionView({el})
  })

  afterEach(() => {
    fakeENV.teardown()
    $('#fixtures').empty()
    jest.restoreAllMocks()
  })

  test('hits the course url', () => {
    const spy = jest.spyOn(axios, 'post').mockResolvedValue({data: {upload_url: null}})
    view.uploadFileFromUrl({}, model)
    expect(spy).toHaveBeenCalledWith(
      '/api/v1/courses/42/assignments/24/submissions/5/files',
      expect.anything(),
    )
  })

  test('hits the group url', () => {
    window.ENV.SUBMIT_ASSIGNMENT.GROUP_ID_FOR_USER = 2

    const spy = jest.spyOn(axios, 'post').mockResolvedValue({data: {upload_url: null}})
    view.uploadFileFromUrl({}, model)
    expect(spy).toHaveBeenCalledWith(
      '/api/v1/groups/2/files?assignment_id=24&submit_assignment=1',
      expect.anything(),
    )
  })

  test('sends the eula agreement timestamp to the submission endpoint', () => {
    const spy = jest.spyOn(axios, 'post').mockResolvedValue({data: {upload_url: null}})
    view.uploadFileFromUrl({}, model)
    expect(spy).toHaveBeenCalledWith(
      '/api/v1/courses/42/assignments/24/submissions/5/files',
      expect.objectContaining({
        eula_agreement_timestamp: model.get('eula_agreement_timestamp'),
      }),
    )
  })

  test('sends the comment to the submission endpoint', () => {
    const spy = jest.spyOn(axios, 'post').mockResolvedValue({data: {upload_url: null}})
    view.uploadFileFromUrl({}, model)
    expect(spy).toHaveBeenCalledWith(
      '/api/v1/courses/42/assignments/24/submissions/5/files',
      expect.objectContaining({
        comment: model.get('comment'),
      }),
    )
  })
})
