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
import {EnrollmentTreeGroup} from '../EnrollmentTreeGroup'
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
    expect(getByText('Course 1 - Section 1')).toBeInTheDocument()
  })

  it('renders role with one course group when toggled', () => {
    courseNode.children.push(section2Node)
    const {getByText} = render(<EnrollmentTreeGroup {...rProps} />)
    expect(getByText('Role 1')).toBeInTheDocument()
    expect(getByText('Course 1')).toBeInTheDocument()
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
})
