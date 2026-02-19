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

import React, {useEffect, useState} from 'react'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import LoadingIndicator from '@canvas/loading-indicator'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine} from '@instructure/ui-icons'
import type {Rubric, RubricAssociation} from '../../../types/rubric'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {RubricSearchFooter} from './RubricSearchFooter'
import {RubricsForContext} from './RubricsForContext'
import {RubricContextSelect} from './RubricContextSelect'

const I18n = createI18nScope('enhanced-rubrics-assignment-search')

type RubricSearchTrayProps = {
  courseId: string
  isOpen: boolean
  onPreview: (rubric: Rubric) => void
  onDismiss: () => void
  onAddRubric: (rubricId: string, updatedAssociation: RubricAssociation) => void
}
export const RubricSearchTray = ({
  courseId,
  isOpen,
  onPreview,
  onDismiss,
  onAddRubric,
}: RubricSearchTrayProps) => {
  const [search, setSearch] = useState<string>('')
  const [selectedContext, setSelectedContext] = useState<string>()
  const [selectedAssociation, setSelectedAssociation] = useState<RubricAssociation>()
  const [selectedRubricId, setSelectedRubricId] = useState<string>()

  useEffect(() => {
    if (isOpen) {
      setSearch('')
      setSelectedAssociation(undefined)
      setSelectedRubricId(undefined)
    }
  }, [isOpen])

  const handleChangeContext = (contextCode: string) => {
    setSelectedContext(contextCode)
    setSelectedAssociation(undefined)
    setSelectedRubricId(undefined)
  }

  return (
    <Tray
      label={I18n.t('Rubric Search Tray')}
      open={isOpen}
      onDismiss={onDismiss}
      size="small"
      placement="end"
      shouldCloseOnDocumentClick={true}
      id="enhanced-rubric-assignment-search-tray"
    >
      <View as="div" padding="medium" data-testid="rubric-search-tray">
        <Flex>
          <Flex.Item shouldGrow={true} shouldShrink={true}>
            <Heading level="h3">{I18n.t('Find Rubric')}</Heading>
          </Flex.Item>
          <Flex.Item>
            <CloseButton
              placement="end"
              offset="small"
              screenReaderLabel={I18n.t('Close')}
              onClick={onDismiss}
            />
          </Flex.Item>
        </Flex>
      </View>

      <View as="div" margin="x-small 0 0" padding="0 small">
        <TextInput
          autoComplete="off"
          renderLabel={<ScreenReaderContent>{I18n.t('search rubrics input')}</ScreenReaderContent>}
          placeholder={I18n.t('Search rubrics')}
          value={search}
          onChange={e => setSearch(e.target.value)}
          renderAfterInput={() => <IconSearchLine inline={false} />}
        />
      </View>

      {isOpen && (
        <View as="div" margin="medium 0 0" padding="0 small">
          <RubricContextSelect
            courseId={courseId}
            selectedContext={selectedContext}
            handleChangeContext={handleChangeContext}
            setSelectedContext={setSelectedContext}
          />

          <View
            as="div"
            margin="small 0 0"
            height="100vh"
            maxHeight="calc(100vh - 272px)"
            padding="small 0"
            overflowY="auto"
          >
            {selectedContext ? (
              <RubricsForContext
                courseId={courseId}
                selectedAssociation={selectedAssociation}
                selectedContext={selectedContext}
                search={search}
                onPreview={onPreview}
                onSelect={(rubricAssociation, rubricId) => {
                  setSelectedAssociation(rubricAssociation)
                  setSelectedRubricId(rubricId)
                }}
              />
            ) : (
              <LoadingIndicator />
            )}
          </View>
        </View>
      )}

      <View as="footer" margin="small 0 0" height="62px" id="rubric-search-footer-container">
        <View as="hr" margin="0" />
        <RubricSearchFooter
          disabled={!selectedRubricId}
          onSubmit={() => {
            if (!selectedRubricId || !selectedAssociation) return

            onAddRubric(selectedRubricId, selectedAssociation)
          }}
          onCancel={onDismiss}
        />
      </View>
    </Tray>
  )
}
