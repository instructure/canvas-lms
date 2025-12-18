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

import MessageStudentsDialog from '../index'
import {fireEvent} from '@testing-library/react'

describe('MessageStudentsDialog', () => {
  const testData = {
    context: 'The Quiz',
    recipientGroups: [
      {
        name: 'have taken the quiz',
        recipients: [
          {
            id: 1,
            short_name: 'bob',
          },
        ],
      },
      {
        name: "haven't taken the quiz",
        recipients: [
          {
            id: 2,
            short_name: 'alice',
          },
        ],
      },
    ],
  }

  let dialog
  let container

  beforeEach(() => {
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
    dialog = new MessageStudentsDialog(testData)
    dialog.render()
    container.appendChild(dialog.$el[0])
  })

  afterEach(() => {
    dialog.remove()
    container.remove()
  })

  it('initializes with correct data', () => {
    expect(dialog.recipientGroups).toEqual(testData.recipientGroups)
    expect(dialog.recipients).toEqual(testData.recipientGroups[0].recipients)
    expect(dialog.options.title).toContain(testData.context)
    expect(dialog.model).toBeTruthy()
  })

  it('updates recipients when dropdown selection changes', () => {
    const select = dialog.$recipientGroupName[0]
    select.value = "haven't taken the quiz"
    fireEvent.change(select)

    const dialogContent = dialog.$el[0].textContent
    expect(dialogContent).toContain('alice')
    expect(dialogContent).not.toContain('bob')
  })

  it('returns correct form values', () => {
    const messageBody = 'Students please take your quiz, dang it!'
    dialog.$messageBody.val(messageBody)

    const formData = dialog.getFormData()

    expect(formData.body).toBe(messageBody)
    expect(formData.recipientGroupName).toBeUndefined()
    expect(formData.recipients).toEqual(testData.recipientGroups[0].recipients.map(r => r.id))
  })

  it('validates form before save', () => {
    const emptyBodyErrors = dialog.validateBeforeSave({body: ''}, {})
    expect(emptyBodyErrors.body[0].message).toBeTruthy()

    const noRecipientsErrors = dialog.validateBeforeSave(
      {body: 'take your dang quiz'},
      {recipients: []},
    )
    expect(noRecipientsErrors.recipientGroupName[0].message).toBeTruthy()
  })
})
