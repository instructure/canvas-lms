/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {MessageDetailActions} from '../MessageDetailActions'

describe('MessageDetailActions', () => {
  const setup = () => {
    const props = {
      onReply: vi.fn(),
      onReplyAll: vi.fn(),
      onDelete: vi.fn(),
      onForward: vi.fn(),
      authorName: 'John Cena',
    }

    const utils = render(<MessageDetailActions {...props} />)
    const {getByText} = utils

    const openMoreOptionsMenu = () => {
      const moreOptionsButton = getByText('More options for message from John Cena')
      fireEvent.click(moreOptionsButton)
    }

    const clickOption = label => {
      const {getByText} = utils
      openMoreOptionsMenu()
      fireEvent.click(getByText(label))
    }

    return {
      ...utils,
      props,
      clickOption,
      openMoreOptionsMenu,
    }
  }

  it('sends the selected option to the provided callback function', () => {
    const {getByText, props, clickOption} = setup()

    fireEvent.click(getByText('Reply to John Cena'))
    expect(props.onReply).toHaveBeenCalled()

    clickOption('Reply All')
    expect(props.onReplyAll).toHaveBeenCalled()

    clickOption('Delete')
    expect(props.onDelete).toHaveBeenCalled()

    clickOption('Forward')
    expect(props.onForward).toHaveBeenCalled()
  })

  describe('when restrict_student_access feature is enabled', () => {
    beforeAll(() => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.restrict_student_access = true
    })

    afterAll(() => {
      delete window.ENV.FEATURES.restrict_student_access
    })

    it('does not render the reply all & delete button', async () => {
      const {queryByText, openMoreOptionsMenu} = setup()
      openMoreOptionsMenu()

      expect(queryByText('Reply All')).not.toBeInTheDocument()
      expect(queryByText('Delete')).not.toBeInTheDocument()
    })

    it('renders only Forward button', async () => {
      const {getByText, openMoreOptionsMenu} = setup()
      openMoreOptionsMenu()

      expect(getByText('Forward')).toBeInTheDocument()
    })
  })
})
