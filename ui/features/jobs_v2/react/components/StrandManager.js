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
import React, {useState, useMemo} from 'react'
import {useQuery, useMutation} from 'react-apollo'
import {GET_SETTING_QUERY, SET_SETTING_MUTATION} from '../../graphql/Queries'
import {Modal} from '@instructure/ui-modal'
import {Button, IconButton, CloseButton} from '@instructure/ui-buttons'
import {IconSettingsLine, IconWarningLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {NumberInput} from '@instructure/ui-number-input'
import {Spinner} from '@instructure/ui-spinner'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = useI18nScope('jobs_v2')

function boundMaxConcurrent(value) {
  if (value < 1) return 1
  else if (value >= 255) return 255
  else return value
}

function boundPriority(value) {
  if (value < 0) return 0
  else if (value >= 1000000) return 1000000
  else return value
}

export default function StrandManager({strand, jobs, onUpdate}) {
  const computedMaxConcurrent = useMemo(() => {
    return Math.max(...jobs.map(job => job.max_concurrent))
  }, [jobs])

  const computedPriority = useMemo(() => {
    return Math.min(...jobs.map(job => job.priority))
  }, [jobs])

  const [modalOpen, setModalOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(false)
  const [maxConcurrent, setMaxConcurrent] = useState(computedMaxConcurrent)
  const [priority, setPriority] = useState(computedPriority)
  const [numStrands, setNumStrands] = useState()
  const [numStrandsOG, setNumStrandsOG] = useState()
  const [numStrandsSettingId, setNumStrandsSettingId] = useState()

  const handleClose = () => setModalOpen(false)

  const [saveSetting] = useMutation(SET_SETTING_MUTATION)

  const handleSubmit = e => {
    e.preventDefault()
    setLoading(true)
    setError(false)

    const calls = [
      doFetchApi({
        method: 'PUT',
        path: '/api/v1/jobs2/manage',
        params: {strand, max_concurrent: maxConcurrent || '', priority},
      }),
    ]
    if (numStrands && numStrands !== numStrandsOG) {
      calls.push(saveSetting({variables: {id: numStrandsSettingId, value: numStrands.toString()}}))
    }

    return Promise.all(calls).then(
      results => {
        handleClose()
        onUpdate(results[0])
        if (results.length === 2) {
          setNumStrandsOG(numStrands)
        }
        setLoading(false)
      },
      _error => {
        setLoading(false)
        setError(true)
      }
    )
  }

  const onChangeConcurrency = (_event, value) =>
    setMaxConcurrent(value && boundMaxConcurrent(parseInt(value, 10)))

  const onIncrementConcurrency = diff => setMaxConcurrent(boundMaxConcurrent(maxConcurrent + diff))

  const onChangePriority = (_event, value) =>
    setPriority(value && boundPriority(parseInt(value, 10)))

  const onIncrementPriority = diff => setPriority(boundPriority(priority + diff))

  const onChangeNumStrands = (_event, value) =>
    setNumStrands(value && boundMaxConcurrent(parseInt(value, 10)))

  const onIncrementNumStrands = diff => setNumStrands(boundMaxConcurrent(numStrands + diff))

  const enableSubmit = () =>
    !loading && typeof maxConcurrent === 'number' && typeof priority === 'number'

  useQuery(GET_SETTING_QUERY, {
    variables: {name: `${strand}_num_strands`},
    onCompleted: data => {
      const setting = data.internalSetting
      if (setting) {
        const n = parseInt(setting.value, 10)
        setNumStrands(n)
        setNumStrandsOG(n)
        setNumStrandsSettingId(setting.id)
      }
    },
  })

  // presently all we do is update parallelism / priority for entire strands, so don't render an icon otherwise
  if (!strand || jobs.length === 0) return null

  const caption = I18n.t('Manage strand "%{strand}"', {strand})
  return (
    <>
      <Tooltip renderTip={caption} on={['hover', 'focus']}>
        <IconButton onClick={() => setModalOpen(true)} screenReaderLabel={caption}>
          <IconSettingsLine />
        </IconButton>
      </Tooltip>
      <Modal
        as="form"
        label={caption}
        open={modalOpen}
        onDismiss={handleClose}
        onSubmit={handleSubmit}
        shouldCloseOnDocumentClick={false}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={handleClose}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{strand}</Heading>
        </Modal.Header>
        <Modal.Body>
          <Flex direction="column">
            <Flex.Item padding="xx-small">
              <NumberInput
                renderLabel={I18n.t('Priority')}
                value={priority}
                onChange={onChangePriority}
                onIncrement={() => onIncrementPriority(1)}
                onDecrement={() => onIncrementPriority(-1)}
              />
            </Flex.Item>
            <Flex.Item padding="0 xx-small">
              <Text fontStyle="italic">{I18n.t('Smaller numbers mean higher priority')}</Text>
            </Flex.Item>
            {maxConcurrent > 1 && (
              <>
                <Flex.Item margin="medium 0 0 0" padding="xx-small">
                  <NumberInput
                    renderLabel={I18n.t('Dynamic concurrency')}
                    value={maxConcurrent}
                    onChange={onChangeConcurrency}
                    onIncrement={() => onIncrementConcurrency(1)}
                    onDecrement={() => onIncrementConcurrency(-1)}
                  />
                </Flex.Item>
                {numStrands && (
                  <Flex.Item margin="medium 0 0 0" padding="xx-small">
                    <NumberInput
                      renderLabel={I18n.t('Permanent num_strands setting')}
                      value={numStrands}
                      onChange={onChangeNumStrands}
                      onIncrement={() => onIncrementNumStrands(1)}
                      onDecrement={() => onIncrementNumStrands(-1)}
                    />
                  </Flex.Item>
                )}
              </>
            )}
          </Flex>
        </Modal.Body>
        <Modal.Footer>
          {loading ? (
            <Spinner renderTitle={I18n.t('Applying changes')} size="small" margin="0 medium" />
          ) : error ? (
            <IconWarningLine size="small" color="error" title={I18n.t('Failed to update strand')} />
          ) : null}
          <Button
            interaction={enableSubmit() ? 'enabled' : 'disabled'}
            color="primary"
            type="submit"
          >
            {I18n.t('Apply')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}
