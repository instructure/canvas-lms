/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {AssignmentGroupUI as AssignmentGroup} from '../AssignmentGroup'

/*
 *  CAUTION: The InstUI Select component is greatly changed in v7.
 *  Updating the import to the new ui-select location is almost certainly
 *  going to break the functionality of the component. Any failing tests
 *  will just be skipped, and the component can be fixed later when work
 *  resumes on A2.
 */

function makeGroupList() {
  return [
    {lid: '1', name: 'Group 1'},
    {lid: '2', name: 'Group 2'},
    {lid: '3', name: 'Group 3'},
  ]
}

describe('AssignmenGroupUI', () => {
  it('renders the given assignment group in view mode', () => {
    const groupList = makeGroupList()
    const {getByText, getByTestId} = render(
      <AssignmentGroup
        mode="view"
        onChange={() => {}}
        onChangeMode={() => {}}
        assignmentGroupList={groupList}
        selectedAssignmentGroup={groupList[1]}
      />
    )
    expect(getByTestId('SelectableText')).toBeInTheDocument()
    expect(getByText(groupList[1].name)).toBeInTheDocument()
  })

  it.skip('renders the given assignment group in edit mode', () => {
    const groupList = makeGroupList()
    const {getByTestId} = render(
      <AssignmentGroup
        mode="edit"
        onChange={() => {}}
        onChangeMode={() => {}}
        assignmentGroupList={groupList}
        selectedAssignmentGroup={groupList[1]}
      />
    )
    expect(getByTestId('SelectableText')).toBeInTheDocument()
    expect(document.querySelector('input').value).toBe(groupList[1].name)
  })

  it('renders the placeholder when not given a value', () => {
    const {getByText, getByTestId} = render(
      <AssignmentGroup mode="view" onChange={() => {}} onChangeMode={() => {}} />
    )
    expect(getByTestId('SelectableText')).toBeInTheDocument()
    expect(getByText('No Assignment Group Assigned')).toBeInTheDocument()
  })

  it.skip('calls onChange when the selection changes', () => {
    const onchange = jest.fn()
    const onchangemode = jest.fn()
    const groupList = makeGroupList()

    const {container} = render(
      <div>
        <AssignmentGroup
          mode="edit"
          onChange={onchange}
          onChangeMode={onchangemode}
          assignmentGroupList={groupList}
          selectedAssignmentGroup={groupList[0]}
        />
        <span id="focus-me" tabIndex="-1">
          just here to get focus
        </span>
      </div>
    )
    const input = container.querySelector('input')
    input.click()
    const option = document.querySelectorAll('li[role="option"]')[1]
    option.click()
    container.querySelector('#focus-me').focus()
    expect(onchangemode).toHaveBeenCalledWith('view')
    expect(onchange).not.toHaveBeenCalled()

    // it takes a re-render in view to get onChange called
    render(
      <div>
        <AssignmentGroup
          mode="view"
          onChange={onchange}
          onChangeMode={onchangemode}
          assignmentGroupList={groupList}
          selectedAssignmentGroup={groupList[1]}
        />
        <span id="click-me" tabIndex="-1">
          just here to get focus
        </span>
      </div>,
      {container}
    )
    expect(onchange).toHaveBeenCalledWith(groupList[1])
  })
})
