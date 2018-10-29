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
import CommentButton from '../CommentButton'

describe('The CommentButton component', () => {
  const props = {
    description: 'Criterion description',
    open: false,
    comments: 'some things',
    finalize: sinon.spy(),
    initialize: sinon.spy(),
    setComments: sinon.spy()
  }

  const component = (mods) => shallow(<CommentButton {...{ ...props, ...mods }} />)

  it('renders the root component as expected', () => {
    expect(component()).toMatchSnapshot()
    expect(component().find('CommentDialog').shallow()).toMatchSnapshot()
  })

  it('opens the dialog when the outer button is clicked', () => {
    const initialize = sinon.spy()
    const el = component({ initialize })
    el.find('Button[variant="icon"]').prop('onClick')()
    expect(initialize.calledOnce).toEqual(true)
  })

  describe('closes the dialog without saving', () => {
    const when = (description, action) => {
      it(`when ${description}`, () => {
        const finalize = sinon.spy()
        const el = component({ open: true, finalize })
        action(el.find('CommentDialog'))
        expect(finalize.args).toEqual([[false]])
      })
    }

    when('dismissed', (dialog) =>
      dialog.shallow().find('Modal').prop('onDismiss')()
    )

    when('the top close button is clicked', (dialog) =>
      dialog.shallow().find('CloseButton').prop('onClick')()
    )
  })

  const prepareDialog = () => {
    const setComments = sinon.spy()
    const finalize = sinon.spy()
    const el = component({ open: true, setComments })
    const first = el.find('CommentDialog').shallow()

    const comments = 'some text'
    first.find('TextArea').prop('onChange')({ target: { value: comments } })

    expect(setComments.args).toEqual([
      ['some text'],
    ])

    const rerender = component({ comments, open: true, finalize })
    const dialog = rerender.find('CommentDialog').shallow()

    return { dialog, finalize }
  }

  describe('finalizes with true if update is clicked', () => {
    const { dialog, finalize } = prepareDialog()
    dialog.find('Button[variant="primary"]').prop('onClick')()

    expect(finalize.args).toEqual([[true]])
  })

  describe('cancels update when cancel is clicked', () => {
    const { dialog, finalize } = prepareDialog()
    dialog.find('Button[variant="light"]').prop('onClick')()

    expect(finalize.args).toEqual([[false]])
  })
})
