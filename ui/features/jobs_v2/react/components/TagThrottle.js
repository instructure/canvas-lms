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
import React, {useState, useEffect} from 'react'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconSettingsLine, IconInfoLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {NumberInput} from '@instructure/ui-number-input'
import {Spinner} from '@instructure/ui-spinner'
import useFetchApi from '@canvas/use-fetch-api-hook'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Tooltip} from '@instructure/ui-tooltip'
import {Alert} from '@instructure/ui-alerts'
import useDebouncedSearchTerm from '@canvas/search-item-selector/react/hooks/useDebouncedSearchTerm'

const I18n = useI18nScope('jobs_v2')

export default function TagThrottle({tag, jobs, onUpdate}) {
  const [modalOpen, setModalOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState(false)
  const [term, setTerm] = useState(tag)
  const [shardId, setShardId] = useState(jobs[0]?.shard_id)
  const [maxConcurrent, setMaxConcurrent] = useState(1)
  const [searchResult, setSearchResult] = useState({})
  const {searchTerm: debouncedTerm, setSearchTerm: setDebouncedTerm} = useDebouncedSearchTerm(
    term,
    {timeout: 250}
  )
  const {searchTerm: debouncedShardId, setSearchTerm: setDebouncedShardId} = useDebouncedSearchTerm(
    shardId,
    {timeout: 250}
  )

  const handleClose = () => setModalOpen(false)

  const handleSubmit = e => {
    e.preventDefault()
    setSaving(true)
    setError(false)

    return doFetchApi({
      method: 'PUT',
      path: '/api/v1/jobs2/throttle',
      params: {term, shard_id: shardId, max_concurrent: maxConcurrent},
    }).then(
      ({json}) => {
        handleClose()
        onUpdate(json)
        setSaving(false)
      },
      err => {
        setSaving(false)
        setError(err)
      }
    )
  }

  useEffect(() => {
    setDebouncedTerm(term)
    setDebouncedShardId(shardId)
  }, [term, shardId, setDebouncedTerm, setDebouncedShardId])

  useFetchApi(
    {
      path: '/api/v1/jobs2/throttle/check',
      params: {term: debouncedTerm, shard_id: debouncedShardId},
      loading: setLoading,
      success: setSearchResult,
      forceResult: modalOpen ? undefined : {},
    },
    [modalOpen]
  )

  const enableSubmit = () => !loading && !saving && term.length > 1 && searchResult.matched_jobs > 1

  const onChangeConcurrency = (_event, value) =>
    setMaxConcurrent(value && boundMaxConcurrent(parseInt(value, 10)))

  const onIncrementConcurrency = diff => setMaxConcurrent(boundMaxConcurrent(maxConcurrent + diff))

  const boundMaxConcurrent = value => Math.max(1, Math.min(value, 255))

  const Footer = () => {
    return (
      <>
        {saving ? <Spinner renderTitle={I18n.t('Throttling jobs')} /> : null}
        <Button
          color="primary"
          interaction={enableSubmit() ? 'enabled' : 'disabled'}
          onClick={handleSubmit}
          margin="0 x-small 0 0"
        >
          {I18n.t('Throttle Jobs')}
        </Button>
        <Button onClick={handleClose}>{I18n.t('Cancel')}</Button>
      </>
    )
  }

  // don't render an icon unless a tag matching non-stranded jobs is given
  if (!tag || jobs.length === 0 || jobs.some(job => job.strand || job.singleton)) return null

  const caption = I18n.t('Throttle tag "%{tag}"', {tag})
  return (
    <>
      <Tooltip renderTip={caption} on={['hover', 'focus']}>
        <IconButton onClick={() => setModalOpen(true)} screenReaderLabel={caption}>
          <IconSettingsLine />
        </IconButton>
      </Tooltip>
      <CanvasModal footer={<Footer />} label={caption} open={modalOpen} onDismiss={handleClose}>
        <Flex direction="column">
          {error && (
            <Flex.Item>
              <Alert variant="error">{I18n.t('Failed to throttle tag: %{error}', {error})}</Alert>
            </Flex.Item>
          )}
          <Flex.Item padding="xx-small">
            <TextInput
              renderLabel={I18n.t('Tag starts with')}
              value={term}
              onChange={(_, value) => setTerm(value)}
            />
          </Flex.Item>
          <Flex.Item padding="xx-small">
            <TextInput
              renderLabel={I18n.t('Shard ID (optional)')}
              value={shardId}
              onChange={(_, value) => setShardId(value)}
            />
          </Flex.Item>
          <Flex.Item padding="0 xx-small">
            {loading ? (
              <Spinner size="x-small" renderTitle={I18n.t('Finding matched jobs')} />
            ) : (
              <Text fontStyle="italic">
                {searchResult?.matched_jobs > 0
                  ? I18n.t('Matched %{jobs} jobs with %{tags} tags', {
                      jobs: searchResult.matched_jobs,
                      tags: searchResult.matched_tags,
                    })
                  : I18n.t('No matched jobs')}
              </Text>
            )}
          </Flex.Item>
          <Flex.Item padding="xx-small">
            <NumberInput
              renderLabel={I18n.t('New Concurrency')}
              value={maxConcurrent}
              onChange={onChangeConcurrency}
              onIncrement={() => onIncrementConcurrency(1)}
              onDecrement={() => onIncrementConcurrency(-1)}
            />
          </Flex.Item>
          <Flex.Item>
            <Flex direction="row" padding="small">
              <Flex.Item padding="0 x-small 0 0">
                <IconInfoLine size="x-small" color="brand" />
              </Flex.Item>
              <Flex.Item>
                <Text>
                  {I18n.t(
                    'After throttling the selected jobs, the newly created strand will be selected.'
                  )}
                </Text>
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      </CanvasModal>
    </>
  )
}
