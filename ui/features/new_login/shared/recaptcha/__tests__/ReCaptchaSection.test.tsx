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

import {act, render, screen, waitFor} from '@testing-library/react'
import React, {createRef} from 'react'
import {ReCaptchaSection, type ReCaptchaSectionRef} from '../index'

beforeAll(() => {
  window.grecaptcha = {
    ready: jest.fn(callback => callback()),
    render: jest.fn(() => 1),
    reset: jest.fn(),
  }
})

afterAll(() => {
  delete window.grecaptcha
})

describe('ReCaptchaSection', () => {
  it('mounts without crashing', () => {
    const props = {
      onVerify: jest.fn(),
      recaptchaKey: 'test-site-key',
    }
    const {container} = render(<ReCaptchaSection {...props} />)
    expect(container).toBeInTheDocument()
    expect(window.grecaptcha.ready).toHaveBeenCalled()
    expect(window.grecaptcha.render).toHaveBeenCalled()
  })

  it('validates reCAPTCHA and triggers error state if missing', () => {
    const props = {
      onVerify: jest.fn(),
      recaptchaKey: 'test-site-key',
    }
    const ref = createRef<ReCaptchaSectionRef>()
    render(<ReCaptchaSection ref={ref} {...props} />)
    act(() => {
      expect(ref.current?.validate()).toBe(false)
    })
    expect(screen.getByText(/please complete the verification/i)).toBeInTheDocument()
  })

  it('resets reCAPTCHA and clears error state', () => {
    const props = {
      onVerify: jest.fn(),
      recaptchaKey: 'test-site-key',
    }
    const ref = createRef<ReCaptchaSectionRef>()
    render(<ReCaptchaSection ref={ref} {...props} />)
    act(() => {
      ref.current?.validate()
    })
    expect(screen.getByText(/please complete the verification/i)).toBeInTheDocument()
    act(() => {
      ref.current?.reset()
    })
    expect(screen.queryByText(/please complete the verification/i)).not.toBeInTheDocument()
    expect(window.grecaptcha.reset).toHaveBeenCalled()
  })

  it('sets error when an invalid token is received', async () => {
    const props = {
      onVerify: jest.fn(),
      recaptchaKey: 'test-site-key',
    }
    const ref = createRef<ReCaptchaSectionRef>()
    render(<ReCaptchaSection ref={ref} {...props} />)
    expect(screen.queryByText('Please complete the verification.')).not.toBeInTheDocument()
    act(() => {
      ref.current?.validate()
    })
    await waitFor(() => {
      expect(screen.getByText('Please complete the verification.')).toBeInTheDocument()
    })
  })

  it('removes error when a valid token is received', async () => {
    const props = {
      onVerify: jest.fn(),
      recaptchaKey: 'test-site-key',
    }
    const ref = createRef<ReCaptchaSectionRef>()
    render(<ReCaptchaSection ref={ref} {...props} />)
    act(() => {
      ref.current?.validate()
    })
    await waitFor(() => {
      expect(screen.getByText(/please complete the verification/i)).toBeInTheDocument()
    })
    act(() => {
      ref.current?.reset()
    })
    await waitFor(() => {
      expect(screen.queryByText(/please complete the verification/i)).not.toBeInTheDocument()
    })
  })
})
