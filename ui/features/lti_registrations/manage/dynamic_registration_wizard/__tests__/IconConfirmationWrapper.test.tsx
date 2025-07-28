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
import {mockConfigWithPlacements, mockRegistration} from './helpers'
import {createDynamicRegistrationOverlayStore} from '../DynamicRegistrationOverlayState'
import {IconConfirmationWrapper} from '../components/IconConfirmationWrapper'
import {render, screen} from '@testing-library/react'
import * as ue from '@testing-library/user-event'
import {LtiPlacements, LtiPlacementsWithIcons} from '../../model/LtiPlacement'
import {i18nLtiPlacement} from '../../model/i18nLtiPlacement'

const userEvent = ue.userEvent.setup({advanceTimers: jest.advanceTimersByTime})

describe('IconConfirmation', () => {
  beforeEach(() => {
    jest.useFakeTimers()
    jest.resetAllMocks()
  })

  afterEach(() => {
    jest.runOnlyPendingTimers()
    jest.useRealTimers()
  })

  const mockTransitionToConfirmationState = jest.fn()
  const mockTransitionToReviewingState = jest.fn()

  it('should render', () => {
    const reg = mockRegistration()
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(
      <IconConfirmationWrapper
        registration={reg}
        overlayStore={overlayStore}
        reviewing={false}
        transitionToConfirmationState={mockTransitionToConfirmationState}
        transitionToReviewingState={mockTransitionToReviewingState}
      />,
    )

    expect(screen.getByText('Icon URLs')).toBeInTheDocument()
  })

  it('should render inputs for all placements that support icons', () => {
    const config = mockConfigWithPlacements([
      ...LtiPlacementsWithIcons,
      LtiPlacements.CourseNavigation,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(
      <IconConfirmationWrapper
        registration={reg}
        overlayStore={overlayStore}
        reviewing={false}
        transitionToConfirmationState={mockTransitionToConfirmationState}
        transitionToReviewingState={mockTransitionToReviewingState}
      />,
    )

    for (const placement of LtiPlacementsWithIcons) {
      expect(screen.getByText(i18nLtiPlacement(placement))).toBeInTheDocument()
    }

    expect(
      screen.queryByText(i18nLtiPlacement(LtiPlacements.CourseNavigation)),
    ).not.toBeInTheDocument()
  })

  it('lets the user change the icon url', async () => {
    const iconPlacement = LtiPlacementsWithIcons[0]
    const config = mockConfigWithPlacements([iconPlacement])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(
      <IconConfirmationWrapper
        registration={reg}
        overlayStore={overlayStore}
        reviewing={false}
        transitionToConfirmationState={mockTransitionToConfirmationState}
        transitionToReviewingState={mockTransitionToReviewingState}
      />,
    )

    const iconUrl = 'http://example.com/icon.png'

    const input = screen.getByLabelText(new RegExp(i18nLtiPlacement(iconPlacement)), {
      selector: 'input',
    })

    // Testing Library is *incredibly* slow at typing into inputs, so we'll just paste the value in
    await userEvent.clear(input)
    await userEvent.click(input)
    await userEvent.paste(iconUrl)

    expect(input).toHaveValue(iconUrl)
  })

  it('should render the default generated icon if no icon url is provided for the EditorButton, TopNavigation placements', () => {
    const defaultIconPlacements = [LtiPlacements.EditorButton, LtiPlacements.TopNavigation]
    const config = mockConfigWithPlacements([
      ...defaultIconPlacements,
      LtiPlacements.GlobalNavigation,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    render(
      <IconConfirmationWrapper
        registration={reg}
        overlayStore={overlayStore}
        reviewing={false}
        transitionToConfirmationState={mockTransitionToConfirmationState}
        transitionToReviewingState={mockTransitionToReviewingState}
      />,
    )

    for (const defaultIconPlacement of defaultIconPlacements) {
      const input = screen.getByLabelText(new RegExp(i18nLtiPlacement(defaultIconPlacement)), {
        selector: 'input',
      })

      expect(input).toHaveValue('')
      expect(
        screen.getByAltText(`${i18nLtiPlacement(defaultIconPlacement)} icon`),
      ).toBeInTheDocument()
    }
    expect(screen.getAllByText(/default icon resembling the one displayed/i)).toHaveLength(
      defaultIconPlacements.length,
    )
  })

  it("should render the tool's provided default icon if no value is provided at the placement level", async () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.GlobalNavigation,
      LtiPlacements.FileIndexMenu,
    ])
    config.placements!.find(p => p.placement === 'global_navigation')!.icon_url =
      'http://example.com/icon.png'
    config.placements!.find(p => p.placement === 'file_index_menu')!.icon_url =
      'http://example.com/icon2.png'
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    render(
      <IconConfirmationWrapper
        registration={reg}
        overlayStore={overlayStore}
        reviewing={false}
        transitionToConfirmationState={mockTransitionToConfirmationState}
        transitionToReviewingState={mockTransitionToReviewingState}
      />,
    )

    const iconPlacement = LtiPlacements.GlobalNavigation
    const input = screen.getByLabelText(new RegExp(i18nLtiPlacement(iconPlacement)), {
      selector: 'input',
    })

    await userEvent.clear(input)
    expect(input).toHaveValue('')
    expect(screen.getByAltText('Global Navigation icon')).toHaveAttribute(
      'src',
      'http://example.com/icon.png',
    )
    expect(screen.getByText(/the tool's default icon/i)).toBeInTheDocument()
  })

  it("should inform the user no icon is rendered if one isn't provided for non-EditorButton placements", async () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.GlobalNavigation,
      LtiPlacements.FileIndexMenu,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    render(
      <IconConfirmationWrapper
        registration={reg}
        overlayStore={overlayStore}
        reviewing={false}
        transitionToConfirmationState={mockTransitionToConfirmationState}
        transitionToReviewingState={mockTransitionToReviewingState}
      />,
    )

    const iconPlacement = LtiPlacements.GlobalNavigation
    const input = screen.getByLabelText(new RegExp(i18nLtiPlacement(iconPlacement)), {
      selector: 'input',
    })

    expect(input).toHaveValue('')
    await userEvent.clear(input)
    await userEvent.click(input)
    await userEvent.paste('http://example.com/icon.png')
    expect(screen.getByTitle('Files Index Menu icon')).toBeInTheDocument()
    expect(screen.getByText(/no icon will display/i)).toBeInTheDocument()
  })

  it("shouldn't allow invalid URLs and warn the user about them", async () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.GlobalNavigation,
      LtiPlacements.FileIndexMenu,
    ])

    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    render(
      <IconConfirmationWrapper
        registration={reg}
        overlayStore={overlayStore}
        reviewing={false}
        transitionToConfirmationState={mockTransitionToConfirmationState}
        transitionToReviewingState={mockTransitionToReviewingState}
      />,
    )

    const iconPlacement = LtiPlacements.GlobalNavigation
    const input = screen.getByLabelText(new RegExp(i18nLtiPlacement(iconPlacement)), {
      selector: 'input',
    })

    await userEvent.clear(input)
    await userEvent.click(input)
    await userEvent.paste('invalid-url')
    await userEvent.tab()

    expect(input).toHaveValue('invalid-url')
    expect(screen.getByText(/invalid URL/i)).toBeInTheDocument()
    expect(screen.getByTitle('Global Navigation icon')).not.toHaveAttribute('src', 'invalid-url')
  })

  it('should transition to reviewing state when all icons are valid and the next button is clicked', async () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.GlobalNavigation,
      LtiPlacements.FileIndexMenu,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    render(
      <IconConfirmationWrapper
        registration={reg}
        overlayStore={overlayStore}
        reviewing={false}
        transitionToConfirmationState={mockTransitionToConfirmationState}
        transitionToReviewingState={mockTransitionToReviewingState}
      />,
    )
    const iconPlacement = LtiPlacements.GlobalNavigation
    const input = screen.getByLabelText(new RegExp(i18nLtiPlacement(iconPlacement)), {
      selector: 'input',
    })
    await userEvent.clear(input)
    await userEvent.click(input)
    await userEvent.paste('http://example.com/icon.png')
    // Wait for debouncing
    jest.runOnlyPendingTimers()
    expect(input).toHaveValue('http://example.com/icon.png')
    expect(screen.getByAltText('Global Navigation icon')).toHaveAttribute(
      'src',
      'http://example.com/icon.png',
    )
    const nextButton = screen.getByRole('button', {name: /next/i})
    await userEvent.click(nextButton)
    expect(mockTransitionToReviewingState).toHaveBeenCalledTimes(1)
  })

  it("should render the image provided in the icon url if it's a valid URL", async () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.GlobalNavigation,
      LtiPlacements.FileIndexMenu,
    ])

    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    render(
      <IconConfirmationWrapper
        registration={reg}
        overlayStore={overlayStore}
        reviewing={false}
        transitionToConfirmationState={mockTransitionToConfirmationState}
        transitionToReviewingState={mockTransitionToReviewingState}
      />,
    )

    const iconPlacement = LtiPlacements.GlobalNavigation
    const input = screen.getByLabelText(new RegExp(i18nLtiPlacement(iconPlacement)), {
      selector: 'input',
    })

    await userEvent.clear(input)
    await userEvent.click(input)
    await userEvent.paste('http://example.com/icon.png')
    // Wait for debouncing
    jest.runOnlyPendingTimers()

    expect(input).toHaveValue('http://example.com/icon.png')
    expect(screen.getByAltText('Global Navigation icon')).toHaveAttribute(
      'src',
      'http://example.com/icon.png',
    )
  })

  it('should render a Back to Review button when the user is reviewing', () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.GlobalNavigation,
      LtiPlacements.FileIndexMenu,
    ])

    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(
      <IconConfirmationWrapper
        overlayStore={overlayStore}
        registration={reg}
        reviewing={true}
        transitionToConfirmationState={mockTransitionToConfirmationState}
        transitionToReviewingState={mockTransitionToReviewingState}
      />,
    )

    const backButton = screen.getByRole('button', {name: /back to review/i})
    expect(backButton).toBeInTheDocument()
  })
})
