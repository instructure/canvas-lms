/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import React, {useEffect, useCallback, useState} from 'react'
import ReactDOM from 'react-dom'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {Table} from '@instructure/ui-table'
import type {ContentItem} from '@canvas/deep-linking/models/ContentItem'
import type {DeepLinkResponse} from '@canvas/deep-linking/DeepLinkResponse'
import {Pill} from '@instructure/ui-pill'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('external_content.success')

const {
  Head: TableHead,
  Row: TableRow,
  ColHeader: TableColHeader,
  Body: TableBody,
  Cell: TableCell,
} = Table as any

type ContentItemDisplay = {
  title: string
  error?: ContentItemError
}

type ContentItemError = {
  field: string
  message: string
}

const header = () => (
  <View
    display="inline-block"
    padding="none small"
    borderWidth="none none none large"
    borderColor="danger"
  >
    <View display="block">
      {I18n.t(
        'One or more content items sent by this external app failed to process correctly. ' +
          'These have not been saved by Canvas, and the reasons for failure are listed below.'
      )}
    </View>
    <View display="block" margin="small 0 0 0">
      {I18n.t('All items marked "processed" have been saved by Canvas.')}
    </View>
  </View>
)

const renderContentItem = (item: ContentItemDisplay) => {
  let key = item.title
  let pill = <Pill color="success">{I18n.t('Processed')}</Pill>

  if (item.error) {
    key = `${item.title}.${item.error.field}`
    pill = <Pill color="danger">{I18n.t('Discarded')}</Pill>
  }

  return (
    <TableRow key={key}>
      <TableCell>{item.title}</TableCell>
      <TableCell>{pill}</TableCell>
      <TableCell>{item.error?.field}</TableCell>
      <TableCell>{item.error?.message}</TableCell>
    </TableRow>
  )
}

const buildContentItems = (items: ContentItem[]) =>
  items.reduce<ContentItemDisplay[]>((acc, item) => {
    if (item.errors) {
      const errorItems = Object.entries(item.errors).map(
        ([field, message]) =>
          ({
            title: item.title,
            error: {field, message},
          } as ContentItemDisplay)
      )
      return [...acc, ...errorItems]
    }

    return [
      ...acc,
      {
        title: item.title,
      } as ContentItemDisplay,
    ]
  }, [])

type RetrievingContentProps = {
  environment: Environment
  parentWindow: Window
}

type Environment = {
  deep_link_response: DeepLinkResponse
  DEEP_LINKING_POST_MESSAGE_ORIGIN: string
  deep_linking_use_window_parent: boolean
}

export const RetrievingContent = ({environment, parentWindow}: RetrievingContentProps) => {
  const subject = 'LtiDeepLinkingResponse'
  const deepLinkResponse = environment.deep_link_response
  const [hasErrors, setHasErrors] = useState(false)
  const [contentItems, setContentItems] = useState<ContentItemDisplay[]>([])

  const sendMessage = useCallback(() => {
    parentWindow.postMessage(
      {
        subject,
        ...deepLinkResponse,
      },
      environment.DEEP_LINKING_POST_MESSAGE_ORIGIN
    )
  }, [deepLinkResponse, environment.DEEP_LINKING_POST_MESSAGE_ORIGIN, parentWindow])

  useEffect(() => {
    const anyItemHasError = deepLinkResponse.content_items.some(
      item => Object.keys(item.errors || {}).length > 0
    )
    setHasErrors(anyItemHasError)

    if (!anyItemHasError) {
      sendMessage()
      return
    }

    const items = buildContentItems(deepLinkResponse.content_items)
    setContentItems(items)
  }, [deepLinkResponse.content_items, sendMessage])

  if (hasErrors) {
    return (
      <Flex justifyItems="center" direction="column">
        <Flex.Item>{header()}</Flex.Item>
        <Flex.Item margin="medium 0">
          <Table caption={I18n.t('Content Items with Errors')}>
            <TableHead>
              <TableRow>
                <TableColHeader id="content_item_title">
                  {I18n.t('Content Item Title')}
                </TableColHeader>
                <TableColHeader id="status">{I18n.t('Status')}</TableColHeader>
                <TableColHeader id="field">{I18n.t('Field')}</TableColHeader>
                <TableColHeader id="error">{I18n.t('Error')}</TableColHeader>
              </TableRow>
            </TableHead>
            <TableBody>{contentItems.map(item => renderContentItem(item))}</TableBody>
          </Table>
        </Flex.Item>
        <Flex.Item overflowY="hidden">
          <Button
            margin="none small"
            color="primary"
            onClick={() => {
              setHasErrors(false)
              sendMessage()
            }}
          >
            {I18n.t('I Understand, Continue')}
          </Button>
        </Flex.Item>
      </Flex>
    )
  }

  const message = I18n.t('Retrieving Content')
  return (
    <div>
      <Flex justifyItems="center" margin="x-large 0 large 0">
        <Flex.Item>
          <Spinner renderTitle={message} size="large" />
        </Flex.Item>
      </Flex>
      <Flex justifyItems="center" margin="0 0 large">
        <Flex.Item>
          <Text size="x-large" fontStyle="italic">
            {message}
          </Text>
        </Flex.Item>
      </Flex>
    </div>
  )
}

export default class DeepLinkingResponse {
  static targetWindow(window: Window) {
    // Use window.parent instead of window.top to allow
    // tools within tools to send content items to the tool,
    // not to Canvas. This assumes that tools are always only
    // "one level deep" in the frame hierarchy.
    const environment: Environment = window.ENV as Environment
    const shouldUseParent = environment.deep_linking_use_window_parent
    return window.opener || (shouldUseParent && window.parent) || window.top
  }

  static mount() {
    const parentWindow = this.targetWindow(window)
    ReactDOM.render(
      <RetrievingContent environment={window.ENV as Environment} parentWindow={parentWindow} />,
      document.getElementById('deepLinkingContent')
    )
  }
}
