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

import React, {useCallback, useMemo} from 'react'
import {Modal} from '@instructure/ui-modal'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getWidgetsForRole} from '../WidgetRegistry'
import {useWidgetLayout} from '../../hooks/useWidgetLayout'
import {useResponsiveContext} from '../../hooks/useResponsiveContext'
import {useWidgetDashboard} from '../../hooks/useWidgetDashboardContext'
import {WIDGET_TYPES, EDUCATOR_CANVAS_ROLES, EDUCATOR_WIDGET_ROLE} from '../../constants'
import WidgetCard from './WidgetCard'

const I18n = createI18nScope('widget_dashboard')

interface AddWidgetModalProps {
  open: boolean
  onClose: () => void
  targetColumn: number
  targetRow: number
}

const AddWidgetModal: React.FC<AddWidgetModalProps> = ({
  open,
  onClose,
  targetColumn,
  targetRow,
}) => {
  const {addWidget, config} = useWidgetLayout()
  const {isMobile} = useResponsiveContext()
  const {currentUserRoles} = useWidgetDashboard()
  const isObserver = currentUserRoles?.includes('observer') ?? false
  const widgetRole = EDUCATOR_CANVAS_ROLES.some(r => currentUserRoles?.includes(r))
    ? EDUCATOR_WIDGET_ROLE
    : undefined

  const visibleWidgets = useMemo(() => {
    const widgets = Object.entries(getWidgetsForRole(widgetRole))
    // TODO: observer INBOX exclusion owned by learner dashboard team — remove when they add role tagging to INBOX
    return isObserver ? widgets.filter(([type]) => type !== WIDGET_TYPES.INBOX) : widgets
  }, [widgetRole, isObserver])

  const isWidgetOnDashboard = useCallback(
    (widgetType: string): boolean => {
      return config.widgets.some(w => w.type === widgetType)
    },
    [config.widgets],
  )

  const handleAddWidget = useCallback(
    (widgetType: string, displayName: string) => {
      addWidget(widgetType, displayName, targetColumn, targetRow)
      onClose()
    },
    [addWidget, targetColumn, targetRow, onClose],
  )

  return (
    <Modal
      open={open}
      onDismiss={onClose}
      size="large"
      label={I18n.t('Add widget')}
      data-testid="add-widget-modal"
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
          data-testid="close-button"
        />
        <Heading data-testid="modal-heading">{I18n.t('Add widget')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Flex direction="row" wrap="wrap" gap="small" alignItems="stretch">
          {visibleWidgets.map(([type, renderer]) => (
            <Flex.Item key={type} width={isMobile ? '100%' : 'calc(50% - 0.5rem)'}>
              <WidgetCard
                type={type}
                displayName={renderer.displayName}
                description={renderer.description}
                onAdd={() => handleAddWidget(type, renderer.displayName)}
                disabled={isWidgetOnDashboard(type)}
              />
            </Flex.Item>
          ))}
        </Flex>
      </Modal.Body>
    </Modal>
  )
}

export default AddWidgetModal
