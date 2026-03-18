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

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_checker')

export interface CommunityLink {
  url: string
  label: string
}

export const COMMUNITY_LINKS: Record<string, CommunityLink> = {
  'list-structure': {
    url: 'https://community.instructure.com/en/discussion/665371/accessible-list-formatting?utm_source=community-share',
    label: I18n.t('Read about accessible lists'),
  },
  'adjacent-links': {
    url: 'https://community.instructure.com/en/discussion/665375/link-accessibility',
    label: I18n.t('Read about link accessibility'),
  },
  'table-caption': {
    url: 'https://community.instructure.com/en/discussion/665370/table-accessibility?utm_source=community-share',
    label: I18n.t('Read about table accessibility'),
  },
  'table-header': {
    url: 'https://community.instructure.com/en/discussion/665370/table-accessibility?utm_source=community-share',
    label: I18n.t('Read about table accessibility'),
  },
  'table-header-scope': {
    url: 'https://community.instructure.com/en/discussion/665370/table-accessibility?utm_source=community-share',
    label: I18n.t('Read about table accessibility'),
  },
  'small-text-contrast': {
    url: 'https://community.instructure.com/en/discussion/665372/text-color-contrast-accessibility?utm_source=community-share',
    label: I18n.t('Read about text contrast'),
  },
  'large-text-contrast': {
    url: 'https://community.instructure.com/en/discussion/665372/text-color-contrast-accessibility?utm_source=community-share',
    label: I18n.t('Read about text contrast'),
  },
  'paragraphs-for-headings': {
    url: 'https://community.instructure.com/en/discussion/665373/heading-accessibility',
    label: I18n.t('Read about heading accessibility'),
  },
  'headings-start-at-h2': {
    url: 'https://community.instructure.com/en/discussion/665373/heading-accessibility',
    label: I18n.t('Read about heading accessibility'),
  },
  'headings-sequence': {
    url: 'https://community.instructure.com/en/discussion/665373/heading-accessibility',
    label: I18n.t('Read about heading accessibility'),
  },
  'img-alt': {
    url: 'https://community.instructure.com/en/discussion/665374/image-accessibility-alt-text',
    label: I18n.t('Read about writing alt text'),
  },
  'img-alt-filename': {
    url: 'https://community.instructure.com/en/discussion/665374/image-accessibility-alt-text',
    label: I18n.t('Read about writing alt text'),
  },
  'img-alt-length': {
    url: 'https://community.instructure.com/en/discussion/665374/image-accessibility-alt-text',
    label: I18n.t('Read about writing alt text'),
  },
}
