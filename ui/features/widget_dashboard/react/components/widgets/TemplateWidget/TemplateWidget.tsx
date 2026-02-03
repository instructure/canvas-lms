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

import React, {useEffect} from 'react'
import {flushSync} from 'react-dom'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {Pagination} from '@instructure/ui-pagination'
import {Overlay, Mask} from '@instructure/ui-overlays'
import {IconDragHandleLine, IconTrashLine} from '@instructure/ui-icons'
import type {BaseWidgetProps} from '../../../types'
import {useResponsiveContext} from '../../../hooks/useResponsiveContext'
import {useWidgetLayout, type MoveAction} from '../../../hooks/useWidgetLayout'
import WidgetContextMenu from '../../shared/WidgetContextMenu'

const I18n = createI18nScope('widget_dashboard')

export interface PaginationProps {
  currentPage: number
  totalPages: number
  onPageChange: (page: number) => void
  ariaLabel: string
}

export interface LoadingOverlayProps {
  isLoading: boolean
  ariaLabel?: string
}

export interface TemplateWidgetProps extends BaseWidgetProps {
  title?: string
  children: React.ReactNode
  actions?: React.ReactNode
  showHeader?: boolean
  headerActions?: React.ReactNode
  loadingText?: string
  pagination?: PaginationProps
  loadingOverlay?: LoadingOverlayProps
  footerActions?: React.ReactNode
  isEditMode?: boolean
  dragHandleProps?: any
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
  loadingOverlay,
  footerActions,
  isEditMode = false,
  dragHandleProps,
}) => {
  const {isMobile, isDesktop} = useResponsiveContext()
  const {config, moveWidget, removeWidget} = useWidgetLayout()
  const widgetTitle = title || widget.title
  const headingId = `${widget.id}-heading`
  const contentRef = React.useRef<HTMLElement | null>(null)
  const [mountNode, setMountNode] = React.useState<HTMLElement | null>(null)

  useEffect(() => {
    if (contentRef.current) {
      setMountNode(contentRef.current)
    }
  }, [])

  const handleMenuSelect = (action: string) => {
    flushSync(() => {
      moveWidget(widget.id, action as MoveAction)
    })

    const dragHandle = document.querySelector(
      `[data-testid="${widget.id}-drag-handle"]`,
    ) as HTMLElement
    if (dragHandle) {
      dragHandle.focus()
    }
  }

  const handleRemove = () => {
    removeWidget(widget.id)
  }

  const editModeActions = (
    <div style={{display: 'flex', gap: '0.5rem', alignItems: 'center'}}>
      <WidgetContextMenu
        trigger={
          <button
            {...dragHandleProps}
            data-testid={`${widget.id}-drag-handle`}
            style={{
              ...dragHandleProps?.style,
              cursor: 'grab',
              display: 'flex',
              alignItems: 'center',
              border: 'none',
              background: 'transparent',
              padding: '0.375rem',
              margin: 0,
              lineHeight: 1,
            }}
            type="button"
            aria-label={I18n.t('Reorder %{widgetName}', {widgetName: widgetTitle})}
          >
            <IconDragHandleLine />
          </button>
        }
        widget={widget}
        config={config}
        isStacked={!isDesktop}
        onSelect={handleMenuSelect}
      />
      <IconButton
        screenReaderLabel={I18n.t('Remove %{widgetName}', {widgetName: widgetTitle})}
        size="small"
        withBackground={false}
        withBorder={false}
        onClick={handleRemove}
        data-testid={`${widget.id}-remove-button`}
      >
        <IconTrashLine />
      </IconButton>
    </div>
  )

  const renderContent = () => {
    if (isLoading) {
      return (
        <Flex justifyItems="center" alignItems="center" height="400px">
          <Spinner renderTitle={loadingText || I18n.t('Loading widget data...')} size="medium" />
        </Flex>
      )
    }

    if (error) {
      return (
        <View as="div" textAlign="center">
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
        <View as="div" textAlign="center">
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
      as="section"
      height="100%"
      margin="x-small"
      padding="medium"
      shadow="above"
      borderRadius="large"
      background="primary"
      data-testid={`widget-${widget.id}`}
      aria-labelledby={showHeader && widgetTitle ? headingId : undefined}
      role="region"
    >
      <Flex direction="column" gap="small">
        {showHeader && widgetTitle && (
          <>
            {isMobile ? (
              <Flex direction="column" gap="x-small">
                <Flex.Item>
                  <Heading level="h2" margin="0" id={headingId}>
                    {widgetTitle}
                  </Heading>
                </Flex.Item>
                {headerActions && (
                  <Flex.Item padding="x-small 0 x-small x-small">{headerActions}</Flex.Item>
                )}
                {isEditMode && (
                  <Flex.Item padding="x-small 0 x-small x-small">{editModeActions}</Flex.Item>
                )}
              </Flex>
            ) : (
              <Flex direction="row" alignItems="center" justifyItems="space-between" wrap="wrap">
                <Flex.Item shouldGrow>
                  <Heading level="h2" variant="titleCardSection" margin="0" id={headingId}>
                    {widgetTitle}
                  </Heading>
                </Flex.Item>
                {headerActions && <Flex.Item shouldGrow={false}>{headerActions}</Flex.Item>}
                {isEditMode && (
                  <Flex.Item margin="0 0 0 small" shouldGrow={false}>
                    {editModeActions}
                  </Flex.Item>
                )}
              </Flex>
            )}
          </>
        )}

        <View
          as="div"
          position="relative"
          elementRef={el => {
            contentRef.current = el as HTMLElement
          }}
        >
          {renderContent()}
          {loadingOverlay?.isLoading && !isLoading && !error && mountNode && (
            <Overlay
              open={true}
              transition="fade"
              label={loadingOverlay.ariaLabel || I18n.t('Loading')}
              data-testid="loading-overlay"
              mountNode={mountNode}
            >
              <Mask>
                <Spinner
                  renderTitle={loadingText || I18n.t('Loading...')}
                  size="medium"
                  margin="0 0 0 medium"
                />
              </Mask>
            </Overlay>
          )}
        </View>

        {actions && !isLoading && !error && (
          <View as="div" margin="small 0 0">
            {actions}
          </View>
        )}

        {pagination && !isLoading && !error && pagination.totalPages > 1 && (
          <View as="div" textAlign="center" padding="x-small 0" data-testid="pagination-container">
            <Flex direction="row" justifyItems="center" alignItems="center" gap="small">
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

        {footerActions && !isLoading && !error && (
          <View as="div" margin="small 0 0">
            {footerActions}
          </View>
        )}
      </Flex>
    </View>
  )
}

export default TemplateWidget
