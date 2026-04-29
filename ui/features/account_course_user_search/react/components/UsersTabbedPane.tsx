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

import React, {useCallback, useState, Suspense, lazy} from 'react'
import {Tabs} from '@instructure/ui-tabs'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import UsersPane from './UsersPane'

const I18n = createI18nScope('account_course_user_search')

const TAB_PARAM = 'account_tags'

const AccountTagsPane = lazy(() => import('./AccountTagsPane'))

interface UsersTabbedPaneProps {
  store: {
    getState: () => unknown
    dispatch: (action: unknown) => unknown
    subscribe: (listener: () => void) => () => void
  }
  roles: Array<{id: string; label: string}>
  onUpdateQueryParams: (params: Record<string, string>) => void
  queryParams: {
    page?: string
    search_term?: string
    include_deleted_users?: string
    role_filter_id?: string
    tab?: string
    tag_id?: string
  }
  permissions: {
    can_view_institutional_tags?: boolean
    [key: string]: boolean | undefined
  }
}

const UsersTabbedPane = (props: UsersTabbedPaneProps) => {
  const {queryParams, onUpdateQueryParams, permissions} = props
  const canViewInstitutionalTags = permissions?.can_view_institutional_tags

  const [selectedTabIndex, setSelectedTabIndex] = useState(
    canViewInstitutionalTags && queryParams?.tab === TAB_PARAM ? 1 : 0,
  )
  const [tagId, setTagId] = useState<string | null>(queryParams?.tag_id ?? null)

  const handleTagSelect = useCallback(
    (id: string | null) => {
      setTagId(id)
      onUpdateQueryParams({
        tab: TAB_PARAM,
        ...(id ? {tag_id: id} : {}),
      })
    },
    [onUpdateQueryParams],
  )

  if (!canViewInstitutionalTags) {
    return <UsersPane {...props} />
  }

  const handleTabChange = (_e: any, {index}: {index: number; id?: string}) => {
    setSelectedTabIndex(index)
    if (index === 1) {
      onUpdateQueryParams({tab: TAB_PARAM})
    } else {
      setTagId(null)
      onUpdateQueryParams({})
    }
  }

  return (
    <Tabs onRequestTabChange={handleTabChange}>
      <Tabs.Panel renderTitle={I18n.t('People')} isSelected={selectedTabIndex === 0}>
        <UsersPane {...props} />
      </Tabs.Panel>
      <Tabs.Panel renderTitle={I18n.t('Account Tags')} isSelected={selectedTabIndex === 1}>
        {selectedTabIndex === 1 && (
          <Suspense fallback={<Spinner renderTitle={I18n.t('Loading')} />}>
            <AccountTagsPane initialTagId={tagId ?? undefined} onTagSelect={handleTagSelect} />
          </Suspense>
        )}
      </Tabs.Panel>
    </Tabs>
  )
}

export default UsersTabbedPane
