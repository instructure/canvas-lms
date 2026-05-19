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

import React from 'react'
import {render, screen} from '@testing-library/react'
import {IconUrlsReadOnlyView} from '../IconUrlsReadOnlyView'
import {LtiPlacements} from '../../model/LtiPlacement'
import type {InternalPlacementConfiguration} from '../../model/internal_lti_configuration/placement_configuration/InternalPlacementConfiguration'

describe('IconUrlsReadOnlyView', () => {
  const toolIconUrl = 'https://example.com/tool-icon.png'
  const registrationName = 'Test Tool'

  it('shows placement-specific icon_url when set', () => {
    const placements: InternalPlacementConfiguration[] = [
      {
        placement: LtiPlacements.CourseNavigation,
        message_type: 'LtiResourceLinkRequest',
        icon_url: 'https://example.com/placement-icon.png',
      },
    ]

    render(
      <IconUrlsReadOnlyView
        toolIconUrl={toolIconUrl}
        placements={placements}
        registrationName={registrationName}
      />,
    )

    const iconUrlEl = screen.getByTestId(`icon-url-${LtiPlacements.CourseNavigation}`)
    expect(iconUrlEl).toHaveTextContent('https://example.com/placement-icon.png')
  })

  it('falls back to toolIconUrl when placement has no icon_url', () => {
    const placements: InternalPlacementConfiguration[] = [
      {
        placement: LtiPlacements.CourseNavigation,
        message_type: 'LtiResourceLinkRequest',
      },
    ]

    render(
      <IconUrlsReadOnlyView
        toolIconUrl={toolIconUrl}
        placements={placements}
        registrationName={registrationName}
      />,
    )

    const iconUrlEl = screen.getByTestId(`icon-url-${LtiPlacements.CourseNavigation}`)
    expect(iconUrlEl).toHaveTextContent('Default Icon')

    const imgs = screen.getAllByRole('img')
    const placementImg = imgs.find(img => img.getAttribute('src') === toolIconUrl)
    expect(placementImg).toBeTruthy()
  })

  it('prefers toolIconUrl over auto-generated default for placements that support default icons', () => {
    const placements: InternalPlacementConfiguration[] = [
      {
        placement: LtiPlacements.EditorButton,
        message_type: 'LtiDeepLinkingRequest',
      },
    ]

    render(
      <IconUrlsReadOnlyView
        toolIconUrl={toolIconUrl}
        placements={placements}
        registrationName={registrationName}
      />,
    )

    const iconUrlEl = screen.getByTestId(`icon-url-${LtiPlacements.EditorButton}`)
    expect(iconUrlEl).toHaveTextContent('Default Icon')

    const imgs = screen.getAllByRole('img')
    const placementImg = imgs.find(img => img.getAttribute('src') === toolIconUrl)
    expect(placementImg).toBeTruthy()
  })

  it('shows auto-generated default icon for placements that support it when no toolIconUrl', () => {
    const placements: InternalPlacementConfiguration[] = [
      {
        placement: LtiPlacements.EditorButton,
        message_type: 'LtiDeepLinkingRequest',
      },
    ]

    render(
      <IconUrlsReadOnlyView
        toolIconUrl={undefined}
        placements={placements}
        registrationName={registrationName}
      />,
    )

    const iconUrlEl = screen.getByTestId(`icon-url-${LtiPlacements.EditorButton}`)
    expect(iconUrlEl).toHaveTextContent('Default Icon')
  })

  it('shows "Not Included" when no icon_url, no toolIconUrl, and placement has no default', () => {
    const placements: InternalPlacementConfiguration[] = [
      {
        placement: LtiPlacements.CourseNavigation,
        message_type: 'LtiResourceLinkRequest',
      },
    ]

    render(
      <IconUrlsReadOnlyView
        toolIconUrl={undefined}
        placements={placements}
        registrationName={registrationName}
      />,
    )

    const iconUrlEl = screen.getByTestId(`icon-url-${LtiPlacements.CourseNavigation}`)
    expect(iconUrlEl).toHaveTextContent('Not Included')
  })
})
