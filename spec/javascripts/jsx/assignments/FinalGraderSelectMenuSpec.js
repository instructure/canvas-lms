/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {mount} from 'enzyme'
import FinalGraderSelectMenu from 'jsx/assignments/FinalGraderSelectMenu'

QUnit.module('FinalGraderSelectMenu', hooks => {
  let props
  let wrapper

  function selectMenu() {
    return wrapper.find('select[name="final_grader_id"]')
  }

  function selectMenuOptions() {
    return selectMenu()
      .find('option')
      .map(option => {
        const $option = option.instance()
        return {
          hidden: $option.hidden,
          selected: $option.selected,
          text: $option.innerText,
          value: $option.value
        }
      })
  }

  function mountComponent() {
    wrapper = mount(<FinalGraderSelectMenu {...props} />)
  }

  hooks.beforeEach(() => {
    props = {
      availableModerators: [{name: 'John Doe', id: '923'}, {name: 'Jane Doe', id: '492'}],
      finalGraderID: undefined
    }
  })

  test('renders a select menu', () => {
    mountComponent()
    strictEqual(selectMenu().length, 1)
  })

  test('the menu includes a menuitem for each moderator', () => {
    mountComponent()
    const moderatorNames = props.availableModerators.map(user => user.name)
    const options = selectMenuOptions().map(option => option.text)
    strictEqual(moderatorNames.every(name => options.indexOf(name) >= 0), true)
  })

  test('the corresponding value for the moderator menuitems is the user id', () => {
    mountComponent()
    const moderatorIDs = props.availableModerators.map(user => user.id)
    const optionValues = selectMenuOptions().map(option => option.value)
    strictEqual(moderatorIDs.every(id => optionValues.indexOf(id) >= 0), true)
  })

  test('excludes the "Select Grader" menuitem if passed a finalGraderID', () => {
    props.finalGraderID = props.availableModerators[0].id
    mountComponent()
    const menuitem = selectMenuOptions().find(option => option.text === 'Select Grader')
    strictEqual(menuitem, undefined)
  })

  test('removes the "Select Grader" menuitem if a final grader is selected', () => {
    mountComponent()
    selectMenu().simulate('change', {target: {value: props.availableModerators[0].id}})
    const menuitem = selectMenuOptions().find(option => option.text === 'Select Grader')
    strictEqual(menuitem, undefined)
  })

  test('selects the "Select Grader" menuitem if not passed a finalGraderID', () => {
    mountComponent()
    const menuitem = selectMenuOptions().find(option => option.text === 'Select Grader')
    strictEqual(menuitem.selected, true)
  })

  test('selects the appropriate final grader menuitem if passed a finalGraderID', () => {
    const [finalGrader] = props.availableModerators
    props.finalGraderID = finalGrader.id
    mountComponent()
    const menuitem = selectMenuOptions().find(option => option.text === finalGrader.name)
    strictEqual(menuitem.selected, true)
  })

  test('selects an option when clicked', () => {
    const [finalGrader] = props.availableModerators
    mountComponent()
    selectMenu().simulate('change', {target: {value: finalGrader.id}})
    const menuitem = selectMenuOptions().find(option => option.text === finalGrader.name)
    strictEqual(menuitem.selected, true)
  })
})
