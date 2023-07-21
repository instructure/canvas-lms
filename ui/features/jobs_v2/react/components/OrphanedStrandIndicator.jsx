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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconWarningSolid} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Button, IconButton} from '@instructure/ui-buttons'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {Spinner} from '@instructure/ui-spinner'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Text} from '@instructure/ui-text'
import {Alert} from '@instructure/ui-alerts'

const I18n = useI18nScope('jobs_v2')

export default function OrphanedStrandIndicator({name, type, onComplete}) {
  const [modalOpen, setModalOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState()
  const [blocked, setBlocked] = useState(false)

  let tipLabel =
    type === 'strand'
      ? I18n.t('Strand "%{name}" has no next_in_strand.', {name})
      : I18n.t('Singleton "%{name}" has no next_in_strand.', {name})
  if (ENV?.manage_jobs) {
    tipLabel += ' ' + I18n.t('Click to fix')
  }

  const actionLabel =
    type === 'strand'
      ? I18n.t('Unblock strand "%{name}"', {name})
      : I18n.t('Unblock singleton "%{name}"', {name})

  const onClose = () => setModalOpen(false)

  const onSubmit = () => {
    setError(null)
    setBlocked(false)
    setLoading(true)
    doFetchApi({
      method: 'PUT',
      path: `/api/v1/jobs2/unstuck`,
      params: {[type]: name},
    })
      .then(({json}) => {
        if (json.status === 'OK') {
          onComplete(json)
          setLoading(false)
          setModalOpen(false)
        } else if (json.status === 'blocked') {
          setLoading(false)
          setBlocked(true)
        }
      })
      .catch(e => {
        setLoading(false)
        setError(e)
      })
  }

  const LoadingFeedback = () => {
    if (loading) {
      return (
        <View as="div" margin="medium 0 0 0">
          <Spinner size="small" renderTitle={I18n.t('Working')} />
        </View>
      )
    }
    return null
  }

  const Footer = () => {
    return (
      <>
        <Button
          interaction={loading ? 'disabled' : 'enabled'}
          onClick={onClose}
          margin="0 x-small 0 0"
        >
          {I18n.t('Cancel')}
        </Button>
        <Button interaction={loading ? 'disabled' : 'enabled'} color="primary" onClick={onSubmit}>
          {I18n.t('Unblock')}
        </Button>
      </>
    )
  }

  return (
    <>
      <Tooltip as="span" renderTip={tipLabel}>
        <View margin="0 x-small 0 0">
          {ENV?.manage_jobs ? (
            <IconButton screenReaderLabel={actionLabel} onClick={() => setModalOpen(true)}>
              <IconWarningSolid color="warning" />
            </IconButton>
          ) : (
            <IconWarningSolid color="warning" />
          )}
        </View>
      </Tooltip>
      <CanvasModal
        open={modalOpen}
        padding="large"
        onDismiss={onClose}
        label={actionLabel}
        footer={<Footer />}
        shouldCloseOnDocumentClick={false}
      >
        {error && <Alert variant="error">{I18n.t('Failed to unblock strand/singleton')}</Alert>}
        {blocked && (
          <Alert variant="warning">
            {I18n.t('Strand or singleton is blocked by the shard migrator')}
          </Alert>
        )}
        <Text>
          {I18n.t(
            'This will set next_in_strand on the appropriate number of jobs to unblock the strand or singleton.'
          )}
        </Text>
        <LoadingFeedback />
      </CanvasModal>
    </>
  )
}
