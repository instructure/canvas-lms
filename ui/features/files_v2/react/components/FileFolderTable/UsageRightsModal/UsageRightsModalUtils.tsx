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

import {useScope as createI18nScope} from '@canvas/i18n'
import {type File, type Folder} from '../../../../interfaces/File'
import {getUniqueId} from '../../../../utils/fileFolderUtils'

const I18n = createI18nScope('files_v2')

export const CONTENT_OPTIONS = [
  {
    display: I18n.t('Choose usage rights...'),
    value: 'choose',
  },
  {
    display: I18n.t('I hold the copyright'),
    value: 'own_copyright',
  },
  {
    display: I18n.t('I have permission to use this file'),
    value: 'used_by_permission',
  },
  {
    display: I18n.t('The material is in the public domain'),
    value: 'public_domain',
  },
  {
    display: I18n.t(
      'The material is subject to an exception - e.g. fair use, the right to quote, or others under applicable copyright laws',
    ),
    value: 'fair_use',
  },
  {
    display: I18n.t('Creative Commons License'),
    value: 'creative_commons',
  },
]

export function defaultSelectedRight(items: (File | Folder)[]) {
  if (items.length === 0) return 'choose'

  const useJustification = items[0].usage_rights && items[0].usage_rights.use_justification
  if (
    useJustification &&
    items.every(
      item => (item.usage_rights && item.usage_rights.use_justification) === useJustification,
    )
  ) {
    return useJustification
  } else {
    return 'choose'
  }
}

export function defaultCopyright(items: (File | Folder)[]) {
  if (items.length === 0) return null

  const copyright = (items[0].usage_rights && items[0].usage_rights.legal_copyright) || ''
  if (
    items.every(
      item =>
        (item.usage_rights && item.usage_rights.legal_copyright) === copyright ||
        (item.usage_rights && item.usage_rights.license) === copyright,
    )
  ) {
    return copyright
  } else {
    return null
  }
}

export function defaultCCValue(usageRight: string | null, items: (File | Folder)[]) {
  if (items.length === 0) return null

  if (usageRight === 'creative_commons') {
    return items[0].usage_rights && items[0].usage_rights.license
  } else {
    return null
  }
}

// determined from lib/content_licenses.rb
const ccLicenseMap: Record<string, string> = {
  cc_by: I18n.t('CC Attribution'),
  cc_by_sa: I18n.t('CC Attribution Share Alike'),
  cc_by_nc: I18n.t('CC Attribution Non-Commercial'),
  cc_by_nc_sa: I18n.t('CC Attribution Non-Commercial Share Alike'),
  cc_by_nd: I18n.t('CC Attribution No Derivatives'),
  cc_by_nc_nd: I18n.t('CC Attribution Non-Commercial No Derivatives'),
}

const privateLicense = I18n.t('Private (Copyrighted)')

const usageRightMap: Record<string, string> = {
  own_copyright: privateLicense,
  used_by_permission: privateLicense,
  fair_use: privateLicense,
  public_domain: I18n.t('Public Domain'),
}

export function determineLicenseName(usageRight: string, ccLicenseOption: string | null) {
  if (usageRight === 'creative_commons' && ccLicenseOption) {
    return ccLicenseMap[ccLicenseOption] || ''
  }

  return usageRightMap[usageRight] || ''
}

export function parseNewRows({
  items,
  currentRows,
  usageRight,
  ccLicenseOption,
  copyrightHolder,
}: {
  items: (File | Folder)[]
  currentRows: (File | Folder)[]
  usageRight: string
  ccLicenseOption: string | null
  copyrightHolder: string | null
}) {
  const newUsageRights = {
    legal_copyright: copyrightHolder || undefined,
    use_justification: usageRight || undefined,
    license_name: usageRight ? determineLicenseName(usageRight, ccLicenseOption) : undefined,
    license: ccLicenseOption || undefined,
  }
  const newRows = [...currentRows]
  items.forEach(item => {
    const index = newRows.findIndex(row => getUniqueId(row) === getUniqueId(item))
    if (index !== -1) {
      newRows[index].usage_rights = newUsageRights
    }
  })
  return newRows
}
