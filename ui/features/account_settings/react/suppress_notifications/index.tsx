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

import {useState, useCallback, useEffect, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Checkbox, CheckboxGroup} from '@instructure/ui-checkbox'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {InstUIModal as Modal} from '@instructure/platform-instui-bindings'

const I18n = createI18nScope('suppress_notifications')

export interface NotificationCategory {
  slug: string
  displayName: string
}

export interface SuppressNotificationsProps {
  suppressNotifications: boolean | string[]
  notificationCategories: NotificationCategory[]
}

type SuppressMode = 'all' | 'specific'

function deriveState(value: boolean | string[]) {
  if (value === true) {
    return {enabled: true, mode: 'all' as SuppressMode, selectedSlugs: [] as string[]}
  }
  if (Array.isArray(value) && value.length > 0) {
    return {enabled: true, mode: 'specific' as SuppressMode, selectedSlugs: value}
  }
  return {enabled: false, mode: 'all' as SuppressMode, selectedSlugs: [] as string[]}
}

export default function SuppressNotifications(props: SuppressNotificationsProps): JSX.Element {
  const initial = deriveState(props.suppressNotifications)
  const [enabled, setEnabled] = useState(initial.enabled)
  const [mode, setMode] = useState<SuppressMode>(initial.mode)
  const [selectedSlugs, setSelectedSlugs] = useState<string[]>(initial.selectedSlugs)
  const [pendingSlugs, setPendingSlugs] = useState<string[]>(initial.selectedSlugs)
  const [modalOpen, setModalOpen] = useState(false)
  const hiddenFieldsRef = useRef<HTMLDivElement>(null)

  const openModal = useCallback(() => {
    setPendingSlugs(selectedSlugs)
    setModalOpen(true)
  }, [selectedSlugs])

  const handleModalSave = useCallback(() => {
    setSelectedSlugs(pendingSlugs)
    setModalOpen(false)
  }, [pendingSlugs])

  const handleModalClose = useCallback(() => setModalOpen(false), [])

  useEffect(() => {
    const container = hiddenFieldsRef.current
    if (!container) return
    container.replaceChildren()

    if (!enabled) {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'account[settings][suppress_notifications]'
      input.value = '0'
      container.appendChild(input)
    } else if (mode === 'specific' && selectedSlugs.length > 0) {
      selectedSlugs.forEach(slug => {
        const input = document.createElement('input')
        input.type = 'hidden'
        input.name = 'account[settings][suppress_notifications][]'
        input.value = slug
        container.appendChild(input)
      })
    } else {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'account[settings][suppress_notifications]'
      input.value = '1'
      container.appendChild(input)
    }
  }, [enabled, mode, selectedSlugs])

  // Attach confirmation validator to the DOM mount point so the parent
  // form's jQuery submit handler can call it before submitting
  useEffect(() => {
    const node = document.getElementById('suppress-notifications-mount') as
      | (HTMLElement & {__performValidation?: () => boolean})
      | null
    if (!node) return
    node.__performValidation = () => {
      const wasSuppressAll = initial.enabled && initial.mode === 'all'
      if (enabled && mode === 'all' && !wasSuppressAll) {
        return window.confirm(
          I18n.t(
            'This will suppress all notifications from being created and sent out for this account. Are you sure?',
          ),
        )
      }
      return true
    }
    return () => {
      delete node.__performValidation
    }
  }, [enabled, mode, initial.enabled, initial.mode])

  return (
    <div>
      <Checkbox
        id="account_settings_suppress_notifications"
        label={I18n.t('Suppress notifications from being created and sent out')}
        checked={enabled}
        onChange={e => {
          setEnabled(e.target.checked)
          if (!e.target.checked) {
            setMode('all')
            setSelectedSlugs([])
          }
        }}
      />
      {enabled && (
        <View as="div" margin="x-small 0 0 medium">
          <RadioInputGroup
            name="suppress_notifications_mode"
            value={mode}
            onChange={(_e, val) => setMode(val as SuppressMode)}
            description={<ScreenReaderContent>{I18n.t('Suppression scope')}</ScreenReaderContent>}
          >
            <RadioInput value="all" label={I18n.t('All notifications')} />
            <RadioInput value="specific" label={I18n.t('Specific categories only')} />
          </RadioInputGroup>
          {mode === 'specific' && (
            <Button onClick={openModal} margin="x-small 0 0 0" data-testid="edit-categories-button">
              {selectedSlugs.length > 0
                ? I18n.t('Edit categories (%{count} selected)', {count: selectedSlugs.length})
                : I18n.t('Choose categories\u2026')}
            </Button>
          )}
        </View>
      )}
      <Modal
        open={modalOpen}
        onDismiss={handleModalClose}
        size="small"
        label={I18n.t('Suppress specific notification categories')}
        shouldCloseOnDocumentClick
      >
        <Modal.Body>
          <View as="div" maxHeight="20rem" overflowY="auto" padding="x-small">
            <CheckboxGroup
              name="suppress_notification_categories"
              description={
                <ScreenReaderContent>{I18n.t('Notification categories')}</ScreenReaderContent>
              }
              value={pendingSlugs}
              onChange={values => setPendingSlugs(values.map(String))}
            >
              {props.notificationCategories.map(cat => (
                <Checkbox
                  key={cat.slug}
                  id={`suppress_category_${cat.slug}`}
                  label={cat.displayName}
                  value={cat.slug}
                  data-testid={`category-${cat.slug}`}
                />
              ))}
            </CheckboxGroup>
          </View>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={handleModalClose} margin="0 x-small 0 0" data-testid="cancel-button">
            {I18n.t('Cancel')}
          </Button>
          <Button onClick={handleModalSave} color="primary" data-testid="save-button">
            {I18n.t('Save')}
          </Button>
        </Modal.Footer>
      </Modal>
      <div ref={hiddenFieldsRef} style={{display: 'none'}} />
    </div>
  )
}
