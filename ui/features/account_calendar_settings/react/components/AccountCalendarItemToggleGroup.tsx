/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {Spinner} from '@instructure/ui-spinner'
import {ToggleGroup} from '@instructure/ui-toggle-details'
import {IconMiniArrowEndSolid, IconMiniArrowDownSolid} from '@instructure/ui-icons'

import {AccountCalendarItem} from './AccountCalendarItem'
import {Account, VisibilityChange, Collection} from '../types'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('account_calendar_settings_account_group')

type ComponentProps = {
  readonly parentId: null | number
  readonly accountGroup: Account[] | number[]
  readonly defaultExpanded: boolean
  readonly collections: Collection
  readonly handleToggle: (account: Account, expanded: boolean) => void
  readonly visibilityChanges: VisibilityChange[]
  readonly onAccountToggled: (id: number, visible: boolean) => void
}

const accGroupSortCalback = (a, b, parentId) => {
  if (a.id == parentId) {
    return -1
  }
  if (b.id == parentId) {
    return 1
  }
  if (b.sub_account_count < a.sub_account_count) {
    return 1
  }
  if (b.sub_account_count > a.sub_account_count) {
    return -1
  }
  return 0
}

export const AccountCalendarItemToggleGroup: React.FC<ComponentProps> = ({
  parentId,
  accountGroup,
  defaultExpanded,
  collections,
  handleToggle,
  visibilityChanges,
  onAccountToggled,
}) => {
  if (!accountGroup) return <Spinner renderTitle={I18n.t('Loading accounts')} size="x-small" />

  accountGroup = accountGroup
    .map(id => collections[id])
    .sort((a, b) => accGroupSortCalback(a, b, parentId))

  return (
    <div className="account-group">
      {accountGroup.map(acc => {
        if (!(acc.sub_account_count > 0 && parentId != acc.id)) {
          return (
            <div key={`toggle-group-single-${acc.id}`}>
              <AccountCalendarItem
                item={acc}
                visibilityChanges={visibilityChanges}
                onAccountToggled={onAccountToggled}
                padding="small"
              />
            </div>
          )
        }

        return (
          <div key={`toggle-group-${acc.id}`}>
            <ToggleGroup
              border={false}
              data-testid={`toggle-group-${acc.id}`}
              summary={acc.heading}
              toggleLabel={I18n.t('%{account_name}, %{number_of_children} accounts', {
                account_name: acc.name,
                number_of_children: acc.sub_account_count,
              })}
              iconExpanded={IconMiniArrowDownSolid}
              icon={IconMiniArrowEndSolid}
              onToggle={(ev, ex) => {
                handleToggle(acc, ex)
              }}
              defaultExpanded={defaultExpanded}
            >
              <AccountCalendarItemToggleGroup
                parentId={acc.id}
                accountGroup={acc.children}
                defaultExpanded={false}
                collections={collections}
                handleToggle={handleToggle}
                visibilityChanges={visibilityChanges}
                onAccountToggled={onAccountToggled}
              />
            </ToggleGroup>
          </div>
        )
      })}
    </div>
  )
}
