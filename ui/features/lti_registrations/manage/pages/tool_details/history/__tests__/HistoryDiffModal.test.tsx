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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {HistoryDiffModal} from '../HistoryDiffModal'
import type {ConfigChangeHistoryEntry} from '../../../../model/LtiRegistrationHistoryEntry'
import {ZLtiRegistrationHistoryEntryId} from '../../../../model/LtiRegistrationHistoryEntry'
import {ZAccountId} from '../../../../model/AccountId'
import {ZLtiRegistrationId} from '../../../../model/LtiRegistrationId'
import {mockUser} from '../../../manage/__tests__/helpers'
import {LtiPlacements} from '../../../../model/LtiPlacement'
import type {ConfigChangeEntryWithDiff} from '../differ'

const mockConfigSnapshot = () => ({
  internal_config: {
    custom_fields: {},
    placements: [],
    description: '',
    domain: '',
    launch_settings: {},
    oidc_initiation_url: 'https://example.com',
    oidc_initiation_urls: {},
    scopes: [],
    title: 'Test Tool',
    redirect_uris: [],
    target_link_uri: 'https://example.com',
  },
  developer_key: {
    email: 'test@example.com',
    user_name: 'Test User',
    name: 'Test Key',
    redirect_uri: 'https://example.com',
    redirect_uris: [],
    icon_url: null,
    vendor_code: null,
    public_jwk: null,
    oidc_initiation_url: 'https://example.com',
    public_jwk_url: null,
    scopes: [],
  },
  registration: {
    admin_nickname: 'Test Tool',
    name: 'Test Tool',
    vendor: null,
    workflow_state: 'on' as const,
    description: null,
  },
  overlaid_internal_config: {
    custom_fields: {},
    placements: [],
    description: '',
    domain: '',
    launch_settings: {},
    oidc_initiation_url: 'https://example.com',
    oidc_initiation_urls: {},
    scopes: [],
    title: 'Test Tool',
    redirect_uris: [],
    target_link_uri: 'https://example.com',
  },
  overlay: {},
})

const mockConfigChangeEntryWithDiff = (
  overrides: Partial<ConfigChangeEntryWithDiff> &
    Pick<ConfigChangeHistoryEntry, 'old_configuration' | 'new_configuration'>,
): ConfigChangeEntryWithDiff => ({
  id: ZLtiRegistrationHistoryEntryId.parse('1'),
  root_account_id: ZAccountId.parse('4'),
  lti_registration_id: ZLtiRegistrationId.parse('1'),
  created_at: new Date('2025-01-15T12:00:00Z'),
  updated_at: new Date('2025-01-15T12:00:00Z'),
  diff: {},
  update_type: 'manual_edit',
  comment: 'Test update',
  created_by: mockUser({overrides: {name: 'Test User'}}),
  internalConfig: {
    icons: {
      iconUrl: null,
      placementIcons: new Map(),
      ...(overrides.internalConfig?.icons || {}),
    },
    launchSettings: {
      customFields: null,
      domain: null,
      oidcInitiationUrl: null,
      oidcInitiationUrls: null,
      publicJwk: null,
      publicJwkUrl: null,
      redirectUris: null,
      targetLinkUri: null,
      ...(overrides.internalConfig?.launchSettings || {}),
    },
    naming: {
      adminNickname: null,
      description: null,
      placementTexts: new Map(),
      ...(overrides.internalConfig?.naming || {}),
    },
    permissions: {
      added: [],
      removed: [],
      ...(overrides.internalConfig?.permissions || {}),
    },
    placements: {
      added: [],
      removed: [],
      courseNavigationDefault: null,
      placementChanges: new Map(),
      ...(overrides.internalConfig?.placements || {}),
    },
    privacyLevel: null,
    ...overrides.internalConfig,
  },
  totalAdditions: 0,
  totalRemovals: 0,
  ...overrides,
})

describe('HistoryDiffModal', () => {
  const onClose = jest.fn()

  beforeEach(() => {
    onClose.mockClear()
  })

  describe('modal behavior', () => {
    it('renders when open', () => {
      const mockSnapshot = mockConfigSnapshot()
      const entry = mockConfigChangeEntryWithDiff({
        old_configuration: mockSnapshot,
        new_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            title: 'Updated Title',
          },
        },
        internalConfig: {
          launchSettings: null,
          permissions: null,
          privacyLevel: null,
          placements: null,
          naming: {
            adminNickname: null,
            description: null,
            placementTexts: new Map(),
          },
          icons: null,
        },
        totalAdditions: 1,
        totalRemovals: 0,
      })

      render(<HistoryDiffModal entry={entry} isOpen={true} onClose={onClose} />)

      expect(screen.getByText(/Changes by Test User on/)).toBeInTheDocument()
      expect(screen.getByText('1 addition')).toBeInTheDocument()
      expect(screen.getByText('0 removals')).toBeInTheDocument()
    })

    it('does not render when closed', () => {
      render(<HistoryDiffModal entry={null} isOpen={false} onClose={onClose} />)

      expect(screen.queryByText(/Changes by/)).not.toBeInTheDocument()
    })

    it('calls onClose when close button is clicked', async () => {
      const user = userEvent.setup()
      const mockSnapshot = mockConfigSnapshot()
      const entry = mockConfigChangeEntryWithDiff({
        old_configuration: mockSnapshot,
        new_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            title: 'Updated Title',
          },
        },
        internalConfig: {
          launchSettings: null,
          permissions: null,
          privacyLevel: null,
          placements: null,
          naming: {
            adminNickname: null,
            description: null,
            placementTexts: new Map(),
          },
          icons: null,
        },
        totalAdditions: 1,
        totalRemovals: 0,
      })

      render(<HistoryDiffModal entry={entry} isOpen={true} onClose={onClose} />)

      const closeButtons = screen.getAllByRole('button', {name: /Close/i})
      await user.click(closeButtons[0])

      expect(onClose).toHaveBeenCalled()
    })
  })

  describe('launch settings diff', () => {
    it('displays redirect URI changes', () => {
      const mockSnapshot = mockConfigSnapshot()
      const entry = mockConfigChangeEntryWithDiff({
        old_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            redirect_uris: ['https://old.com/redirect'],
          },
        },
        new_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            redirect_uris: ['https://new.com/redirect', 'https://another.com/redirect'],
          },
        },
        internalConfig: {
          launchSettings: {
            redirectUris: {
              added: ['https://new.com/redirect', 'https://another.com/redirect'],
              removed: ['https://old.com/redirect'],
            },
            targetLinkUri: null,
            oidcInitiationUrl: null,
            oidcInitiationUrls: null,
            publicJwk: null,
            publicJwkUrl: null,
            domain: null,
            customFields: null,
          },
          permissions: null,
          privacyLevel: null,
          placements: null,
          naming: null,
          icons: null,
        },
        totalAdditions: 2,
        totalRemovals: 1,
      })

      render(<HistoryDiffModal entry={entry} isOpen={true} onClose={onClose} />)

      expect(screen.getByText('Launch Settings')).toBeInTheDocument()
      expect(screen.getByText('Redirect URIs')).toBeInTheDocument()

      expect(screen.getByText('[-] https://old.com/redirect')).toBeInTheDocument()
      expect(screen.getByText('[+] https://new.com/redirect')).toBeInTheDocument()
      expect(screen.getByText('[+] https://another.com/redirect')).toBeInTheDocument()
    })

    it('displays custom fields changes', () => {
      const mockSnapshot = mockConfigSnapshot()
      const entry = mockConfigChangeEntryWithDiff({
        old_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            custom_fields: {
              old_field: 'old_value',
              shared_field: 'same_value',
            },
          },
        },
        new_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            custom_fields: {
              new_field: 'new_value',
              shared_field: 'same_value',
            },
          },
        },
        internalConfig: {
          launchSettings: {
            redirectUris: null,
            targetLinkUri: null,
            oidcInitiationUrl: null,
            oidcInitiationUrls: null,
            publicJwk: null,
            publicJwkUrl: null,
            domain: null,
            customFields: {
              added: {new_field: 'new_value'},
              removed: {old_field: 'old_value'},
            },
          },
          permissions: null,
          privacyLevel: null,
          placements: null,
          naming: null,
          icons: null,
        },
        totalAdditions: 1,
        totalRemovals: 1,
      })

      render(<HistoryDiffModal entry={entry} isOpen={true} onClose={onClose} />)

      expect(screen.getByText('Launch Settings')).toBeInTheDocument()
      expect(screen.getByText('Custom Fields')).toBeInTheDocument()
      expect(screen.getByText('[-] old_field: old_value')).toBeInTheDocument()
      expect(screen.getByText('[+] new_field: new_value')).toBeInTheDocument()
    })

    it('displays OIDC URL changes', () => {
      const mockSnapshot = mockConfigSnapshot()
      const entry = mockConfigChangeEntryWithDiff({
        old_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            oidc_initiation_url: 'https://old.com/oidc',
          },
        },
        new_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            oidc_initiation_url: 'https://new.com/oidc',
          },
        },
        internalConfig: {
          launchSettings: {
            redirectUris: null,
            targetLinkUri: null,
            oidcInitiationUrl: {
              oldValue: 'https://old.com/oidc',
              newValue: 'https://new.com/oidc',
            },
            oidcInitiationUrls: null,
            publicJwk: null,
            publicJwkUrl: null,
            domain: null,
            customFields: null,
          },
          permissions: null,
          privacyLevel: null,
          placements: null,
          naming: null,
          icons: null,
        },
        totalAdditions: 1,
        totalRemovals: 1,
      })

      render(<HistoryDiffModal entry={entry} isOpen={true} onClose={onClose} />)

      expect(screen.getByRole('heading', {name: 'OIDC Initiation URL'})).toBeInTheDocument()
      expect(screen.getByText('[-] https://old.com/oidc')).toBeInTheDocument()
      expect(screen.getByText('[+] https://new.com/oidc')).toBeInTheDocument()
    })
  })

  describe('permissions diff', () => {
    it('displays scope additions and removals', () => {
      const mockSnapshot = mockConfigSnapshot()
      const entry = mockConfigChangeEntryWithDiff({
        old_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            scopes: [
              'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
              'https://purl.imsglobal.org/spec/lti-ags/scope/score',
            ],
          },
        },
        new_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            scopes: [
              'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
              'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
            ],
          },
        },
        internalConfig: {
          launchSettings: null,
          permissions: {
            added: ['https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly'],
            removed: ['https://purl.imsglobal.org/spec/lti-ags/scope/score'],
          },
          privacyLevel: null,
          placements: null,
          naming: null,
          icons: null,
        },
        totalAdditions: 1,
        totalRemovals: 1,
      })

      render(<HistoryDiffModal entry={entry} isOpen={true} onClose={onClose} />)

      expect(screen.getByText('Permissions')).toBeInTheDocument()
      expect(screen.getByText('Scopes')).toBeInTheDocument()
      expect(
        screen.getByText(
          /\[\+\] can view submission data for assignments associated with the tool/i,
        ),
      ).toBeInTheDocument()
      expect(
        screen.getByText(
          /\[\-\] can create and update submission results for assignments associated with the tool/i,
        ),
      ).toBeInTheDocument()
    })
  })

  describe('placements diff', () => {
    it('displays placement additions', () => {
      const mockSnapshot = mockConfigSnapshot()
      const entry = mockConfigChangeEntryWithDiff({
        old_configuration: mockSnapshot,
        new_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            placements: [
              {
                placement: LtiPlacements.CourseNavigation,
                enabled: true,
                message_type: 'LtiResourceLinkRequest',
                text: 'Course Nav',
              },
            ],
          },
        },
        internalConfig: {
          launchSettings: null,
          permissions: null,
          privacyLevel: null,
          placements: {
            added: [LtiPlacements.CourseNavigation],
            removed: [],
            courseNavigationDefault: null,
            placementChanges: new Map(),
          },
          naming: {
            adminNickname: null,
            description: null,
            placementTexts: new Map([
              [
                LtiPlacements.CourseNavigation,
                {
                  oldValue: undefined,
                  newValue: 'Course Nav',
                },
              ],
            ]),
          },
          icons: null,
        },
        totalAdditions: 1,
        totalRemovals: 0,
      })

      render(<HistoryDiffModal entry={entry} isOpen={true} onClose={onClose} />)

      expect(screen.getByText('Placements')).toBeInTheDocument()
      expect(screen.getByText('[+] Course Navigation')).toBeInTheDocument()
    })

    it('displays placement modifications', () => {
      const mockSnapshot = mockConfigSnapshot()
      const entry = mockConfigChangeEntryWithDiff({
        old_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            placements: [
              {
                placement: LtiPlacements.CourseNavigation,
                enabled: true,
                message_type: 'LtiResourceLinkRequest',
                target_link_uri: 'https://old.com/launch',
                text: 'Old Text',
                icon_url: 'https://old.com/icon.png',
              },
            ],
          },
        },
        new_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            placements: [
              {
                placement: LtiPlacements.CourseNavigation,
                enabled: true,
                message_type: 'LtiResourceLinkRequest',
                target_link_uri: 'https://new.com/launch',
                text: 'New Text',
                icon_url: 'https://new.com/icon.png',
              },
            ],
          },
        },
        internalConfig: {
          launchSettings: null,
          permissions: null,
          privacyLevel: null,
          placements: {
            added: [],
            removed: [],
            courseNavigationDefault: null,
            placementChanges: new Map([
              [
                LtiPlacements.CourseNavigation,
                {
                  targetLinkUri: {
                    oldValue: 'https://old.com/launch',
                    newValue: 'https://new.com/launch',
                  },
                  messageType: null,
                },
              ],
            ]),
          },
          naming: {
            adminNickname: null,
            description: null,
            placementTexts: new Map([
              [
                LtiPlacements.CourseNavigation,
                {
                  oldValue: 'Old Text',
                  newValue: 'New Text',
                },
              ],
            ]),
          },
          icons: {
            iconUrl: null,
            placementIcons: new Map([
              [
                LtiPlacements.CourseNavigation,
                {
                  oldValue: 'https://old.com/icon.png',
                  newValue: 'https://new.com/icon.png',
                },
              ],
            ]),
          },
        },
        totalAdditions: 3,
        totalRemovals: 3,
      })

      render(<HistoryDiffModal entry={entry} isOpen={true} onClose={onClose} />)

      expect(screen.getByText('Override URIs')).toBeInTheDocument()
      expect(screen.getByText('Target Link URI')).toBeInTheDocument()
      expect(screen.getByText('[-] https://old.com/launch')).toBeInTheDocument()
      expect(screen.getByText('[+] https://new.com/launch')).toBeInTheDocument()

      expect(screen.getByText('Naming')).toBeInTheDocument()
      expect(screen.getByText('[-] Old Text')).toBeInTheDocument()
      expect(screen.getByText('[+] New Text')).toBeInTheDocument()

      expect(screen.getByText('Icon Changes')).toBeInTheDocument()
      expect(screen.getByText('[-] https://old.com/icon.png')).toBeInTheDocument()
      expect(screen.getByText('[+] https://new.com/icon.png')).toBeInTheDocument()
    })
  })

  describe('naming diff', () => {
    it('displays admin nickname and description changes', () => {
      const mockSnapshot = mockConfigSnapshot()
      const entry = mockConfigChangeEntryWithDiff({
        old_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            description: 'Old Description',
          },
          registration: {
            ...mockSnapshot.registration,
            admin_nickname: 'Old Nickname',
          },
        },
        new_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            description: 'New Description',
          },
          registration: {
            ...mockSnapshot.registration,
            admin_nickname: 'New Nickname',
          },
        },
        internalConfig: {
          launchSettings: null,
          permissions: null,
          privacyLevel: null,
          placements: null,
          naming: {
            adminNickname: {
              oldValue: 'Old Nickname',
              newValue: 'New Nickname',
            },
            description: {
              oldValue: 'Old Description',
              newValue: 'New Description',
            },
            placementTexts: new Map(),
          },
          icons: null,
        },
        totalAdditions: 2,
        totalRemovals: 2,
      })

      render(<HistoryDiffModal entry={entry} isOpen={true} onClose={onClose} />)

      expect(screen.getByText('Naming')).toBeInTheDocument()
      expect(screen.getByText('Admin Nickname')).toBeInTheDocument()
      expect(screen.getByText('[-] Old Nickname')).toBeInTheDocument()
      expect(screen.getByText('[+] New Nickname')).toBeInTheDocument()
      expect(screen.getByText('[-] Old Description')).toBeInTheDocument()
      expect(screen.getByText('[+] New Description')).toBeInTheDocument()
    })
  })

  describe('icons diff', () => {
    it('displays icon URL changes', () => {
      const mockSnapshot = mockConfigSnapshot()
      const entry = mockConfigChangeEntryWithDiff({
        old_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            launch_settings: {
              icon_url: 'https://old.com/icon.png',
            },
          },
        },
        new_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            launch_settings: {
              icon_url: 'https://new.com/icon.png',
            },
          },
        },
        internalConfig: {
          launchSettings: null,
          permissions: null,
          privacyLevel: null,
          placements: null,
          naming: null,
          icons: {
            iconUrl: {
              oldValue: 'https://old.com/icon.png',
              newValue: 'https://new.com/icon.png',
            },
            placementIcons: new Map(),
          },
        },
        totalAdditions: 1,
        totalRemovals: 1,
      })

      render(<HistoryDiffModal entry={entry} isOpen={true} onClose={onClose} />)

      expect(screen.getByText('1 addition')).toBeInTheDocument()
      expect(screen.getByText('1 removal')).toBeInTheDocument()

      expect(screen.getByText('Default Icon URL')).toBeInTheDocument()
      expect(screen.getByText('[-] https://old.com/icon.png')).toBeInTheDocument()
      expect(screen.getByText('[+] https://new.com/icon.png')).toBeInTheDocument()
    })
  })

  describe('privacy level diff', () => {
    it('displays privacy level changes', () => {
      const mockSnapshot = mockConfigSnapshot()
      const entry = mockConfigChangeEntryWithDiff({
        old_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            privacy_level: 'public',
          },
        },
        new_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            privacy_level: 'anonymous',
          },
        },
        internalConfig: {
          launchSettings: null,
          permissions: null,
          privacyLevel: {
            oldValue: 'public',
            newValue: 'anonymous',
          },
          placements: null,
          naming: null,
          icons: null,
        },
        totalAdditions: 1,
        totalRemovals: 1,
      })

      render(<HistoryDiffModal entry={entry} isOpen={true} onClose={onClose} />)

      expect(screen.getByText('Privacy Level')).toBeInTheDocument()
      expect(screen.getByText('[-] All user data')).toBeInTheDocument()
      expect(screen.getByText('[+] None (Anonymized)')).toBeInTheDocument()
    })
  })

  describe('comprehensive configuration changes', () => {
    it('displays all diff components together for a multi-section change', () => {
      const mockSnapshot = mockConfigSnapshot()
      const entry = mockConfigChangeEntryWithDiff({
        old_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            title: 'Old Title',
            description: 'Old Description',
            domain: 'old-domain.com',
            redirect_uris: ['https://old.com/redirect'],
            target_link_uri: 'https://old.com/launch',
            scopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem'],
            privacy_level: 'public',
            custom_fields: {old_field: 'old_value'},
            placements: [
              {
                placement: LtiPlacements.CourseNavigation,
                enabled: true,
                message_type: 'LtiResourceLinkRequest',
                target_link_uri: 'https://old.com/course',
                text: 'Old Course Nav',
                icon_url: 'https://old.com/icon.png',
              },
            ],
          },
          developer_key: {
            ...mockSnapshot.developer_key,
            icon_url: 'https://old.com/icon.png',
          },
          registration: {
            ...mockSnapshot.registration,
            name: 'Old Tool Name',
            admin_nickname: 'Old Nickname',
          },
        },
        new_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            title: 'New Title',
            description: 'New Description',
            domain: 'new-domain.com',
            redirect_uris: ['https://new.com/redirect'],
            target_link_uri: 'https://new.com/launch',
            scopes: [
              'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
              'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
            ],
            privacy_level: 'anonymous',
            custom_fields: {new_field: 'new_value'},
            placements: [
              {
                placement: LtiPlacements.CourseNavigation,
                enabled: true,
                message_type: 'LtiResourceLinkRequest',
                target_link_uri: 'https://new.com/course',
                text: 'New Course Nav',
                icon_url: 'https://new.com/icon.png',
              },
              {
                placement: LtiPlacements.AccountNavigation,
                enabled: true,
                message_type: 'LtiResourceLinkRequest',
                target_link_uri: 'https://new.com/account',
                text: 'Account Nav',
              },
            ],
          },
          developer_key: {
            ...mockSnapshot.developer_key,
            icon_url: 'https://new.com/icon.png',
          },
          registration: {
            ...mockSnapshot.registration,
            name: 'New Tool Name',
            admin_nickname: 'New Nickname',
          },
        },
        internalConfig: {
          launchSettings: {
            redirectUris: {
              added: ['https://new.com/redirect'],
              removed: ['https://old.com/redirect'],
            },
            targetLinkUri: {
              oldValue: 'https://old.com/launch',
              newValue: 'https://new.com/launch',
            },
            oidcInitiationUrl: null,
            oidcInitiationUrls: null,
            publicJwk: null,
            publicJwkUrl: null,
            domain: {
              oldValue: 'old-domain.com',
              newValue: 'new-domain.com',
            },
            customFields: {
              added: {new_field: 'new_value'},
              removed: {old_field: 'old_value'},
            },
          },
          permissions: {
            added: ['https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly'],
            removed: [],
          },
          privacyLevel: {
            oldValue: 'public',
            newValue: 'anonymous',
          },
          placements: {
            added: [LtiPlacements.AccountNavigation],
            removed: [],
            courseNavigationDefault: null,
            placementChanges: new Map([
              [
                LtiPlacements.CourseNavigation,
                {
                  targetLinkUri: {
                    oldValue: 'https://old.com/course',
                    newValue: 'https://new.com/course',
                  },
                  messageType: null,
                },
              ],
            ]),
          },
          naming: {
            adminNickname: {
              oldValue: 'Old Nickname',
              newValue: 'New Nickname',
            },
            description: {
              oldValue: 'Old Description',
              newValue: 'New Description',
            },
            placementTexts: new Map([
              [
                LtiPlacements.CourseNavigation,
                {
                  oldValue: 'Old Course Nav',
                  newValue: 'New Course Nav',
                },
              ],
            ]),
          },
          icons: {
            iconUrl: {
              oldValue: 'https://old.com/icon.png',
              newValue: 'https://new.com/icon.png',
            },
            placementIcons: new Map([
              [
                LtiPlacements.CourseNavigation,
                {
                  oldValue: 'https://old.com/icon-course.png',
                  newValue: 'https://new.com/icon-course.png',
                },
              ],
            ]),
          },
        },
        totalAdditions: 6,
        totalRemovals: 2,
      })

      render(<HistoryDiffModal entry={entry} isOpen={true} onClose={onClose} />)

      expect(screen.getByText('Launch Settings')).toBeInTheDocument()
      expect(screen.getByText('Permissions')).toBeInTheDocument()
      expect(screen.getByText('Privacy Level')).toBeInTheDocument()
      expect(screen.getByText('Placements')).toBeInTheDocument()
      expect(screen.getByText('Naming')).toBeInTheDocument()
      expect(screen.getByText('Icon Changes')).toBeInTheDocument()

      expect(screen.getByText('Domain')).toBeInTheDocument()
      expect(screen.getByText('[-] old-domain.com')).toBeInTheDocument()
      expect(screen.getByText('[+] new-domain.com')).toBeInTheDocument()

      expect(screen.getByText('[-] https://old.com/redirect')).toBeInTheDocument()
      expect(screen.getByText('[+] https://new.com/redirect')).toBeInTheDocument()

      expect(screen.getByText(/\[\-\] old_field: old_value/i)).toBeInTheDocument()
      expect(screen.getByText(/\[\+\] new_field: new_value/i)).toBeInTheDocument()

      expect(
        screen.getByText(
          /\[\+\] can view submission data for assignments associated with the tool/i,
        ),
      ).toBeInTheDocument()

      expect(screen.getByText('[-] All user data')).toBeInTheDocument()
      expect(screen.getByText('[+] None (Anonymized)')).toBeInTheDocument()

      expect(screen.getByText('[+] Account Navigation')).toBeInTheDocument()

      expect(screen.getByRole('heading', {name: 'Admin Nickname'})).toBeInTheDocument()
      expect(screen.getByText('[-] Old Nickname')).toBeInTheDocument()
      expect(screen.getByText('[+] New Nickname')).toBeInTheDocument()

      expect(screen.getByRole('heading', {name: 'Description'})).toBeInTheDocument()
      expect(screen.getByText('[-] Old Description')).toBeInTheDocument()
      expect(screen.getByText('[+] New Description')).toBeInTheDocument()

      expect(screen.getByText('[-] Old Course Nav')).toBeInTheDocument()
      expect(screen.getByText('[+] New Course Nav')).toBeInTheDocument()

      expect(screen.getByText('[-] https://old.com/icon-course.png')).toBeInTheDocument()
      expect(screen.getByText('[+] https://new.com/icon-course.png')).toBeInTheDocument()
    })

    it('displays addition and removal counts', () => {
      const mockSnapshot = mockConfigSnapshot()
      const entry = mockConfigChangeEntryWithDiff({
        old_configuration: {
          ...mockSnapshot,
        },
        new_configuration: {
          ...mockSnapshot,
        },
        totalAdditions: 3,
        totalRemovals: 3,
      })

      render(<HistoryDiffModal entry={entry} isOpen={true} onClose={onClose} />)

      expect(screen.getByText('3 additions')).toBeInTheDocument()
      expect(screen.getByText('3 removals')).toBeInTheDocument()
    })

    it('shows message when no parseable changes are detected', () => {
      const mockSnapshot = mockConfigSnapshot()
      const entry = mockConfigChangeEntryWithDiff({
        old_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            launch_settings: {
              ...mockSnapshot.overlaid_internal_config.launch_settings,
              // Launch height isn't (currently) parsed as a diffable field
              launch_height: 400,
            },
          },
        },
        new_configuration: {
          ...mockSnapshot,
          overlaid_internal_config: {
            ...mockSnapshot.overlaid_internal_config,
            launch_settings: {
              ...mockSnapshot.overlaid_internal_config.launch_settings,
              launch_height: 800,
            },
          },
        },
        internalConfig: null,
        totalAdditions: 0,
        totalRemovals: 0,
      })

      render(<HistoryDiffModal entry={entry} isOpen={true} onClose={onClose} />)

      expect(
        screen.getByText(
          /We're unable to show a comparison for these changes. For a complete representation of changes, please use the API\./,
        ),
      ).toBeInTheDocument()
    })
  })
})
