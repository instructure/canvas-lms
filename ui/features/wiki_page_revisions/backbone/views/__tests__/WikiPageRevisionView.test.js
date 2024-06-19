/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import WikiPageRevision from '@canvas/wiki/backbone/models/WikiPageRevision'
import WikiPageRevisionsCollection from '../../collections/WikiPageRevisionsCollection'
import WikiPageRevisionView from '../WikiPageRevisionView'
import {waitFor} from '@testing-library/react'
import sinon from 'sinon'

const sandbox = sinon.createSandbox()

describe('WikiPageRevisionView', () => {
  ENV.context_asset_string = 'course_1'

  test('binds to model change triggers', () => {
    const revision = new WikiPageRevision()
    const view = new WikiPageRevisionView({model: revision})
    sandbox.mock(view).expects('render').atLeast(1)
    revision.set('body', 'A New Body')
  })

  test('restore delegates to model.restore', async () => {
    const revision = new WikiPageRevision()
    const view = new WikiPageRevisionView({model: revision})
    sandbox.spy(view.model, 'restore')
    sandbox.stub(view, 'windowLocation').returns({
      href: '',
      reload() {
        return true
      },
    })
    view.restore()
    $('button[data-testid="confirm-button"]').trigger('click')
    await waitFor(() => view.model.restore.called)
    expect(view.model.restore.callCount).toBe(1)
  })

  test('toJSON serializes expected values', () => {
    const attributes = {
      latest: true,
      selected: true,
      title: 'Title',
      body: 'Body',
    }
    const revision = new WikiPageRevision(attributes)
    const collection = new WikiPageRevisionsCollection([revision])
    collection.latest = new WikiPageRevision(attributes)
    const view = new WikiPageRevisionView({model: revision})
    const json = view.toJSON()

    // IS.LATEST
    expect(json.IS != null ? json.IS.LATEST : undefined).toBe(true)

    // IS.SELECTED
    expect(json.IS != null ? json.IS.SELECTED : undefined).toBe(true)

    // IS.LOADED
    expect(json.IS != null ? json.IS.LOADED : undefined).toBe(true)

    // IS.SAME_AS_LATEST
    expect(json.IS != null ? json.IS.SAME_AS_LATEST : undefined).toBe(true)
  })
})
