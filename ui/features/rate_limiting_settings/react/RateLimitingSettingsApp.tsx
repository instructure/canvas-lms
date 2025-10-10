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

import React, {useState, useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {Table} from '@instructure/ui-table'
import {IconMoreLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Tooltip} from '@instructure/ui-tooltip'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import CreateRateLimitModal from './CreateRateLimitModal'
import EditRateLimitModal from './EditRateLimitModal'
import CopyToClipboardButton from '@canvas/copy-to-clipboard-button'

const I18n = createI18nScope('rate_limiting_settings')

export interface RateLimitSetting {
  id: string
  identifier_type: string
  identifier_value: string
  masked_identifier: string
  rate_limit: number
  outflow_rate?: number
  client_name: string
  comment: string
  created_at: string
  updated_at: string
  updated_by: string
}

// BookmarkedCollection returns the array directly, pagination metadata is in HTTP headers

type RateLimitingColumnId =
  | 'type'
  | 'identifier'
  | 'client_name'
  | 'throttle_high_water_mark'
  | 'throttle_outflow'
  | 'comment'
  | 'updated_at'
  | 'updated_by'

const RateLimitingSettingsApp: React.FC = () => {
  const [settings, setSettings] = useState<RateLimitSetting[]>([])
  const [loading, setLoading] = useState(true)
  const [loadingMore, setLoadingMore] = useState(false)
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [editingSetting, setEditingSetting] = useState<RateLimitSetting | null>(null)
  // BookmarkedCollection pagination is handled via HTTP Link headers
  const [nextUrl, setNextUrl] = useState<string | null>(null)
  const [sortBy, setSortBy] = useState<RateLimitingColumnId>('updated_at')
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('asc')

  const getSortDirection = (column: RateLimitingColumnId): 'ascending' | 'descending' | 'none' => {
    if (sortBy === column) {
      return sortDirection === 'asc' ? 'ascending' : 'descending'
    }
    return 'none'
  }

  const loadSettings = React.useCallback(
    async (url?: string, append = false) => {
      try {
        if (append) {
          setLoadingMore(true)
        } else {
          setLoading(true)
        }
        const result = url
          ? await doFetchApi<RateLimitSetting[]>({path: url})
          : await fetchRules({
              order_by: sortBy,
              direction: sortDirection,
            })

        const json = result.json

        if (typeof json !== 'undefined' && json) {
          if (append) {
            setSettings(prevSettings => [...prevSettings, ...json])
          } else {
            setSettings(json)
          }

          // Check for next link for pagination (BookmarkedCollection style)
          setNextUrl(result.link?.next?.url || null)
        }
      } catch (error) {
        console.error('Error loading settings:', error)
        showFlashAlert({
          message: I18n.t('Failed to load rate limiting settings'),
          type: 'error',
        })
      } finally {
        setLoading(false)
        setLoadingMore(false)
      }
    },
    [sortBy, sortDirection],
  )

  useEffect(() => {
    loadSettings()
  }, [loadSettings])

  const handleSort = (column: RateLimitingColumnId) => {
    if (sortBy === column) {
      // Toggle direction if same column
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc')
    } else {
      // New column, start with ascending
      setSortBy(column)
      setSortDirection('asc')
    }
  }

  const handleLoadMore = () => {
    if (nextUrl) {
      loadSettings(nextUrl, true)
    }
  }

  const handleCreateSuccess = (newSetting: RateLimitSetting) => {
    setShowCreateModal(false)
    showFlashAlert({
      message: I18n.t('Rate limit set for identifier %{identifier} to %{limit}', {
        identifier: newSetting.identifier_value,
        limit: newSetting.rate_limit,
      }),
      type: 'success',
    })
    loadSettings()
  }

  const handleEditSuccess = (updatedSetting: RateLimitSetting) => {
    setSettings(prevSettings =>
      prevSettings.map(setting => (setting.id === updatedSetting.id ? updatedSetting : setting)),
    )
    setEditingSetting(null)
    showFlashAlert({
      message: I18n.t('Rate limit set for identifier %{identifier} to %{limit}', {
        identifier: updatedSetting.identifier_value,
        limit: updatedSetting.rate_limit,
      }),
      type: 'success',
    })
  }

  const handleDelete = async (setting: RateLimitSetting) => {
    if (!confirm(I18n.t('Are you sure you want to delete this rate limit setting?'))) {
      return
    }

    try {
      await doFetchApi({
        path: `/accounts/${ENV.ACCOUNT_ID}/rate_limiting_settings/${setting.id}`,
        method: 'DELETE',
      })

      setSettings(prevSettings => prevSettings.filter(s => s.id !== setting.id))
      showFlashAlert({
        message: I18n.t('Rate limit setting deleted'),
        type: 'success',
      })
    } catch (error) {
      console.error('Error deleting setting:', error)
      showFlashAlert({
        message: I18n.t('Failed to delete rate limit setting'),
        type: 'error',
      })
    }
  }

  return (
    <View as="div" padding="small none none none">
      <h1>{I18n.t('Rate Limiting Configuration')}</h1>
      <div>{I18n.t('Configure rules for limiting the API usage rates of various clients.')}</div>
      <Flex direction="row" justifyItems="space-between" margin="small none small none">
        <Flex.Item>
          <Button color="primary" onClick={() => setShowCreateModal(true)}>
            {I18n.t('Create rate limit')}
          </Button>
        </Flex.Item>
      </Flex>

      <View as="div" style={{overflowX: 'auto'}}>
        <Table caption={I18n.t('Rate limiting settings')} layout="auto">
          <Table.Head renderSortLabel={I18n.t('Sort By')}>
            <Table.Row>
              <Table.ColHeader
                id="type"
                sortDirection={getSortDirection('type')}
                onRequestSort={() => handleSort('type')}
                width="10%"
              >
                {I18n.t('Type')}
              </Table.ColHeader>
              <Table.ColHeader
                id="identifier"
                sortDirection={getSortDirection('identifier')}
                onRequestSort={() => handleSort('identifier')}
                width="15%"
              >
                {I18n.t('Identifier')}
              </Table.ColHeader>
              <Table.ColHeader
                id="name"
                sortDirection={getSortDirection('client_name')}
                onRequestSort={() => handleSort('client_name')}
                width="20%"
              >
                {I18n.t('Name')}
              </Table.ColHeader>
              <Table.ColHeader
                id="rate_limit"
                sortDirection={getSortDirection('throttle_high_water_mark')}
                onRequestSort={() => handleSort('throttle_high_water_mark')}
                width="10%"
              >
                {I18n.t('High water mark')}
              </Table.ColHeader>
              <Table.ColHeader
                id="outflow_rate"
                sortDirection={getSortDirection('throttle_outflow')}
                onRequestSort={() => handleSort('throttle_outflow')}
                width="10%"
              >
                {I18n.t('Outflow rate')}
              </Table.ColHeader>
              <Table.ColHeader
                id="comment"
                sortDirection={getSortDirection('comment')}
                onRequestSort={() => handleSort('comment')}
                width="20%"
              >
                {I18n.t('Comment')}
              </Table.ColHeader>
              <Table.ColHeader
                id="updated"
                sortDirection={getSortDirection('updated_at')}
                onRequestSort={() => handleSort('updated_at')}
                width="10%"
              >
                {I18n.t('Updated')}
              </Table.ColHeader>
              <Table.ColHeader
                id="updated_by"
                sortDirection={getSortDirection('updated_by')}
                onRequestSort={() => handleSort('updated_by')}
                width="10%"
              >
                {I18n.t('Updated by')}
              </Table.ColHeader>
              <Table.ColHeader id="actions" width="5%">
                {I18n.t('Actions')}
              </Table.ColHeader>
            </Table.Row>
          </Table.Head>
          <Table.Body>
            {loading ? (
              <Table.Row>
                <Table.Cell colSpan={9}>
                  <View as="div" textAlign="center" padding="large">
                    <Spinner renderTitle={I18n.t('Loading rate limiting settings')} size="large" />
                  </View>
                </Table.Cell>
              </Table.Row>
            ) : settings.length === 0 ? (
              <Table.Row>
                <Table.Cell colSpan={9}>
                  <View as="div" textAlign="center" padding="large">
                    <Text>{I18n.t('No rate limiting settings found')}</Text>
                  </View>
                </Table.Cell>
              </Table.Row>
            ) : (
              settings.map(setting => (
                <Table.Row key={setting.id}>
                  <Table.Cell headers="type">
                    <Text>{setting.identifier_type}</Text>
                  </Table.Cell>
                  <Table.Cell headers="identifier">
                    <Flex direction="row" alignItems="center">
                      <Flex.Item shouldGrow>
                        <Text>{setting.masked_identifier}</Text>
                      </Flex.Item>
                      <Flex.Item>
                        <CopyToClipboardButton
                          value={setting.identifier_value}
                          screenReaderLabel={I18n.t('Copy full identifier to clipboard')}
                          tooltipText={I18n.t('Copy full identifier to clipboard')}
                          tooltip={true}
                          buttonProps={{size: 'small', withBackground: false, withBorder: false}}
                        />
                      </Flex.Item>
                    </Flex>
                  </Table.Cell>
                  <Table.Cell headers="name">
                    <Text>{setting.client_name || '—'}</Text>
                  </Table.Cell>
                  <Table.Cell headers="rate_limit">
                    <Text>{setting.rate_limit || '—'}</Text>
                  </Table.Cell>
                  <Table.Cell headers="outflow_rate">
                    <Text>{setting.outflow_rate ?? '—'}</Text>
                  </Table.Cell>
                  <Table.Cell headers="comment">{setting.comment}</Table.Cell>
                  <Table.Cell headers="updated">
                    <Text>{new Date(setting.updated_at).toLocaleDateString()}</Text>
                  </Table.Cell>
                  <Table.Cell headers="updated_by">
                    <Text>{setting.updated_by || '—'}</Text>
                  </Table.Cell>
                  <Table.Cell headers="actions">
                    <Menu
                      trigger={
                        <IconButton
                          size="small"
                          screenReaderLabel={I18n.t('Actions for %{identifier}', {
                            identifier: setting.identifier_value,
                          })}
                          withBackground={false}
                          withBorder={false}
                          renderIcon={IconMoreLine}
                        />
                      }
                    >
                      <Menu.Item onSelect={() => setEditingSetting(setting)}>
                        {I18n.t('Edit')}
                      </Menu.Item>
                      <Menu.Item onSelect={() => handleDelete(setting)}>
                        {I18n.t('Delete')}
                      </Menu.Item>
                    </Menu>
                  </Table.Cell>
                </Table.Row>
              ))
            )}
          </Table.Body>
        </Table>
      </View>

      {nextUrl && (
        <View as="div" textAlign="center" padding="medium">
          <Button
            onClick={handleLoadMore}
            disabled={loadingMore}
            renderIcon={
              loadingMore ? <Spinner size="x-small" renderTitle={I18n.t('Loading')} /> : undefined
            }
          >
            {loadingMore ? I18n.t('Loading...') : I18n.t('Load more')}
          </Button>
        </View>
      )}

      <CreateRateLimitModal
        open={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onSuccess={handleCreateSuccess}
      />

      {editingSetting && (
        <EditRateLimitModal
          setting={editingSetting}
          onClose={() => setEditingSetting(null)}
          onSuccess={handleEditSuccess}
        />
      )}
    </View>
  )
}

function fetchRules(params: {order_by: RateLimitingColumnId; direction: 'asc' | 'desc'}) {
  return doFetchApi<RateLimitSetting[]>({
    path: `/accounts/${ENV.ACCOUNT_ID}/rate_limiting_settings`,
    params,
  })
}

export default RateLimitingSettingsApp
