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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import {RegistrationWizardModal} from '../RegistrationWizardModal'
import {ZAccountId} from '../../model/AccountId'
import {
  openDynamicRegistrationWizard,
  openRegistrationWizard,
  useRegistrationModalWizardState,
} from '../RegistrationWizardModalState'

describe('RegistrationWizardModal', () => {
  let error: (...data: any[]) => void
  let warn: (...data: any[]) => void

  beforeAll(() => {
    // instui logs an error when we render a component
    // immediately under Modal

    // eslint-disable-next-line no-console
    error = console.error
    // eslint-disable-next-line no-console
    warn = console.warn

    // eslint-disable-next-line no-console
    console.error = jest.fn()
    // eslint-disable-next-line no-console
    console.warn = jest.fn()
  })

  afterAll(() => {
    // eslint-disable-next-line no-console
    console.error = error
    // eslint-disable-next-line no-console
    console.warn = warn
  })

  describe('When opened normally', () => {
    beforeEach(() => {
      openRegistrationWizard({
        dynamicRegistrationUrl: '',
        unifiedToolId: '',
        lti_version: '1p3',
        method: 'dynamic_registration',
        registering: false,
        progress: 0,
        progressMax: 100,
        exitOnCancel: false,
      })
    })

    afterEach(() => {
      useRegistrationModalWizardState.getState().close()
    })

    it('should render the modal title', () => {
      const accountId = ZAccountId.parse('123')
      render(<RegistrationWizardModal accountId={accountId} />)
      const headerText = screen.getByText(/Install App/i)
      expect(headerText).toBeInTheDocument()
    })

    it('should disable the next button when there is no dynamic registration url', () => {
      const accountId = ZAccountId.parse('123')
      render(<RegistrationWizardModal accountId={accountId} />)
      const nextButton = screen.getByRole('button', {
        name: /Next/i,
      })
      expect(nextButton).toBeInTheDocument()
      expect(nextButton).toBeDisabled()
    })

    it('should enable the next button when there is a valid url in the dynamic registration input', () => {
      const accountId = ZAccountId.parse('123')
      render(<RegistrationWizardModal accountId={accountId} />)
      const urlInput = screen.getByLabelText(/Dynamic Registration URL/i, {selector: 'input'})
      fireEvent.change(urlInput, {target: {value: 'https://example.com'}})
      const nextButton = screen.getByRole('button', {
        name: /Next/i,
      })
      expect(nextButton).toBeInTheDocument()
      expect(nextButton).toBeEnabled()
    })

    it('should render the dynamic registration wizard when dynamic registration is selected', () => {
      const accountId = ZAccountId.parse('123')
      const screen = render(<RegistrationWizardModal accountId={accountId} />)
      const urlInput = screen.getByLabelText(/Dynamic Registration URL/i, {selector: 'input'})
      fireEvent.change(urlInput, {target: {value: 'https://example.com'}})
      const nextButton = screen.getByRole('button', {
        name: /Next/i,
      })
      fireEvent.click(nextButton)
      // expect the dynamic registration wizard to be rendered
      const el = screen.getByText(/Loading/i, {ignore: 'title'})
      expect(el).toBeInTheDocument()
    })
  })

  describe('when pre-opened with dynamic registration', () => {
    it('should exit the modal when the cancel button is clicked & exitOnCancel is true', async () => {
      openRegistrationWizard({
        dynamicRegistrationUrl: 'http://example.com',
        unifiedToolId: 'asdf',
        lti_version: '1p3',
        method: 'dynamic_registration',
        registering: true,
        progress: 0,
        progressMax: 100,
        exitOnCancel: true,
      })
      const accountId = ZAccountId.parse('123')
      const screen = render(<RegistrationWizardModal accountId={accountId} />)
      const cancelButton = screen.getByRole('button', {
        name: /Cancel/i,
      })
      fireEvent.click(cancelButton)
      await waitFor(() => {
        expect(screen.queryByText(/Install App/i)).not.toBeInTheDocument()
      })
    })
  })
})
