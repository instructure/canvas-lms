/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import WikiPageEditView from '../WikiPageEditView'
import WikiPage from '../../models/WikiPage'
import {BODY_MAX_LENGTH} from '../../../utils/constants'

const createView = opts => {
  const view = new WikiPageEditView({
    model: new WikiPage({editor: 'block_editor'}),
    wiki_pages_path: '/courses/1/pages',
    ...opts,
  })
  view.$el.appendTo(document.getElementById('fixtures'))
  return view.render()
}

describe('WikiPageEditView', () => {
  let container

  beforeEach(() => {
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
    fakeENV.setup()
  })

  afterEach(() => {
    container.remove()
    fakeENV.teardown()
  })

  test('should render the view', () => {
    const view = createView()
    expect(view.$el).toBeDefined()
  })

  test('should show errors', () => {
    const view = createView()
    const errors = {
      body: [{type: 'too_long', message: 'Error...'}],
    }
    view.showErrors(errors)
    expect(view.$('.body_has_errors')).toBeDefined()
  })

  test('saveAndPublish should trigger native submit', async () => {
    window.block_editor = false
    const view = createView()
    const triggerSpy = jest.spyOn(view.$el, 'trigger')
    view.saveAndPublish()
    expect(triggerSpy).toHaveBeenCalledWith('submit')
  })

  describe('validate form data', () => {
    test('should validate form data with body too long', () => {
      const view = createView()
      const data = {body: 'a'.repeat(BODY_MAX_LENGTH + 1)}
      const errors = view.validateFormData(data)
      expect(errors.body[0].type).toBe('too_long')
      expect(errors.body[0].message).toBe(
        'Input exceeds 500 KB limit. Please reduce the text size.',
      )
    })
  })
})
