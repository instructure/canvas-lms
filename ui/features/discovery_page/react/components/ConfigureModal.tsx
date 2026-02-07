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
import {useScope as createI18nScope} from '@canvas/i18n'
import {fetchDiscoveryConfig, saveDiscoveryConfig, toApiConfig, toCardConfig} from '../api'
import type {CardConfig, ModalError} from '../types'
import {LoadingSaveOverlay} from './LoadingSaveOverlay'
import {useExitConfirmation} from '../hooks/useExitConfirmation'
import {useDiscovery} from '../hooks/useDiscovery'
import {useIframeMessaging} from '../hooks/useIframeMessaging'
import {Flex} from '@instructure/ui-flex'
import {PreviewAndSidebar} from './PreviewAndSidebar'
import {SignInOptionsHeader} from './SignInOptionsHeader'
import {backfillLabels, useDiscoveryConfig} from '../hooks/useDiscoveryConfig'
import {AuthProvider} from './AuthProvider'
import {getDiscoveryPageIcons} from '../constants'

const I18n = createI18nScope('discovery_page')

const EMPTY_CONFIG: CardConfig = {
  discovery_page: {primary: [], secondary: []},
}

interface ConfigureModalProps {
  open: boolean
  onClose: () => void
}

export function ConfigureModal({open, onClose}: ConfigureModalProps) {
  const [isLoadingConfig, setIsLoadingConfig] = useState(false)
  const [isSaving, setIsSaving] = useState(false)
  const [error, setError] = useState<ModalError | null>(null)
  const [expandedCardId, setExpandedCardId] = useState<string | null>(null)
  const {previewUrl, authProviders} = useDiscovery()
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
    authProviders,
  })
  const handleConfirmedClose = useExitConfirmation(isDirty)

  const modalBodyRef = useRef<HTMLElement | null>(null)
  const savedConfigRef = useRef<CardConfig | null>(null)
  const iframeRef = useRef<HTMLIFrameElement>(null)

  // Send config updates to iframe via postMessage for live preview
  useIframeMessaging({iframeRef, config, previewUrl})

  const isLoading = isLoadingConfig || isSaving

  const resetAndClose = () => {
    setIsDirty(false)
    setConfig(EMPTY_CONFIG)
    savedConfigRef.current = null
    onClose()
  }

  const handleCloseModal = async () => {
    await handleConfirmedClose(resetAndClose)
  }

  useEffect(() => {
    if (open && !savedConfigRef.current) {
      setError(null)
      setIsDirty(false)

      const loadConfig = async () => {
        setIsLoadingConfig(true)

        try {
          const data = await fetchDiscoveryConfig()
          const cardConfig = toCardConfig(data)
          setConfig(cardConfig)
          savedConfigRef.current = cardConfig
        } catch (err) {
          const errorMessage =
            err instanceof Error ? err.message : I18n.t('Failed to load configuration')
          setError({message: errorMessage, code: 'LOAD_ERROR'})
        } finally {
          setIsLoadingConfig(false)
        }
      }

      loadConfig()
    }
  }, [open, setConfig, setIsDirty])

  const handleSave = async () => {
    setError(null)
    setIsSaving(true)

    try {
      await saveDiscoveryConfig(toApiConfig(backfillLabels(config)))
      resetAndClose()
    } catch (err) {
      const errorMessage =
        err instanceof Error ? err.message : I18n.t('Failed to save configuration')
      setError({message: errorMessage, code: 'SAVE_ERROR'})
    } finally {
      setIsSaving(false)
    }
  }

  const renderCloseButton = () => {
    return (
      <CloseButton
        disabled={isLoading}
        offset="small"
        onClick={handleCloseModal}
        placement="end"
        screenReaderLabel={I18n.t('Close')}
      />
    )
  }

  const renderAuthProviderSection = (section: 'primary' | 'secondary', title: string) => (
    <>
      <SignInOptionsHeader title={title} onAddClick={() => handleAddCard(section)} />

      <Flex as="div" gap="x-small" direction="column">
        {config.discovery_page[section].map((card, index) => (
          <AuthProvider
            key={card.id}
            label={card.label}
            iconUrl={getDiscoveryPageIcons().find(i => i.id === card.icon)?.url}
            loginLabel={card.label}
            selectedProviderId={String(card.authentication_provider_id)}
            onLoginChange={value =>
              handleUpdateCard(section, card.id, {
                label: value,
              })
            }
            onProviderChange={providerId =>
              handleUpdateCard(section, card.id, {
                authentication_provider_id: Number(providerId),
              })
            }
            selectedIconId={card.icon || ''}
            onIconSelect={iconId => {
              handleUpdateCard(section, card.id, {
                icon: iconId,
              })
            }}
            expanded={expandedCardId === card.id}
            onToggle={() => setExpandedCardId(expandedCardId === card.id ? null : card.id)}
            // cross-section moves are allowed: last primary item can move to secondary,
            // first secondary item can move to primary (only disable at absolute boundaries)
            disableMoveUp={section === 'primary' && index === 0}
            disableMoveDown={
              section === 'secondary' && index === config.discovery_page.secondary.length - 1
            }
            onDelete={() => handleDeleteCard(section, card.id)}
            onMoveUp={() => {
              setExpandedCardId(null)
              handleMoveCard(section, card.id, 'up')
            }}
            onMoveDown={() => {
              setExpandedCardId(null)
              handleMoveCard(section, card.id, 'down')
            }}
          />
        ))}
      </Flex>
    </>
  )

  return (
    <Modal
      data-testid="configure-modal"
      label={I18n.t('Configure Identity Service Discovery Page')}
      onClose={handleCloseModal}
      onDismiss={handleCloseModal}
      open={open}
      shouldCloseOnDocumentClick={!isLoading}
      size="fullscreen"
    >
      <Modal.Header spacing="compact">
        {renderCloseButton()}
        <Heading>{I18n.t('Configure Identity Service Discovery Page')}</Heading>
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
              isLoading={isLoadingConfig || isSaving}
              isLoadingConfig={isLoadingConfig}
              mountNode={() => modalBodyRef.current}
            />

            <PreviewAndSidebar previewUrl={previewUrl} iframeRef={iframeRef}>
              <Heading level="h3" margin="0 0 medium 0">
                {I18n.t('Configure sign in options')}
              </Heading>

              <Flex as="div" gap="medium" direction="column">
                {renderAuthProviderSection('primary', I18n.t('Main sign in options'))}
                {renderAuthProviderSection('secondary', I18n.t('More sign in options'))}
              </Flex>
            </PreviewAndSidebar>
          </>
        )}
      </Modal.Body>

      <Modal.Footer>
        <Flex direction="row" gap="small">
          <Button onClick={handleCloseModal} disabled={isLoading} data-testid="cancel-button">
            {I18n.t('Cancel')}
          </Button>

          <Button
            color="primary"
            data-testid="save-button"
            disabled={isLoading}
            onClick={handleSave}
          >
            {isSaving ? I18n.t('Saving...') : I18n.t('Save')}
          </Button>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
