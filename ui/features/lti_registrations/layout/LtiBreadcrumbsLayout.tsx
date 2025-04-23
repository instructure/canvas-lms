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

import {useAppendBreadcrumb} from '@canvas/breadcrumbs/useAppendBreadcrumb'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Outlet} from 'react-router-dom'
import type {AccountId} from '../manage/model/AccountId'
import {useTopLevelPage} from './useTopLevelPage'

const I18n = createI18nScope('lti_registrations')

export type LtiBreadcrumbsLayoutProps = {
  accountId: AccountId
}

/**
 * Ensures that the appropriate breadcrumb for the current top-level page is
 * always appended.
 * @returns
 */
export const LtiBreadcrumbsLayout = ({accountId}: LtiBreadcrumbsLayoutProps) => {
  const page = useTopLevelPage()

  const manage = I18n.t('Apps - Manage')
  const discover = I18n.t('Apps - Discover')
  const create = I18n.t('Apps - Monitor')

  let breadcrumbTitle: string
  let url: string
  switch (page) {
    case 'manage':
      breadcrumbTitle = manage
      url = `/accounts/${accountId}/apps/manage`
      break
    case 'discover':
      breadcrumbTitle = discover
      url = `/accounts/${accountId}/apps`
      break
    case 'monitor':
      breadcrumbTitle = create
      url = `/accounts/${accountId}/apps/monitor`
      break
  }

  useAppendBreadcrumb(breadcrumbTitle, url)

  return <Outlet />
}
