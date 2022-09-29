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
import {shallow} from 'enzyme'
import Comments from '../Comments'

import {assessments} from './fixtures'

describe('The Comments component', () => {
  const props = {
    editing: true,
    assessment: assessments.freeForm.data[1],
    savedComments: ['I award you no points', 'May god have mercy on your soul'],
    saveLater: false,
    setComments: jest.fn(),
    setSaveLater: jest.fn(),
  }

  const component = mods => shallow(<Comments {...{...props, ...mods}} />)
  const editor = mods => component(mods).find('FreeFormComments').shallow()
  const rating = mods => component(mods).find('CommentText').shallow()

  it('renders the root component as expected when editing', () => {
    expect(component()).toMatchSnapshot()
  })

  it('directly renders comments_html', () => {
    const el = rating({editing: false})
      .findWhere(e => e.children().length === 0)
      .last()
    expect(el.html()).toMatchSnapshot()
  })

  it('renders a placeholder when no assessment provided', () => {
    expect(rating({editing: false, assessment: null})).toMatchSnapshot()
  })

  it('shows no selector when no comments are presented', () => {
    expect(component({savedComments: []}).find('SimpleSelect')).toHaveLength(0)
  })

  it('can used saved comments from before', () => {
    const setComments = jest.fn()
    const el = editor({setComments})
    const select = el.find('SimpleSelect')
    const option = select.children().last()
    select.prop('onChange')(null, {value: option.prop('value')})

    const selectedText = props.savedComments[option.prop('value')]
    expect(setComments.mock.calls[0][0]).toEqual(selectedText)
  })

  it('truncates long saved comments', () => {
    const long = 'this is the song that never ends, yes it goes on and on my friends-'.repeat(50)
    const el = editor({savedComments: [long]})
    const option = el.find('Option').last()
    expect(option.props().children).toHaveLength(100) // includes the trailing '…'
  })

  it('avoids creating illegal DOM ids', () => {
    const el = editor({savedComments: ['this is bad comment 3"', 'this is bad comment 2\n']})
    const options = el.find('Option')
    let optProps = options.at(1).props()
    expect(optProps.id).toBe(`mment3_${optProps.value}`)
    optProps = options.at(2).props()
    expect(optProps.id).toBe(`mment2_${optProps.value}`)
  })

  it('can check / uncheck save for later', () => {
    const setSaveLater = jest.fn()
    const el = editor({setSaveLater})
    el.find('Checkbox').prop('onChange')({target: {checked: true}})

    expect(setSaveLater.mock.calls[0][0]).toBe(true)
  })

  it('can disable save later checkbox', () => {
    const el = editor({allowSaving: false})
    expect(el.find('Checkbox')).toHaveLength(0)
  })

  it('renders a footer after the comment when provided', () => {
    const el = component({editing: false, footer: <div>this is a footer</div>})

    expect(el.shallow()).toMatchSnapshot()
  })
})
