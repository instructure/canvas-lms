/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import $ from 'jquery'
import 'compiled/jquery.rails_flash_notifications'
import React from 'react'
import {render, waitForElementToBeRemoved} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import {courseMocks, accountMocks} from './mocks'
import OutcomeManagementPanel from '../index'

describe('OutcomeManagementPanel', () => {
  it('renders the empty billboard for accounts without child outcomes', async () => {
    const {getByText, queryByText} = render(
      <MockedProvider mocks={accountMocks({childGroupsCount: 0})}>
        <OutcomeManagementPanel contextType="Account" contextId="1" />
      </MockedProvider>
    )
    await waitForElementToBeRemoved(() => queryByText('Loading'))
    expect(getByText(/Outcomes have not been added to this account yet/)).not.toBeNull()
  })

  it('renders the empty billboard for courses without child outcomes', async () => {
    const {getByText, queryByText} = render(
      <MockedProvider mocks={courseMocks({childGroupsCount: 0})}>
        <OutcomeManagementPanel contextType="Course" contextId="2" />
      </MockedProvider>
    )
    await waitForElementToBeRemoved(() => queryByText('Loading'))
    expect(getByText(/Outcomes have not been added to this course yet/)).not.toBeNull()
  })

  it('loads outcome group data for Account', async () => {
    const {getByText, queryByText} = render(
      <MockedProvider mocks={accountMocks()}>
        <OutcomeManagementPanel contextType="Account" contextId="1" />
      </MockedProvider>
    )
    expect(getByText('Loading')).toBeInTheDocument()
    await waitForElementToBeRemoved(() => queryByText('Loading'))
    expect(getByText(/Outcome Groups/)).toBeInTheDocument()
  })

  it('loads outcome group data for Course', async () => {
    const {getByText, queryByText} = render(
      <MockedProvider mocks={courseMocks()}>
        <OutcomeManagementPanel contextType="Course" contextId="2" />
      </MockedProvider>
    )
    expect(getByText('Loading')).toBeInTheDocument()
    await waitForElementToBeRemoved(() => queryByText('Loading'))
    expect(getByText(/Outcome Groups/)).toBeInTheDocument()
  })

  it('displays an error on failed request for course outcome groups', async () => {
    const flashMock = jest.spyOn($, 'flashError').mockImplementation()
    const {getByText, queryByText} = render(
      <MockedProvider mocks={[]}>
        <OutcomeManagementPanel contextType="Course" contextId="2" />
      </MockedProvider>
    )
    await waitForElementToBeRemoved(() => queryByText('Loading'))
    expect(flashMock).toHaveBeenCalledWith('An error occurred while loading course outcomes.')
    expect(getByText(/course/)).toBeInTheDocument()
  })

  it('displays an error on failed request for account outcome groups', async () => {
    const flashMock = jest.spyOn($, 'flashError').mockImplementation()
    const {getByText, queryByText} = render(
      <MockedProvider mocks={[]}>
        <OutcomeManagementPanel contextType="Account" contextId="1" />
      </MockedProvider>
    )

    await waitForElementToBeRemoved(() => queryByText('Loading'))
    expect(flashMock).toHaveBeenCalledWith('An error occurred while loading account outcomes.')
    expect(getByText(/account/)).toBeInTheDocument()
  })
})
