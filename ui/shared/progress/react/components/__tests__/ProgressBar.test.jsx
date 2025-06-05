/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import ProgressBar from '../ProgressBar'

it('sets width on progress bar', () => {
  const {getByRole} = render(<ProgressBar progress={35} />)
  expect(getByRole('progressbar')).toHaveStyle('width: 35%')
})

it('shows indeterminate loader when progress is 100 but not yet complete', () => {
  const {container} = render(<ProgressBar progress={100} />)
  expect(container.firstChild).toHaveClass('almost-done')
})

test('style width value never reaches over 100%', () => {
  const {getByRole} = render(<ProgressBar progress={200} />)
  expect(getByRole('progressbar')).toHaveStyle('width: 100%')
})
