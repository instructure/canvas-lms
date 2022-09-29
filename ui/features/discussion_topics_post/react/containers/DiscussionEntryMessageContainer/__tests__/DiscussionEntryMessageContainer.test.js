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
import {DiscussionEntry} from '../../../../graphql/DiscussionEntry'
import {render} from '@testing-library/react'
import {DiscussionEntryMessageContainer} from '../DiscussionEntryMessageContainer'

describe('DiscussionEntryMessageContainer', () => {
  const defaultProps = (discussionEntry = {}) => ({
    discussionEntry: {...DiscussionEntry.mock(), ...discussionEntry},
  })

  const setup = props => {
    return render(<DiscussionEntryMessageContainer {...props} />)
  }

  it('should render', () => {
    const {container} = setup(defaultProps())
    expect(container).toBeTruthy()
  })

  it('should display edited by if editor is different to author', () => {
    const container = setup(
      defaultProps({
        editor: {
          id: 'vfx5000',
          _id: '99',
          displayName: 'Eddy Tor',
          avatarUrl: 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==',
        },
      })
    )
    expect(container.getByTestId('created-tooltip')).toBeTruthy()
    // one for the screenreader, the other for the tooltip
    expect(container.getAllByText('Created Feb 8, 2021 8:35pm').length).toEqual(2)
    expect(container.getByText('Edited by Eddy Tor Apr 13, 2021 4pm')).toBeInTheDocument()
  })

  it('should display plain edited if author is editor', () => {
    const container = setup(
      defaultProps({
        editor: {
          id: 'wqe54678',
          _id: '2',
          displayName: 'Hank McCoy',
          avatarUrl: 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==',
        },
      })
    )
    expect(container.getByText('Edited Apr 13, 2021 4pm')).toBeInTheDocument()
  })

  it('should not display edit info when no editor', () => {
    const container = setup(
      defaultProps({
        editor: null,
      })
    )
    expect(container.queryByText(/Edited by/)).toBeNull()
    expect(container.queryByTestId('created-tooltip')).toBeFalsy()
  })

  it('displays deletion info if delete', () => {
    const {getByText} = setup(defaultProps({deleted: true}))
    expect(getByText('Deleted by Hank Mccoy')).toBeInTheDocument()
    expect(getByText('Deleted Apr 13, 2021 4pm')).toBeInTheDocument()
  })

  it('displays discussion entry message', () => {
    const {queryByText} = setup(defaultProps())

    expect(queryByText('Hank Mccoy')).toBeTruthy()
    expect(queryByText('This is the parent reply')).toBeTruthy()
  })
})
