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
import * as ue from '@testing-library/user-event'
import {IconConfirmationWrapper} from '../components/IconConfirmationWrapper'
import {createLti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {mockInternalConfiguration} from './helpers'
import {LtiPlacements, type LtiPlacementWithIcon} from '../../model/LtiPlacement'
import {i18nLtiPlacement} from '../../model/i18nLtiPlacement'

const userEvent = ue.userEvent.setup({advanceTimers: jest.advanceTimersByTime})
describe('IconConfirmationWrapper', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    jest.useFakeTimers()
  })

  afterEach(() => {
    jest.runAllTimers()
    jest.useRealTimers()
  })

  it('renders correctly', () => {
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: LtiPlacements.GlobalNavigation}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextButtonClicked = jest.fn()
    const onPreviousButtonClicked = jest.fn()

    render(
      <IconConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        reviewing={false}
        onNextButtonClicked={onNextButtonClicked}
        onPreviousButtonClicked={onPreviousButtonClicked}
      />,
    )

    expect(screen.getByText(/Icon URLs/i)).toBeInTheDocument()
  })

  it('renders the correct number of icon inputs', () => {
    const internalConfig = mockInternalConfiguration({
      placements: [
        {placement: LtiPlacements.GlobalNavigation},
        {placement: LtiPlacements.EditorButton},
      ],
      launch_settings: {
        icon_url: 'https://example.com/icon',
      },
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextButtonClicked = jest.fn()
    const onPreviousButtonClicked = jest.fn()

    render(
      <IconConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        reviewing={false}
        onNextButtonClicked={onNextButtonClicked}
        onPreviousButtonClicked={onPreviousButtonClicked}
      />,
    )

    expect(screen.getAllByPlaceholderText(/https:\/\/example.com\/icon/i)).toHaveLength(2)
  })

  it('allows users to change the icon URL for a placement', async () => {
    const internalConfig = mockInternalConfiguration({
      placements: [
        {placement: LtiPlacements.GlobalNavigation, icon_url: 'https://example.com/icon/first'},
      ],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextButtonClicked = jest.fn()
    const onPreviousButtonClicked = jest.fn()

    render(
      <IconConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        reviewing={false}
        onNextButtonClicked={onNextButtonClicked}
        onPreviousButtonClicked={onPreviousButtonClicked}
      />,
    )

    const state = overlayStore.getState().state
    const placements = state.placements.placements!
    const placement = placements[0]

    const input = screen.getByLabelText(new RegExp(i18nLtiPlacement(placement)), {
      selector: 'input',
    })

    await userEvent.click(input)
    await userEvent.clear(input)
    await userEvent.paste('https://new-icon-url.com')
    jest.runAllTimers()

    expect(overlayStore.getState().state.icons.placements[placement as LtiPlacementWithIcon]).toBe(
      'https://new-icon-url.com',
    )
  })

  it('displays a friendly error message if the user enters an invalid URL', async () => {
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: 'global_navigation', icon_url: 'https://example.com/icon'}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextButtonClicked = jest.fn()
    const onPreviousButtonClicked = jest.fn()

    render(
      <IconConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        reviewing={false}
        onNextButtonClicked={onNextButtonClicked}
        onPreviousButtonClicked={onPreviousButtonClicked}
      />,
    )

    const input = screen.getByLabelText(
      new RegExp(i18nLtiPlacement(LtiPlacements.GlobalNavigation)),
    )
    await userEvent.click(input)
    await userEvent.clear(input)
    await userEvent.paste('invalid-url')
    await userEvent.tab()

    expect(screen.getByText('Invalid URL')).toBeInTheDocument()
  })

  it('focuses the invalid input if any of the URLs are invalid', async () => {
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: 'global_navigation', icon_url: 'https://example.com/icon'}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextButtonClicked = jest.fn()
    const onPreviousButtonClicked = jest.fn()
    render(
      <IconConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        reviewing={false}
        onNextButtonClicked={onNextButtonClicked}
        onPreviousButtonClicked={onPreviousButtonClicked}
      />,
    )
    const input = screen.getByLabelText(
      new RegExp(i18nLtiPlacement(LtiPlacements.GlobalNavigation)),
    )
    await userEvent.click(input)
    await userEvent.clear(input)
    await userEvent.paste('invalid-url')
    await userEvent.tab()

    await userEvent.click(screen.getByText('Next').closest('button')!)

    expect(input).toHaveFocus()
    expect(onNextButtonClicked).not.toHaveBeenCalled()
  })

  it('renders a default icon if no icon is provided for the editor button placement', () => {
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: LtiPlacements.EditorButton, icon_url: undefined}],
      launch_settings: {
        icon_url: undefined,
      },
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextButtonClicked = jest.fn()
    const onPreviousButtonClicked = jest.fn()

    render(
      <IconConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        reviewing={false}
        onNextButtonClicked={onNextButtonClicked}
        onPreviousButtonClicked={onPreviousButtonClicked}
      />,
    )

    expect(
      screen.getByText(
        'If left blank, a default icon resembling the one displayed will be provided. Color may vary.',
      ),
    ).toBeInTheDocument()
  })

  it('uses the default icon url if none is provided', async () => {
    const internalConfig = mockInternalConfiguration({
      placements: [
        {
          placement: LtiPlacements.GlobalNavigation,
          icon_url: 'https://example.com/agreatlittleicon',
        },
      ],
      launch_settings: {
        icon_url: 'https://example.com/icon',
      },
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextButtonClicked = jest.fn()
    const onPreviousButtonClicked = jest.fn()

    render(
      <IconConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        reviewing={false}
        onNextButtonClicked={onNextButtonClicked}
        onPreviousButtonClicked={onPreviousButtonClicked}
      />,
    )

    await userEvent.clear(
      screen.getByLabelText(new RegExp(i18nLtiPlacement(LtiPlacements.GlobalNavigation)), {
        selector: 'input',
      }),
    )

    expect(
      screen.getByText("If left blank, the tool's default icon will display."),
    ).toBeInTheDocument()
  })

  it('debounces input', async () => {
    const internalConfig = mockInternalConfiguration({
      placements: [
        {placement: LtiPlacements.GlobalNavigation, icon_url: 'https://example.com/icon/first'},
      ],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextButtonClicked = jest.fn()
    const onPreviousButtonClicked = jest.fn()

    render(
      <IconConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        reviewing={false}
        onNextButtonClicked={onNextButtonClicked}
        onPreviousButtonClicked={onPreviousButtonClicked}
      />,
    )

    const input = screen.getByLabelText(new RegExp('Global Navigation'), {
      selector: 'input',
    })

    await userEvent.clear(input)
    await userEvent.paste('https://new-icon-url.com')

    const img = screen.getByTestId(`img-icon-global_navigation`)

    expect(input).toHaveValue('https://new-icon-url.com')
    expect(overlayStore.getState().state.icons.placements[LtiPlacements.GlobalNavigation]).toBe(
      'https://new-icon-url.com',
    )
    expect(img).toHaveAttribute('src', 'https://example.com/icon/first')

    jest.runAllTimers()

    expect(overlayStore.getState().state.icons.placements[LtiPlacements.GlobalNavigation]).toBe(
      'https://new-icon-url.com',
    )
    expect(img).toHaveAttribute('src', 'https://new-icon-url.com')
  })

  it('handles users adding new placements', async () => {
    const internalConfig = mockInternalConfiguration({
      placements: [
        {placement: LtiPlacements.GlobalNavigation, icon_url: 'https://example.com/icon'},
      ],
      launch_settings: {
        icon_url: 'https://example.com/default_icon',
      },
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextButtonClicked = jest.fn()
    const onPreviousButtonClicked = jest.fn()

    render(
      <IconConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        reviewing={false}
        onNextButtonClicked={onNextButtonClicked}
        onPreviousButtonClicked={onPreviousButtonClicked}
      />,
    )

    overlayStore.getState().togglePlacement(LtiPlacements.EditorButton)
    jest.runAllTimers()

    const input = screen.getByLabelText(
      new RegExp(i18nLtiPlacement(LtiPlacements.GlobalNavigation), 'i'),
      {
        selector: 'input',
      },
    )

    expect(input).toHaveAttribute('placeholder', 'https://example.com/icon')
    const newPlacementInput: HTMLInputElement = screen.getByLabelText(
      new RegExp(i18nLtiPlacement(LtiPlacements.EditorButton), 'i'),
      {
        selector: 'input',
      },
    )

    expect(newPlacementInput.placeholder).toBe('https://example.com/default_icon')
    expect(newPlacementInput).toHaveValue('')
  })
})
