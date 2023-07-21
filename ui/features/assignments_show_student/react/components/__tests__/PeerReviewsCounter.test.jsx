/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import PeerReviewsCounter from '../PeerReviewsCounter'

const props = {current: 3, total: 6}

it('displays the current value in the first part of the text', () => {
  const {getByTestId} = render(<PeerReviewsCounter {...props} />)
  expect(getByTestId('current-counter')).toHaveTextContent('3')
})

it('displays the total value in the second part of the text', () => {
  const {getByTestId} = render(<PeerReviewsCounter {...props} />)
  expect(getByTestId('total-counter')).toHaveTextContent('of 6')
})
