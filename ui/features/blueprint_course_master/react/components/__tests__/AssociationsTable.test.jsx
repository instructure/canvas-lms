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
import userEvent from '@testing-library/user-event'
import {shallow} from 'enzyme'
import AssociationsTable from '../AssociationsTable'
import FocusManager from '../../focusManager'
import getSampleData from './getSampleData'
import sinon from 'sinon'

describe('AssociationsTable component', () => {

  const focusManager = new FocusManager()
  focusManager.before = document.body

  const defaultProps = () => ({
    existingAssociations: getSampleData().courses,
    addedAssociations: [],
    removedAssociations: [],
    onRemoveAssociations: () => {},
    onRestoreAssociations: () => {},
    isLoadingAssociations: false,
    focusManager,
  })

  test('renders the AssociationsTable component', () => {
    const tree = shallow(<AssociationsTable {...defaultProps()} />)
    const node = tree.find('.bca-associations-table')
    expect(node.exists()).toBeTruthy()
  })

  test('displays correct table data', () => {
    const props = defaultProps()
    const tree = render(<AssociationsTable {...props} />)
    const rows = tree.container.querySelectorAll('tr[data-testid="associations-course-row"]')

    expect(rows.length).toEqual(props.existingAssociations.length)
    expect(rows[0].querySelectorAll('td')[0].textContent).toEqual(props.existingAssociations[0].name)
    expect(rows[1].querySelectorAll('td')[0].textContent).toEqual(props.existingAssociations[1].name)
  })

  test('calls onRemoveAssociations when association remove button is clicked', async () => {
    const props = defaultProps()
    props.onRemoveAssociations = sinon.spy()
    const tree = render(<AssociationsTable {...props} />)
    const button = tree.container.querySelectorAll('tr[data-testid="associations-course-row"] button')
    await userEvent.click(button[0])

    expect(props.onRemoveAssociations.callCount).toEqual(1)
    expect(props.onRemoveAssociations.getCall(0).args[0]).toEqual(['1'])
  })
})
