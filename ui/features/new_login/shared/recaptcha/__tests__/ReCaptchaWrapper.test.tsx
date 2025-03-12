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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React, {useRef} from 'react'
import ReCaptchaWrapper, {ReCaptchaWrapperRef} from '../ReCaptchaWrapper'

describe('ReCaptchaWrapper', () => {
  test('renders children inside the wrapper', () => {
    render(
      <ReCaptchaWrapper>
        <div data-testid="recaptcha-content">ReCaptcha Widget</div>
      </ReCaptchaWrapper>,
    )
    expect(screen.getByTestId('recaptcha-content')).toBeInTheDocument()
  })

  test('renders error message and icon when hasError is true', () => {
    render(<ReCaptchaWrapper hasError={true}>ReCaptcha Widget</ReCaptchaWrapper>)
    expect(screen.getByText('Please complete the verification.')).toBeInTheDocument()
    expect(screen.getByTestId('recaptcha-error-text')).toBeInTheDocument()
    const icon = screen.getByTestId('recaptcha-error-icon')
    expect(icon).toBeInTheDocument()
    expect(icon).toHaveAttribute('width', '0.875rem')
    expect(icon).toHaveAttribute('height', '0.875rem')
    expect(icon).toHaveStyle({verticalAlign: 'top'})
  })

  test('does not render error message or icon when hasError is false', () => {
    render(<ReCaptchaWrapper hasError={false}>ReCaptcha Widget</ReCaptchaWrapper>)
    expect(screen.queryByText('Please complete the verification.')).not.toBeInTheDocument()
    expect(screen.queryByTestId('recaptcha-error-icon')).not.toBeInTheDocument()
  })

  test('focus() method moves focus to the container', async () => {
    const user = userEvent.setup()
    const TestComponent = () => {
      const recaptchaRef = useRef<ReCaptchaWrapperRef>(null)
      return (
        <div>
          <button onClick={() => recaptchaRef.current?.focus()}>Focus Recaptcha</button>
          <ReCaptchaWrapper ref={recaptchaRef}>ReCaptcha Widget</ReCaptchaWrapper>
        </div>
      )
    }
    render(<TestComponent />)
    const focusButton = screen.getByText('Focus Recaptcha')
    const recaptchaContainer = screen.getByTestId('recaptcha-container')
    expect(recaptchaContainer).not.toHaveFocus()
    await user.click(focusButton)
    expect(recaptchaContainer).toHaveFocus()
  })
})
