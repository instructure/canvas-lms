/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import CreateEditModal from '../CreateEditModal'

const fancyNote = {
  id: '8a8407a1-ed8f-48e6-8fe7-087bac0a8fe2',
  target_roles: ['student', 'observer'],
  langs: {
    en: {
      title: 'A super great note title',
      description: 'An even better note description',
      url: 'https://example.com/amazing_url'
    },
    es: {
      title: 'A super great note title (spanish)',
      description: 'An even better note description (spanish)',
      url: 'https://es.example.com/amazing_url'
    }
  },
  show_ats: {},
  published: true
}

describe('create modal', () => {
  it('It renders reasonable defaults', () => {
    const {getByText} = render(
      <CreateEditModal
        open
        onClose={() => {}}
        onSubmit={() => {}}
        currentNote={undefined}
        envs={['test']}
        langs={['en', 'es']}
      />
    )
    expect(getByText('Everyone')).toBeInTheDocument()
  })

  // TODO unskip and finish these tests after upgrading jest/jsdom
  it.skip('It blocks submission unless the basic english fields are completed', () => {
    const onSubmit = jest.fn()
    const {getByLabelText, getByText} = render(
      <CreateEditModal
        open
        onClose={() => {}}
        onSubmit={onSubmit}
        currentNote={undefined}
        envs={['test']}
        langs={['en', 'es']}
      />
    )
    expect(getByText('Save').closest('button')).toBeDisabled()
    userEvent.type(getByLabelText('Title'), 'A great english title')
    expect(getByText('Save').closest('button')).toBeDisabled()
    userEvent.type(getByLabelText('Description'), 'A great english description')
    expect(getByText('Save').closest('button')).not.toBeDisabled()
    userEvent.type(getByLabelText('Link URL'), 'https://whatever.com')
    expect(getByText('Save').closest('button')).not.toBeDisabled()
  })

  it.skip('It submits the expected object', () => {
    const onSubmit = jest.fn()
    const {getByLabelText, getByText} = render(
      <CreateEditModal
        open
        onClose={() => {}}
        onSubmit={onSubmit}
        currentNote={undefined}
        envs={['test']}
        langs={['en', 'es']}
      />
    )
    userEvent.type(getByLabelText('Title'), 'A great english title')
    userEvent.type(getByLabelText('Description'), 'A great english description')
    userEvent.type(getByLabelText('Link URL'), 'https://whatever.com')
    userEvent.click(getByText('Save').closest('button'))

    expect(onSubmit).toHaveBeenCalledTimes(1)
    expect(onSubmit).toHaveBeenCalledWith({})
  })
})
