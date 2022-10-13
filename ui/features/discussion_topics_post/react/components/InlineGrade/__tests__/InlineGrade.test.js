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

import {render} from '@testing-library/react'
import React from 'react'
import {InlineGrade} from '../InlineGrade'

jest.mock('../../../utils', () => ({
  ...jest.requireActual('../../../utils'),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}}),
}))

const setup = props => {
  return render(<InlineGrade {...props} />)
}

const defaultProps = ({
  isGraded = false,
  isLoading = false,
  currentGrade = '',
  pointsPossible = '100',
} = {}) => ({
  isGraded,
  isLoading,
  currentGrade,
  pointsPossible,
})

describe('DiscussionTopicAlertManager', () => {
  it('should render ungraded icon', async () => {
    const container = setup(defaultProps())
    expect(await container.findByTestId('inline-grade-ungraded-status')).toBeTruthy()
  })

  it('should render loading icon', async () => {
    const container = setup(defaultProps({isLoading: true}))
    expect(await container.findByTestId('inline-grade-loading-status')).toBeTruthy()
  })

  it('should render graded icon', async () => {
    const container = setup(defaultProps({isGraded: true}))
    expect(await container.findByTestId('inline-grade-graded-status')).toBeTruthy()
  })

  it('should set current grade', () => {
    const container = setup(defaultProps({currentGrade: '80'}))
    expect(container.container.querySelector('input').value).toEqual('80')
  })

  it('should set points possible', () => {
    const container = setup(defaultProps())
    expect(container.getByText('/100')).toBeTruthy()
  })
})
