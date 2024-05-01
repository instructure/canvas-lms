/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {fireEvent, render} from '@testing-library/react'
import {EnrollmentTreeGroup, constructLabel} from '../EnrollmentTreeGroup'
import type {NodeStructure} from '../types'
import type {Spacing} from '@instructure/emotion'

const checkCallback = jest.fn()
const toggleCallback = jest.fn()

interface TestableNodeStructure extends NodeStructure {
  parent?: NodeStructure
}

const emptyNode = {
  id: '',
  label: '',
  children: [],
  isMixed: false,
  isCheck: false,
}

const section2Node: TestableNodeStructure = {
  id: 's2',
  label: 'Section 2',
  children: [],
  parent: emptyNode,
  isCheck: false,
  isMixed: false,
}

const section1Node: TestableNodeStructure = {
  id: 's1',
  label: 'Section 1',
  children: [],
  parent: emptyNode,
  isCheck: false,
  isMixed: false,
}

const courseNode: TestableNodeStructure = {
  id: 'c1',
  label: 'Course 1',
  children: [section1Node],
  termName: 'Fall 2021',
  parent: emptyNode,
  isCheck: false,
  isToggle: true,
  isMixed: false,
}

const roleNode: TestableNodeStructure = {
  enrollId: '1',
  id: 'r1',
  label: 'Role 1',
  children: [courseNode],
  isCheck: false,
  isToggle: true,
  isMixed: false,
}

courseNode.parent = roleNode
section1Node.parent = courseNode
section2Node.parent = courseNode

const rProps = {
  id: roleNode.id,
  label: roleNode.label,
  isCheck: roleNode.isCheck,
  isMixed: roleNode.isMixed,
  isToggle: roleNode.isToggle,
  children: roleNode.children,
  indent: '0 0 0 0' as Spacing,
  updateCheck: checkCallback,
  updateToggle: toggleCallback,
}

describe('EnrollmentTreeGroup', () => {
  it('renders role with one course item when toggled', () => {
    const {getByText} = render(<EnrollmentTreeGroup {...rProps} />)
    expect(getByText('Role 1')).toBeInTheDocument()
    // course and section labels will be shown because they are different
    expect(getByText('Course 1 - Section 1 - Fall 2021')).toBeInTheDocument()
  })

  it('renders only course name because section name is the same', () => {
    const updatedSection2Node = {
      ...section2Node,
      label: 'Course 1',
    }
    const updatedRProps = {
      ...rProps,
      children: [{...courseNode, children: [updatedSection2Node]}],
    }
    const {getByText, queryByText} = render(<EnrollmentTreeGroup {...updatedRProps} />)
    // only the course label will be displayed
    expect(getByText('Course 1 - Fall 2021')).toBeInTheDocument()
    // default section labels that match course labels will not be shown to reduce UI clutter
    expect(queryByText('Course 1 - Course 1 - Fall 2021')).not.toBeInTheDocument()
  })

  it('renders role with one course group when toggled', () => {
    courseNode.children.push(section2Node)
    const {getByText} = render(<EnrollmentTreeGroup {...rProps} />)
    expect(getByText('Role 1')).toBeInTheDocument()
    expect(getByText('Course 1 - Fall 2021')).toBeInTheDocument()
    expect(getByText('Section 1')).toBeInTheDocument()
    expect(getByText('Section 2')).toBeInTheDocument()
  })

  it('does not render children when not toggled', () => {
    const {getByText, queryByText} = render(<EnrollmentTreeGroup {...rProps} isToggle={false} />)
    expect(getByText('Role 1')).toBeInTheDocument()
    expect(queryByText('Course 1')).not.toBeInTheDocument()
    expect(queryByText('Section 1')).not.toBeInTheDocument()
  })

  it('calls updateCheck when checked', () => {
    const {getByTestId} = render(<EnrollmentTreeGroup {...rProps} />)
    const checkBox = getByTestId('check-r1')
    fireEvent.click(checkBox)
    expect(checkCallback).toHaveBeenCalled()
  })

  it('calls updateToggle when clicked', () => {
    const {getByText} = render(<EnrollmentTreeGroup {...rProps} />)
    const toggle = getByText('Toggle group Role 1')
    fireEvent.click(toggle)
    expect(toggleCallback).toHaveBeenCalled()
  })

  describe('constructLabel', () => {
    // testing behavior when optional parameters are not provided
    describe('when no optional parameters are provided', () => {
      it('should return only the main label if no term name or children are provided', () => {
        expect(constructLabel('Default Course')).toBe('Default Course')
      })
    })

    // testing behavior with termName variations
    describe('handling termName', () => {
      it('should append term name if provided', () => {
        expect(constructLabel('Default Course', 'Fall 2021')).toBe('Default Course - Fall 2021')
      })

      it('should handle empty termName with no effect', () => {
        const children = [{id: 'child1', label: '', children: [], isCheck: false, isMixed: false}]
        expect(constructLabel('Default Course', '', children)).toBe('Default Course')
      })
    })

    // testing behavior with children variations
    describe('handling children', () => {
      it('should append section label if it exists and is different from the main label', () => {
        const children = [
          {
            id: 'child1',
            label: 'Section 1',
            children: [],
            isCheck: false,
            isMixed: false,
          },
        ]
        expect(constructLabel('Default Course', undefined, children)).toBe(
          'Default Course - Section 1'
        )
      })

      it('should not append section label if it is the same as the main label', () => {
        const children = [
          {
            id: 'child1',
            label: 'Default Course',
            children: [],
            isCheck: false,
            isMixed: false,
          },
        ]
        expect(constructLabel('Default Course', 'Fall 2021', children)).toBe(
          'Default Course - Fall 2021'
        )
      })

      it('should handle multiple children, appending only the first valid differing label', () => {
        const children = [
          {
            id: 'child1',
            label: 'Section 1',
            children: [],
            isCheck: false,
            isMixed: false,
          },
          {
            id: 'child2',
            label: 'Section 2',
            children: [],
            isCheck: false,
            isMixed: false,
          },
        ]
        expect(constructLabel('Default Course', 'Fall 2021', children)).toBe(
          'Default Course - Section 1 - Fall 2021'
        )
      })
    })

    // testing integration of children and termName
    describe('integration of children and termName', () => {
      it('should append both child label and term name when both are available and valid', () => {
        const children = [
          {
            id: 'child1',
            label: 'Section 1',
            children: [],
            isCheck: false,
            isMixed: false,
          },
        ]
        expect(constructLabel('Default Course', 'Fall 2021', children)).toBe(
          'Default Course - Section 1 - Fall 2021'
        )
      })
    })
  })
})
