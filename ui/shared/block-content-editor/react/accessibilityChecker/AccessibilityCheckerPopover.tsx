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

import React, {useState, useEffect, useRef} from 'react'
import {Popover} from '@instructure/ui-popover'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Button, CondensedButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {AccessibilityIssue} from './types'
import {IconInfoLine} from '@instructure/ui-icons'

const I18n = createI18nScope('block_content_editor')

interface AccessibilityCheckerPopoverProps {
  isShowingContent: boolean
  onShowContent: () => void
  onHideContent: () => void
  renderTrigger: (props: any) => React.ReactElement
  issues: AccessibilityIssue[]
}

const linkColor = '#0374B5'

export const AccessibilityCheckerPopover = ({
  isShowingContent,
  onShowContent,
  onHideContent,
  renderTrigger,
  issues,
}: AccessibilityCheckerPopoverProps) => {
  const [currentIssueIndex, setCurrentIssueIndex] = useState(0)
  const [isInfoPopoverOpen, setIsInfoPopoverOpen] = useState(false)
  const originalStylesRef = useRef(new Map<Element, {border?: string; outline?: string}>())
  const previousIssueRef = useRef<Element | null>(null)

  const currentIssue = issues[currentIssueIndex]
  const totalIssues = issues.length

  const addHighlight = (node: Element) => {
    if (!node || !(node instanceof HTMLElement)) return

    if (!originalStylesRef.current.has(node)) {
      originalStylesRef.current.set(node, {
        border: node.style.border,
        outline: node.style.outline,
      })
    }

    node.style.border = '2px solid black'
    node.style.outline = 'none'
  }

  const removeHighlight = (node: Element) => {
    if (!node || !(node instanceof HTMLElement)) return

    const originalStyles = originalStylesRef.current.get(node)
    if (originalStyles) {
      node.style.border = originalStyles.border || ''
      node.style.outline = originalStyles.outline || ''
      originalStylesRef.current.delete(node)
    }
  }

  const removeAllHighlights = () => {
    originalStylesRef.current.forEach((originalStyles, node) => {
      if (node instanceof HTMLElement) {
        node.style.border = originalStyles.border || ''
        node.style.outline = originalStyles.outline || ''
      }
    })
    originalStylesRef.current.clear()
  }

  const handlePrevious = () => {
    setCurrentIssueIndex(prev => (prev > 0 ? prev - 1 : totalIssues - 1))
  }

  const handleNext = () => {
    setCurrentIssueIndex(prev => (prev < totalIssues - 1 ? prev + 1 : 0))
  }

  const handleShowInfoPopover = () => {
    setIsInfoPopoverOpen(true)
  }

  const handleHideInfoPopover = () => {
    setIsInfoPopoverOpen(false)
  }

  useEffect(() => {
    if (!isShowingContent || totalIssues === 0) return

    if (previousIssueRef.current) {
      removeHighlight(previousIssueRef.current)
    }

    if (currentIssue?.node) {
      addHighlight(currentIssue.node)
      previousIssueRef.current = currentIssue.node

      currentIssue.node.scrollIntoView({
        behavior: 'smooth',
        block: 'center',
        inline: 'nearest',
      })
    }
  }, [currentIssueIndex, isShowingContent, currentIssue])

  useEffect(() => {
    if (!isShowingContent) {
      removeAllHighlights()
    }
  }, [isShowingContent])

  useEffect(() => {
    return () => {
      removeAllHighlights()
    }
  }, [])

  return (
    <Popover
      isShowingContent={isShowingContent}
      onShowContent={onShowContent}
      onHideContent={onHideContent}
      on="click"
      placement="center end"
      shouldContainFocus
      shouldReturnFocus
      shouldCloseOnDocumentClick={true}
      renderTrigger={renderTrigger}
    >
      <View as="div" width="30rem">
        <Flex direction="column" justifyItems="space-between" padding="small medium">
          <Heading level="h3" margin="0" data-testid="a11y-checker-popover-header">
            {I18n.t('Accessibility checker')}
          </Heading>

          {totalIssues > 0 && (
            <View>
              <Flex alignItems="center" gap="x-small" margin="medium 0 small 0">
                <Text weight="bold">
                  {I18n.t('Issue %{current}/%{total}', {
                    current: currentIssueIndex + 1,
                    total: totalIssues,
                  })}
                </Text>
                <Popover
                  isShowingContent={isInfoPopoverOpen}
                  onShowContent={handleShowInfoPopover}
                  onHideContent={handleHideInfoPopover}
                  on="click"
                  placement="top"
                  shouldContainFocus
                  shouldReturnFocus
                  shouldCloseOnDocumentClick={true}
                  renderTrigger={() => (
                    <CondensedButton
                      onClick={handleShowInfoPopover}
                      renderIcon={<IconInfoLine />}
                    ></CondensedButton>
                  )}
                >
                  <Flex direction="column" width="18rem" padding="medium" gap="medium">
                    <Flex.Item>
                      <Text size="medium" lineHeight="default">
                        {currentIssue?.rule.why()}
                      </Text>
                    </Flex.Item>
                    {currentIssue?.rule.link && (
                      <Flex.Item>
                        <Text size="medium">
                          <a
                            href={currentIssue.rule.link}
                            target="_blank"
                            rel="noopener noreferrer"
                            style={{color: linkColor, textDecoration: 'underline'}}
                          >
                            {currentIssue.rule.linkText?.()}
                          </a>
                        </Text>
                      </Flex.Item>
                    )}
                  </Flex>
                </Popover>
              </Flex>

              <Text variant="content">{currentIssue?.rule.message()}</Text>
            </View>
          )}
        </Flex>

        <View as="div" background="secondary" padding="small" borderRadius="medium">
          <Flex alignItems="center" gap="small">
            <Button
              size="small"
              data-testid="prev-button"
              onClick={handlePrevious}
              interaction={totalIssues > 1 ? 'enabled' : 'disabled'}
            >
              {I18n.t('Prev')}
            </Button>
            <Button
              size="small"
              data-testid="next-button"
              onClick={handleNext}
              interaction={totalIssues > 1 ? 'enabled' : 'disabled'}
            >
              {I18n.t('Next')}
            </Button>
          </Flex>
        </View>
      </View>
    </Popover>
  )
}
