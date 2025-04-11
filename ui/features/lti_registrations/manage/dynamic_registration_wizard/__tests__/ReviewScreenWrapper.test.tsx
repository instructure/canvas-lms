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

import {screen, render} from '@testing-library/react'

import React from 'react'
import {ReviewScreenWrapper} from '../components/ReviewScreenWrapper'
import {mockConfigWithPlacements, mockRegistration, mockToolConfiguration} from './helpers'
import {LtiPlacements, type LtiPlacementWithIcon} from '../../model/LtiPlacement'
import {i18nLtiPlacement} from '../../model/i18nLtiPlacement'
import {createDynamicRegistrationOverlayStore} from '../DynamicRegistrationOverlayState'
import {i18nLtiScope} from '@canvas/lti/model/i18nLtiScope'
import {i18nLtiPrivacyLevelDescription} from '../../model/i18nLtiPrivacyLevel'

describe('ReviewScreen', () => {
  it('renders without error', () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.CourseNavigation,
      LtiPlacements.GlobalNavigation,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(
      <ReviewScreenWrapper
        registration={reg}
        overlayStore={overlayStore}
        transitionToConfirmationState={jest.fn()}
      />,
    )

    expect(screen.getByText('Review')).toBeInTheDocument()
  })

  it('renders a summary of requested permissions', () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.CourseNavigation,
      LtiPlacements.GlobalNavigation,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(
      <ReviewScreenWrapper
        registration={reg}
        overlayStore={overlayStore}
        transitionToConfirmationState={jest.fn()}
      />,
    )

    expect(screen.getByText('Permissions')).toBeInTheDocument()

    for (const scope of reg.configuration.scopes) {
      expect(screen.getByText(i18nLtiScope(scope))).toBeInTheDocument()
    }
    expect(screen.getByRole('button', {name: 'Edit Permissions'})).toBeInTheDocument()
  })

  it('renders a summary of the configured privacy level', () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.CourseNavigation,
      LtiPlacements.GlobalNavigation,
    ])
    config.privacy_level = 'public'
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    render(
      <ReviewScreenWrapper
        registration={reg}
        overlayStore={overlayStore}
        transitionToConfirmationState={jest.fn()}
      />,
    )

    expect(screen.getByText('Data Sharing')).toBeInTheDocument()
    expect(
      screen.getByText(i18nLtiPrivacyLevelDescription(reg.configuration.privacy_level!)),
    ).toBeInTheDocument()
    expect(screen.getByRole('button', {name: 'Edit Data Sharing'})).toBeInTheDocument()
  })

  it('renders a summary of the configured placements', () => {
    const placements = [
      LtiPlacements.CourseNavigation,
      LtiPlacements.GlobalNavigation,
      LtiPlacements.FileIndexMenu,
    ]
    const config = mockConfigWithPlacements(placements)

    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(
      <ReviewScreenWrapper
        registration={reg}
        overlayStore={overlayStore}
        transitionToConfirmationState={jest.fn()}
      />,
    )

    expect(screen.getByText('Placements')).toBeInTheDocument()
    placements.forEach(p => {
      expect(screen.getByText(i18nLtiPlacement(p))).toBeInTheDocument()
    })
    expect(screen.queryByText('File Index Menu')).not.toBeInTheDocument()
    expect(screen.getByRole('button', {name: 'Edit Placements'})).toBeInTheDocument()
  })

  it('renders a summary of the configured names', () => {
    const nickname = 'a great nickname'
    const description = 'a great description'
    const placementLabel = 'a great placement nickname'
    const config = mockConfigWithPlacements([
      LtiPlacements.CourseNavigation,
      LtiPlacements.GlobalNavigation,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    overlayStore.setState(s => {
      return {
        ...s,
        state: {
          ...s.state,
          adminNickname: nickname,
          overlay: {
            ...s.state.overlay,
            description,
            placements: Object.fromEntries(
              Object.entries(s.state.overlay.placements!).map(([k, p]) => [
                k,
                {
                  ...p,
                  text: placementLabel,
                },
              ]),
            ),
          },
        },
      }
    })
    render(
      <ReviewScreenWrapper
        registration={reg}
        overlayStore={overlayStore}
        transitionToConfirmationState={jest.fn()}
      />,
    )

    expect(screen.getByText('Naming')).toBeInTheDocument()
    expect(screen.getByText(nickname)).toBeInTheDocument()
    expect(screen.getByText(description)).toBeInTheDocument()
    expect(screen.getAllByText(placementLabel)).toHaveLength(reg.configuration.placements.length)
    expect(screen.getByText('Edit Naming')).toBeInTheDocument()
  })

  describe('Icon URLs summary', () => {
    it("says the 'Default' icon is being used if the user hasn't changed anything", () => {
      const config = mockConfigWithPlacements([
        LtiPlacements.CourseNavigation,
        LtiPlacements.GlobalNavigation,
      ])
      config.placements!.forEach(p => {
        p.icon_url = 'https://example.com/icon.png'
      })

      const reg = mockRegistration({}, config)

      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(
        <ReviewScreenWrapper
          registration={reg}
          overlayStore={overlayStore}
          transitionToConfirmationState={jest.fn()}
        />,
      )

      expect(screen.getByText('Icon URLs')).toBeInTheDocument()

      expect(screen.getByText('Default Icon')).toBeInTheDocument()
    })

    it("says a 'Default Icon' is being used if the configured url is blank and the tool has a top-level icon", () => {
      const placements: LtiPlacementWithIcon[] = [
        LtiPlacements.GlobalNavigation,
        LtiPlacements.FileIndexMenu,
        LtiPlacements.EditorButton,
      ]
      const config = mockConfigWithPlacements(placements)
      config.placements!.forEach(p => {
        p.icon_url = ''
      })

      const reg = mockRegistration({
        configuration: mockToolConfiguration({
          ...config,
          launch_settings: {
            icon_url: 'https://example.com/icon.png',
          },
        }),
      })

      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(
        <ReviewScreenWrapper
          registration={reg}
          overlayStore={overlayStore}
          transitionToConfirmationState={jest.fn()}
        />,
      )

      expect(screen.getByText('Icon URLs')).toBeInTheDocument()
      expect(screen.getAllByText('Default Icon')).toHaveLength(placements.length)
    })

    it("says a 'Custom Icon' is being used if the user added their own custom icon url", () => {
      const placements: LtiPlacementWithIcon[] = [
        LtiPlacements.GlobalNavigation,
        LtiPlacements.FileIndexMenu,
      ]
      const config = mockConfigWithPlacements(placements)
      config.placements!.forEach(p => {
        p.icon_url = 'https://example.com/icon.png'
      })

      const reg = mockRegistration({}, config)

      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      overlayStore.setState(s => {
        return {
          ...s,
          state: {
            ...s.state,
            overlay: {
              ...s.state.overlay,
              placements: Object.fromEntries(
                Object.entries(s.state.overlay.placements!).map(([k, p]) => [
                  k,
                  {
                    ...p,
                    icon_url: 'https://example.com/custom-icon.png',
                  },
                ]),
              ),
            },
          },
        }
      })

      render(
        <ReviewScreenWrapper
          registration={reg}
          overlayStore={overlayStore}
          transitionToConfirmationState={jest.fn()}
        />,
      )

      expect(screen.getByText('Icon URLs')).toBeInTheDocument()
      expect(screen.getAllByText('Custom Icon')).toHaveLength(placements.length)
    })

    it("says that a 'Generated Icon' is being used if the configured icon is blank, the tool doesn't have a top-level icon, and the placement is the editor button", () => {
      const placements: LtiPlacementWithIcon[] = [
        LtiPlacements.GlobalNavigation,
        LtiPlacements.FileIndexMenu,
        LtiPlacements.EditorButton,
      ]
      const config = mockConfigWithPlacements(placements)
      config.placements!.forEach(p => {
        p.icon_url = ''
      })

      const reg = mockRegistration({}, config)
      reg.configuration.launch_settings!.icon_url = ''

      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(
        <ReviewScreenWrapper
          registration={reg}
          overlayStore={overlayStore}
          transitionToConfirmationState={jest.fn()}
        />,
      )

      expect(screen.getByText('Icon URLs')).toBeInTheDocument()
      expect(screen.getByText('Generated Icon')).toBeInTheDocument()
    })

    it("says 'No Icon' is being used if the configured icon is blank and the tool doesn't have a top-level icon", () => {
      const placements: LtiPlacementWithIcon[] = [
        LtiPlacements.GlobalNavigation,
        LtiPlacements.FileIndexMenu,
      ]
      const config = mockConfigWithPlacements(placements)
      config.placements!.forEach(p => {
        p.icon_url = ''
      })

      const reg = mockRegistration({}, config)
      reg.configuration.launch_settings!.icon_url = ''

      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(
        <ReviewScreenWrapper
          registration={reg}
          overlayStore={overlayStore}
          transitionToConfirmationState={jest.fn()}
        />,
      )

      expect(screen.getByText('Icon URLs')).toBeInTheDocument()
      expect(screen.getAllByText('No Icon')).toHaveLength(placements.length)
    })
  })
})
