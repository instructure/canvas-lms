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
import StudentOutcomeScore from '../StudentOutcomeScore'
import * as SVGUrl from '../icons'

describe('StudentOutcomeScore', () => {
  let svgUrlSpy

  const defaultProps = (props = {}) => {
    return {
      outcome: {
        id: '1',
        title: 'Title',
        mastery_points: 5,
        ratings: []
      },
      rollup: {
        rating: {
          color: 'FFFFF',
          points: 3,
          description: 'great!'
        }
      },
      ...props
    }
  }

  beforeEach(() => {
    svgUrlSpy = jest.spyOn(SVGUrl, 'svgUrl')
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('calls svgUrl with the right arguments', () => {
    render(<StudentOutcomeScore {...defaultProps()} />)
    expect(svgUrlSpy).toHaveBeenCalledWith(3, 5)
  })

  it('renders ScreenReaderContent with the rating description', () => {
    const {getByText} = render(<StudentOutcomeScore {...defaultProps()} />)
    expect(getByText('great!')).toBeInTheDocument()
  })

  it('renders ScreenReaderContent with "Unassessed" if there is no rollup rating', () => {
    const {getByText} = render(<StudentOutcomeScore {...defaultProps({rollup: {}})} />)
    expect(getByText('Unassessed')).toBeInTheDocument()
  })
})
