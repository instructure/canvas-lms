/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import $ from 'jquery'
import Backbone from '@canvas/backbone'
import ExternalToolLaunchView from '../ExternalToolLaunchView'
import {isAccessible} from '@canvas/test-utils/jestAssertions'
import sinon from 'sinon'

const sandbox = sinon.createSandbox()
const deepEqual = (x, y) => expect(x).toEqual(y)
const strictEqual = (x, y) => expect(x).toStrictEqual(y)

const ok = x => expect(x).toBeTruthy()

let mockMigration
let mockReturnView
let launchView

describe('ExternalToolLaunchView', () => {
  beforeEach(() => {
    mockMigration = new Backbone.Model()
    mockReturnView = new Backbone.View()
    launchView = new ExternalToolLaunchView({
      contentReturnView: mockReturnView,
      model: mockMigration,
    })
    $('#fixtures').html(launchView.render().el)
  })

  afterEach(() => {
    launchView.remove()
  })

  test('it should be accessible', function (done) {
    isAccessible(launchView, done, {a11yReport: true})
  })

  test('calls render on return view when launch button clicked', function () {
    sandbox.stub(mockReturnView, 'render').returns(this)
    launchView.$el.find('#externalToolLaunch').click()
    ok(mockReturnView.render.calledOnce, 'render not called on return view')
  })

  test("displays file name on 'ready'", function () {
    mockReturnView.trigger('ready', {
      contentItems: [
        {
          text: 'data text',
          url: 'data url',
        },
      ],
    })
    strictEqual(launchView.$fileName.text(), 'data text')
  })

  test("sets settings.data_url on migration on 'ready'", function () {
    mockReturnView.trigger('ready', {
      contentItems: [
        {
          text: 'data text',
          url: 'data url',
        },
      ],
    })
    deepEqual(mockMigration.get('settings'), {file_url: 'data url'})
  })
})
