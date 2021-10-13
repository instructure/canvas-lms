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

import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import ExternalToolOptions from '../ExternalToolOptions'

const studio = {name: 'Studio', _id: '1', settings: {iconUrl: '/url'}}
const office = {name: 'Office 365', _id: '2', settings: {iconUrl: '/url'}}
const google = {name: 'Google Drive', _id: '3', settings: {iconUrl: '/url'}}
const dropbox = {name: 'Dropbox', _id: '4', settings: {iconUrl: '/url'}}
const rollcall = {name: 'Rollcall', _id: '5', settings: {iconUrl: '/url'}}

describe('ExternalToolOptions', () => {
  let updateActiveSubmissionType

  beforeEach(() => {
    updateActiveSubmissionType = jest.fn()
  })

  it('renders a tool with the name Studio as its own button', () => {
    const {getByRole, queryByRole} = render(
      <ExternalToolOptions
        activeSubmissionType="basic_lti_launch"
        externalTools={[studio]}
        updateActiveSubmissionType={updateActiveSubmissionType}
      />
    )

    expect(getByRole('button', {name: /Studio/})).toBeInTheDocument()
    expect(queryByRole('button', {name: /More/})).not.toBeInTheDocument()
  })

  it('renders a tool with the name Office 365 as its own button', () => {
    const {getByRole, queryByRole} = render(
      <ExternalToolOptions
        activeSubmissionType="basic_lti_launch"
        externalTools={[office]}
        updateActiveSubmissionType={updateActiveSubmissionType}
      />
    )

    expect(getByRole('button', {name: /Office 365/})).toBeInTheDocument()
    expect(queryByRole('button', {name: /More/})).not.toBeInTheDocument()
  })

  it('renders a tool with the name Google Drive as its own button', () => {
    const {getByRole, queryByRole} = render(
      <ExternalToolOptions
        activeSubmissionType="basic_lti_launch"
        externalTools={[google]}
        updateActiveSubmissionType={updateActiveSubmissionType}
      />
    )

    expect(getByRole('button', {name: /Google Drive/})).toBeInTheDocument()
    expect(queryByRole('button', {name: /More/})).not.toBeInTheDocument()
  })

  it('renders any other tools as menu items triggered by a "More" button', () => {
    const {getAllByRole} = render(
      <ExternalToolOptions
        activeSubmissionType="basic_lti_launch"
        externalTools={[dropbox, rollcall]}
        updateActiveSubmissionType={updateActiveSubmissionType}
      />
    )

    fireEvent.click(getAllByRole('button', {name: /More/})[0])

    const menuItems = getAllByRole('menuitem')
    expect(menuItems[0]).toHaveTextContent(/Dropbox/)
    expect(menuItems[1]).toHaveTextContent(/Rollcall/)

    fireEvent.click(menuItems[0])
    expect(updateActiveSubmissionType).toHaveBeenCalledWith('basic_lti_launch', dropbox)
  })

  it('calls the updateActiveSubmissionType prop when a tool is selected', () => {
    const {getByRole} = render(
      <ExternalToolOptions
        activeSubmissionType="basic_lti_launch"
        externalTools={[google, dropbox]}
        updateActiveSubmissionType={updateActiveSubmissionType}
      />
    )

    fireEvent.click(getByRole('button', {name: /Google Drive/}))
    expect(updateActiveSubmissionType).toHaveBeenCalledWith('basic_lti_launch', google)
  })
})
