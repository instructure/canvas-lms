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
import TermsAndPolicyCheckbox from '../TermsAndPolicyCheckbox'
import {render, screen} from '@testing-library/react'

describe('TermsAndPolicyCheckbox', () => {
  const termsOfUseUrl = 'http://www.canvaslms.com/policies/terms-of-use'
  const privacyPolicyUrl = 'http://www.canvaslms.com/policies/privacy-policy'

  it('mounts without crashing', () => {
    render(<TermsAndPolicyCheckbox checked={false} isDisabled={false} onChange={jest.fn()} />)
  })

  it('renders both terms of use and privacy policy links when both URLs are provided', () => {
    render(
      <TermsAndPolicyCheckbox
        checked={false}
        isDisabled={false}
        onChange={jest.fn()}
        termsOfUseUrl={termsOfUseUrl}
        privacyPolicyUrl={privacyPolicyUrl}
      />
    )
    expect(screen.getByText('terms of use')).toBeInTheDocument()
    expect(screen.getByText('privacy policy')).toBeInTheDocument()
    expect(screen.getByText('terms of use').closest('a')).toHaveAttribute('href', termsOfUseUrl)
    expect(screen.getByText('privacy policy').closest('a')).toHaveAttribute(
      'href',
      privacyPolicyUrl
    )
  })

  it('renders only the terms of use link when only termsOfUseUrl is provided', () => {
    render(
      <TermsAndPolicyCheckbox
        checked={false}
        isDisabled={false}
        onChange={jest.fn()}
        termsOfUseUrl={termsOfUseUrl}
      />
    )
    expect(screen.getByText('terms of use')).toBeInTheDocument()
    expect(screen.queryByText('privacy policy')).not.toBeInTheDocument()
    expect(screen.getByText('terms of use').closest('a')).toHaveAttribute('href', termsOfUseUrl)
  })

  it('renders only the privacy policy link when only privacyPolicyUrl is provided', () => {
    render(
      <TermsAndPolicyCheckbox
        checked={false}
        isDisabled={false}
        onChange={jest.fn()}
        privacyPolicyUrl={privacyPolicyUrl}
      />
    )
    expect(screen.getByText('privacy policy')).toBeInTheDocument()
    expect(screen.queryByText('terms of use')).not.toBeInTheDocument()
    expect(screen.getByText('privacy policy').closest('a')).toHaveAttribute(
      'href',
      privacyPolicyUrl
    )
  })

  it('renders nothing when neither termsOfUseUrl nor privacyPolicyUrl is provided', () => {
    const {container} = render(
      <TermsAndPolicyCheckbox checked={false} isDisabled={false} onChange={jest.fn()} />
    )
    expect(container).toBeEmptyDOMElement()
  })
})
