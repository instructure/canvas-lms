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
import {useClassNames} from '../useClassNames'

const defaultTestProps = (override = {}) => ({
  enabled: false,
  nodeState: {
    empty: false,
  },
  ...override,
})

type TestComponentProps = {
  enabled: boolean
  nodeState: {
    empty: boolean
    selected?: boolean
    hovered?: boolean
  }
  others?: string | string[]
}

const TestComponent = ({enabled, nodeState, others}: TestComponentProps) => {
  const clazz = useClassNames(enabled, nodeState, others)
  return (
    <div id="test" className={clazz}>
      Test
    </div>
  )
}

describe('useClassNames', () => {
  it('should return empty string if no class is passed', () => {
    render(<TestComponent {...defaultTestProps()} />)
    expect(document.getElementById('test')).toHaveAttribute('class', '')
  })

  it('should return "enabled" if enabled is true', () => {
    render(<TestComponent {...defaultTestProps({enabled: true})} />)
    expect(document.getElementById('test')).toHaveClass('enabled')
  })

  it('should return "empty" if enabled and empty are true', () => {
    render(<TestComponent {...defaultTestProps({enabled: true, nodeState: {empty: true}})} />)
    expect(document.getElementById('test')).toHaveClass('empty')
    expect(document.getElementById('test')).toHaveClass('enabled')
  })

  it('should not return "empty" if empty is true but not enabled', () => {
    render(<TestComponent {...defaultTestProps({nodeState: {empty: true}})} />)
    expect(document.getElementById('test')).not.toHaveClass('class', 'empty')
  })

  it('should return "selected" if selected is true', () => {
    render(<TestComponent {...defaultTestProps({nodeState: {selected: true}})} />)
    expect(document.getElementById('test')).toHaveClass('selected')
  })

  it('should return "hovered" if hovered is true', () => {
    render(<TestComponent {...defaultTestProps({nodeState: {hovered: true}})} />)
    expect(document.getElementById('test')).toHaveClass('hovered')
  })

  it('should return "selected hovered" if selected and hovered are true', () => {
    render(<TestComponent {...defaultTestProps({nodeState: {selected: true, hovered: true}})} />)
    expect(document.getElementById('test')).toHaveClass('selected')
    expect(document.getElementById('test')).toHaveClass('hovered')
  })

  it('should include other class if passed', () => {
    render(<TestComponent {...defaultTestProps({others: 'other-class'})} />)
    expect(document.getElementById('test')).toHaveAttribute('class', 'other-class')
  })

  it('should include multiple other classes if passed', () => {
    render(<TestComponent {...defaultTestProps({others: ['other-class', 'another-class']})} />)
    expect(document.getElementById('test')).toHaveAttribute('class', 'other-class another-class')
  })

  describe('updating', () => {
    it('should update enabled when it changes', () => {
      const {rerender} = render(<TestComponent {...defaultTestProps()} />)
      expect(document.getElementById('test')).not.toHaveClass('enabled')

      rerender(<TestComponent {...defaultTestProps({enabled: true})} />)
      expect(document.getElementById('test')).toHaveClass('enabled')
    })

    it('should update empty when it changes', () => {
      const {rerender} = render(<TestComponent {...defaultTestProps({enabled: true})} />)
      expect(document.getElementById('test')).not.toHaveClass('empty')

      rerender(<TestComponent {...defaultTestProps({enabled: true, nodeState: {empty: true}})} />)
      expect(document.getElementById('test')).toHaveClass('empty')
    })

    it('should update selected when it changes', () => {
      const {rerender} = render(<TestComponent {...defaultTestProps()} />)
      expect(document.getElementById('test')).not.toHaveClass('selected')

      rerender(<TestComponent {...defaultTestProps({nodeState: {selected: true}})} />)
      expect(document.getElementById('test')).toHaveClass('selected')
    })

    it('should update hovered when it changes', () => {
      const {rerender} = render(<TestComponent {...defaultTestProps()} />)
      expect(document.getElementById('test')).not.toHaveClass('hovered')

      rerender(<TestComponent {...defaultTestProps({nodeState: {hovered: true}})} />)
      expect(document.getElementById('test')).toHaveClass('hovered')
    })

    it('should update other classes when they change', () => {
      const {rerender} = render(<TestComponent {...defaultTestProps()} />)
      expect(document.getElementById('test')).not.toHaveAttribute('class', 'other-class')

      rerender(<TestComponent {...defaultTestProps({others: 'other-class'})} />)
      expect(document.getElementById('test')).toHaveAttribute('class', 'other-class')
    })
  })
})
