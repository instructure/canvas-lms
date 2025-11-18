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

import {AccountId} from '@canvas/lti-apps/models/AccountId'
import {queryify} from '@canvas/query/queryify'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconAdminLine,
  IconArrowOpenEndLine,
  IconArrowOpenStartLine,
  IconCheckLine,
  IconCoursesLine,
  IconSearchLine,
  IconSubaccountsLine,
  IconTroubleLine,
} from '@instructure/ui-icons'
import {Popover} from '@instructure/ui-popover'
import {useQuery} from '@tanstack/react-query'
import * as React from 'react'
import {fetchContextSearch} from '../../../../api/contexts'

import {useScope as createI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {Options} from '@instructure/ui-options'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {RenderApiResult} from '../../../../../common/lib/apiResult/RenderApiResult'
import {SearchableContexts} from '../../../../model/SearchableContext'
import {ContextOption} from './ContextOption'
import {ContextSearchOption} from './ContextSearchOption'
import {LtiRegistrationId} from '../../../../model/LtiRegistrationId'
import {LtiDeploymentId} from '../../../../model/LtiDeploymentId'
import {ZAccountId} from '../../../../model/AccountId'
import {LtiDeployment} from '../../../../model/LtiDeployment'

const I18n = createI18nScope('lti_registrations')

export type ContextBrowseProps = {
  rootAccountId: AccountId
  registrationId: LtiRegistrationId
  deployment: LtiDeployment
  onSelectContext: (context: ContextSearchOption) => void
  selectedContexts: ContextSearchOption[]
  browserOpen: boolean
  setBrowserOpen: (open: boolean) => void
}

type AccountSearchOption = Extract<ContextSearchOption, {type: 'account'}>['context']
type SelectedAccountState = Array<AccountSearchOption>

export const ContextBrowse = (props: ContextBrowseProps) => {
  const {browserOpen, setBrowserOpen, rootAccountId, registrationId, deployment} = props
  const [selectedAccounts, setSelectedAccounts] = React.useState<SelectedAccountState>([])
  const addSelectedAccount = React.useCallback((account: AccountSearchOption) => {
    setSelectedAccounts(current => [...current, account])
  }, [])
  const [searchText, setSearchText] = React.useState('')

  const onSelectContext = React.useCallback(
    (option: ContextSearchOption) => {
      props.onSelectContext(option)
      setSearchText('')
      setSelectedAccounts([])
    },
    [props, setSearchText, setSelectedAccounts],
  )

  const selectedAccount = selectedAccounts[selectedAccounts.length - 1]

  const scopedAccountId = selectedAccount?.id || ZAccountId.parse(deployment.context_id)

  const searchContextsQuery = useQuery({
    queryKey: [
      'searchableContexts',
      rootAccountId,
      registrationId,
      deployment.id,
      searchText,
      scopedAccountId,
    ],
    queryFn: queryify(fetchContextSearch),
  })

  const renderClearButton = React.useCallback(() => {
    if (searchText.length > 0) {
      return (
        <IconButton
          screenReaderLabel={I18n.t('Clear search')}
          size="small"
          withBackground={false}
          withBorder={false}
          onClick={() => setSearchText('')}
        >
          <IconTroubleLine />
        </IconButton>
      )
    }
    return null
  }, [searchText])

  return (
    <>
      <Popover
        renderTrigger={
          <IconButton type="button" screenReaderLabel={I18n.t('Browse sub-accounts or courses')}>
            <IconSubaccountsLine />
          </IconButton>
        }
        isShowingContent={browserOpen}
        onShowContent={e => {
          setBrowserOpen(true)
        }}
        onHideContent={() => {
          setSearchText('')
          setSelectedAccounts([])
          setBrowserOpen(false)
        }}
        on="click"
        screenReaderLabel={I18n.t('Browse sub-accounts or courses')}
        shouldContainFocus
        shouldReturnFocus
        shouldCloseOnDocumentClick
        placement="start top"
      >
        <div style={{width: '20rem'}}>
          <View display="block">
            <View borderWidth="0 0 small 0" as="div" borderColor="secondary">
              <Flex direction="column">
                <Flex.Item>
                  {selectedAccounts.length === 0 ? (
                    <Flex margin="x-small" gap="x-small">
                      <Flex.Item>
                        <IconSubaccountsLine size="x-small" />
                      </Flex.Item>
                      <Flex.Item shouldGrow shouldShrink>
                        <Text weight="bold" wrap="break-word">
                          {deployment.context_name}
                        </Text>
                      </Flex.Item>
                    </Flex>
                  ) : (
                    <TabableOption
                      onSelect={() => {
                        setSelectedAccounts(current => current.slice(0, -1))
                      }}
                    >
                      <IconArrowOpenStartLine size="x-small" />
                      {I18n.t('Back')}
                    </TabableOption>
                  )}
                </Flex.Item>
                {selectedAccount ? (
                  <Flex margin="x-small" gap="x-small">
                    <Flex.Item>
                      <IconSubaccountsLine size="x-small" />
                    </Flex.Item>
                    <Flex.Item shouldGrow shouldShrink>
                      <Flex justifyItems="space-between">
                        <Text weight="bold" wrap="break-word">
                          {selectedAccount.name}
                        </Text>
                        <Link
                          variant="standalone"
                          onClick={() => {
                            onSelectContext({
                              context: selectedAccount,
                              type: 'account',
                            })
                          }}
                        >
                          {I18n.t('Select')}
                        </Link>
                      </Flex>
                    </Flex.Item>
                  </Flex>
                ) : undefined}
              </Flex>
            </View>
            <View>
              <View padding="small" as="div">
                <TextInput
                  renderBeforeInput={<IconSearchLine inline={false} />}
                  renderLabel={
                    <ScreenReaderContent>{I18n.t('Search Contexts')}</ScreenReaderContent>
                  }
                  placeholder={I18n.t('Search...')}
                  value={searchText}
                  onChange={e => {
                    setSearchText(e.target.value)
                  }}
                  renderAfterInput={renderClearButton}
                ></TextInput>
              </View>
              <RenderApiResult
                query={searchContextsQuery}
                onSuccess={({data: searchableContexts}) => (
                  <View as="div" overflowY="auto" maxHeight="20rem" tabIndex={-1}>
                    <ContextOptions
                      rootAccountId={props.rootAccountId}
                      onSelectContext={onSelectContext}
                      selectedContexts={props.selectedContexts}
                      searchableContexts={searchableContexts}
                      selectAccount={addSelectedAccount}
                      scopedAccountId={scopedAccountId}
                      searchText={searchText}
                    />
                  </View>
                )}
              />
            </View>
          </View>
        </div>
      </Popover>
    </>
  )
}

type TabableOptionProps = {
  onSelect: () => void
  children: React.ReactNode
}

const TabableOption = (props: TabableOptionProps) => {
  const [highlighted, setHighlighted] = React.useState(false)

  return (
    <Options.Item
      variant={highlighted ? 'highlighted' : 'default'}
      tabIndex={0}
      onClick={props.onSelect}
      onKeyDown={e => {
        if (e.key === 'Enter') {
          e.preventDefault()
          props.onSelect()
        }
      }}
      onFocus={() => setHighlighted(true)}
      onBlur={() => setHighlighted(false)}
      onMouseOver={() => setHighlighted(true)}
      onMouseLeave={() => setHighlighted(false)}
    >
      {props.children}
    </Options.Item>
  )
}

type ContextOptionsProps = {
  rootAccountId: AccountId
  searchableContexts: SearchableContexts
  selectedContexts: ContextSearchOption[]
  onSelectContext: (context: ContextSearchOption) => void
  selectAccount: (account: AccountSearchOption) => void
  scopedAccountId: AccountId
  searchText: string
}

const ContextOptions = (props: ContextOptionsProps) => {
  const courses = props.searchableContexts.courses.map(
    c =>
      ({
        type: 'course',
        context: c,
      }) as const,
  )
  const accounts = props.searchableContexts.accounts
    .filter(a => a.id !== props.scopedAccountId)
    .map(
      a =>
        ({
          type: 'account',
          context: a,
        }) as const,
    )
  const contexts = [...accounts, ...courses]

  if (contexts.length === 0) {
    return (
      <View margin="small" as="div">
        <Text>
          {props.searchText === ''
            ? I18n.t('This sub-account has no children.')
            : I18n.t('No results found.')}
        </Text>
      </View>
    )
  } else {
    return contexts.map(c => (
      <TabableOption
        key={`${c.type}-${c.context.id}`}
        onSelect={() => {
          if (c.type === 'account') {
            props.selectAccount(c.context)
          } else {
            props.onSelectContext(c)
          }
        }}
      >
        <Flex direction="row">
          <Flex.Item shouldGrow shouldShrink>
            <ContextOption
              includePath={false}
              icon={
                props.selectedContexts.some(
                  context => context.context.id === c.context.id && context.type === c.type,
                ) ? (
                  <IconCheckLine size="x-small" />
                ) : (
                  renderIcon(c.type)
                )
              }
              context={c.context}
            />
          </Flex.Item>
          {c.type === 'account' ? <IconArrowOpenEndLine size="x-small" /> : undefined}
        </Flex>
      </TabableOption>
    ))
  }
}

const renderIcon = (type: 'account' | 'course') => {
  return type === 'account' ? (
    <IconSubaccountsLine size="x-small" />
  ) : (
    <IconCoursesLine size="x-small" />
  )
}
