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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import React from 'react'
import {AccessibilityIssue, ContentItem} from '../../types'

interface AccessibilityIssuesModalProps {
  isOpen: boolean
  onClose: () => void
  item: ContentItem
}

export const AccessibilityIssuesModal: React.FC<AccessibilityIssuesModalProps> = ({
  isOpen,
  onClose,
  item,
}) => {
  const I18n = createI18nScope('accessibility_checker')

  const getIssueId = (issue: AccessibilityIssue, index: number): string => {
    return issue.id || `${item.type}-${item.id}-issue-${index}`
  }

  return (
    <Modal
      open={isOpen}
      onDismiss={onClose}
      size="medium"
      label={`${item.title} - ${I18n.t('Accessibility Issues')}`}
    >
      <Modal.Header>
        <CloseButton placement="end" onClick={onClose} screenReaderLabel={I18n.t('Close')} />
        <Heading level="h2">{item.title}</Heading>
        <Flex margin="small 0">
          <Flex.Item padding="0 small 0 0">
            <Text weight="bold">
              {I18n.t(
                {
                  one: '1 accessibility issue found',
                  other: '%{count} accessibility issues found',
                },
                {count: item.count},
              )}
            </Text>
          </Flex.Item>
        </Flex>
      </Modal.Header>

      <Modal.Body>
        <View as="div" maxHeight="500px" overflowY="auto">
          {item.issues && item.issues.length > 0 ? (
            item.issues.map((issue, index) => {
              return (
                <View
                  key={getIssueId(issue, index)}
                  as="div"
                  margin="0 0 medium 0"
                  padding="small"
                  borderWidth="0 0 0 medium"
                  borderColor="danger"
                  background="secondary"
                >
                  <Heading level="h3">{issue.message}</Heading>
                  <Text as="p">{issue.why}</Text>
                  {issue.issueUrl !== '' ? (
                    <Link href={issue.issueUrl}>More information on this</Link>
                  ) : (
                    <></>
                  )}
                </View>
              )
            })
          ) : (
            <Text as="p">{I18n.t('No issues found')}</Text>
          )}
        </View>
      </Modal.Body>

      <Modal.Footer>
        <Flex justifyItems="end">
          <Flex.Item margin="0 small 0 0">
            <Button onClick={onClose}>{I18n.t('Close')}</Button>
          </Flex.Item>
          <Flex.Item>
            <Button color="primary" href={item.editUrl}>
              {I18n.t('Edit content')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
