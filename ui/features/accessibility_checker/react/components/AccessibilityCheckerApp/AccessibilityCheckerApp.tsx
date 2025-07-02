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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import React, {useState, useEffect} from 'react'

import {TypeToKeyMap} from '../../constants'
import {AccessibilityData, ContentItem, ContentItemType} from '../../types'
import {calculateTotalIssuesCount, convertKeysToCamelCase} from '../../utils'
import {AccessibilityIssuesModal} from '../AccessibilityIssuesModal/AccessibilityIssuesModal'
import {AccessibilityIssuesTable} from '../AccessibilityIssuesTable/AccessibilityIssuesTable'
import type {TableSortState} from '../AccessibilityIssuesTable/AccessibilityIssuesTable'
import {IssuesCounter} from './IssuesCounter'

const I18n = createI18nScope('accessibility_checker')

export const AccessibilityCheckerApp: React.FC = () => {
  const [accessibilityIssues, setAccessibilityIssues] = useState<AccessibilityData | null>(null)
  const [loading, setLoading] = useState(true)
  const [tableSortState, setTableSortState] = useState<TableSortState>({})
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    doFetchApi({path: window.location.href + '/issues', method: 'POST'})
      .then(data => {
        setAccessibilityIssues(convertKeysToCamelCase(data.json) as AccessibilityData)
      })
      .catch(err => {
        setError('Error loading accessibility issues. Error is:' + err.message)
        setAccessibilityIssues(null)
      })
      .finally(() => setLoading(false))
  }, [])

  const [selectedItem, setSelectedItem] = useState<ContentItem | null>(null)
  const [showModal, setShowModal] = useState(false)
  const [tableData, setTableData] = useState<ContentItem[]>([])

  useEffect(() => {
    const processData = () => {
      const flatData: ContentItem[] = []

      const processContentItems = (
        items: Record<string, ContentItem> | undefined,
        type: ContentItemType,
        defaultTitle: string,
      ) => {
        if (!items) return

        Object.entries(items).forEach(([id, itemData]) => {
          if (itemData) {
            flatData.push({
              id: Number(id),
              type,
              title: itemData?.title || defaultTitle,
              published: itemData?.published || false,
              updatedAt: itemData?.updatedAt || '',
              count: itemData?.count || 0,
              url: itemData?.url,
              editUrl: itemData?.editUrl,
            })
          }
        })
      }

      processContentItems(accessibilityIssues?.pages, ContentItemType.WikiPage, 'Untitled Page')

      processContentItems(
        accessibilityIssues?.assignments,
        ContentItemType.Assignment,
        'Untitled Assignment',
      )

      processContentItems(
        accessibilityIssues?.attachments,
        ContentItemType.Attachment,
        'Untitled Attachment',
      )

      setTableData(flatData)
    }

    processData()
  }, [accessibilityIssues])

  const handleRowClick = (item: ContentItem) => {
    const typeKey = TypeToKeyMap[item.type]

    const contentItem = accessibilityIssues?.[typeKey]?.[item.id]
      ? structuredClone(accessibilityIssues[typeKey]?.[item.id])
      : undefined
    setSelectedItem({
      ...item,
      issues: contentItem?.issues || [],
    })
    setShowModal(true)
  }

  const handleReload = () => {
    window.location.reload()
  }

  const handleSortRequest = (
    sortId?: string,
    sortDirection?: 'ascending' | 'descending' | 'none',
  ) => {
    try {
      setLoading(true)
      console.log('Sort request:', sortId, sortDirection)
      // TODO invoke backend API with the new values to sort the data
      // Then update states accordingly
      setTableSortState({
        sortId,
        sortDirection,
      })
    } catch {
      // Showing an error alert on the page
    } finally {
      setLoading(false)
    }
  }

  const closeModal = (shallReload: boolean) => {
    setShowModal(false)
    if (shallReload) {
      window.location.reload()
    }
  }

  if (loading)
    return (
      <View as="div">
        <Flex direction="column">
          <Flex.Item>
            <Heading>{I18n.t('Loading accessibility issues...')}</Heading>
          </Flex.Item>
          <Flex.Item shouldGrow>
            <Spinner
              renderTitle="Loading accessibility issues"
              size="large"
              margin="0 0 0 medium"
            />
          </Flex.Item>
        </Flex>
      </View>
    )
  else if (error || !accessibilityIssues)
    return (
      <Alert variant="error" renderCloseButtonLabel="Close" margin="small 0">
        {error || I18n.t('No accessibility issues data available.')}
      </Alert>
    )
  else {
    const lastCheckedDate =
      accessibilityIssues.lastChecked &&
      new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: 'short',
        day: '2-digit',
      }).format(new Date(accessibilityIssues.lastChecked))

    return (
      <View as="div">
        <Flex as="div" alignItems="start" direction="row">
          <Flex.Item>
            <Heading level="h1">{I18n.t('Course Accessibility Checker')}</Heading>
          </Flex.Item>
          <Flex.Item margin="0 0 0 auto" padding="small 0">
            <Button color="primary" onClick={handleReload}>
              {I18n.t('Scan course')}
            </Button>
          </Flex.Item>
        </Flex>
        <Flex as="div" alignItems="start" direction="row">
          {lastCheckedDate && (
            <Flex.Item>
              <Text size="small" color="secondary">
                <>
                  {I18n.t('Last checked at ')}
                  {lastCheckedDate}
                </>
              </Text>
            </Flex.Item>
          )}
        </Flex>

        <Flex margin="medium 0 0 0" gap="small" alignItems="stretch">
          <Flex.Item>
            <View as="div" padding="medium" borderWidth="small" borderRadius="medium" height="100%">
              <IssuesCounter count={calculateTotalIssuesCount(accessibilityIssues)} />
            </View>
          </Flex.Item>
          <Flex.Item shouldGrow shouldShrink>
            <View
              as="div"
              padding="medium"
              borderWidth="small"
              borderRadius="medium"
              height="100%"
            ></View>
          </Flex.Item>
        </Flex>

        <AccessibilityIssuesTable
          isLoading={loading}
          onRowClick={handleRowClick}
          onSortRequest={handleSortRequest}
          tableData={tableData}
          tableSortState={tableSortState}
        />

        {selectedItem && (
          <AccessibilityIssuesModal isOpen={showModal} onClose={closeModal} item={selectedItem} />
        )}
      </View>
    )
  }
}
