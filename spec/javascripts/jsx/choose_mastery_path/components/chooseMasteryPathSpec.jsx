/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import TestUtils from 'react-dom/test-utils'
import ChooseMasterPath from 'ui/features/choose_mastery_path/react/components/choose-mastery-path'

QUnit.module('Choose Mastery Path')

const defaultProps = () => ({
  options: [
    {
      setId: 1,
      assignments: [
        {
          name: 'Ch 2 Quiz',
          type: 'quiz',
          points: 10,
          due_at: new Date(),
          itemId: 1,
          category: {
            id: 'other',
            label: 'Other',
          },
        },
        {
          name: 'Ch 2 Review',
          type: 'assignment',
          points: 10,
          due_at: new Date(),
          itemId: 1,
          category: {
            id: 'other',
            label: 'Other',
          },
        },
      ],
    },
    {
      setId: 2,
      assignments: [
        {
          name: 'Ch 2 Quiz',
          type: 'quiz',
          points: 10,
          due_at: new Date(),
          itemId: 1,
          category: {
            id: 'other',
            label: 'Other',
          },
        },
        {
          name: 'Ch 2 Review',
          type: 'assignment',
          points: 10,
          due_at: new Date(),
          itemId: 1,
          category: {
            id: 'other',
            label: 'Other',
          },
        },
      ],
    },
  ],
  selectedOption: null,
  selectOption: () => {},
})

const renderComponent = props => TestUtils.renderIntoDocument(<ChooseMasterPath {...props} />)

test('renders component', () => {
  const props = defaultProps()
  const component = renderComponent(props)

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-wrapper')
  equal(renderedList.length, 1, 'renders component')
})

test('renders all options', () => {
  const props = defaultProps()
  const component = renderComponent(props)

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-option')
  equal(renderedList.length, 2, 'renders assignments')
})
