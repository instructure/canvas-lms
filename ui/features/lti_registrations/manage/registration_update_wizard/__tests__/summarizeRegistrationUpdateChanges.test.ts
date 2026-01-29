/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {summarizeRegistrationUpdateChanges} from '../summarizeRegistrationUpdateChanges'
import {
  mockRegistration,
  mockToolConfiguration,
} from '../../dynamic_registration_wizard/__tests__/helpers'
import type {LtiRegistrationUpdateRequest} from '../../model/lti_ims_registration/LtiRegistrationUpdateRequest'
import {ZLtiRegistrationUpdateRequestId} from '../../model/lti_ims_registration/LtiRegistrationUpdateRequestId'
import {ZAccountId} from '../../model/AccountId'
import type {LtiOverlay} from '../../model/LtiOverlay'
import {ZLtiOverlayId} from '../../model/ZLtiOverlayId'
import {ZUserId} from '../../model/UserId'
import {ZLtiRegistrationId} from '../../model/LtiRegistrationId'
import {LtiConfigurationOverlay} from '../../model/internal_lti_configuration/LtiConfigurationOverlay'

const mockOverlay = (data: LtiConfigurationOverlay): LtiOverlay => ({
  id: ZLtiOverlayId.parse('overlay-1'),
  registration_id: ZLtiRegistrationId.parse('1'),
  root_account_id: ZAccountId.parse('1'),
  account_id: ZAccountId.parse('1'),
  created_at: new Date(),
  updated_at: new Date(),
  updated_by: {
    id: ZUserId.parse('1'),
    name: 'Test User',
    sortable_name: 'Test User',
    short_name: 'Test',
    created_at: new Date(),
  },
  data,
})

describe('summarizeRegistrationUpdateChanges', () => {
  const baseRegistrationUpdateRequest: LtiRegistrationUpdateRequest = {
    id: ZLtiRegistrationUpdateRequestId.parse('update-1'),
    root_account_id: ZAccountId.parse('1'),
    lti_registration_id: ZLtiRegistrationId.parse('1'),
    internal_lti_configuration: mockToolConfiguration(),
  }

  describe('scopes/permissions changes', () => {
    it('identifies added scopes', () => {
      const registration = mockRegistration(
        {},
        {
          scopes: [
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly',
          ],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          scopes: [
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly',
            'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
            'https://purl.imsglobal.org/spec/lti-ags/scope/score',
          ],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.added).toContainEqual({
        section: 'Permissions',
        detail: 'Added 2 new scopes',
      })
      expect(result.removed).toEqual([])
      expect(result.noChange).toHaveLength(4)
    })

    it('identifies removed scopes', () => {
      const registration = mockRegistration(
        {},
        {
          scopes: [
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly',
            'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
          ],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          scopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem'],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.removed).toContainEqual({
        section: 'Permissions',
        detail: 'Removed 2 scopes',
      })
      expect(result.added).toHaveLength(0)
    })

    it('identifies both added and removed scopes', () => {
      const registration = mockRegistration(
        {},
        {
          scopes: [
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly',
          ],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          scopes: [
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
            'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
          ],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.added).toContainEqual({
        section: 'Permissions',
        detail: 'Added 1 new scope',
      })
      expect(result.removed).toContainEqual({
        section: 'Permissions',
        detail: 'Removed 1 scope',
      })
    })

    it('shows no change when scopes are identical', () => {
      const registration = mockRegistration(
        {},
        {
          scopes: [
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly',
          ],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          scopes: [
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly',
          ],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.noChange).toContainEqual({
        section: 'Permissions',
        detail: '',
      })
      expect(result.added.filter(c => c.section === 'Permissions')).toHaveLength(0)
      expect(result.removed.filter(c => c.section === 'Permissions')).toHaveLength(0)
    })

    it('handles empty scopes arrays', () => {
      const registration = mockRegistration(
        {},
        {
          scopes: [],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          scopes: [],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.noChange).toContainEqual({
        section: 'Permissions',
        detail: '',
      })
    })

    it('handles undefined scopes', () => {
      const registration = mockRegistration({}, {})

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({}),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.noChange).toContainEqual({
        section: 'Permissions',
        detail: '',
      })
    })
  })

  describe('privacy level changes', () => {
    it('identifies privacy level changes', () => {
      const registration = mockRegistration(
        {},
        {
          privacy_level: 'public',
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          privacy_level: 'anonymous',
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.added).toContainEqual({
        section: 'Privacy Level',
        detail: 'Changed to anonymous',
      })
    })

    it('shows no change when privacy level is same', () => {
      const registration = mockRegistration(
        {},
        {
          privacy_level: 'public',
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          privacy_level: 'public',
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.noChange).toContainEqual({
        section: 'Privacy Level',
        detail: '',
      })
    })

    it('shows no change when overlay has privacy level override', () => {
      const registration = mockRegistration(
        {
          overlay: mockOverlay({
            privacy_level: 'name_only',
          }),
        },
        {
          privacy_level: 'public',
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          privacy_level: 'anonymous',
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.noChange).toContainEqual({
        section: 'Privacy Level',
        detail: '',
      })
    })

    it('shows no change when requested privacy level is undefined', () => {
      const registration = mockRegistration(
        {},
        {
          privacy_level: 'public',
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          privacy_level: undefined,
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.noChange).toContainEqual({
        section: 'Privacy Level',
        detail: '',
      })
    })
  })

  describe('placement changes', () => {
    it('identifies added placements', () => {
      const registration = mockRegistration(
        {},
        {
          placements: [{placement: 'course_navigation'}, {placement: 'account_navigation'}],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          placements: [
            {placement: 'course_navigation'},
            {placement: 'account_navigation'},
            {placement: 'user_navigation'},
            {placement: 'assignment_menu'},
          ],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.added).toContainEqual({
        section: 'Placements',
        detail: 'Added 2 placements',
      })
    })

    it('identifies removed placements', () => {
      const registration = mockRegistration(
        {},
        {
          placements: [
            {placement: 'course_navigation'},
            {placement: 'account_navigation'},
            {placement: 'user_navigation'},
          ],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          placements: [{placement: 'course_navigation'}],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.removed).toContainEqual({
        section: 'Placements',
        detail: 'Removed 2 placements',
      })
    })

    it('shows no change when placements are identical', () => {
      const registration = mockRegistration(
        {},
        {
          placements: [{placement: 'course_navigation'}, {placement: 'account_navigation'}],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          placements: [{placement: 'course_navigation'}, {placement: 'account_navigation'}],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.noChange).toContainEqual({
        section: 'Placements',
        detail: '',
      })
    })

    it('handles empty placement arrays', () => {
      const registration = mockRegistration(
        {},
        {
          placements: [],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          placements: [],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.noChange).toContainEqual({
        section: 'Placements',
        detail: '',
      })
    })
  })

  describe('naming changes', () => {
    it('identifies title changes', () => {
      const registration = mockRegistration(
        {
          name: 'Old App Name',
        },
        {
          title: 'Original Title',
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          title: 'New App Name',
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.added).toContainEqual({
        section: 'Naming',
        detail: 'Updated app name',
      })
    })

    it('shows no change when title is same', () => {
      const registration = mockRegistration(
        {
          name: 'App Name',
        },
        {
          title: 'Original Title',
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          title: 'App Name',
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.noChange).toContainEqual({
        section: 'Naming',
        detail: '',
      })
    })

    it('shows no change when requested title is undefined', () => {
      const registration = mockRegistration(
        {
          name: 'App Name',
        },
        {
          title: 'Original Title',
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          title: undefined,
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.noChange).toContainEqual({
        section: 'Naming',
        detail: '',
      })
    })
  })

  describe('icon changes', () => {
    it('identifies icon changes in placements', () => {
      const registration = mockRegistration(
        {},
        {
          placements: [
            {placement: 'course_navigation', icon_url: 'old-icon.png'},
            {placement: 'account_navigation'},
          ],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          placements: [
            {placement: 'course_navigation', icon_url: 'new-icon.png'},
            {placement: 'account_navigation'},
          ],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.added).toContainEqual({
        section: 'Icon',
        detail: 'Icon settings updated',
      })
    })

    it('identifies icon addition in placements', () => {
      const registration = mockRegistration(
        {},
        {
          placements: [{placement: 'course_navigation'}],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          placements: [{placement: 'course_navigation', icon_url: 'new-icon.png'}],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.added).toContainEqual({
        section: 'Icon',
        detail: 'Icon settings updated',
      })
    })

    it('identifies icon removal in placements', () => {
      const registration = mockRegistration(
        {},
        {
          placements: [{placement: 'course_navigation', icon_url: 'old-icon.png'}],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          placements: [{placement: 'course_navigation'}],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.added).toContainEqual({
        section: 'Icon',
        detail: 'Icon settings updated',
      })
    })

    it('shows no change when icon URLs are same', () => {
      const registration = mockRegistration(
        {},
        {
          placements: [{placement: 'course_navigation', icon_url: 'same-icon.png'}],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          placements: [{placement: 'course_navigation', icon_url: 'same-icon.png'}],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.noChange).toContainEqual({
        section: 'Icon',
        detail: '',
      })
    })

    it('ignores placements with icon overrides in overlay', () => {
      const registration = mockRegistration(
        {
          overlay: mockOverlay({
            placements: {
              course_navigation: {
                icon_url: 'overlay-icon.png',
              },
            },
          }),
        },
        {
          placements: [
            {placement: 'course_navigation', icon_url: 'old-icon.png'},
            {placement: 'account_navigation', icon_url: 'old-nav-icon.png'},
          ],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          placements: [
            {placement: 'course_navigation', icon_url: 'new-icon.png'},
            {placement: 'account_navigation', icon_url: 'new-nav-icon.png'},
          ],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.added).toContainEqual({
        section: 'Icon',
        detail: 'Icon settings updated',
      })
    })

    it('shows no change when all icon changes are overridden by overlay', () => {
      const registration = mockRegistration(
        {
          overlay: mockOverlay({
            placements: {
              course_navigation: {
                icon_url: 'overlay-icon.png',
              },
            },
          }),
        },
        {
          placements: [{placement: 'course_navigation', icon_url: 'old-icon.png'}],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          placements: [{placement: 'course_navigation', icon_url: 'new-icon.png'}],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.noChange).toContainEqual({
        section: 'Icon',
        detail: '',
      })
    })

    it('does not show icon changes for newly added placements', () => {
      const registration = mockRegistration(
        {},
        {
          placements: [{placement: 'account_navigation'}],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          placements: [
            {placement: 'account_navigation'},
            {placement: 'course_navigation', icon_url: 'new-icon.png'},
          ],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      // New placement is added
      expect(result.added).toContainEqual({
        section: 'Placements',
        detail: 'Added 1 placement',
      })

      // But icon should not be marked as changed (icon is part of the new placement)
      expect(result.noChange).toContainEqual({
        section: 'Icon',
        detail: '',
      })
    })

    it('handles empty placements arrays', () => {
      const registration = mockRegistration(
        {},
        {
          placements: [],
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          placements: [],
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.noChange).toContainEqual({
        section: 'Icon',
        detail: '',
      })
    })
  })

  describe('complete integration', () => {
    it('handles multiple types of changes', () => {
      const registration = mockRegistration(
        {
          name: 'Old App',
        },
        {
          scopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem'],
          privacy_level: 'public',
          placements: [
            {placement: 'course_navigation', icon_url: 'old.png'},
            {placement: 'user_navigation', icon_url: 'user-old.png'},
          ],
          title: 'Old Title',
        },
      )

      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration({
          scopes: [
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly',
          ],
          privacy_level: 'anonymous',
          placements: [
            {placement: 'user_navigation', icon_url: 'user-new.png'},
            {placement: 'account_navigation', icon_url: 'new.png'},
          ],
          title: 'New App',
        }),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result.added).toEqual(
        expect.arrayContaining([
          {section: 'Permissions', detail: 'Added 1 new scope'},
          {section: 'Privacy Level', detail: 'Changed to anonymous'},
          {section: 'Placements', detail: 'Added 1 placement'},
          {section: 'Naming', detail: 'Updated app name'},
          {section: 'Icon', detail: 'Icon settings updated'},
        ]),
      )
      expect(result.removed).toContainEqual({
        section: 'Placements',
        detail: 'Removed 1 placement',
      })
    })

    it('returns proper structure with all sections', () => {
      const registration = mockRegistration({}, mockToolConfiguration())
      const updateRequest = {
        ...baseRegistrationUpdateRequest,
        internal_lti_configuration: mockToolConfiguration(),
      }

      const result = summarizeRegistrationUpdateChanges(updateRequest, registration)

      expect(result).toHaveProperty('added')
      expect(result).toHaveProperty('removed')
      expect(result).toHaveProperty('noChange')
      expect(Array.isArray(result.added)).toBe(true)
      expect(Array.isArray(result.removed)).toBe(true)
      expect(Array.isArray(result.noChange)).toBe(true)

      const allSections = [...result.added, ...result.removed, ...result.noChange].map(
        c => c.section,
      )

      expect(allSections).toContain('Permissions')
      expect(allSections).toContain('Privacy Level')
      expect(allSections).toContain('Placements')
      expect(allSections).toContain('Naming')
      expect(allSections).toContain('Icon')
    })
  })
})
