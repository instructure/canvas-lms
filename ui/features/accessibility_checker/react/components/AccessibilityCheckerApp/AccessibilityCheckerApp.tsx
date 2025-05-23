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

import {useScope as createI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Badge} from '@instructure/ui-badge'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'
import {IconPublishSolid, IconUnpublishedSolid} from '@instructure/ui-icons'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import React, {useState, useEffect} from 'react'
import {AccessibilityData, ContentItem, ContentItemType} from '../../types'
import {AccessibilityIssuesModal} from '../AccessibilityIssuesModal/AccessibilityIssuesModal'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {TypeToKeyMap} from '../../constants'

export const AccessibilityCheckerApp: React.FC = () => {
  const [accessibilityIssues, setAccessibilityIssues] = useState<AccessibilityData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const snakeToCamel = function (str: string): string {
      return str.replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase())
    }

    const convertKeysToCamelCase = function (input: any): object | boolean {
      if (Array.isArray(input)) {
        return input.map(convertKeysToCamelCase)
      } else if (input !== null && typeof input === 'object') {
        return Object.fromEntries(
          Object.entries(input).map(([key, value]) => [
            snakeToCamel(key),
            convertKeysToCamelCase(value),
          ]),
        )
      }
      return input !== null && input !== undefined ? input : {}
    }
    doFetchApi({path: window.location.href + '/issues', method: 'GET'})
      .then(data => {
        setAccessibilityIssues(convertKeysToCamelCase(data.json) as AccessibilityData)
      })
      .catch(err => {
        setError('Error loading accessibility issues. Error is:' + err.message)
        setAccessibilityIssues(null)
      })
      .finally(() => setLoading(false))
  }, [])

  const I18n = createI18nScope('accessibility_checker')
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

  const closeModal = () => {
    setShowModal(false)
    window.location.reload()
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

        <View as="div" margin="medium 0 0 0" borderWidth="small" borderRadius="medium">
          <Table
            caption={
              <ScreenReaderContent>
                {I18n.t('Content with accessibility issues')}
              </ScreenReaderContent>
            }
            hover
          >
            <Table.Head>
              <Table.Row>
                <Table.ColHeader id="name-header">
                  <Text weight="bold">{I18n.t('Content Name')}</Text>
                </Table.ColHeader>

                <Table.ColHeader id="issues-header" textAlign="center">
                  <Text weight="bold">{I18n.t('Issues')}</Text>
                </Table.ColHeader>

                <Table.ColHeader id="content-type-header">
                  <Text weight="bold">{I18n.t('Content Type')}</Text>
                </Table.ColHeader>

                <Table.ColHeader id="state-header">
                  <Text weight="bold">{I18n.t('State')}</Text>
                </Table.ColHeader>

                <Table.ColHeader id="updated-header">
                  <Text weight="bold">{I18n.t('Last updated')}</Text>
                </Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {tableData.length === 0 ? (
                <Table.Row>
                  <Table.Cell colSpan={5} textAlign="center">
                    <Text color="secondary">{I18n.t('No accessibility issues found')}</Text>
                  </Table.Cell>
                </Table.Row>
              ) : (
                tableData.map(item => (
                  <Table.Row key={`${item.type}-${item.id}`}>
                    <Table.Cell>
                      <Flex alignItems="center">
                        <Flex.Item margin="0 0 0 x-small">
                          <a href={item.url}>{item.title}</a>
                        </Flex.Item>
                      </Flex>
                    </Table.Cell>
                    <Table.Cell textAlign="center">
                      {item.count > 0 ? (
                        <Badge
                          count={item.count}
                          countUntil={999}
                          variant="danger"
                          margin="small 0 small 0"
                        >
                          <Button onClick={() => handleRowClick(item)}>
                            {I18n.t('View Issues')}
                          </Button>
                        </Badge>
                      ) : (
                        <Text color="secondary">No issues</Text>
                      )}
                    </Table.Cell>
                    <Table.Cell>{item.type}</Table.Cell>
                    <Table.Cell>
                      <Flex alignItems="center">
                        {item.published ? (
                          <>
                            <Flex.Item margin="medium">
                              <IconPublishSolid color="success" />
                            </Flex.Item>
                            <Flex.Item>
                              <Text>{I18n.t('Published')}</Text>
                            </Flex.Item>
                          </>
                        ) : (
                          <>
                            <Flex.Item margin="medium">
                              <IconUnpublishedSolid color="secondary" />
                            </Flex.Item>
                            <Flex.Item>
                              <Text>{I18n.t('Unpublished')}</Text>
                            </Flex.Item>
                          </>
                        )}
                      </Flex>
                    </Table.Cell>
                    <Table.Cell>
                      {item.updatedAt
                        ? new Intl.DateTimeFormat('en-US', {
                            year: 'numeric',
                            month: 'short',
                            day: '2-digit',
                          }).format(new Date(item.updatedAt))
                        : '-'}
                    </Table.Cell>
                  </Table.Row>
                ))
              )}
            </Table.Body>
          </Table>
        </View>

        {selectedItem && (
          <AccessibilityIssuesModal isOpen={showModal} onClose={closeModal} item={selectedItem} />
        )}
      </View>
    )
  }
}
