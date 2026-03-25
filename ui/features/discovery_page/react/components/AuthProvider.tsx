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

import {ToggleGroup} from '@instructure/ui-toggle-details'
import {useScope as createI18nScope} from '@canvas/i18n'
import {AuthProviderHeader} from './AuthProviderHeader'
import {AuthProviderForm} from './AuthProviderForm'

const I18n = createI18nScope('discovery_page')

interface AuthProviderProps {
  label: string
  iconUrl?: string
  loginLabel: string
  selectedProviderId: string
  onLoginChange: (value: string) => void
  onProviderChange: (value: string) => void
  selectedIconId: string
  onIconSelect: (iconId: string) => void
  expanded?: boolean
  onToggle?: () => void
  disableMoveUp?: boolean
  disableMoveDown?: boolean
  onDelete: () => void
  onMoveUp: () => void
  onMoveDown: () => void
}

export function AuthProvider({
  label,
  iconUrl,
  loginLabel,
  selectedProviderId,
  onLoginChange,
  onProviderChange,
  selectedIconId,
  onIconSelect,
  expanded,
  onToggle,
  disableMoveUp,
  disableMoveDown,
  onDelete,
  onMoveUp,
  onMoveDown,
}: AuthProviderProps) {
  return (
    <ToggleGroup
      as="div"
      size="small"
      expanded={expanded}
      onToggle={() => onToggle?.()}
      toggleLabel={I18n.t('Expand %{label} settings', {label})}
      summary={
        <AuthProviderHeader
          label={label}
          iconUrl={iconUrl}
          disableMoveUp={disableMoveUp}
          disableMoveDown={disableMoveDown}
          onDelete={onDelete}
          onMoveUp={onMoveUp}
          onMoveDown={onMoveDown}
        />
      }
    >
      <AuthProviderForm
        loginLabel={loginLabel}
        selectedProviderId={selectedProviderId}
        onLoginChange={onLoginChange}
        onProviderChange={onProviderChange}
        selectedIconId={selectedIconId}
        onIconSelect={onIconSelect}
      />
    </ToggleGroup>
  )
}
