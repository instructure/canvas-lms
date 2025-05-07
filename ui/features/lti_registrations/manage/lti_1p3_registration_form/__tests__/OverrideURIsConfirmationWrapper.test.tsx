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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {OverrideURIsConfirmationWrapper} from '../components/OverrideURIsConfirmationWrapper'
import {createLti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {mockInternalConfiguration} from './helpers'
import {LtiPlacements} from '../../model/LtiPlacement'
import {LtiDeepLinkingRequest} from '../../model/LtiMessageType'
import {i18nLtiPlacement} from '../../model/i18nLtiPlacement'

describe('OverrideURIsConfirmation', () => {
  it('renders correctly', () => {
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: LtiPlacements.CourseNavigation}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextClicked = jest.fn()
    const onPreviousClicked = jest.fn()

    render(
      <OverrideURIsConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        onNextClicked={onNextClicked}
        onPreviousClicked={onPreviousClicked}
        reviewing={false}
      />,
    )

    expect(screen.getByText(/Override URIs/i)).toBeInTheDocument()
  })

  it('renders the correct number of override fields', () => {
    const internalConfig = mockInternalConfiguration({
      placements: [
        {placement: LtiPlacements.CourseNavigation},
        {placement: LtiPlacements.GlobalNavigation},
      ],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextClicked = jest.fn()
    const onPreviousClicked = jest.fn()

    render(
      <OverrideURIsConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        onNextClicked={onNextClicked}
        onPreviousClicked={onPreviousClicked}
        reviewing={false}
      />,
    )

    const state = overlayStore.getState().state
    const placements = state.placements.placements || []
    expect(screen.getAllByText(/^Override URI$/i)).toHaveLength(placements.length)
  })

  it('allows users to change the redirect URIs for a placement', async () => {
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: LtiPlacements.CourseNavigation}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextClicked = jest.fn()
    const onPreviousClicked = jest.fn()

    render(
      <OverrideURIsConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        onNextClicked={onNextClicked}
        onPreviousClicked={onPreviousClicked}
        reviewing={false}
      />,
    )

    const state = overlayStore.getState().state
    const placements = state.placements.placements || []
    const placement = placements[0]

    const input = screen.getByPlaceholderText(internalConfig.target_link_uri)
    await userEvent.click(input)
    await userEvent.clear(input)
    await userEvent.paste('https://new-uri.com')

    expect(overlayStore.getState().state.override_uris.placements[placement]!.uri).toBe(
      'https://new-uri.com',
    )
  })

  it('displays a friendly error message if the user enters an invalid URI', async () => {
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: LtiPlacements.CourseNavigation}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextClicked = jest.fn()
    const onPreviousClicked = jest.fn()

    render(
      <OverrideURIsConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        onNextClicked={onNextClicked}
        onPreviousClicked={onPreviousClicked}
        reviewing={false}
      />,
    )

    const input = screen.getByPlaceholderText('https://example.com')
    await userEvent.click(input)
    await userEvent.clear(input)
    await userEvent.paste('invalid-uri')
    await userEvent.tab()

    expect(screen.getByText('Invalid URL')).toBeInTheDocument()
  })

  it('disables the next button if any of the URIs are invalid', async () => {
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: LtiPlacements.CourseNavigation}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextClicked = jest.fn()
    const onPreviousClicked = jest.fn()
    render(
      <OverrideURIsConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        onNextClicked={onNextClicked}
        onPreviousClicked={onPreviousClicked}
        reviewing={false}
      />,
    )
    const input = screen.getByPlaceholderText('https://example.com')
    await userEvent.click(input)
    await userEvent.clear(input)
    await userEvent.paste('invalid-uri^&*&)')
    await userEvent.tab()

    await userEvent.click(screen.getByText('Next').closest('button')!)

    expect(input).toHaveFocus()
    expect(onNextClicked).not.toHaveBeenCalled()
  })

  it('allows users to change the message type on placements that support it', async () => {
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: LtiPlacements.ModuleMenuModal}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextClicked = jest.fn()
    const onPreviousClicked = jest.fn()

    render(
      <OverrideURIsConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        onNextClicked={onNextClicked}
        onPreviousClicked={onPreviousClicked}
        reviewing={false}
      />,
    )

    const radio = screen.getByLabelText(LtiDeepLinkingRequest)
    await userEvent.click(radio)

    expect(radio).toBeChecked()
  })

  it('displays the correct message type for placements that do not support changing the message type', () => {
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: LtiPlacements.EditorButton}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextClicked = jest.fn()
    const onPreviousClicked = jest.fn()

    render(
      <OverrideURIsConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        onNextClicked={onNextClicked}
        onPreviousClicked={onPreviousClicked}
        reviewing={false}
      />,
    )

    expect(screen.queryByLabelText(LtiDeepLinkingRequest)).not.toBeInTheDocument()
    expect(screen.getByText(LtiDeepLinkingRequest)).toBeInTheDocument()
  })

  it('displays all placements that are present in the overlay state', async () => {
    const internalConfig = mockInternalConfiguration({
      placements: [
        {placement: LtiPlacements.CourseNavigation},
        {placement: LtiPlacements.GlobalNavigation},
      ],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextClicked = jest.fn()
    const onPreviousClicked = jest.fn()

    render(
      <OverrideURIsConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        onNextClicked={onNextClicked}
        onPreviousClicked={onPreviousClicked}
        reviewing={false}
      />,
    )

    const state = overlayStore.getState().state
    const placements = state.placements.placements!

    placements.forEach(placement => {
      expect(screen.getByText(i18nLtiPlacement(placement))).toBeInTheDocument()
    })

    // Simulate a user going back and modifying available placements
    overlayStore.getState().togglePlacement(LtiPlacements.CourseNavigation)

    await waitFor(() => {
      expect(
        screen.queryByText(i18nLtiPlacement(LtiPlacements.CourseNavigation)),
      ).not.toBeInTheDocument()
    })
  })

  it("doesn't error when a new placement is added that doesn't have an override defined", async () => {
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: LtiPlacements.CourseNavigation}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const onNextClicked = jest.fn()
    const onPreviousClicked = jest.fn()

    render(
      <OverrideURIsConfirmationWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        onNextClicked={onNextClicked}
        onPreviousClicked={onPreviousClicked}
        reviewing={false}
      />,
    )

    const newPlacement = LtiPlacements.AccountNavigation
    overlayStore.getState().togglePlacement(newPlacement)

    await waitFor(() => {
      expect(screen.getByText(i18nLtiPlacement(newPlacement))).toBeInTheDocument()
    })
  })
})
