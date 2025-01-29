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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import UsageRightsIndicator from '../UsageRightsIndicator'
import Folder from '../../../backbone/models/Folder'
import File from '../../../backbone/models/File'

describe('UsageRightsIndicator', () => {
  const defaultProps = {
    modalOptions: {
      openModal: jest.fn(),
    },
    userCanEditFilesForContext: false,
    userCanRestrictFilesForContext: false,
    usageRightsRequiredForContext: true,
    suppressWarning: false,
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders nothing for folders', () => {
    const {container} = render(
      <UsageRightsIndicator {...defaultProps} model={new Folder({id: 3})} />,
    )
    expect(container).toBeEmptyDOMElement()
  })

  it('renders nothing if usage rights not required and model has no usage rights', () => {
    const {container} = render(
      <UsageRightsIndicator
        {...defaultProps}
        usageRightsRequiredForContext={false}
        model={new File({id: 4})}
      />,
    )
    expect(container).toBeEmptyDOMElement()
  })

  it('renders button if usage rights required, user can edit, and model has no usage rights', () => {
    render(
      <UsageRightsIndicator
        {...defaultProps}
        model={new File({id: 4})}
        userCanEditFilesForContext={true}
      />,
    )
    const button = screen.getByRole('button')
    expect(button).toBeInTheDocument()
    expect(button.type).toBe('submit')
    expect(button).toHaveClass('UsageRightsIndicator__openModal')
  })

  it('opens modal when button is clicked', async () => {
    const openModal = jest.fn()
    render(
      <UsageRightsIndicator
        {...defaultProps}
        model={new File({id: 4})}
        userCanEditFilesForContext={true}
        modalOptions={{openModal}}
      />,
    )

    await userEvent.click(screen.getByRole('button'))
    expect(openModal).toHaveBeenCalled()
  })

  it('displays publish warning when not suppressed', () => {
    render(
      <UsageRightsIndicator
        {...defaultProps}
        model={new File({id: 4})}
        userCanEditFilesForContext={true}
        suppressWarning={false}
      />,
    )

    expect(screen.getByRole('button')).toHaveAttribute(
      'title',
      'Before publishing this file, you must specify usage rights.',
    )
  })

  it('does not display publish warning when suppressed', () => {
    render(
      <UsageRightsIndicator
        {...defaultProps}
        model={new File({id: 4})}
        userCanEditFilesForContext={true}
        suppressWarning={true}
      />,
    )

    expect(screen.getByRole('button')).toHaveAttribute('title', 'Manage usage rights')
  })

  describe('usage rights indicators', () => {
    it('shows own copyright indicator with correct text', () => {
      const usage_rights = {
        use_justification: 'own_copyright',
        legal_copyright: 'Test Copyright',
      }

      render(
        <UsageRightsIndicator
          {...defaultProps}
          model={new File({id: 4, usage_rights})}
          userCanEditFilesForContext={true}
        />,
      )

      const indicator = screen.getByRole('button')
      expect(indicator).toHaveClass('UsageRightsIndicator__openModal')
      expect(indicator.querySelector('i')).toHaveClass('icon-files-copyright')
      expect(indicator).toHaveAccessibleName('Set usage rights')
    })

    it('shows creative commons indicator with correct text', () => {
      const usage_rights = {
        use_justification: 'creative_commons',
        license_name: 'CC Attribution',
      }

      render(
        <UsageRightsIndicator
          {...defaultProps}
          model={new File({id: 4, usage_rights})}
          userCanEditFilesForContext={true}
        />,
      )

      const indicator = screen.getByRole('button')
      expect(indicator).toHaveClass('UsageRightsIndicator__openModal')
      expect(indicator.querySelector('i')).toHaveClass('icon-files-creative-commons')
      expect(indicator).toHaveAccessibleName('Set usage rights')
    })
  })
})
