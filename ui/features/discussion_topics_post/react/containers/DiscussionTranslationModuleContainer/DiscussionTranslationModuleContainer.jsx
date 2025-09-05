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

import React, {useContext, useMemo, useState} from 'react'
import {TranslationControls} from '../../components/TranslationControls/TranslationControls'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Button, IconButton} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconRefreshLine, IconEndLine, IconAiSolid} from '@instructure/ui-icons'
import {DiscussionManagerUtilityContext} from '../../utils/constants'
import {TranslationTriggerModal} from '../../components/TranslationTriggerModal/TranslationTriggerModal'
import {useTranslationAll} from '../../hooks/useTranslationAll'
import {useTranslationStore} from '../../hooks/useTranslationStore'
import {useTranslation} from '../../hooks/useTranslation'

export const DiscussionTranslationModuleContainer = ({isAnnouncement}) => {
  const I18n = useI18nScope('discussions_posts')
  const [isModalOpen, setModalOpen] = useState(false)
  const [isLanguageNotSelectedError, setIsLanguageNotSelectedError] = useState(false)
  const [isLanguageAlreadyActiveError, setIsLanguageAlreadyActiveError] = useState(false)

  const activeLanguage = useTranslationStore(state => state.activeLanguage)
  const setActiveLangauge = useTranslationStore(state => state.setActiveLanguage)
  const isTranslateAll = useTranslationStore(state => state.translateAll)
  const clearTranslateAll = useTranslationStore(state => state.clearTranslateAll)
  const entries = useTranslationStore(state => state.entries)

  const translationControlsRef = React.createRef()
  const {setTranslateTargetLanguage, setShowTranslationControl, enqueueTranslation} = useContext(
    DiscussionManagerUtilityContext,
  )

  const isLoading = useMemo(() => {
    return Object.values(entries).some(entry => entry.loading)
  }, [entries])

  const {translateAll} = useTranslationAll(enqueueTranslation)
  const {preferredLanguage, savePreferredLanguage} = useTranslation()

  const [selectedLanguage, setSelectedLanguage] = useState(
    preferredLanguage || activeLanguage || '',
  )

  const closeTranslationModule = () => {
    if (isTranslateAll) {
      setModalOpen(true)
    } else {
      setShowTranslationControl(false)
    }
  }

  const closeModalAndKeepTranslations = () => {
    setModalOpen(false)
    setShowTranslationControl(false)
  }

  const closeModalAndRemoveTranslations = () => {
    clearTranslateAll()
    setActiveLangauge(null)
    setModalOpen(false)
    setShowTranslationControl(false)
  }

  const resetTranslationsModule = () => {
    translationControlsRef.current?.reset()
    setTranslateTargetLanguage(null)
    setIsLanguageNotSelectedError(false)
    setIsLanguageAlreadyActiveError(false)
    clearTranslateAll()
  }

  const translateDiscussion = () => {
    if (!selectedLanguage) {
      setIsLanguageNotSelectedError(true)
      return
    }

    if (isTranslateAll && selectedLanguage === activeLanguage) {
      setIsLanguageAlreadyActiveError(true)
      return
    }

    // Update preferred language if it was set before
    if (preferredLanguage && preferredLanguage !== selectedLanguage) {
      savePreferredLanguage(selectedLanguage, ENV?.discussion_topic_id)
    }
    setActiveLangauge(selectedLanguage)
    translateAll(selectedLanguage)
  }

  const title = isAnnouncement ? I18n.t('Translate Announcement') : I18n.t('Translate Discussion')

  return (
    <View
      position="relative"
      borderColor="primary"
      as="div"
      borderRadius="medium"
      borderWidth="small"
      padding="large"
      margin="0 0 small 0"
    >
      <TranslationTriggerModal
        isModalOpen={isModalOpen}
        isAnnouncement={isAnnouncement}
        closeModal={() => {
          setModalOpen(false)
        }}
        closeModalAndKeepTranslations={closeModalAndKeepTranslations}
        closeModalAndRemoveTranslations={closeModalAndRemoveTranslations}
      />
      <Flex justifyItems="space-between" alignItems="center">
        <Flex.Item>
          <Heading level="h2">{title}</Heading>
        </Flex.Item>
        <Flex.Item>
          <IconButton
            size="small"
            onClick={closeTranslationModule}
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t('Close translations module')}
            data-testid="close-translation-module-button"
          >
            <IconEndLine />
          </IconButton>
        </Flex.Item>
      </Flex>

      <Text color="secondary" size="small">
        {I18n.t(
          'This translation is generated by AI. Please note that the output may not always be accurate.',
        )}
      </Text>
      <View as="div" margin="medium 0 x-small 0">
        <label id="translate-select-label">
          <Text weight="bold">{I18n.t('Translate to')}</Text>
        </label>
      </View>
      <Flex direction="row" alignItems="start" gap="small" wrap="wrap">
        <Flex.Item maxWidth="360px" shouldGrow>
          <TranslationControls
            ref={translationControlsRef}
            isLanguageNotSelectedError={isLanguageNotSelectedError}
            onSetIsLanguageNotSelectedError={setIsLanguageNotSelectedError}
            isLanguageAlreadyActiveError={isLanguageAlreadyActiveError}
            onSetIsLanguageAlreadyActiveError={setIsLanguageAlreadyActiveError}
            onSetSelectedLanguage={setSelectedLanguage}
            selectedLanguage={selectedLanguage}
          />
        </Flex.Item>
        <Flex.Item>
          <Button
            onClick={translateDiscussion}
            disabled={isLoading}
            margin="0 small 0 0"
            color="ai-primary"
            aria-label={I18n.t('Ignite AI Translate')}
            renderIcon={IconAiSolid}
            data-testid="translate-discussion-button"
          >
            {I18n.t('Translate')}
          </Button>
          <Button
            onClick={resetTranslationsModule}
            renderIcon={<IconRefreshLine />}
            disabled={isLoading}
            data-testid="reset-translation-button"
          >
            {I18n.t('Reset')}
          </Button>
        </Flex.Item>
      </Flex>
    </View>
  )
}
