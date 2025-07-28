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

import React from 'react'
import {render} from '@testing-library/react'
import GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'
import ReadOnlyCell from '../ReadOnlyCell'

describe('GradebookGrid TotalGradeOverrideCellEditor ReadOnlyCell', () => {
  let props
  let component
  let ref

  beforeEach(() => {
    const gradeEntry = new GradeOverrideEntry()
    props = {
      gradeEntry,
      gradeInfo: gradeEntry.parseValue('91%'),
      gradeIsUpdating: false,
      onGradeUpdate: jest.fn(),
      pendingGradeInfo: null,
    }
  })

  const renderComponent = () => {
    ref = React.createRef()
    component = render(<ReadOnlyCell {...props} ref={ref} />)
    return component
  }

  const getGrade = () => {
    return component.container.querySelector('.Grid__GradeCell__Content').textContent
  }

  const getInstance = () => {
    return ref.current
  }

  describe('rendering', () => {
    it('displays the given grade info', () => {
      renderComponent()
      expect(getGrade()).toBe('91%')
    })

    it('displays the given pending grade info when available', () => {
      props.pendingGradeInfo = props.gradeEntry.parseValue('92%')
      renderComponent()
      expect(getGrade()).toBe('92%')
    })
  })

  describe('#applyValue()', () => {
    it('has no effect', () => {
      renderComponent()
      expect(() => getInstance().applyValue()).not.toThrow()
    })
  })

  describe('#focus()', () => {
    it('does not change focus', () => {
      const previousActiveElement = document.activeElement
      renderComponent()
      getInstance().focus()
      expect(document.activeElement).toBe(previousActiveElement)
    })
  })

  describe('#handleKeyDown()', () => {
    it('does not skip default behavior', () => {
      renderComponent()
      const event = new Event('keydown')
      Object.defineProperty(event, 'which', {value: 9}) // tab key
      const continueHandling = getInstance().handleKeyDown(event)
      expect(continueHandling).toBeUndefined()
    })
  })
})
