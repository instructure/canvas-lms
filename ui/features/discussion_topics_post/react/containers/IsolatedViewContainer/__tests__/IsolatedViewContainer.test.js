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
import {IsolatedViewContainer} from '../IsolatedViewContainer'
import {Discussion} from '../../../../graphql/Discussion'
import {DiscussionEntry} from '../../../../graphql/DiscussionEntry'
import {render} from '@testing-library/react'

describe('IsolatedViewContainer', () => {
  const defaultProps = ({discussionTopic = {}, IsolatedRootEntry = {}} = {}) => ({
    discussionTopic: Discussion.mock(),

    IsolatedRootEntry: DiscussionEntry.mock()
  })

  const setup = props => {
    return render(<IsolatedViewContainer {...props} />)
  }

  it('should render', () => {
    const {container} = setup(defaultProps())
    expect(container).toBeTruthy()
  })
})
