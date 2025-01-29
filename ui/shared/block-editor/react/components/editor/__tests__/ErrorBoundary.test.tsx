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

import React from 'react'
import {render} from '@testing-library/react'
import {ErrorBoundary} from '../ErrorBoundary'

describe('ErrorBoundary', () => {
  it('should render children', () => {
    const {getByText} = render(
      <ErrorBoundary>
        <div>hello</div>
      </ErrorBoundary>,
    )
    expect(getByText('hello')).toBeInTheDocument()
  })

  // react will log the exception and its call stack to the console
  // mocking console.error does not help
  // people don't like it, but there's nothing we can do about it
  // until react 19. For now, the error message causes us to fail the test.
  // it('should catch errors', () => {
  //   const Broken = () => {
  //     throw new Error('broken')
  //   }

  //   const {getByText} = render(
  //     <ErrorBoundary>
  //       <Broken />
  //     </ErrorBoundary>
  //   )

  //   expect(getByText('Something went wrong.')).toBeInTheDocument()
  // })
})
