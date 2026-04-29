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

import {cleanup, render, screen} from '@testing-library/react'
import React from 'react'
import TermsAndPolicyCheckbox from '../TermsAndPolicyCheckbox'

afterEach(() => {
  cleanup()
})

describe('TermsAndPolicyCheckbox', () => {
  const termsOfUseUrl = '/acceptable_use_policy'
  const privacyPolicyUrl = 'http://www.canvaslms.com/policies/privacy-policy'

  it('mounts without crashing', () => {
    render(
      <TermsAndPolicyCheckbox
        id="terms-checkbox"
        checked={false}
        isDisabled={false}
        onChange={vi.fn()}
      />,
    )
  })

  it('renders both Acceptable Use Policy and Privacy Policy links when both URLs are provided', () => {
    render(
      <TermsAndPolicyCheckbox
        id="terms-checkbox"
        checked={false}
        isDisabled={false}
        onChange={vi.fn()}
        termsOfUseUrl={termsOfUseUrl}
        privacyPolicyUrl={privacyPolicyUrl}
      />,
    )
    expect(screen.getByText('Acceptable Use Policy')).toBeInTheDocument()
    expect(screen.getByText('Privacy Policy')).toBeInTheDocument()
    expect(screen.getByText('Acceptable Use Policy').closest('a')).toHaveAttribute(
      'href',
      termsOfUseUrl,
    )
    expect(screen.getByText('Privacy Policy').closest('a')).toHaveAttribute(
      'href',
      privacyPolicyUrl,
    )
  })

  it('renders only the Acceptable Use Policy link when only termsOfUseUrl is provided', () => {
    render(
      <TermsAndPolicyCheckbox
        id="terms-checkbox"
        checked={false}
        isDisabled={false}
        onChange={vi.fn()}
        termsOfUseUrl={termsOfUseUrl}
      />,
    )
    expect(screen.getByText('Acceptable Use Policy')).toBeInTheDocument()
    expect(screen.queryByText('Privacy Policy')).not.toBeInTheDocument()
    expect(screen.getByText('Acceptable Use Policy').closest('a')).toHaveAttribute(
      'href',
      termsOfUseUrl,
    )
  })

  it('renders only the privacy policy link when only privacyPolicyUrl is provided', () => {
    render(
      <TermsAndPolicyCheckbox
        id="terms-checkbox"
        checked={false}
        isDisabled={false}
        onChange={vi.fn()}
        privacyPolicyUrl={privacyPolicyUrl}
      />,
    )
    expect(screen.getByText('Privacy Policy')).toBeInTheDocument()
    expect(screen.queryByText('Acceptable Use Policy')).not.toBeInTheDocument()
    expect(screen.getByText('Privacy Policy').closest('a')).toHaveAttribute(
      'href',
      privacyPolicyUrl,
    )
  })

  it('renders nothing when neither termsOfUseUrl nor privacyPolicyUrl is provided', () => {
    const {container} = render(
      <TermsAndPolicyCheckbox
        id="terms-checkbox"
        checked={false}
        isDisabled={false}
        onChange={vi.fn()}
      />,
    )
    expect(container).toBeEmptyDOMElement()
  })

  it('displays the “required” indicator and associates with ARIA when isRequired is true', () => {
    render(
      <TermsAndPolicyCheckbox
        id="terms-checkbox"
        checked={false}
        isDisabled={false}
        onChange={vi.fn()}
        isRequired={true}
        termsOfUseUrl={termsOfUseUrl}
      />,
    )
    const checkbox = screen.getByTestId('terms-and-policy-checkbox')
    expect(checkbox).toHaveAttribute('aria-required', 'true')
    expect(screen.getByText('*')).toBeInTheDocument()
  })

  it('does not display the “required” indicator when isRequired is false or undefined', () => {
    render(
      <TermsAndPolicyCheckbox
        id="terms-checkbox"
        checked={false}
        isDisabled={false}
        onChange={vi.fn()}
        isRequired={false}
        termsOfUseUrl={termsOfUseUrl}
      />,
    )
    const checkbox = screen.getByTestId('terms-and-policy-checkbox')
    expect(checkbox).not.toHaveAttribute('aria-required')
    expect(screen.queryByText('*')).not.toBeInTheDocument()
  })

  it('prevents form submission when isRequired is true and the checkbox is unchecked', async () => {
    const mockOnChange = vi.fn()
    render(
      <TermsAndPolicyCheckbox
        id="terms-checkbox"
        checked={false}
        isDisabled={false}
        onChange={mockOnChange}
        isRequired={true}
        termsOfUseUrl={termsOfUseUrl}
      />,
    )
    const checkbox = screen.getByTestId('terms-and-policy-checkbox')
    expect(checkbox).not.toBeChecked()
    checkbox.focus()
    expect(mockOnChange).not.toHaveBeenCalled()
  })
})
