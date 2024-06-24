/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Tray} from '@instructure/ui-tray'
import {Alert} from '@instructure/ui-alerts'
import {List} from '@instructure/ui-list'
import {Checkbox} from '@instructure/ui-checkbox'
import NumberInputControlled from './NumberInputControlled'
import {Link} from '@instructure/ui-link'
import {IconTrashLine, IconUploadSolid} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Modal} from '@instructure/ui-modal'
import {FileDrop} from '@instructure/ui-file-drop'
import {Billboard} from '@instructure/ui-billboard'
import {Img} from '@instructure/ui-img'

const I18n = useI18nScope('password_complexity_configuration')

const PasswordComplexityConfiguration = () => {
  const [showTray, setShowTray] = useState(false)
  const [minimumCharacterLengthEnabled, setMinimumCharacterLengthEnabled] = useState(true)
  const [requireNumbersEnabled, setRequireNumbersEnabled] = useState(true)
  const [requireSymbolsEnabled, setRequireSymbolsEnabled] = useState(true)
  const [customForbiddenWordsEnabled, setCustomForbiddenWordsEnabled] = useState(false)
  const [customListFile, setCustomListFile] = useState<File | null>(null)
  const [customListUploaded, setCustomListUploaded] = useState(false)
  const [fileModalOpen, setFileModalOpen] = useState(false)
  const [customMaxLoginAttemptsEnabled, setCustomMaxLoginAttemptsEnabled] = useState(false)

  const handleCustomMaxLoginAttemptToggle = (event: React.ChangeEvent<HTMLInputElement>) => {
    const checked = event.target.checked
    setCustomMaxLoginAttemptsEnabled(checked)
  }

  const handleFileDrop = (file: File) => {
    setCustomListFile(file)
  }

  const handleCancelModal = () => {
    setFileModalOpen(false)
    setCustomListFile(null)
  }

  const handleUploadModal = () => {
    setCustomListUploaded(true)
    setFileModalOpen(false)
  }

  const handleDeleteCustomList = () => {
    setCustomListFile(null)
    setCustomListUploaded(false)
  }

  return (
    <>
      <Heading margin="small auto xx-small auto" level="h4">
        {I18n.t('Password Options')}
      </Heading>
      <Button
        onClick={() => {
          setShowTray(true)
        }}
      >
        {I18n.t('View Options')}
      </Button>
      <Tray
        label="Password Options Tray"
        open={showTray}
        onDismiss={() => setShowTray(false)}
        placement="end"
        size="medium"
      >
        <Flex as="div" direction="column" height="100vh">
          <Flex.Item shouldGrow={true} shouldShrink={true} padding="small" as="main">
            <Flex as="div" direction="row" justifyItems="space-between">
              <Flex.Item>
                <View as="div" margin="small 0 small medium">
                  <Heading level="h3">{I18n.t('Password Options')}</Heading>
                </View>
              </Flex.Item>
              <Flex.Item>
                <CloseButton
                  margin="xxx-small 0 0 0"
                  offset="small"
                  screenReaderLabel="Close"
                  onClick={() => setShowTray(false)}
                />
              </Flex.Item>
            </Flex>
            <View as="div" margin="0 0 0 medium">
              <View as="div" margin="xxx-small auto small auto">
                <Text size="small" lineHeight="fit">
                  {I18n.t(
                    'Some institutions have very strict policies regarding passwords. This feature enables customization of password requirements and options for this auth provider. Modifications to password options will customize the password configuration text as seen below.'
                  )}
                </Text>
              </View>
              <Heading level="h4">{I18n.t('Current Password Configuration')}</Heading>
            </View>
            <Alert variant="info" margin="small medium medium medium">
              {I18n.t('Your password must meet the following requirements')}

              <List margin="xxx-small">
                <List.Item>{I18n.t('Must be at least 8 Characters in length.')}</List.Item>
                <List.Item>
                  {I18n.t(
                    'Must not use words or sequences of characters common in passwords (ie: password, 12345, etc...)'
                  )}
                </List.Item>
              </List>
            </Alert>
            <View as="div" margin="medium medium small medium">
              <Checkbox
                label={I18n.t('Minimum character length (minimum: 8 | maximum: 255)')}
                checked={minimumCharacterLengthEnabled}
                onChange={() => setMinimumCharacterLengthEnabled(!minimumCharacterLengthEnabled)}
                defaultChecked={true}
                data-testid="minimumCharacterLengthCheckbox"
              />
            </View>
            <View as="div" maxWidth="9rem" margin="0 medium medium medium">
              <View as="div" margin="0 medium medium medium">
                <NumberInputControlled
                  minimum={8}
                  maximum={255}
                  defaultValue={8}
                  disabled={!minimumCharacterLengthEnabled}
                  data-testid="minimumCharacterLengthInput"
                />
              </View>
            </View>
            <View as="div" margin="medium">
              <Checkbox
                label={I18n.t('Require number characters (0...9)')}
                checked={requireNumbersEnabled}
                onChange={() => setRequireNumbersEnabled(!requireNumbersEnabled)}
                defaultChecked={true}
                data-testid="requireNumbersCheckbox"
              />
            </View>
            <View as="div" margin="medium">
              <Checkbox
                label={I18n.t('Require symbol characters (ie: ! @ # $ %)')}
                checked={requireSymbolsEnabled}
                onChange={() => setRequireSymbolsEnabled(!requireSymbolsEnabled)}
                defaultChecked={true}
                data-testid="requireSymbolsCheckbox"
              />
            </View>

            <View as="div" margin="medium">
              <Checkbox
                checked={customForbiddenWordsEnabled}
                onChange={() => {
                  setCustomForbiddenWordsEnabled(!customForbiddenWordsEnabled)
                }}
                label={I18n.t('Customize forbidden words/termslist (see default list here)')}
                data-testid="customForbiddenWordsCheckbox"
              />

              <View
                as="div"
                insetInlineStart="1.75em"
                position="relative"
                margin="xx-small small small 0"
              >
                <Text size="small">
                  {I18n.t(
                    'Upload a list of forbidden words/terms in addition to the default list. The file should be text file (.txt) with a single word or term per line.'
                  )}
                </Text>

                {!customListUploaded && (
                  <View as="div" margin="small 0">
                    <Button
                      disabled={!customForbiddenWordsEnabled}
                      renderIcon={IconUploadSolid}
                      onClick={() => setFileModalOpen(true)}
                      data-testid="uploadButton"
                    >
                      {I18n.t('Upload')}
                    </Button>
                  </View>
                )}
              </View>
            </View>
            {customListUploaded && (
              <View as="div" margin="0 medium medium medium">
                <Heading level="h4">{I18n.t('Current Custom List')}</Heading>
                <hr />

                <Flex justifyItems="space-between">
                  <Flex.Item>
                    <Link href="#">{customListFile?.name}</Link>
                  </Flex.Item>
                  <Flex.Item>
                    <IconButton
                      withBackground={false}
                      withBorder={false}
                      screenReaderLabel="Delete tag"
                      onClick={() => {
                        handleDeleteCustomList()
                      }}
                    >
                      <IconTrashLine color="warning" />
                    </IconButton>
                  </Flex.Item>
                </Flex>
                <hr />
              </View>
            )}
            <View as="div" margin="medium medium small medium">
              <Checkbox
                onChange={handleCustomMaxLoginAttemptToggle}
                checked={customMaxLoginAttemptsEnabled}
                label={I18n.t('Customize maximum login attempts (default 10 attempts)')}
                data-testid="customMaxLoginAttemptsCheckbox"
              />

              <View
                as="div"
                insetInlineStart="1.75em"
                position="relative"
                margin="xx-small small xxx-small 0"
              >
                <Text size="small">
                  {I18n.t(
                    'This option controls the number of attempts a single user can make consecutively to login without success before their user’s login is suspended. Users can be unsuspended by institutional admins. Cannot be higher than 20 attempts.'
                  )}
                </Text>
              </View>
            </View>
            <View as="div" maxWidth="9rem" margin="0 medium medium medium">
              <View as="div" margin="0 medium medium medium">
                <NumberInputControlled
                  minimum={3}
                  maximum={20}
                  defaultValue={10}
                  disabled={!customMaxLoginAttemptsEnabled}
                  data-testid="customMaxLoginAttemptsInput"
                />
              </View>
            </View>
          </Flex.Item>

          <Flex.Item as="footer">
            <View as="div" background="secondary" width="100%" textAlign="end">
              <View as="div" display="inline-block">
                <Button
                  margin="small 0"
                  color="secondary"
                  onClick={() => setShowTray(false)}
                  data-testid="cancelButton"
                >
                  {I18n.t('Cancel')}
                </Button>
                <Button margin="small" color="primary">
                  {I18n.t('Apply')}
                </Button>
              </View>
            </View>
          </Flex.Item>
        </Flex>
      </Tray>

      <View as="div">
        <Modal
          open={fileModalOpen}
          onDismiss={() => {
            setFileModalOpen(false)
          }}
          size="medium"
          label="Upload Forbidden Words/Terms List"
          shouldCloseOnDocumentClick={true}
          overflow="scroll"
        >
          <Modal.Header>
            <Heading>{I18n.t('Upload Forbidden Words/Terms List')}</Heading>
            <CloseButton
              margin="small 0 0 0"
              placement="end"
              offset="small"
              onClick={() => setFileModalOpen(false)}
              screenReaderLabel="Close"
            />
          </Modal.Header>
          <Modal.Body>
            {!customListFile && (
              <div style={{overflowY: 'clip'}}>
                <FileDrop
                  accept=".txt"
                  onDrop={files => {
                    const file = files[0] as File
                    handleFileDrop(file)
                  }}
                  renderLabel={
                    <Billboard
                      heading={I18n.t('Upload File')}
                      headingLevel="h2"
                      message={I18n.t('Drag and drop, or click to browse your local filesystem')}
                      hero={<Img src="/images/upload_rocket.svg" height="10rem" />}
                    />
                  }
                />
              </div>
            )}
            {customListFile && <Text>{customListFile.name}</Text>}
          </Modal.Body>
          <Modal.Footer>
            <Button onClick={() => handleCancelModal()} margin="0 x-small 0 0">
              {I18n.t('Close')}
            </Button>
            <Button color="primary" onClick={() => handleUploadModal()}>
              {I18n.t('Upload')}
            </Button>
          </Modal.Footer>
        </Modal>
      </View>
    </>
  )
}

export default PasswordComplexityConfiguration
