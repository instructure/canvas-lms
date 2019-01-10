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
import sinon from 'sinon'
import React from 'react'
import { shallow } from 'enzyme'
import Comments from '../Comments'

import { assessments } from './fixtures'

describe('The Comments component', () => {
  const props = {
    assessing: true,
    assessment: assessments.freeForm.data[1],
    savedComments: [
      'I award you no points',
      'May god have mercy on your soul'
    ],
    saveLater: false,
    setComments: sinon.spy(),
    setSaveLater: sinon.spy()
  }

  const component = (mods) => shallow(<Comments {...{ ...props, ...mods }} />)
  const editor = (mods) => component(mods).find('FreeFormComments').shallow()
  const rating = (mods) => component(mods).find('CommentText').shallow()

  it('renders the root component as expected when assessing', () => {
    expect(component()).toMatchSnapshot()
  })

  it('directly renders comments_html', () => {
    const el = rating({ assessing: false }).findWhere((e) => e.children().length === 0)
    expect(el.html()).toMatchSnapshot()
  })

  it('renders a placeholder when no assessment provided', () => {
    expect(rating({ assessing: false, assessment: null })).toMatchSnapshot()
  })

  it('shows no selector when no comments are presented', () => {
    expect(component({ savedComments: [] }).find('Select')).toHaveLength(0)
  })

  it('can used saved comments from before', () => {
    const setComments = sinon.spy()
    const el = editor({ setComments })
    const option = el.find('option').last()
    el.find('Select').prop('onChange')(null, { value: option.prop('value') })

    expect(setComments.args).toEqual([
      [option.text()]
    ])
  })

  it('truncates long saved comments', () => {
    const long = `
    this is the song that never ends, yes it goes on and on my friends
    some people started singing it not knowing what it was
    and they'll continue singing it forever just because
    `.trim().repeat(50)
    const el = editor({ savedComments: [long] })
    const option = el.find('option').last()
    expect(option.text()).toHaveLength(100) // includes the trailing '…'
  })

  it('can check / uncheck save for later', () => {
    const setSaveLater = sinon.spy()
    const el = editor({ setSaveLater })
    el.find('Checkbox').prop('onChange')({ target: { checked: true } })

    expect(setSaveLater.args).toEqual([[true]])
  })

  it('can disable save later checkbox', () => {
    const el = editor({ allowSaving: false })
    expect(el.find('Checkbox')).toHaveLength(0)
  })

  it('renders a footer after the comment when provided', () => {
    const el = component({ assessing: false, footer: <div>this is a footer</div> })

    expect(el.shallow()).toMatchSnapshot()
  })
})
