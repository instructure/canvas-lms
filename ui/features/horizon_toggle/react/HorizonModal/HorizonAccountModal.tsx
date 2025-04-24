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

import React from 'react'
import {useCanvasCareer} from '../hooks/useCanvasCareer'
import {HorizonToggleContext} from '../HorizonToggleContext'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ContentChanges} from '../contents/ContentChanges'
import {ContentUnsupported} from '../contents/ContentUnsupported'
import {Checkbox} from '@instructure/ui-checkbox'
import {Menu} from '@instructure/ui-menu'
import {LoadingContainer} from '../LoadingContainer'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('horizon_toggle_page')

type AccountChangeModalProps = {
  isOpen: boolean
  onClose: () => void
  onConfirm: () => void
}

export const AccountChangeModal: React.FC<AccountChangeModalProps> = ({
  isOpen,
  onClose,
  onConfirm,
}) => {
  const {
    data,
    hasUnsupportedContent,
    hasChangesNeededContent,
    loadingText,
    isTermsAccepted,
    setTermsAccepted,
    onSubmit,
  } = useCanvasCareer({onConversionCompleted: onConfirm})

  return (
    <HorizonToggleContext.Provider value={data}>
      <Modal
        open={isOpen}
        onDismiss={onClose}
        onSubmit={onConfirm}
        size="medium"
        label={I18n.t('Change Sub-Account')}
        shouldCloseOnDocumentClick={false}
      >
        <Modal.Header>
          <CloseButton placement="end" offset="small" onClick={onClose} screenReaderLabel="Close" />
          <Heading level="h2">{I18n.t('Canvas Career Sub-Account')}</Heading>
        </Modal.Header>
        <Modal.Body>
          <Flex direction="column" gap="large" as="div" padding="medium 0">
            {loadingText ? (
              <LoadingContainer loadingText={loadingText} />
            ) : (
              <>
                {hasUnsupportedContent && <ContentUnsupported />}
                {hasChangesNeededContent && <ContentChanges />}
              </>
            )}
            {!hasUnsupportedContent && !hasChangesNeededContent && !loadingText && (
              <View as="div" minHeight="500px">
                <Text as="p">
                  {I18n.t(
                    'All existing course content is supported. Your course is ready to convert to Canvas Career.',
                  )}
                </Text>
              </View>
            )}
          </Flex>
        </Modal.Body>
        <Modal.Footer>
          <Flex gap="small" direction="column" margin="small 0 0 0" as="div">
            {!loadingText && (
              <Checkbox
                label={I18n.t(
                  'I acknowledge that switching to the Canvas Career learner experience may result in some course content being deleted or modified.',
                )}
                checked={isTermsAccepted}
                onChange={() => setTermsAccepted(!isTermsAccepted)}
              />
            )}
            <Menu.Separator />
            <Flex justifyItems="end" gap="x-small">
              <Button onClick={onClose}>{I18n.t('Cancel')}</Button>
              <Button
                color="primary"
                disabled={!!loadingText || !isTermsAccepted}
                onClick={onSubmit}
              >
                {I18n.t('Switch to Canvas Career')}
              </Button>
            </Flex>
          </Flex>
        </Modal.Footer>
      </Modal>
    </HorizonToggleContext.Provider>
  )
}
