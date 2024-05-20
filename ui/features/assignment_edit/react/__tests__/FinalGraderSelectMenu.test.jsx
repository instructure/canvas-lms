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
import FinalGraderSelectMenu from '../FinalGraderSelectMenu'
import userEvent from '@testing-library/user-event'

describe('FinalGraderSelectMenu', () => {
  let props
  let wrapper

  function selectMenu() {
    return wrapper.container.querySelector('select[name="final_grader_id"]')
  }

  function selectMenuOptions() {
    return [...selectMenu().options].map(option => {
      return {
        hidden: option.hidden,
        selected: option.selected,
        text: option.textContent,
        value: option.value,
      }
    })
  }

  function mountComponent() {
    wrapper = render(<FinalGraderSelectMenu {...props} />)
  }

  beforeEach(() => {
    props = {
      availableModerators: [
        {name: 'John Doe', id: '923'},
        {name: 'Jane Doe', id: '492'},
      ],
      finalGraderID: undefined,
    }
  })

  test('renders a select menu', () => {
    mountComponent()
    expect(selectMenu()).toBeInTheDocument()
  })

  test('the menu includes a menuitem for each moderator', () => {
    mountComponent()
    const moderatorNames = props.availableModerators.map(user => user.name)
    const options = selectMenuOptions().map(option => option.text)
    expect(moderatorNames.every(name => options.indexOf(name) >= 0)).toBe(true)
  })

  test('the corresponding value for the moderator menuitems is the user id', () => {
    mountComponent()
    const moderatorIDs = props.availableModerators.map(user => user.id)
    const optionValues = selectMenuOptions().map(option => option.value)
    expect(moderatorIDs.every(id => optionValues.indexOf(id) >= 0)).toBe(true)
  })

  test('excludes the "Select Grader" menuitem if passed a finalGraderID', () => {
    props.finalGraderID = props.availableModerators[0].id
    mountComponent()
    const menuitem = selectMenuOptions().find(option => option.text === 'Select Grader')
    expect(menuitem).toBeUndefined()
  })

  test('removes the "Select Grader" menuitem if a final grader is selected', async () => {
    const user = userEvent.setup()
    mountComponent()
    await user.selectOptions(selectMenu(), props.availableModerators[0].name)
    const menuitem = selectMenuOptions().find(option => option.text === 'Select Grader')
    expect(menuitem).toBeUndefined()
  })

  test('selects the "Select Grader" menuitem if not passed a finalGraderID', () => {
    mountComponent()
    const menuitem = selectMenuOptions().find(option => option.text === 'Select Grader')
    expect(menuitem.selected).toBe(true)
  })

  test('selects the appropriate final grader menuitem if passed a finalGraderID', () => {
    const [finalGrader] = props.availableModerators
    props.finalGraderID = finalGrader.id
    mountComponent()
    const menuitem = selectMenuOptions().find(option => option.text === finalGrader.name)
    expect(menuitem.selected).toBe(true)
  })

  test('selects an option when clicked', async () => {
    const user = userEvent.setup()
    const [finalGrader] = props.availableModerators
    mountComponent()
    await user.selectOptions(selectMenu(), finalGrader.name)
    const menuitem = selectMenuOptions().find(option => option.text === finalGrader.name)
    expect(menuitem.selected).toBe(true)
  })
})
