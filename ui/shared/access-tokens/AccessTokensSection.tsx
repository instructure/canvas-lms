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

import {format} from '@instructure/moment-utils'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconSearchLine, IconTrashLine} from '@instructure/ui-icons'
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import type {Token} from './Token'
import type {UserId} from './UserId'
import {useManuallyGeneratedTokens, useDeleteToken} from './api'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {Flex} from '@instructure/ui-flex'
import {memo} from 'react'
import {confirmDanger} from '@canvas/instui-bindings/react/Confirm'
import TruncateWithTooltip from '@canvas/instui-bindings/react/TruncateWithTooltip'

const I18n = createI18nScope('access_tokens')

export type AccessTokensTableProps = {
  userId: UserId
}

export const AccessTokensSection = ({userId}: AccessTokensTableProps) => {
  const {data, isError, isPending, isFetching, fetchNextPage, hasNextPage} =
    useManuallyGeneratedTokens(userId)

  if (isPending) {
    return (
      <Flex alignItems="center" justifyItems="center" padding="small">
        <Flex.Item>
          <Spinner renderTitle={I18n.t('Loading access tokens')} />
        </Flex.Item>
      </Flex>
    )
  }

  if (isError) {
    return (
      <Alert
        variant="error"
        margin="x-small"
        liveRegion={() => document.getElementById('flash_screenreader_holder') as HTMLElement}
        liveRegionPoliteness="assertive"
      >
        {I18n.t('Failed to load access tokens')}
      </Alert>
    )
  }

  const tokens = data.pages.flatMap(page => page.json)

  if (tokens.length === 0) {
    return (
      <Flex direction="column" alignItems="center" padding="small 0">
        <IconSearchLine size="medium" color="secondary" />
        <View margin="small 0 0">
          <Text size="large">{I18n.t('This user has not generated any access tokens.')}</Text>
        </View>
        <Alert
          liveRegion={() => document.getElementById('flash_screenreader_holder') as HTMLElement}
          liveRegionPoliteness="assertive"
          screenReaderOnly={true}
        >
          {I18n.t(`No results found`)}
        </Alert>
      </Flex>
    )
  }

  return (
    <div>
      <View as="div" margin="0 0 small 0">
        <Text size="medium">
          {I18n.t('These are the access tokens this user has generated to access Canvas:')}
        </Text>
      </View>
      <Table caption={I18n.t('User Generated Access Tokens')} margin="small 0" layout="fixed">
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="token-id" width="5%">
              {I18n.t('ID')}
            </Table.ColHeader>
            <Table.ColHeader id="visible-token" width="15%">
              {I18n.t('Token')}
            </Table.ColHeader>
            <Table.ColHeader id="purpose">{I18n.t('Purpose')}</Table.ColHeader>
            <Table.ColHeader id="created">{I18n.t('Created')}</Table.ColHeader>
            <Table.ColHeader id="last-used">{I18n.t('Last Used')}</Table.ColHeader>
            <Table.ColHeader id="expires">{I18n.t('Expires')}</Table.ColHeader>
            <Table.ColHeader id="remove" width="7%">
              {I18n.t('Remove')}
            </Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {tokens.map(token => (
            <TokenRow key={token.id} token={token} />
          ))}
        </Table.Body>
      </Table>
      {hasNextPage && (
        <Flex as="div" margin="small 0 small 0" alignItems="center" justifyItems="center">
          <Button
            disabled={isFetching}
            onClick={() => {
              // Make sure the user's focus doesn't get lost when more tokens are loaded
              const buttons = document.querySelectorAll(
                '[data-pendo="admin_user_tokens_delete_token"]',
              )
              const lastButton = buttons[buttons.length - 1]

              if (lastButton instanceof HTMLElement) {
                lastButton.focus()
              }
              fetchNextPage()
            }}
          >
            {I18n.t('Show More')}
          </Button>
        </Flex>
      )}
    </div>
  )
}

/**
 * Handles the deletion of a token after user confirmation.
 * @param token The token to delete
 * @param deleteToken The mutation hook to delete the token
 * @returns
 */
const handleDeleteToken = async (token: Token, deleteToken: ReturnType<typeof useDeleteToken>) => {
  if (
    !(await confirmDanger({
      title: I18n.t('Delete Access Token'),
      messageDangerouslySetInnerHTML: {
        __html: I18n.t(
          `You are about to delete a user generated API token with the following purpose:
          *%{purpose}*
          This action can not be undone.`,
          {
            wrappers:
              '<div style="text-overflow: ellipsis; overflow: hidden; white-space: nowrap;"><strong>$1</strong></div>',
            purpose: token.purpose || I18n.t('User Generated'),
          },
        ),
      },
    }))
  ) {
    return
  }

  try {
    await deleteToken.mutateAsync(token.id)
    showFlashAlert({
      message: I18n.t('Access token deleted successfully.'),
      type: 'success',
    })
  } catch (error) {
    console.error('Error deleting access token:', error)
    showFlashAlert({
      message: I18n.t('Unable to delete access token. Please try again.'),
      type: 'error',
    })
  }
}

type TokenRowProps = {
  token: Token
}

const TokenRow = memo(({token}: TokenRowProps) => {
  const deleteToken = useDeleteToken(token.user_id)

  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore - format's third argument (zone) is optional at runtime but required by tsgo
  const createdAtFormatted = format(token.created_at, 'date.formats.full')
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore - format's third argument (zone) is optional at runtime but required by tsgo
  const lastUsedAtFormattedValue = format(token.last_used_at, 'date.formats.full')
  const lastUsedAtFormatted = token.last_used_at ? lastUsedAtFormattedValue : null
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore - format's third argument (zone) is optional at runtime but required by tsgo
  const expiresAtFormattedValue = format(token.expires_at, 'date.formats.full')
  const expiresAtFormatted = token.expires_at ? expiresAtFormattedValue : null

  return (
    <Table.Row>
      <Table.Cell>
        <Text>{token.id}</Text>
      </Table.Cell>
      <Table.Cell>
        <Text wrap="break-word">{token.visible_token}</Text>
      </Table.Cell>
      <Table.Cell>
        <TruncateWithTooltip>
          <Text>{token.purpose || I18n.t('User Generated')}</Text>
        </TruncateWithTooltip>
      </Table.Cell>
      <Table.Cell>
        <Text>{createdAtFormatted}</Text>
      </Table.Cell>
      <Table.Cell>
        <Text>{lastUsedAtFormatted ?? I18n.t('Unused')}</Text>
      </Table.Cell>
      <Table.Cell>
        <Text>{expiresAtFormatted ?? I18n.t('Never')}</Text>
      </Table.Cell>
      <Table.Cell>
        <IconButton
          screenReaderLabel={I18n.t('Delete %{purpose} Token', {
            purpose: token.purpose || I18n.t('User Generated'),
          })}
          onClick={() => handleDeleteToken(token, deleteToken)}
          color="secondary"
          size="medium"
          disabled={deleteToken.isPending}
          data-pendo="admin_user_tokens_delete_token"
        >
          <IconTrashLine />
        </IconButton>
      </Table.Cell>
    </Table.Row>
  )
})
