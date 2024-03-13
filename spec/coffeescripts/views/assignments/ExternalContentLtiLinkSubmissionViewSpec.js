/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import ExternalContentLtiLinkSubmissionView from 'ui/features/submit_assignment/backbone/views/ExternalContentLtiLinkSubmissionView'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from 'helpers/fakeENV'

QUnit.module('ExternalContentLtiLinkSubmissionView', {
  setup() {
    const contentItem = {
      '@type': 'LtiLinkItem',
      url: 'http://lti.example.com/content/launch/42',
      comment: 'Foo all the bars!',
      lookup_uuid: '0b8fbc86-fdd7-4950-852d-ffa789b37ff2',
    }

    fakeENV.setup()
    window.ENV.COURSE_ID = 42
    window.ENV.SUBMIT_ASSIGNMENT = {ID: 24}
    this.model = new Backbone.Model(contentItem)
    this.view = new ExternalContentLtiLinkSubmissionView({
      externalTool: {},
      model: this.model,
    })
  },
  teardown() {
    fakeENV.teardown()
    $('#fixtures').empty()
  },
})

test("buildSubmission must return an object with submission_type set to 'basic_lti_launch'", function () {
  equal(this.view.buildSubmission().submission_type, 'basic_lti_launch')
})

test('buildSubmission must return an object with url set to the value from the supplied model', function () {
  equal(this.view.buildSubmission().url, this.model.get('url'))
})

test('buildSubmission must return an object with resource_link_lookup_uuid set to the value from the supplied model.', function () {
  equal(this.view.buildSubmission().resource_link_lookup_uuid, this.model.get('lookup_uuid'))
})

test("extractComment must return an object with the model's comment field", function () {
  equal(this.view.extractComment().text_comment, this.model.get('comment'))
})

test('submissionURL() must return a url with the correct shape', function () {
  equal(this.view.submissionURL(), '/api/v1/courses/42/assignments/24/submissions')
})
