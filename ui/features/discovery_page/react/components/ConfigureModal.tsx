/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useEffect, useRef, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Alert} from '@instructure/ui-alerts'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {fetchDiscoveryConfig, saveDiscoveryConfig, toApiConfig, toCardConfig} from '../api'
import type {CardConfig, ConfigureModalProps, DiscoverySection, ModalError} from '../types'
import {LoadingSaveOverlay} from './LoadingSaveOverlay'
import {useExitConfirmation} from '../hooks/useExitConfirmation'
import {useIframeMessaging} from '../hooks/useIframeMessaging'
import {useCardEditing} from '../hooks/useCardEditing'
import {Flex} from '@instructure/ui-flex'
import {PreviewAndSidebar} from './PreviewAndSidebar'
import {SignInOptionsHeader} from './SignInOptionsHeader'
import {useDiscoveryConfig} from '../hooks/useDiscoveryConfig'
import {AuthProvider} from './AuthProvider'

const I18n = createI18nScope('discovery_page')

const EMPTY_CONFIG: CardConfig = {
  discovery_page: {primary: [], secondary: []},
}

export function ConfigureModal({open, onClose}: ConfigureModalProps) {
  const [isLoadingConfig, setIsLoadingConfig] = useState(false)
  const [isSaving, setIsSaving] = useState(false)
  const [error, setError] = useState<ModalError | null>(null)
  const authProviders = ENV.auth_providers
  const previewUrl = ENV.discovery_page_url
  const {
    config,
    setConfig,
    isDirty,
    setIsDirty,
    handleAddCard,
    handleUpdateCard,
    handleDeleteCard,
    handleMoveCard,
  } = useDiscoveryConfig({
    initialConfig: EMPTY_CONFIG,
  })
  const {
    editingCardId,
    isEditingAnyCard,
    cardRefs,
    handleAddAndEdit,
    handleEditStart,
    handleEditDone,
    handleEditCancel,
    resetEditing,
  } = useCardEditing({config, handleAddCard, handleUpdateCard, handleDeleteCard, setIsDirty})
  const handleConfirmedClose = useExitConfirmation(isDirty)
  const modalBodyRef = useRef<HTMLElement | null>(null)
  const hasLoaded = useRef(false)
  const prevOpen = useRef(false)
  const iframeRef = useRef<HTMLIFrameElement>(null)
  const isLoading = isLoadingConfig || isSaving
  const isActionsDisabled = isLoading || isEditingAnyCard
  // withheld while loading so the iframe can’t fire READY before config is fetched,
  // and so useIframeMessaging resets its ready state on each open
  const activePreviewUrl = isLoadingConfig ? undefined : previewUrl

  useIframeMessaging({iframeRef, config, previewUrl: activePreviewUrl})

  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      if (isDirty) {
        e.preventDefault()
      }
    }

    window.addEventListener('beforeunload', handleBeforeUnload)

    return () => window.removeEventListener('beforeunload', handleBeforeUnload)
  }, [isDirty])

  const resetAndClose = () => {
    setIsDirty(false)
    resetEditing()
    onClose()
  }

  const handleCloseModal = () => {
    handleConfirmedClose(resetAndClose)
  }

  if (open && !prevOpen.current) {
    setConfig(EMPTY_CONFIG)
    setError(null)
    setIsDirty(false)
    setIsLoadingConfig(true)
    hasLoaded.current = false
  }
  prevOpen.current = open

  useEffect(() => {
    if (open && !hasLoaded.current) {
      const loadConfig = async () => {
        try {
          const data = await fetchDiscoveryConfig()
          const cardConfig = toCardConfig(data)
          setConfig(cardConfig)
          hasLoaded.current = true
        } catch (err) {
          console.error('Failed to load discovery configuration:', err)

          setError({
            message: I18n.t('Failed to load configuration. Please close and try again.'),
            code: 'LOAD_ERROR',
          })
        } finally {
          setIsLoadingConfig(false)
        }
      }

      loadConfig()
    }
  }, [open, setConfig])

  const handleSave = async () => {
    setError(null)
    setIsSaving(true)

    try {
      await saveDiscoveryConfig(toApiConfig(config))
      setIsDirty(false)
      // keep modal open after save
    } catch (err) {
      console.error('Failed to save discovery configuration:', err)

      showFlashAlert({
        message: I18n.t('Failed to save configuration. Please try again.'),
        type: 'error',
      })
    } finally {
      setIsSaving(false)
    }
  }

  const renderCloseButton = () => {
    return (
      <CloseButton
        disabled={isActionsDisabled}
        offset="small"
        onClick={handleCloseModal}
        placement="end"
        screenReaderLabel={I18n.t('Close')}
      />
    )
  }

  const renderAuthProviderSection = (
    section: DiscoverySection,
    title: string,
    description?: string,
  ) => (
    <>
      <SignInOptionsHeader
        title={title}
        description={description}
        onAddClick={() => handleAddAndEdit(section)}
        disabled={isActionsDisabled}
      />

      <Flex as="div" gap="x-small" direction="column">
        {config.discovery_page[section].map((card, index) => {
          const providerEntry = authProviders?.find(
            p => p.id === String(card.authentication_provider_id),
          )

          return (
            <AuthProvider
              key={card.id}
              authProviders={authProviders}
              card={card}
              elementRef={el => {
                if (el) {
                  cardRefs.current?.set(card.id, el)
                } else {
                  cardRefs.current?.delete(card.id)
                }
              }}
              isEditing={editingCardId === card.id}
              isDisabled={isActionsDisabled && editingCardId !== card.id}
              authProviderUrl={providerEntry?.url}
              onEditStart={() => handleEditStart(section, card.id)}
              onEditDone={draft => handleEditDone(section, card.id, draft)}
              onEditCancel={() => handleEditCancel(section, card.id)}
              // cross-section moves are allowed: last primary item can move to secondary,
              // first secondary item can move to primary (only disable at absolute boundaries)
              disableMoveUp={section === 'primary' && index === 0}
              disableMoveDown={
                section === 'secondary' && index === config.discovery_page.secondary.length - 1
              }
              onDelete={() => {
                handleDeleteCard(section, card.id)
                setIsDirty(true)
              }}
              onMoveUp={() => {
                handleMoveCard(section, card.id, 'up')
                setIsDirty(true)
              }}
              onMoveDown={() => {
                handleMoveCard(section, card.id, 'down')
                setIsDirty(true)
              }}
            />
          )
        })}
      </Flex>
    </>
  )

  return (
    <Modal
      data-testid="configure-modal"
      label={I18n.t('Configure Discovery Page')}
      onClose={handleCloseModal}
      onDismiss={handleCloseModal}
      open={open}
      size="fullscreen"
    >
      <Modal.Header spacing="compact">
        {renderCloseButton()}

        <Heading>{I18n.t('Configure Discovery Page')}</Heading>
      </Modal.Header>

      <Modal.Body
        padding="none"
        elementRef={el => {
          modalBodyRef.current = el instanceof HTMLElement ? el : null
        }}
      >
        {error && (
          <Alert variant="error" margin="medium" data-testid="error-alert">
            {error.message}
          </Alert>
        )}

        {!error && (
          <>
            <LoadingSaveOverlay
              isLoading={isLoading}
              isLoadingConfig={isLoadingConfig}
              mountNode={() => modalBodyRef.current}
            />

            <PreviewAndSidebar previewUrl={activePreviewUrl} iframeRef={iframeRef}>
              <Heading level="h3" margin="0 0 medium 0">
                {I18n.t('Configure sign in options')}
              </Heading>

              <Flex as="div" gap="medium" direction="column">
                {renderAuthProviderSection('primary', I18n.t('Main sign in options'))}

                {renderAuthProviderSection(
                  'secondary',
                  I18n.t('More sign in options'),
                  I18n.t(
                    'These options are hidden until a user expands the “More sign in options” section on the login page.',
                  ),
                )}
              </Flex>
            </PreviewAndSidebar>
          </>
        )}
      </Modal.Body>

      <Modal.Footer>
        <Flex direction="row" gap="small">
          <Button
            onClick={handleCloseModal}
            disabled={isActionsDisabled}
            data-testid="close-button"
          >
            {I18n.t('Close')}
          </Button>

          <Button
            color="primary"
            data-testid="save-button"
            disabled={isActionsDisabled || !isDirty}
            onClick={handleSave}
          >
            {isSaving ? I18n.t('Saving...') : I18n.t('Save')}
          </Button>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
