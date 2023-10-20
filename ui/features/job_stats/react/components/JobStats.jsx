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
import {Spinner} from '@instructure/ui-spinner'
import useFetchApi from '@canvas/use-fetch-api-hook'
import doFetchApi from '@canvas/do-fetch-api-effect'
import React, {useState, useCallback, useEffect} from 'react'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconWarningLine} from '@instructure/ui-icons'
import {showConfirmationDialog} from '@canvas/feature-flags/react/ConfirmationDialog'
import JobStatsTable from './JobStatsTable'
import StuckModal from './StuckModal'

const I18n = useI18nScope('jobs_v2')

export default function JobStats() {
  const [clusters, setClusters] = useState()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState()
  const [unstuckQueue, setUnstuckQueue] = useState({})
  const [stuckModalShard, setStuckModalShard] = useState()

  useFetchApi(
    {
      path: '/api/v1/jobs2/clusters',
      loading: setLoading,
      success: setClusters,
      error: setError,
      fetchAllPages: true,
    },
    []
  )

  const updateRow = useCallback(
    (shard_id, data) => {
      setClusters(
        clusters.map(cluster => (cluster.id === shard_id ? {...cluster, ...data} : cluster))
      )
    },
    [clusters]
  )

  const onRefresh = useCallback(
    shard_id => {
      updateRow(shard_id, {loading: true, error: null, message: I18n.t('Refreshing...')})
      doFetchApi({
        path: '/api/v1/jobs2/clusters',
        params: {job_shards: [shard_id]},
      })
        .then(({json}) => {
          updateRow(shard_id, {...json[0], loading: false, error: null})
        })
        .catch(e => {
          updateRow(shard_id, {loading: false, error: e})
        })
    },
    [updateRow]
  )

  const addUnstuckJob = (shard_id, progress_url) => {
    setUnstuckQueue({...unstuckQueue, [shard_id]: progress_url})
  }

  const removeUnstuckJob = useCallback(
    shard_id => {
      const newQueue = {...unstuckQueue}
      delete newQueue[shard_id]
      setUnstuckQueue(newQueue)
    },
    [unstuckQueue]
  )

  const confirmUnblock = async shard_id => {
    const cluster = clusters.find(c => c.id === shard_id)
    const blocked_shards =
      cluster.block_stranded_shard_ids.length > 0 || cluster.jobs_held_shard_ids.length > 0
    const result = await showConfirmationDialog({
      label: I18n.t('Unblock Jobs in Cluster'),
      body: (
        <Flex>
          <Flex.Item margin="medium">
            <IconWarningLine size="medium" color="warning" />
          </Flex.Item>
          <Flex.Item>
            <Text>
              {I18n.t('Are you sure you want to unblock all stuck jobs in this job cluster?')}
            </Text>
            {blocked_shards ? (
              <Text as="div">
                {I18n.t('NOTE: Jobs blocked by shard migrations will not be unblocked.')}
              </Text>
            ) : null}
          </Flex.Item>
        </Flex>
      ),
    })
    if (result) onUnblock(shard_id)
  }

  const onUnblock = shard_id => {
    updateRow(shard_id, {loading: true, error: null, message: I18n.t('Unblocking...')})
    doFetchApi({
      method: 'PUT',
      path: '/api/v1/jobs2/unstuck',
      params: {job_shards: [shard_id]},
    })
      .then(({json}) => {
        addUnstuckJob(shard_id, json.progress.url)
      })
      .catch(e => {
        updateRow(shard_id, {loading: false, error: e})
      })
  }

  // check for completion of any outstanding unstuck-shard jobs
  useEffect(() => {
    if (Object.keys(unstuckQueue).length === 0) return

    const intervalId = setInterval(() => {
      for (const shard_id in unstuckQueue) {
        const progress_url = unstuckQueue[shard_id]
        doFetchApi({
          path: progress_url,
        })
          .then(({json}) => {
            if (json.workflow_state === 'completed') {
              removeUnstuckJob(shard_id)
              onRefresh(shard_id)
            }
          })
          .catch(e => {
            removeUnstuckJob(shard_id)
            updateRow(shard_id, {loading: false, error: e})
          })
      }
    }, 1000)

    return () => clearInterval(intervalId)
  }, [onRefresh, removeUnstuckJob, unstuckQueue, updateRow])

  return (
    <>
      {error && (
        <Alert variant="error">{I18n.t('Failed to load job stats: %{error}', {error})}</Alert>
      )}
      {clusters && (
        <JobStatsTable
          clusters={clusters}
          onRefresh={onRefresh}
          onUnblock={confirmUnblock}
          onShowStuckModal={setStuckModalShard}
        />
      )}
      {loading ? <Spinner renderTitle={I18n.t('Loading job cluster info')} /> : null}
      {stuckModalShard && (
        <StuckModal
          shard={stuckModalShard}
          isOpen={true}
          onClose={() => setStuckModalShard(null)}
        />
      )}
    </>
  )
}
