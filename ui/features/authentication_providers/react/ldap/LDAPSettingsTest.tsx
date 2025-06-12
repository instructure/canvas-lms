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

import {FormEvent, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {useMutation, useQuery} from '@tanstack/react-query'
import {verifyBind, verifyConnection, verifyLogin, verifySearch} from './utils'
import LDAPTestStatus from './LDAPTestStatus'
import {TestResultResponse, TestStatus} from './types'
import LDAPTroubleshootInfo from './LDAPTroubleshootInfo'
import {TextInput} from '@instructure/ui-text-input'
import {List} from '@instructure/ui-list'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('ldap_settings_test')

export interface LDAPSettingsTestProps {
  accountId: string
  ldapIps?: string
}

const LDAPSettingsTest = ({accountId, ldapIps}: LDAPSettingsTestProps) => {
  const usernameInputRef = useRef<TextInput>(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const connectionTest = useQuery({
    queryKey: ['ldapConnectionTest', accountId],
    queryFn: verifyConnection,
    enabled: isModalOpen,
  })
  const bindTest = useQuery({
    queryKey: ['ldapBindTest', accountId],
    queryFn: verifyBind,
    enabled: isModalOpen && connectionTest.isSuccess && connectionTest.data?.ldap_connection_test,
  })
  const searchTest = useQuery({
    queryKey: ['ldapSearchTest', accountId],
    queryFn: verifySearch,
    enabled: isModalOpen && bindTest.isSuccess && bindTest.data?.ldap_bind_test,
  })
  const loginTest = useMutation({
    mutationKey: ['ldapLoginTest', accountId],
    mutationFn: verifyLogin,
  })

  const connectionTestStatus = calculateTestStatus({
    testResult: connectionTest.data?.ldap_connection_test,
    isLoading: connectionTest.isLoading,
  })
  const bindTestStatus = calculateTestStatus({
    testResult: bindTest.data?.ldap_bind_test,
    isLoading: bindTest.isLoading,
    dependentTestStatus: connectionTestStatus,
  })
  const searchTestStatus = calculateTestStatus({
    testResult: searchTest.data?.ldap_search_test,
    isLoading: searchTest.isLoading,
    dependentTestStatus: bindTestStatus,
  })
  const loginTestStatus = calculateTestStatus({
    testResult: loginTest.data?.ldap_login_test,
    isLoading: loginTest.isPending,
    dependentTestStatus: searchTestStatus,
  })
  const title = I18n.t('Test LDAP Settings')
  const closeButtonText = I18n.t('Close')

  function calculateTestStatus({
    testResult,
    isLoading,
    dependentTestStatus,
  }: {
    testResult?: boolean
    isLoading: boolean
    dependentTestStatus?: TestStatus
  }): TestStatus {
    if (isLoading) {
      return TestStatus.LOADING
    }

    if (testResult != null) {
      return testResult ? TestStatus.SUCCEED : TestStatus.FAILED
    } else {
      return dependentTestStatus &&
        [TestStatus.CANCELED, TestStatus.FAILED].includes(dependentTestStatus)
        ? TestStatus.CANCELED
        : TestStatus.IDLE
    }
  }

  const extractError = (data: TestResultResponse | undefined) => {
    if (!data || data.errors.length === 0) {
      return null
    }

    const result = Object.entries(data.errors[0]).find(
      ([key]) => typeof key === 'string' && key.startsWith('ldap_') && key.endsWith('_test'),
    )
    const errorMessage = result ? result[1] : null

    return errorMessage
  }

  const onClose = () => {
    setIsModalOpen(false)
  }

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()

    const genericErrorMessage = I18n.t('Error while testing LDAP login.')
    const formData = new FormData(event.target as HTMLFormElement)

    try {
      const response = await loginTest.mutateAsync({
        accountId,
        username: formData.get('username') as string,
        password: formData.get('password') as string,
      })

      if (!response.ldap_login_test) {
        const reason = extractError(response)

        setErrorMessage(reason ?? genericErrorMessage)
        usernameInputRef.current?.focus()
      }
    } catch {
      setErrorMessage(genericErrorMessage)
      usernameInputRef.current?.focus()
    }
  }

  return (
    <View as="div">
      <Button
        width="100%"
        display="block"
        margin="x-small 0"
        data-testid="ldap-setting-test-modal-trigger"
        onClick={() => setIsModalOpen(true)}
      >
        {I18n.t('Test LDAP Authentication')}
      </Button>
      <Modal
        open={isModalOpen}
        onDismiss={onClose}
        label={title}
        shouldCloseOnDocumentClick={false}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={onClose}
            screenReaderLabel={closeButtonText}
          />
          <Heading>{title}</Heading>
        </Modal.Header>
        <Modal.Body padding="x-small medium">
          <List delimiter="solid" margin="0" isUnstyled width="650px">
            <List.Item padding="mediumSmall 0" data-testid="ldap-setting-test-connection">
              <LDAPTestStatus title={I18n.t('Testing connection')} status={connectionTestStatus} />
              {connectionTestStatus === TestStatus.FAILED && (
                <LDAPTroubleshootInfo
                  info={{
                    title: I18n.t("Canvas can't connect to your LDAP server"),
                    description: I18n.t(
                      'The connection either timed out or was refused. Things to consider:',
                    ),
                    hints: [
                      I18n.t('Canvas is connecting to %{ips}', {
                        ips: ldapIps || '<no IP found>',
                      }),
                      I18n.t(
                        'This was only a connection test. SSL certificates were not validated.',
                      ),
                      I18n.t(
                        'Check your firewall settings. Are all Canvas IP address allowed to access your server?',
                      ),
                    ],
                  }}
                  error={extractError(connectionTest.data)}
                />
              )}
            </List.Item>
            <List.Item padding="mediumSmall 0" data-testid="ldap-setting-test-bind">
              <LDAPTestStatus title={I18n.t('Testing LDAP bind')} status={bindTestStatus} />
              {bindTestStatus === TestStatus.FAILED && (
                <LDAPTroubleshootInfo
                  info={{
                    title: I18n.t("Canvas can't bind (login) to your LDAP server"),
                    description: I18n.t(
                      'Your LDAP server rejected the bind attempt. Things to consider:',
                    ),
                    hints: [
                      I18n.t(
                        "Verify the provided filter string (i.e. '(sAMAccountName={{login}})').",
                      ),
                      I18n.t(
                        "Does the username require more scoping information? (i.e. 'cn=Canvas,ou=people,dc=example,dc=com').",
                      ),
                    ],
                  }}
                  error={extractError(bindTest.data)}
                />
              )}
            </List.Item>
            <List.Item padding="mediumSmall 0" data-testid="ldap-setting-test-search">
              <LDAPTestStatus title={I18n.t('Testing LDAP search')} status={searchTestStatus} />
              {searchTestStatus === TestStatus.FAILED && (
                <Flex margin="0 0 0 medium">
                  {
                    <LDAPTroubleshootInfo
                      info={{
                        title: I18n.t("Canvas can't search your LDAP instance"),
                        description: I18n.t(
                          'The search either failed or returned 0 results. Things to consider:',
                        ),
                        hints: [
                          I18n.t(
                            "Verify the provided filter string (i.e. '(sAMAccountName={{login}})').",
                          ),
                          I18n.t(
                            "Verify the provided search base (i.e. 'ou=people,dc=example,dc=com').",
                          ),
                          I18n.t(
                            'Verify that the user object in LDAP has search privileges for the provided search base.',
                          ),
                        ],
                      }}
                      error={extractError(searchTest.data)}
                    />
                  }
                </Flex>
              )}
            </List.Item>
            <List.Item padding="mediumSmall 0" data-testid="ldap-setting-test-login">
              <LDAPTestStatus title={I18n.t('Testing user login')} status={loginTestStatus} />
              {searchTestStatus === TestStatus.SUCCEED && (
                <View
                  as="form"
                  background="secondary"
                  padding="mediumSmall"
                  borderRadius="medium"
                  borderWidth="small"
                  margin="mediumSmall 0 0 0"
                  onChange={() => setErrorMessage('')}
                  onSubmit={handleSubmit}
                >
                  <Flex direction="column" gap="small" alignItems="start">
                    <Heading level="h4">
                      {I18n.t('Supply a valid LDAP username/password to test login:')}
                    </Heading>
                    <TextInput
                      renderLabel={I18n.t('Username')}
                      autoComplete="username"
                      name="username"
                      width="270px"
                      messages={errorMessage ? [{type: 'newError', text: errorMessage}] : []}
                      ref={usernameInputRef}
                    />
                    <TextInput
                      renderLabel={I18n.t('Password')}
                      name="password"
                      type="password"
                      width="270px"
                    />
                    <Button color="primary" type="submit">
                      {I18n.t('Test Login')}
                    </Button>
                  </Flex>
                </View>
              )}
            </List.Item>
          </List>
        </Modal.Body>
        <Modal.Footer>
          <Button type="button" color="secondary" onClick={onClose}>
            {closeButtonText}
          </Button>
        </Modal.Footer>
      </Modal>
    </View>
  )
}

export default LDAPSettingsTest
