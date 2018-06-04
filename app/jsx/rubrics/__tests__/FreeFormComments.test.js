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
import FreeFormComments from '../FreeFormComments'

describe('The FreeFormComments component', () => {
  const props = {
    savedComments: [
      'I award you no points',
      'May god have mercy on your soul'
    ],
    comments: 'some things',
    saveLater: false,
    setComments: sinon.spy(),
    setSaveLater: sinon.spy()
  }

  const component = (mods) => shallow(<FreeFormComments {...{ ...props, ...mods }} />)

  it('renders the root component as expected', () => {
    expect(component().debug()).toMatchSnapshot()
  })

  it('shows no selector when no comments are presented', () => {
    expect(component({ savedComments: [] }).find('Select')).toHaveLength(0)
  })

  it('can used saved comments from before', () => {
    const setComments = sinon.spy()
    const el = component({ setComments })
    const option = el.find('option').last()
    el.find('Select').prop('onChange')(null, { value: option.prop('value') })

    expect(setComments.args).toEqual([
      [option.text()]
    ])
  })

  it('can check / uncheck save for later', () => {
    const setSaveLater = sinon.spy()
    const el = component({ setSaveLater })
    el.find('Checkbox').prop('onChange')({ target: { checked: true } })

    expect(setSaveLater.args).toEqual([[true]])
  })
})
