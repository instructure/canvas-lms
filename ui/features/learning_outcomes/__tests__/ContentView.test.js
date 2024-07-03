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
import ContentView from '@canvas/outcomes/content-view/backbone/views/index'
import fakeENV from '@canvas/test-utils/fakeENV'
import instructionsTemplate from '../jst/mainInstructions.handlebars'
import {isAccessible} from '@canvas/test-utils/jestAssertions'
import {publish} from 'jquery-tinypubsub'

const fixtures = document.createElement('div')
fixtures.setAttribute('id', 'fixtures')
document.body.appendChild(fixtures)

const ok = value => expect(value).toBeTruthy()

let contentView

describe('CollectionView', () => {
  beforeEach(() => {
    fakeENV.setup()
    const viewEl = $('<div id="content-view-el">original_text</div>')
    viewEl.appendTo(fixtures)
    contentView = new ContentView({
      el: viewEl,
      instructionsTemplate,
      renderengInstructions: false,
    })
    contentView.$el.appendTo($('#fixtures'))
    contentView.render()
  })

  afterEach(() => {
    fakeENV.teardown()
    contentView.remove()
  })

  test('should be accessible', function (done) {
    isAccessible(contentView, done, {a11yReport: true})
  })

  test('collectionView replaces text with warning and link on renderNoOutcomeWarning event', function () {
    ok(contentView.$el.text().match(/original_text/))
    publish('renderNoOutcomeWarning')
    ok(contentView.$el.text().match(/You have no outcomes/))
    ok(!contentView.$el.text().match(/original_text/))
    ok(contentView.$el.find('a').attr('href').search(`${contentView._contextPath()}/outcomes`) > 0)
  })
})
