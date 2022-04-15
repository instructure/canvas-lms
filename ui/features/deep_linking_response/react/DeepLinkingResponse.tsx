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
import {ContentItem, DeepLinkResponse} from '@canvas/deep-linking/types'
import {Pill} from '@instructure/ui-pill'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('external_content.success')

// Doing this to avoid TS2339 errors-- remove and rename once we're on InstUI 8
const {Item: FlexItem} = Flex as any
const {
  Head: TableHead,
  Row: TableRow,
  ColHeader: TableColHeader,
  Body: TableBody,
  Cell: TableCell
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
  items.reduce((acc, item) => {
    if (item.errors) {
      const errorItems = Object.entries(item.errors).map(
        ([field, message]) =>
          ({
            title: item.title,
            error: {field, message}
          } as ContentItemDisplay)
      )
      return [...acc, ...errorItems]
    }

    return [
      ...acc,
      {
        title: item.title
      } as ContentItemDisplay
    ]
  }, [] as ContentItemDisplay[])

export const RetrievingContent = ({environment, parentWindow}) => {
  const subject = 'LtiDeepLinkingResponse'
  const deepLinkResponse = environment.deep_link_response as DeepLinkResponse
  const [hasErrors, setHasErrors] = useState(false)
  const [contentItems, setContentItems] = useState([] as ContentItemDisplay[])

  const sendMessage = useCallback(() => {
    parentWindow.postMessage(
      {
        subject,
        ...deepLinkResponse
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
        <FlexItem>{header()}</FlexItem>
        <FlexItem margin="medium 0">
          <Table caption={I18n.t('Content Items with Errors')}>
            <TableHead>
              <TableRow>
                <TableColHeader>{I18n.t('Content Item Title')}</TableColHeader>
                <TableColHeader>{I18n.t('Status')}</TableColHeader>
                <TableColHeader>{I18n.t('Field')}</TableColHeader>
                <TableColHeader>{I18n.t('Error')}</TableColHeader>
              </TableRow>
            </TableHead>
            <TableBody>{contentItems.map(item => renderContentItem(item))}</TableBody>
          </Table>
        </FlexItem>
        <FlexItem overflowY="hidden">
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
        </FlexItem>
      </Flex>
    )
  }

  const message = I18n.t('Retrieving Content')
  return (
    <div>
      <Flex justifyItems="center" margin="x-large 0 large 0">
        <FlexItem>
          <Spinner renderTitle={message} size="large" />
        </FlexItem>
      </Flex>
      <Flex justifyItems="center" margin="0 0 large">
        <FlexItem>
          <Text size="x-large" fontStyle="italic">
            {message}
          </Text>
        </FlexItem>
      </Flex>
    </div>
  )
}

export default class DeepLinkingResponse {
  static mount() {
    const parentWindow = window.opener || window.top
    ReactDOM.render(
      <RetrievingContent environment={window.ENV} parentWindow={parentWindow} />,
      document.getElementById('deepLinkingContent')
    )
  }
}
