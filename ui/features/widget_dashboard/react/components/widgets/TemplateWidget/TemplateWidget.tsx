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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {Pagination} from '@instructure/ui-pagination'
import type {BaseWidgetProps} from '../../../types'
import {useResponsiveContext} from '../../../hooks/useResponsiveContext'

const I18n = createI18nScope('widget_dashboard')

export interface PaginationProps {
  currentPage: number
  totalPages: number
  onPageChange: (page: number) => void
  ariaLabel: string
  isLoading?: boolean
}

export interface TemplateWidgetProps extends BaseWidgetProps {
  title?: string
  children: React.ReactNode
  actions?: React.ReactNode
  showHeader?: boolean
  headerActions?: React.ReactNode
  loadingText?: string
  pagination?: PaginationProps
}

const TemplateWidget: React.FC<TemplateWidgetProps> = ({
  widget,
  title,
  children,
  actions,
  showHeader = true,
  headerActions,
  isLoading = false,
  error = null,
  onRetry,
  loadingText,
  pagination,
}) => {
  const {isMobile} = useResponsiveContext()
  const widgetTitle = title || widget.title

  const renderContent = () => {
    if (isLoading) {
      return (
        <View as="div" textAlign="center" margin="large 0">
          <Spinner renderTitle={loadingText || I18n.t('Loading widget data...')} size="medium" />
        </View>
      )
    }

    if (error) {
      return (
        <View as="div" textAlign="center" margin="large 0">
          <Text color="danger" size="medium">
            {error}
          </Text>
          {onRetry && (
            <View as="div" margin="small 0 0">
              <Button onClick={onRetry} size="small" data-testid={`${widget.id}-retry-button`}>
                {I18n.t('Retry')}
              </Button>
            </View>
          )}
        </View>
      )
    }

    if (!children) {
      return (
        <View as="div" textAlign="center" margin="large 0">
          <Text color="secondary" size="medium">
            {I18n.t('No content available')}
          </Text>
        </View>
      )
    }

    return children
  }

  return (
    <View
      as="div"
      height="100%"
      padding="medium"
      shadow="above"
      borderRadius="large"
      background="primary"
      data-testid={`widget-${widget.id}`}
      style={{overflow: 'hidden', boxSizing: 'border-box'}}
    >
      <Flex direction="column" gap="small" height="100%" style={{overflow: 'hidden'}}>
        {showHeader && widgetTitle && (
          <>
            {isMobile ? (
              <Flex direction="column" gap="x-small">
                <Flex.Item>
                  <Heading level="h2" margin="0">
                    {widgetTitle}
                  </Heading>
                </Flex.Item>
                {headerActions && (
                  <Flex.Item padding="x-small 0 x-small x-small">{headerActions}</Flex.Item>
                )}
              </Flex>
            ) : (
              <Flex direction="row" alignItems="center" justifyItems="space-between">
                <Flex.Item shouldGrow>
                  <Heading level="h2" margin="0">
                    {widgetTitle}
                  </Heading>
                </Flex.Item>
                {headerActions && <Flex.Item shouldGrow={false}>{headerActions}</Flex.Item>}
              </Flex>
            )}
          </>
        )}

        <View as="div">{renderContent()}</View>

        {actions && !isLoading && !error && (
          <View as="div" margin="small 0 0">
            {actions}
          </View>
        )}

        {pagination && !isLoading && !error && pagination.totalPages > 1 && (
          <View as="div" textAlign="center" padding="x-small 0" data-testid="pagination-container">
            <Flex direction="row" justifyItems="center" alignItems="center" gap="small">
              {pagination.isLoading && (
                <Spinner size="x-small" renderTitle={I18n.t('Loading...')} />
              )}
              <Pagination
                as="nav"
                margin="x-small"
                variant="compact"
                currentPage={pagination.currentPage}
                totalPageNumber={pagination.totalPages}
                onPageChange={pagination.onPageChange}
                aria-label={pagination.ariaLabel}
              />
            </Flex>
          </View>
        )}
      </Flex>
    </View>
  )
}

export default TemplateWidget
