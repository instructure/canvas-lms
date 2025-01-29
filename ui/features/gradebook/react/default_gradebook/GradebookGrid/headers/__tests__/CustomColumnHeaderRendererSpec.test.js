/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import {getCustomColumnId} from '../../../Gradebook.utils'
import {createGradebook} from '../../../__tests__/GradebookSpecHelper'
import CustomColumnHeaderRenderer from '../CustomColumnHeaderRenderer'

const I18n = createI18nScope('gradebook')

describe('CustomColumnHeaderRenderer', () => {
  let container
  let gradebook
  let column
  let renderer
  let component

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)

    gradebook = createGradebook()
    gradebook.gotCustomColumns([
      {id: '2401', teacher_notes: true, title: 'Notes'},
      {id: '2402', teacher_notes: false, title: 'Other Notes'},
    ])
    column = {id: getCustomColumnId('2401'), customColumnId: '2401'}
    renderer = new CustomColumnHeaderRenderer(gradebook)
  })

  afterEach(() => {
    renderer.destroy({}, container)
    container.remove()
  })

  describe('render', () => {
    it('renders the CustomColumnHeader with correct title', () => {
      renderer.render(
        column,
        container,
        {},
        {
          ref: ref => {
            component = ref
          },
        },
      )
      expect(container.textContent).toContain('Notes')
    })

    it('uses the custom column title for non-teacher notes columns', () => {
      column = {id: 'custom_col_2402', customColumnId: '2402'}
      renderer.render(
        column,
        container,
        {},
        {
          ref: ref => {
            component = ref
          },
        },
      )
      expect(container.textContent).toContain('Other Notes')
    })

    it('provides a ref to the rendered component', () => {
      renderer.render(
        column,
        container,
        {},
        {
          ref: ref => {
            component = ref
          },
        },
      )
      expect(component).toBeTruthy()
      expect(component.constructor.name).toBe('CustomColumnHeader')
    })
  })

  describe('destroy', () => {
    it('cleans up the rendered component', () => {
      renderer.render(
        column,
        container,
        {},
        {
          ref: ref => {
            component = ref
          },
        },
      )
      renderer.destroy({}, container)
      expect(container.innerHTML).toBe('')
    })
  })
})
