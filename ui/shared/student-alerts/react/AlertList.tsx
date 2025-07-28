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

import {Fragment, useState} from 'react'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import Alert from './Alert'
import {Alert as AlertData, AlertUIMetadata, SaveAlertPayload} from './types'
import {View} from '@instructure/ui-view'
import SaveAlert from './SaveAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('alerts')

export const getCourseDescription = () =>
  I18n.t(
    'An alert is generated for each student that meets all of the criteria. They are checked every day, and notifications will be sent to the student and/or the teacher until the triggering problem is resolved.',
  )
export const getAccountDescription = () =>
  I18n.t(
    'An alert is generated for each student that meets all of the criteria. They are checked every day, and notifications will be sent to the student, teacher, and/or account admin until the triggering problem is resolved.',
  )

export interface AlertListProps {
  alerts: AlertData[]
  contextId: string
  contextType: string
  uiMetadata: AlertUIMetadata
}

const AlertList = ({alerts: initialAlerts, contextId, contextType, uiMetadata}: AlertListProps) => {
  const [alerts, setAlerts] = useState<Array<AlertData>>(initialAlerts)
  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const [selectedAlert, setSelectedAlert] = useState<AlertData>()
  const description = contextType === 'Course' ? getCourseDescription() : getAccountDescription()
  const urlPrefix = `/${contextType === 'Course' ? 'courses' : 'accounts'}/${contextId}`

  const saveAlert = async (payload: SaveAlertPayload) => {
    const alertId = payload.alert.id
    const isEdit = Boolean(alertId)

    if (isEdit) {
      try {
        const {json: updatedAlert} = await doFetchApi<AlertData>({
          path: `${urlPrefix}/alerts/${alertId}`,
          method: 'PUT',
          body: payload,
        })

        setIsTrayOpen(false)
        setAlerts(alerts.map(alert => (alert.id === alertId ? updatedAlert! : alert)))
        showFlashSuccess(I18n.t('Alert updated successfully.'))()
      } catch {
        showFlashError(I18n.t('Failed to update alert. Please try again later.'))()
      }
    } else {
      try {
        const {json: createdAlert} = await doFetchApi<AlertData>({
          path: `${urlPrefix}/alerts`,
          method: 'POST',
          body: payload,
        })

        setIsTrayOpen(false)
        setAlerts([...alerts, createdAlert!])
        showFlashSuccess(I18n.t('Alert created successfully.'))()
      } catch {
        showFlashError(I18n.t('Failed to create alert. Please try again later.'))()
      }
    }

    setIsTrayOpen(false)
    setSelectedAlert(undefined)
  }

  const deleteAlert = async (alertToDelete: AlertData) => {
    if (isTrayOpen) {
      return
    }

    try {
      await doFetchApi({
        path: `${urlPrefix}/alerts/${alertToDelete.id}`,
        method: 'DELETE',
      })

      setAlerts(alerts.filter(alert => alert.id !== alertToDelete.id))
      showFlashSuccess(I18n.t('Alert deleted successfully.'))()
    } catch {
      showFlashError(I18n.t('Failed to delete alert. Please try again later.'))()
    }
  }

  const editAlert = (alertToEdit: AlertData) => {
    if (isTrayOpen) {
      return
    }

    setSelectedAlert(alertToEdit)
    setIsTrayOpen(true)
  }

  const createAlert = () => {
    if (isTrayOpen) {
      return
    }

    setSelectedAlert(undefined)
    setIsTrayOpen(true)
  }

  const closeTray = () => {
    setIsTrayOpen(false)
    setTimeout(() => setSelectedAlert(undefined), 500)
  }

  return (
    <Flex direction="column">
      <Heading margin="medium 0 small 0">{I18n.t('Alerts')}</Heading>
      <Text>{description}</Text>
      <SaveAlert
        initialAlert={selectedAlert}
        uiMetadata={uiMetadata}
        isOpen={isTrayOpen}
        onClick={createAlert}
        onSave={saveAlert}
        onClose={closeTray}
      />
      <View data-testid="alerts">
        {alerts.map(alert => (
          <Fragment key={alert.id}>
            <hr aria-hidden={true} style={{margin: '36px 0'}} />
            <Alert
              alert={alert}
              uiMetadata={uiMetadata}
              onEdit={editAlert}
              onDelete={deleteAlert}
            />
          </Fragment>
        ))}
      </View>
    </Flex>
  )
}

export default AlertList
export {calculateUIMetadata} from './utils'
