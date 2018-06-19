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

import Backbone from 'Backbone'
import ExternalContentFileSubmissionView from 'compiled/views/assignments/ExternalContentFileSubmissionView'
import $ from 'jquery'
import fakeENV from 'helpers/fakeENV'
import axios from 'axios'

const contentItem = {
  '@type': 'FileItem',
  url: 'http://lti.example.com/content/launch/42',
  name: 'FileDude',
  comment: 'Foo all the bars!',
  eula_agreement_timestamp: 1522419910
}

let sandbox
let model
let view

QUnit.module('ExternalContentFileSubmissionView#uploadFileFromUrl', {
  setup () {
    sandbox = sinon.sandbox.create()
    fakeENV.setup()
    window.ENV.COURSE_ID = 42
    window.ENV.current_user_id = 5
    window.ENV.SUBMIT_ASSIGNMENT = {
      ID: 24
    }
    model = new Backbone.Model(contentItem)
    view = new ExternalContentFileSubmissionView
      externalTool: {}
      model: model
  },

  teardown () {
    fakeENV.teardown()
    $('#fixtures').empty()
    sandbox.restore()
  }
})

test("hits the course url", () => {
  const spy = sandbox.spy(axios, 'post')
  view.uploadFileFromUrl({}, model)
  ok(spy.calledWith('/api/v1/courses/42/assignments/24/submissions/5/files'))
})

test("hits the group url", () => {
  window.ENV.SUBMIT_ASSIGNMENT.GROUP_ID_FOR_USER = 2

  const spy = sandbox.spy(axios, 'post')
  view.uploadFileFromUrl({}, model)
  ok(spy.calledWith('/api/v1/groups/2/files'))
})

test("sends the eula agreement timestamp to the submission endpoint", () => {
  const spy = sandbox.spy(axios, 'post')
  view.uploadFileFromUrl({}, model)
  equal(spy.args[0][1].eula_agreement_timestamp, model.get('eula_agreement_timestamp'))
  ok(spy.calledWith('/api/v1/courses/42/assignments/24/submissions/5/files'))
})
