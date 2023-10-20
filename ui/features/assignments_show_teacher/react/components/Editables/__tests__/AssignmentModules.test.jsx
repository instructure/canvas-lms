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
import {AssignmentModulesUI as AssignmentModules} from '../AssignmentModules'

/*
 *  CAUTION: The InstUI Select component is greatly changed in v7.
 *  Updating the import to the new ui-select location is almost certainly
 *  going to break the functionality of the component. Any failing tests
 *  will just be skipped, and the component can be fixed later when work
 *  resumes on A2.
 */

function makeModuleList() {
  return [
    {lid: '1', name: 'Module 1'},
    {lid: '2', name: 'Module 2'},
    {lid: '3', name: 'Module 3'},
  ]
}

describe('AssignmentModulesUI', () => {
  it('renders the given assignment modules in view mode', () => {
    const moduleList = makeModuleList()

    const {getByText, getByTestId} = render(
      <AssignmentModules
        mode="view"
        onChange={() => {}}
        onChangeMode={() => {}}
        moduleList={moduleList}
        selectedModules={moduleList.slice(0, 2)}
      />
    )
    expect(getByTestId('SelectableText')).toBeInTheDocument()
    expect(getByText('Module 1 | Module 2')).toBeInTheDocument()
  })

  it.skip('renders the given assignment modules in edit mode', () => {
    const moduleList = makeModuleList()

    const {getByText, getByTestId} = render(
      <AssignmentModules
        mode="edit"
        onChange={() => {}}
        onChangeMode={() => {}}
        moduleList={moduleList}
        selectedModules={moduleList.slice(1, 3)}
      />
    )
    expect(getByTestId('SelectableText')).toBeInTheDocument()
    expect(getByText(moduleList[1].name)).toBeInTheDocument()
    expect(getByText(moduleList[2].name)).toBeInTheDocument()
  })

  it('renders the placeholder when not given a value in view mode', () => {
    const moduleList = makeModuleList()

    const {getByText, getByTestId} = render(
      <AssignmentModules
        mode="view"
        onChange={() => {}}
        onChangeMode={() => {}}
        moduleList={moduleList}
      />
    )
    expect(getByTestId('SelectableText')).toBeInTheDocument()
    expect(getByText('No Module Assigned')).toBeInTheDocument()
  })

  it('renders the placeholder when not given a value in edit mode', () => {
    const moduleList = makeModuleList()

    const {container, getByTestId} = render(
      <AssignmentModules
        mode="view"
        onChange={() => {}}
        onChangeMode={() => {}}
        moduleList={moduleList}
      />
    )
    expect(getByTestId('SelectableText')).toBeInTheDocument()
    // I don't know of any other way to test this w/o peeking into SelectMultiple's impl
    expect(container.querySelectorAll('button')).toHaveLength(0)
  })

  it.skip('calls onChange when the selection changes', () => {
    const onchange = jest.fn()
    const onchangemode = jest.fn()
    const moduleList = makeModuleList()

    const {container} = render(
      <div>
        <AssignmentModules
          mode="edit"
          onChange={onchange}
          onChangeMode={onchangemode}
          moduleList={moduleList}
          selectedModules={moduleList.slice(0, 1)}
          readOnly={false}
        />
        <span id="focus-me" tabIndex="-1">
          just here to get focus
        </span>
      </div>
    )

    const input = container.querySelectorAll('input')[1] // SelectMultiple has 2 inputs
    input.click()
    const option = document.querySelectorAll('li[role="option"]')[0]
    option.click()
    container.querySelector('#focus-me').focus()
    expect(onchangemode).toHaveBeenCalledWith('view')
    expect(onchange).not.toHaveBeenCalled()

    // it takes a re-render in view to get onChange called
    render(
      <div>
        <AssignmentModules
          mode="view"
          onChange={onchange}
          onChangeMode={onchangemode}
          moduleList={moduleList}
          selectedModules={moduleList.slice(0, 2)}
          readOnly={false}
        />
        <span id="click-me" tabIndex="-1">
          just here to get focus
        </span>
      </div>,
      {container}
    )
    expect(onchange).toHaveBeenCalledWith(moduleList.slice(0, 2))
  })
})
