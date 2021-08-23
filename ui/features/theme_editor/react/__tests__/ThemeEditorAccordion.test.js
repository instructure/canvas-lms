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
import {shallow} from 'enzyme'
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
            ...conditionalVariableThings
          }
        ]
      }
    ],
    brandConfigVariables: {
      foo: 'bar'
    },
    changedValues: {
      foo: {val: 'baz'}
    },
    changeSomething() {},
    getDisplayValue: () => 'display_name',
    ...overrides
  }
}

describe('ThemeEditorAccordion', () => {
  it('renders', () => {
    const wrapper = shallow(<ThemeEditorAccordion {...generateProps('color')} />)
    expect(wrapper.find('ThemeEditorVariableGroup')).toHaveLength(1)
  })

  it('opens up the last used accordion', () => {
    window.sessionStorage.setItem('Theme__editor-accordion-index', 2)
    const wrapper = shallow(<ThemeEditorAccordion {...generateProps('color')} />)
    expect(wrapper.state('expandedIndex')).toBe(2)
  })

  it('renders each group', () => {
    const props = generateProps()
    props.variableSchema = [
      {
        group_name: 'Foo',
        variables: []
      },
      {
        group_name: 'Bar',
        variables: []
      }
    ]
    const wrapper = shallow(<ThemeEditorAccordion {...props} />)
    expect(wrapper.find('ThemeEditorVariableGroup')).toHaveLength(2)
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
            type: 'color'
          },
          {
            default: 'image.png',
            human_name: 'Image',
            variable_name: 'image',
            type: 'image',
            accept: 'image/*'
          }
        ]
      }
    ]
    const wrapper = shallow(<ThemeEditorAccordion {...props} />)
    expect(wrapper.find('ThemeEditorVariableGroup').children()).toHaveLength(2)
    expect(wrapper.find('ThemeEditorColorRow').exists()).toBe(true)
    expect(wrapper.find('ThemeEditorImageRow').exists()).toBe(true)
  })

  describe('renderRow', () => {
    it('renders color rows', () => {
      const wrapper = shallow(<ThemeEditorAccordion {...generateProps('color')} />)
      expect(wrapper.find('ThemeEditorColorRow')).toHaveLength(1)
    })

    it('renders image rows', () => {
      const wrapper = shallow(<ThemeEditorAccordion {...generateProps('image')} />)
      expect(wrapper.find('ThemeEditorImageRow')).toHaveLength(1)
    })

    it('renders percentage rows', () => {
      const wrapper = shallow(<ThemeEditorAccordion {...generateProps('percentage')} />)
      expect(wrapper.find('RangeInput')).toHaveLength(1)
    })
  })
})
