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
import {AccessibilityData, ContentItem, ContentItemIssues, ContentItemType} from '../../types'
import {AccessibilityIssuesModal} from '../AccessibilityIssuesModal/AccessibilityIssuesModal'
import doFetchApi from '@canvas/do-fetch-api-effect'

type SeverityFilter = 'all' | 'high' | 'medium' | 'low' | 'none'

export const AccessibilityCheckerApp: React.FC = () => {
  const [accessibilityIssues, setAccessibilityIssues] = useState<AccessibilityData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    doFetchApi({path: window.location.href + '/issues', method: 'GET'})
      .then(data => setAccessibilityIssues(data.json as AccessibilityData))
      .catch(err => {
        setError('Error loading accessibility issues. Error is:' + err.message)
        setAccessibilityIssues(null)
      })
      .finally(() => setLoading(false))
  }, [])

  const courseContextPath = `/courses/${ENV.course_id}`

  const I18n = createI18nScope('accessibility_checker')
  const [selectedItem, setSelectedItem] = useState<ContentItem | null>(null)
  const [showModal, setShowModal] = useState(false)
  const [tableData, setTableData] = useState<ContentItem[]>([])
  const [severityFilter, _setSeverityFilter] = useState<SeverityFilter>('all')
  const [filteredData, setFilteredData] = useState<ContentItem[]>([])

  useEffect(() => {
    const processData = () => {
      const flatData: ContentItem[] = []

      if (accessibilityIssues?.pages) {
        Object.entries(accessibilityIssues.pages).forEach(([id, pageData]) => {
          if (pageData) {
            flatData.push({
              id,
              type: ContentItemType.Page,
              name: pageData.title || 'Untitled Page',
              contentType: 'Page',
              published: pageData.published || false,
              updatedAt: pageData.updated_at || '',
              count: pageData.count || 0,
              severity: pageData.severity || 'none',
              url: pageData.url,
              editUrl: pageData.edit_url,
            })
          }
        })
      }

      if (accessibilityIssues?.assignments) {
        Object.entries(accessibilityIssues.assignments).forEach(([id, assignmentData]) => {
          if (assignmentData) {
            flatData.push({
              id,
              type: ContentItemType.Assignment,
              name: assignmentData.title || 'Untitled Assignment',
              contentType: 'Assignment',
              published: assignmentData.published || false,
              updatedAt: assignmentData.updated_at || '',
              count: assignmentData.count || 0,
              severity: assignmentData.severity || 'none',
              url: assignmentData.url,
              editUrl: assignmentData.edit_url,
            })
          }
        })
      }

      setTableData(flatData)
    }

    processData()
  }, [accessibilityIssues, courseContextPath])

  useEffect(() => {
    if (severityFilter === 'all') {
      setFilteredData(tableData)
    } else {
      setFilteredData(tableData.filter(item => item.severity === severityFilter))
    }
  }, [tableData, severityFilter])

  const getIssuesForItem = (
    type: 'page' | 'assignment' | 'file',
    id: string,
  ): ContentItemIssues | null => {
    const typeKey = type === 'page' ? 'pages' : type === 'assignment' ? 'assignments' : 'files'

    if (accessibilityIssues?.[typeKey]?.[id]) {
      return structuredClone(accessibilityIssues[typeKey]?.[id])
    }

    return null
  }

  const handleRowClick = (item: ContentItem) => {
    const issues = getIssuesForItem(item.type, item.id)
    setSelectedItem({
      ...item,
      issues: issues?.issues || [],
    })
    setShowModal(true)
  }

  const handleReload = () => {
    window.location.reload()
  }

  const getSeverityVariant = (
    severity: 'high' | 'medium' | 'low' | 'none',
  ): 'danger' | 'primary' => {
    switch (severity) {
      case 'high':
        return 'danger'
      case 'medium':
        return 'danger'
      case 'low':
        return 'primary'
      default:
        return 'primary'
    }
  }

  const getSeverityText = (severity: 'high' | 'medium' | 'low' | 'none'): string => {
    switch (severity) {
      case 'high':
        return I18n.t('High')
      case 'medium':
        return I18n.t('Medium')
      case 'low':
        return I18n.t('Low')
      case 'none':
        return I18n.t('None')
      default:
        return I18n.t('All')
    }
  }

  const closeModal = () => {
    setShowModal(false)
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
    return (
      <View as="div">
        <Flex as="div" margin="medium 0" alignItems="start" direction="column">
          <Flex.Item>
            <Heading level="h1">{I18n.t('Accessibility Checker')}</Heading>
          </Flex.Item>
          <Flex.Item margin="0 0 0 auto" padding="small">
            <Button color="primary" onClick={handleReload}>
              {I18n.t('Scan course')}
            </Button>
          </Flex.Item>
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
              {filteredData.length === 0 ? (
                <Table.Row>
                  <Table.Cell colSpan={5} textAlign="center">
                    <Text color="secondary">
                      {severityFilter !== 'all'
                        ? I18n.t('No %{severity} severity accessibility issues found', {
                            severity: getSeverityText(severityFilter).toLowerCase(),
                          })
                        : I18n.t('No accessibility issues found')}
                    </Text>
                  </Table.Cell>
                </Table.Row>
              ) : (
                filteredData.map(item => (
                  <Table.Row key={`${item.type}-${item.id}`}>
                    <Table.Cell>
                      <Flex alignItems="center">
                        <Flex.Item>
                          {item.type === ContentItemType.Page && <i className="icon-document"></i>}
                          {item.type === ContentItemType.Assignment && (
                            <i className="icon-assignment"></i>
                          )}
                        </Flex.Item>
                        <Flex.Item margin="0 0 0 x-small">
                          <a href={item.url}>{item.name}</a>
                        </Flex.Item>
                      </Flex>
                    </Table.Cell>
                    <Table.Cell textAlign="center">
                      {item.count > 0 ? (
                        <Badge
                          count={item.count}
                          countUntil={999}
                          variant={getSeverityVariant(item.severity)}
                          margin="small 0 small 0"
                        >
                          <Button onClick={() => handleRowClick(item)}>View Issues</Button>
                        </Badge>
                      ) : (
                        <Text color="secondary">No issues</Text>
                      )}
                    </Table.Cell>
                    <Table.Cell>{item.contentType}</Table.Cell>
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
                      {new Intl.DateTimeFormat('en-US', {
                        year: 'numeric',
                        month: 'short',
                        day: '2-digit',
                      }).format(new Date(item.updatedAt))}
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
