/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import ThemeEditorAccordion from '../ThemeEditorAccordion'

function generateProps(type, overrides = {}) {
  const conditionalVariableThings = {}

  if (type === 'image') {
    conditionalVariableThings.accept = 'image/*'
  }

  return {
    variableSchema: [
      {
        group_name: 'test',
        variables: [
          {
            default: 'default',
            human_name: 'Friendly Foo',
            variable_name: 'foo',
            type,
            ...conditionalVariableThings,
          },
        ],
      },
    ],
    brandConfigVariables: {
      foo: 'bar',
    },
    changedValues: {
      foo: {val: 'baz'},
    },
    changeSomething() {},
    getDisplayValue: () => 'display_name',
    ...overrides,
  }
}

describe('ThemeEditorAccordion', () => {
  beforeEach(() => {
    window.sessionStorage.clear()
  })
  it('renders', () => {
    const {getByText} = render(<ThemeEditorAccordion {...generateProps('color')} />)
    // Check that the accordion group is rendered with the test group name
    expect(getByText('test')).toBeInTheDocument()
  })

  it('opens up the last used accordion', () => {
    window.sessionStorage.setItem('Theme__editor-accordion-index', '2')
    const props = generateProps('color')
    // Add more groups to test the expanded index
    props.variableSchema = [
      {group_name: 'Group 1', variables: []},
      {group_name: 'Group 2', variables: []},
      {group_name: 'Group 3', variables: []},
    ]
    const {getByText, container} = render(<ThemeEditorAccordion {...props} />)
    // Check that all groups are rendered
    expect(getByText('Group 1')).toBeInTheDocument()
    expect(getByText('Group 2')).toBeInTheDocument()
    expect(getByText('Group 3')).toBeInTheDocument()
    // The third group (index 2) should be expanded - check via aria-expanded
    const expandedButtons = container.querySelectorAll('button[aria-expanded="true"]')
    expect(expandedButtons).toHaveLength(1)
  })

  it('renders each group', () => {
    const props = generateProps()
    props.variableSchema = [
      {
        group_name: 'Foo',
        variables: [],
      },
      {
        group_name: 'Bar',
        variables: [],
      },
    ]
    const {getByText} = render(<ThemeEditorAccordion {...props} />)
    expect(getByText('Foo')).toBeInTheDocument()
    expect(getByText('Bar')).toBeInTheDocument()
  })

  it('renders a row for each variable in a group', () => {
    const props = generateProps()
    props.variableSchema = [
      {
        group_name: 'Test Group',
        variables: [
          {
            default: '#047',
            human_name: 'Color',
            variable_name: 'color',
            type: 'color',
          },
          {
            default: 'image.png',
            human_name: 'Image',
            variable_name: 'image',
            type: 'image',
            accept: 'image/*',
          },
        ],
      },
    ]
    const {getByText, getByLabelText, getAllByText} = render(<ThemeEditorAccordion {...props} />)
    expect(getByText('Test Group')).toBeInTheDocument()
    // Color row should have a color input
    expect(getByLabelText('Color')).toBeInTheDocument()
    // Image row should have the image text (appears multiple times in the UI)
    expect(getAllByText('Image')).toHaveLength(2)
  })

  describe('renderRow', () => {
    it('renders color rows', () => {
      const {getByLabelText} = render(<ThemeEditorAccordion {...generateProps('color')} />)
      expect(getByLabelText('Friendly Foo')).toBeInTheDocument()
    })

    it('renders image rows', () => {
      const {getAllByText} = render(<ThemeEditorAccordion {...generateProps('image')} />)
      // Image rows show the label text multiple times
      const friendlyFooElements = getAllByText('Friendly Foo')
      expect(friendlyFooElements.length).toBeGreaterThan(0)
    })

    it('renders percentage rows', () => {
      const {getByLabelText} = render(<ThemeEditorAccordion {...generateProps('percentage')} />)
      expect(getByLabelText('Friendly Foo')).toBeInTheDocument()
    })
  })
})
