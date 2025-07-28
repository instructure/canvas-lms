/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import Alerts, {AlertListProps, getAccountDescription, getCourseDescription} from '../AlertList'
import {alert, accountRole} from './helpers'
import {calculateUIMetadata} from '../utils'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import userEvent from '@testing-library/user-event'
import {CriterionType} from '../types'

const server = setupServer()

describe('AlertList', () => {
  const props: AlertListProps = {
    alerts: [alert],
    uiMetadata: calculateUIMetadata([accountRole]),
    contextId: '1',
    contextType: 'Account',
  }
  const getUrlPrefixFor = (resource: string, alertId?: string | number) =>
    `/${resource}/${props.contextId}/alerts${alertId ? `/${alertId}` : ''}`

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  describe.each([
    {contextType: 'Account', resource: 'accounts', description: getAccountDescription()},
    {contextType: 'Course', resource: 'courses', description: getCourseDescription()},
  ])(`when contextType is $contextType`, ({contextType, description, resource}) => {
    it('should render the correct description', () => {
      render(<Alerts {...props} contextType={contextType} />)

      const descriptionText = screen.getByText(description)
      expect(descriptionText).toBeInTheDocument()
    })

    describe('when it comes to delete an alert', () => {
      const url = getUrlPrefixFor(resource, alert.id)

      it('should show a success massage when the request succeed', async () => {
        server.use(http.delete(url, () => new HttpResponse(null, {status: 200})))
        render(<Alerts {...props} contextType={contextType} />)

        const deleteButton = screen.getByLabelText('Delete alert button')
        await userEvent.click(deleteButton)

        const successMessage = await screen.findAllByText('Alert deleted successfully.')
        expect(successMessage.length).toBeTruthy()
      })

      it('should show a error massage when the request fail', async () => {
        server.use(http.delete(url, () => new HttpResponse(null, {status: 500})))
        render(<Alerts {...props} contextType={contextType} />)

        const deleteButton = screen.getByLabelText('Delete alert button')
        await userEvent.click(deleteButton)

        const errorMessage = await screen.findAllByText(
          'Failed to delete alert. Please try again later.',
        )
        expect(errorMessage.length).toBeTruthy()
      })
    })

    describe('when it comes to edit an alert', () => {
      const url = getUrlPrefixFor(resource, alert.id)

      it('should show a success massage when the request succeed', async () => {
        server.use(http.put(url, () => HttpResponse.json(alert)))
        render(<Alerts {...props} contextType={contextType} />)

        const editButton = screen.getByLabelText('Edit alert button')
        await userEvent.click(editButton)
        const saveButton = screen.getByLabelText('Save Alert')
        await userEvent.click(saveButton)

        const successMessage = await screen.findAllByText('Alert updated successfully.')
        expect(successMessage.length).toBeTruthy()
      })

      it('should show a error massage when the request fail', async () => {
        server.use(http.put(url, () => new HttpResponse(null, {status: 500})))
        render(<Alerts {...props} contextType={contextType} />)

        const editButton = screen.getByLabelText('Edit alert button')
        await userEvent.click(editButton)
        const saveButton = screen.getByLabelText('Save Alert')
        await userEvent.click(saveButton)

        const errorMessage = await screen.findAllByText(
          'Failed to update alert. Please try again later.',
        )
        expect(errorMessage.length).toBeTruthy()
      })
    })

    describe('when it comes to create an alert', () => {
      const url = getUrlPrefixFor(resource)
      const expectedBodyPayload = {
        alert: {
          criteria: [{criterion_type: CriterionType.Interaction, threshold: 7}],
          recipients: [':student'],
          repetition: null,
        },
      }

      it('should show a success massage when the request succeed', async () => {
        server.use(http.post(url, () => HttpResponse.json(alert)))
        render(<Alerts {...props} alerts={[]} contextType={contextType} />)

        const createButton = screen.getByLabelText('Create new alert')
        await userEvent.click(createButton)
        const addTriggerButton = screen.getByLabelText('Add trigger')
        await userEvent.click(addTriggerButton)
        const sendToStudent = screen.getByLabelText('Student')
        await userEvent.click(sendToStudent)
        const saveButton = screen.getByLabelText('Save Alert')
        await userEvent.click(saveButton)

        const successMessage = await screen.findAllByText('Alert created successfully.')
        expect(successMessage.length).toBeTruthy()
      })

      it('should show a error massage when the request fail', async () => {
        server.use(http.post(url, () => new HttpResponse(null, {status: 500})))
        render(<Alerts {...props} alerts={[]} contextType={contextType} />)

        const createButton = screen.getByLabelText('Create new alert')
        await userEvent.click(createButton)
        const addTriggerButton = screen.getByLabelText('Add trigger')
        await userEvent.click(addTriggerButton)
        const sendToStudent = screen.getByLabelText('Student')
        await userEvent.click(sendToStudent)
        const saveButton = screen.getByLabelText('Save Alert')
        await userEvent.click(saveButton)

        const errorMessage = await screen.findAllByText(
          'Failed to create alert. Please try again later.',
        )
        expect(errorMessage.length).toBeTruthy()
      })
    })
  })
})
