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

import {useEffect, useRef, useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {AuthProviderHeader} from './AuthProviderHeader'
import {AuthProviderForm} from './AuthProviderForm'
import {DISCOVERY_PAGE_ICONS} from '../constants'
import type {AuthProviderProps, CardFormErrors} from '../types'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('discovery_page')

export function AuthProvider({
  card,
  isEditing,
  isDisabled,
  authProviders,
  authProviderUrl,
  elementRef,
  onEditStart,
  onEditDone,
  onEditCancel,
  disableMoveUp,
  disableMoveDown,
  onDelete,
  onMoveUp,
  onMoveDown,
}: AuthProviderProps) {
  const [draftLabel, setDraftLabel] = useState(card.label)
  const [draftProviderId, setDraftProviderId] = useState<number | null>(
    card.authentication_provider_id,
  )
  const [draftIcon, setDraftIcon] = useState(card.icon ?? '')
  const [errors, setErrors] = useState<CardFormErrors>({})
  const labelRef = useRef<HTMLInputElement | null>(null)
  const providerRef = useRef<HTMLSelectElement | null>(null)

  // sync draft state on every edit mode transition (open and close) so stale
  // draft values never flash on the next open after a cancelled edit
  useEffect(() => {
    setDraftLabel(card.label)
    setDraftProviderId(card.authentication_provider_id)
    setDraftIcon(card.icon ?? '')
    setErrors({})

    if (isEditing) {
      labelRef.current?.focus()
    }

    // card is intentionally excluded: we only want to reset on isEditing transition
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isEditing])

  const handleDone = () => {
    const newErrors: CardFormErrors = {}

    // label sanitization (HTML stripping, entity encoding) is handled
    // server-side by Sanitize.clean (only check for presence here)
    if (!draftLabel.trim()) {
      newErrors.label = I18n.t('Please enter a label.')
    }

    if (draftProviderId === null) {
      newErrors.providerId = I18n.t('Please choose an authentication provider.')
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors)

      if (newErrors.label) {
        labelRef.current?.focus()
      } else if (newErrors.providerId) {
        providerRef.current?.focus()
      }

      return
    }

    onEditDone({
      label: draftLabel.trim(),
      authentication_provider_id: draftProviderId!,
      icon: draftIcon || undefined,
    })
  }

  const draftIconUrl = DISCOVERY_PAGE_ICONS.find(i => i.id === draftIcon)?.url
  const committedIconUrl = DISCOVERY_PAGE_ICONS.find(i => i.id === card.icon)?.url
  const draftProviderUrl = authProviders?.find(p => p.id === String(draftProviderId))?.url

  return (
    <View
      as="div"
      data-card-id={card.id}
      borderColor={isEditing ? 'brand' : undefined}
      borderRadius="medium"
      borderWidth="small"
      elementRef={el => elementRef?.(el instanceof HTMLElement ? el : null)}
      padding="small"
      shadow={isEditing ? 'above' : undefined}
    >
      <Flex as="div" direction="column" gap="small">
        <AuthProviderHeader
          label={isEditing ? draftLabel : card.label}
          iconUrl={isEditing ? draftIconUrl : committedIconUrl}
          providerUrl={isEditing ? draftProviderUrl : authProviderUrl}
          isEditing={isEditing}
          isDisabled={isDisabled}
          disableMoveUp={disableMoveUp}
          disableMoveDown={disableMoveDown}
          onEditStart={onEditStart}
          onDelete={onDelete}
          onMoveUp={onMoveUp}
          onMoveDown={onMoveDown}
        />

        {isEditing && (
          <>
            <View as="div" padding="small large">
              <AuthProviderForm
                authProviders={authProviders}
                loginLabel={draftLabel}
                selectedProviderId={draftProviderId ? String(draftProviderId) : ''}
                selectedIconId={draftIcon}
                onLoginChange={setDraftLabel}
                onProviderChange={id => setDraftProviderId(id ? Number(id) : null)}
                onIconSelect={setDraftIcon}
                errors={errors}
                onLabelRef={el => {
                  labelRef.current = el
                }}
                onProviderRef={el => {
                  providerRef.current = el
                }}
              />
            </View>

            <Flex gap="mediumSmall" direction="row-reverse">
              <Button onClick={handleDone} size="small" data-testid="auth-provider-done-button">
                {I18n.t('Done')}
              </Button>

              <Link isWithinText={false} onClick={onEditCancel}>
                {I18n.t('Cancel')}
              </Link>
            </Flex>
          </>
        )}
      </Flex>
    </View>
  )
}
