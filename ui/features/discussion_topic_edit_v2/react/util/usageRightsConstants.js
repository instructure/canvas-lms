/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('discussion_create')

export const defaultUsageRights = [
  {
    display: I18n.t('Choose usage rights...'),
    value: 'choose',
  },
  {
    display: I18n.t('I hold the copyright'),
    value: 'own_copyright',
  },
  {
    display: I18n.t('I have obtained permission to use this file.'),
    value: 'used_by_permission',
  },
  {
    display: I18n.t('The material is in the public domain'),
    value: 'public_domain',
  },
  {
    display: I18n.t(
      'The material is subject to an exception - e.g. fair use, the right to quote, or others under applicable copyright laws'
    ),
    value: 'fair_use',
  },
  {
    display: I18n.t('The material is licensed under Creative Commons'),
    value: 'creative_commons',
  },
]

export const defaultCreativeOptions = [
  {
    id: 'cc_by',
    name: I18n.t('CC Attribution'),
    url: 'http://creativecommons.org/licenses/by/4.0',
  },
  {
    id: 'cc_by_sa',
    name: 'CC Attribution Share Alike',
    url: 'http://creativecommons.org/licenses/by-sa/4.0',
  },
  {
    id: 'cc_by_nc',
    name: I18n.t('CC Attribution Non-Commercial'),
    url: 'http://creativecommons.org/licenses/by-nc/4.0',
  },
  {
    id: 'cc_by_nc_sa',
    name: I18n.t('CC Attribution Non-Commercial Share Alike'),
    url: 'http://creativecommons.org/licenses/by-nc-sa/4.0',
  },
  {
    id: 'cc_by_nd',
    name: I18n.t('CC Attribution No Derivatives'),
    url: 'http://creativecommons.org/licenses/by-nd/4.0',
  },
  {
    id: 'cc_by_nc_nd',
    name: I18n.t('CC Attribution Non-Commercial No Derivatives'),
    url: 'http://creativecommons.org/licenses/by-nc-nd/4.0/',
  },
]
