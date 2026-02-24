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

import React, {useState, useRef, useCallback} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {List} from '@instructure/ui-list'
import {Heading} from '@instructure/ui-heading'
import {Table} from '@instructure/ui-table'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconPlusSolid, IconTrashLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Billboard} from '@instructure/ui-billboard'
import type {FormMessage} from '@instructure/ui-form-field'
import isValidDomain from 'is-valid-domain'

import EmptyDesert from '@canvas/images/react/EmptyDesert'
import type {WhitelistedDomains} from './SecurityPanel'

const I18n = createI18nScope('security_panel')

const PROTOCOL_REGEX = /^(?:(ht|f)tp(s?):\/\/)?/

interface WhitelistProps {
  whitelistedDomains: WhitelistedDomains
  onAddDomain: (domain: string) => void
  onRemoveDomain: (domain: string) => void
  isSubAccount?: boolean
  inherited?: boolean
  maxDomains: number
}

function validateInput(input: string): boolean {
  const domainOnly = input.replace(PROTOCOL_REGEX, '')
  const parts = domainOnly.split('.')
  const isWildcard = parts[0] === '*'
  if (isWildcard) {
    parts.shift()
    return isValidDomain(parts.join('.'))
  }
  return isValidDomain(domainOnly)
}

export function Whitelist({
  whitelistedDomains,
  onAddDomain,
  onRemoveDomain,
  isSubAccount = false,
  inherited = false,
  maxDomains,
}: WhitelistProps) {
  const [addDomainInputValue, setAddDomainInputValue] = useState('')
  const [errors, setErrors] = useState<FormMessage[]>([])

  const domainNameInputRef = useRef<TextInput | null>(null)
  const deleteButtonsRef = useRef<Record<string, IconButton | null>>({})
  const addDomainBtnRef = useRef<Button | null>(null)

  const handleSubmit = useCallback(() => {
    if (validateInput(addDomainInputValue)) {
      onAddDomain(addDomainInputValue)
      setErrors([])
      setAddDomainInputValue('')
    } else {
      setErrors([{text: I18n.t('Invalid domain'), type: 'newError'}])
      domainNameInputRef.current?.focus()
    }
  }, [addDomainInputValue, onAddDomain])

  const handleRemoveDomain = useCallback(
    (domain: string) => {
      const deletedIndex = whitelistedDomains.account.findIndex(x => x === domain)
      let newIndex = 0
      if (deletedIndex > 0) {
        newIndex = deletedIndex - 1
      }
      const newDomainToFocus = whitelistedDomains.account[newIndex]

      onRemoveDomain(domain)

      if (deletedIndex <= 0) {
        addDomainBtnRef.current?.focus()
      } else {
        deleteButtonsRef.current[newDomainToFocus]?.focus()
      }
    },
    [whitelistedDomains.account, onRemoveDomain],
  )

  const domainLimitReached = whitelistedDomains.account.length >= maxDomains && !inherited
  const toolsWhitelistKeys = whitelistedDomains.tools ? Object.keys(whitelistedDomains.tools) : []
  const whitelistToShow = inherited ? whitelistedDomains.inherited : whitelistedDomains.account

  return (
    <div>
      <View
        as="div"
        margin="none none small none"
        padding="xxx-small"
        background="primary"
        borderWidth="none none small none"
      >
        <Flex justifyItems="space-between">
          <Flex.Item>
            <Heading margin="small" level="h4" as="h3">
              {inherited
                ? I18n.t('Domains')
                : I18n.t('Domains (%{count}/%{max})', {
                    count: whitelistedDomains.account.length,
                    max: maxDomains,
                  })}
            </Heading>
          </Flex.Item>
        </Flex>
      </View>

      <form
        noValidate={true}
        onSubmit={e => {
          e.preventDefault()
          handleSubmit()
        }}
      >
        {domainLimitReached && (
          <Alert variant="error" margin="small 0">
            {I18n.t(
              `You have reached the domain limit. You can add more domains by deleting existing domains in your allowed list.`,
            )}
          </Alert>
        )}

        {inherited && isSubAccount && (
          <Alert variant="info" margin="small 0">
            {I18n.t(
              `Domain editing is disabled when security settings are inherited from a parent account.`,
            )}
          </Alert>
        )}

        <Flex>
          <Flex.Item shouldGrow={true} shouldShrink={true} padding="0 medium 0 0">
            <TextInput
              ref={domainNameInputRef}
              renderLabel={I18n.t('Domain Name')}
              placeholder="http://somedomain.com"
              value={addDomainInputValue}
              messages={errors}
              disabled={(inherited && isSubAccount) || domainLimitReached}
              isRequired={true}
              onChange={e => {
                setAddDomainInputValue(e.currentTarget.value)
              }}
            />
          </Flex.Item>
          <Flex.Item align={errors.length ? 'center' : 'end'}>
            <Button
              aria-label={I18n.t('Add Domain')}
              ref={addDomainBtnRef}
              type="submit"
              margin="0 x-small 0 0"
              renderIcon={<IconPlusSolid />}
              disabled={(inherited && isSubAccount) || domainLimitReached}
            >
              {I18n.t('Domain')}
            </Button>
          </Flex.Item>
        </Flex>
      </form>
      {whitelistToShow.length <= 0 ? (
        <Billboard size="small" heading={I18n.t('No allowed domains')} hero={<EmptyDesert />} />
      ) : (
        <Table caption={I18n.t('Allowed Domains')}>
          <Table.Head>
            <Table.Row>
              <Table.ColHeader id="allowed-domain-name">
                {I18n.t('Allowed Domains')}
              </Table.ColHeader>
              <Table.ColHeader id="allowed-domain-actions">
                <ScreenReaderContent>{I18n.t('Actions')}</ScreenReaderContent>
              </Table.ColHeader>
            </Table.Row>
          </Table.Head>
          <Table.Body>
            {whitelistToShow.map(domain => (
              <Table.Row key={domain}>
                <Table.Cell>{domain}</Table.Cell>
                <Table.Cell textAlign="end">
                  <IconButton
                    ref={c => (deleteButtonsRef.current[domain] = c)}
                    renderIcon={IconTrashLine}
                    withBackground={false}
                    withBorder={false}
                    onClick={() => handleRemoveDomain(domain)}
                    data-testid={`delete-button-${domain}`}
                    disabled={inherited && isSubAccount}
                    screenReaderLabel={I18n.t('Remove %{domain} as an allowed domain', {domain})}
                  />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table.Body>
        </Table>
      )}
      {toolsWhitelistKeys && toolsWhitelistKeys.length > 0 && (
        <View as="div" margin="large 0">
          <Heading level="h4" as="h3">
            {I18n.t('Associated Tool Domains')}
          </Heading>
          <p>
            {I18n.t(
              `The following domains have automatically been allowed from tools that already exist in your account.
               To remove these domains, remove the associated tools.`,
            )}
          </p>
          <p>
            {I18n.t(
              `NOTE: Associated tools are only listed once, even if they have
              been installed in multiple subaccounts.`,
            )}
          </p>
          <Table
            caption={<ScreenReaderContent>{I18n.t('Associated Tool Domains')}</ScreenReaderContent>}
          >
            <Table.Head>
              <Table.Row>
                <Table.ColHeader id="whitelisted-tools-domain-name">Domain Name</Table.ColHeader>
                <Table.ColHeader id="whitelisted-tools-tools">Associated Tools</Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {toolsWhitelistKeys.map(domain => (
                <Table.Row key={domain}>
                  <Table.Cell>{domain}</Table.Cell>
                  <Table.Cell>
                    <List isUnstyled={true}>
                      {whitelistedDomains.tools[domain].map(associatedTool => (
                        <List.Item key={associatedTool.id}>{associatedTool.name}</List.Item>
                      ))}
                    </List>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table.Body>
          </Table>
        </View>
      )}
    </div>
  )
}
