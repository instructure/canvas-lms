/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import shortid from '@canvas/shortid'
import {Button, CloseButton, CondensedButton} from '@instructure/ui-buttons'
import {FormField} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
// @ts-ignore // TODO JS: get ui modal types
import {Modal} from '@instructure/ui-modal'
import {Spinner} from '@instructure/ui-spinner'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

import {useGradingSchemeSummaries} from '../hooks/useGradingSchemeSummaries'
import {useDefaultGradingScheme} from '../hooks/useDefaultGradingScheme'
import {GradingSchemesManagement} from './GradingSchemesManagement'

import {GradingSchemeTemplate, GradingSchemeSummary} from '../../gradingSchemeApiModel'
import {GradingSchemeViewEditModal} from './GradingSchemeViewEditModal'
import {GradingSchemeViewCopyTemplateModal} from './GradingSchemeViewCopyTemplateModal'

const I18n = useI18nScope('assignments.grading_type_selector')
// Doing this to avoid TS2339 errors -- TODO: remove once we're on InstUI 8
const {Item} = Flex as any

interface ComponentProps {
  contextType: 'Course' | 'Account'
  contextId: string
  initiallySelectedGradingSchemeId?: string
  onChange: (gradingStandardId?: string) => any
}
export const GradingSchemesSelector = ({
  initiallySelectedGradingSchemeId,
  onChange,
  contextType,
  contextId,
}: ComponentProps) => {
  if (initiallySelectedGradingSchemeId === '0' || initiallySelectedGradingSchemeId === '') {
    initiallySelectedGradingSchemeId = undefined
  }
  const [showViewEditGradingSchemeModal, setShowViewEditGradingSchemeModal] = useState(false)
  const [showManageGradingSchemesModal, setShowManageGradingSchemesModal] = useState(false)
  const [gradingSchemeSummaries, setGradingSchemeSummaries] = useState<
    GradingSchemeSummary[] | undefined
  >(undefined)
  const [defaultCanvasGradingScheme, setDefaultCanvasGradingScheme] = useState<
    GradingSchemeTemplate | undefined
  >(undefined)

  const [selectedGradingSchemeId, setSelectedGradingSchemeId] = useState<string | undefined>(
    initiallySelectedGradingSchemeId
  )
  const {loadGradingSchemeSummaries /* loadGradingSchemesStatus */} = useGradingSchemeSummaries()
  const {loadDefaultGradingScheme /* loadGradingSchemesStatus */} = useDefaultGradingScheme()

  useEffect(() => {
    loadGradingSchemeSummaries(contextType, contextId)
      .then(summaries => {
        setGradingSchemeSummaries(summaries)
      })
      .catch(error => {
        showFlashError(I18n.t('There was an error while loading grading schemes'))(error)
      })
    // defaultCanvasGradingScheme
    loadDefaultGradingScheme(contextType, contextId)
      .then(defaultGradingScheme => {
        setDefaultCanvasGradingScheme(defaultGradingScheme)
      })
      .catch(error => {
        showFlashError(
          I18n.t('There was an error while loading the default canvas grading scheme')
        )(error)
      })
    return () => {
      // this is called when the component unmounts
    }
  }, [loadGradingSchemeSummaries, loadDefaultGradingScheme, contextType, contextId])

  if (gradingSchemeSummaries && selectedGradingSchemeId) {
    const matchSelect = gradingSchemeSummaries.filter(
      summary => summary.id === selectedGradingSchemeId
    )
    if (matchSelect.length === 0) {
      handleChangeSelectedGradingSchemeId(undefined)
    }
  }

  function handleChangeSelectedGradingSchemeId(newlySelectedGradingSchemeId: string | undefined) {
    if (newlySelectedGradingSchemeId === '') {
      newlySelectedGradingSchemeId = undefined
    }
    setSelectedGradingSchemeId(newlySelectedGradingSchemeId)
    onChange(newlySelectedGradingSchemeId)
  }

  function handleCreatedGradingScheme(gradingSchemeSummary: GradingSchemeSummary) {
    if (!gradingSchemeSummaries) return
    closeGradingSchemeViewEditModal()
    setGradingSchemeSummaries([gradingSchemeSummary, ...gradingSchemeSummaries])
    handleChangeSelectedGradingSchemeId(gradingSchemeSummary.id)
  }
  function handleUpdatedGradingScheme(updatedGradingSchemeSummary: GradingSchemeSummary) {
    if (!gradingSchemeSummaries) return
    closeGradingSchemeViewEditModal()
    setGradingSchemeSummaries(
      gradingSchemeSummaries.map(gradingSchemeSummary => {
        if (gradingSchemeSummary.id !== updatedGradingSchemeSummary.id) {
          return gradingSchemeSummary
        } else {
          return updatedGradingSchemeSummary
        }
      })
    )
  }
  function handleDeletedGradingScheme(gradingSchemeId: string) {
    if (!gradingSchemeSummaries) return
    closeGradingSchemeViewEditModal()
    if (gradingSchemeId === selectedGradingSchemeId) {
      handleChangeSelectedGradingSchemeId(undefined)
    }
    setGradingSchemeSummaries(
      gradingSchemeSummaries.filter(
        gradingSchemeSummary => gradingSchemeSummary.id !== gradingSchemeId
      )
    )
  }

  const onChangeSelectedGradingScheme = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const newGradingSchemeId: string | undefined = event.target.value
    handleChangeSelectedGradingSchemeId(newGradingSchemeId)
  }
  function openGradingSchemeViewEditModal() {
    setShowViewEditGradingSchemeModal(true)
  }
  function closeGradingSchemeViewEditModal() {
    setShowViewEditGradingSchemeModal(false)
  }
  function openManageGradingSchemesModal() {
    setShowManageGradingSchemesModal(true)
  }
  function closeManageGradingSchemesModal() {
    setShowManageGradingSchemesModal(false)
  }

  function handleGradingSchemesChanged() {
    loadGradingSchemeSummaries(contextType, contextId)
      .then(loadedGradingSchemes => {
        const matchingSelectedId = loadedGradingSchemes.filter(
          gradingSchemeSummary => gradingSchemeSummary.id === selectedGradingSchemeId
        )
        if (matchingSelectedId.length === 0) {
          handleChangeSelectedGradingSchemeId(undefined)
        }
        setGradingSchemeSummaries(loadedGradingSchemes)
      })
      .catch(error => {
        showFlashError(I18n.t('There was an error while refreshing grading schemes'))(error)
      })
  }

  if (!gradingSchemeSummaries || !defaultCanvasGradingScheme) {
    return (
      <>
        <Spinner renderTitle="Loading" size="x-small" />
      </>
    )
  } else {
    return (
      <>
        <Flex
          justifyItems="center"
          alignItems="end"
          margin="small none small none"
          withVisualDebug={false}
        >
          <Item shouldShrink={true} shouldGrow={true}>
            <View as="div" withVisualDebug={false}>
              <FormField label="" id={shortid()}>
                <select
                  style={{width: '100%', margin: 0, padding: 0}}
                  id={shortid()}
                  value={selectedGradingSchemeId || undefined}
                  onChange={onChangeSelectedGradingScheme}
                >
                  <option value="">{I18n.t('Default Canvas Grading Scheme')}</option>
                  {gradingSchemeSummaries.map(gradingSchemeSummary => (
                    <option key={gradingSchemeSummary.id} value={gradingSchemeSummary.id}>
                      {gradingSchemeSummary.title}
                    </option>
                  ))}
                </select>
              </FormField>
            </View>
          </Item>
          <Item>
            <View as="div" margin="none none none xx-small" withVisualDebug={false}>
              <Button onClick={openGradingSchemeViewEditModal}>{I18n.t('View/Edit')}</Button>
            </View>
          </Item>
        </Flex>

        <View as="div" margin="none none small none" withVisualDebug={false}>
          <CondensedButton color="primary" onClick={openManageGradingSchemesModal}>
            {I18n.t('Manage All Grading Schemes')}
          </CondensedButton>
        </View>

        {showViewEditGradingSchemeModal ? (
          <>
            {selectedGradingSchemeId ? (
              <GradingSchemeViewEditModal
                contextType={contextType}
                contextId={contextId}
                gradingSchemeId={selectedGradingSchemeId}
                onCancel={closeGradingSchemeViewEditModal}
                onUpdate={handleUpdatedGradingScheme}
                onDelete={() => handleDeletedGradingScheme(selectedGradingSchemeId)}
              />
            ) : (
              <GradingSchemeViewCopyTemplateModal
                allowDuplication={true}
                contextId={contextId}
                contextType={contextType}
                onCancel={closeGradingSchemeViewEditModal}
                onCreate={handleCreatedGradingScheme}
              />
            )}
          </>
        ) : (
          <></>
        )}

        {showManageGradingSchemesModal ? (
          <Modal
            open={showManageGradingSchemesModal}
            size="large"
            label={I18n.t('Manage All Grading Schemes')}
            shouldCloseOnDocumentClick={true}
          >
            <Modal.Header>
              <CloseButton
                placement="end"
                offset="small"
                onClick={closeManageGradingSchemesModal}
                screenReaderLabel={I18n.t('Close')}
              />
              <Heading>{I18n.t('Manage All Grading Schemes')}</Heading>
            </Modal.Header>
            <Modal.Body>
              <>
                <GradingSchemesManagement
                  contextId={contextId}
                  contextType={contextType}
                  onGradingSchemesChanged={handleGradingSchemesChanged}
                />
              </>
            </Modal.Body>
            <Modal.Footer>
              <Button onClick={closeManageGradingSchemesModal} margin="0 x-small 0 0">
                {I18n.t('Close')}
              </Button>
            </Modal.Footer>
          </Modal>
        ) : (
          <></>
        )}
      </>
    )
  }
}
