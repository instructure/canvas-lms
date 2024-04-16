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
import {Modal} from '@instructure/ui-modal'
import {Spinner} from '@instructure/ui-spinner'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'

import {useGradingSchemeSummaries} from '../hooks/useGradingSchemeSummaries'
import {useDefaultGradingScheme} from '../hooks/useDefaultGradingScheme'
import {GradingSchemesManagement} from './GradingSchemesManagement'
import {defaultPointsGradingScheme} from '../../defaultPointsGradingScheme'

import type {GradingSchemeSummary, GradingScheme} from '../../gradingSchemeApiModel'
import {GradingSchemeViewEditModal} from './GradingSchemeViewEditModal'
import {GradingSchemeViewCopyTemplateModal} from './GradingSchemeViewCopyTemplateModal'
import {IconAddLine, IconCheckSolid} from '@instructure/ui-icons'
import GradingSchemeViewModal from './GradingSchemeViewModal'
import GradingSchemeDuplicateModal from './GradingSchemeDuplicateModal'
import {useGradingSchemeCreate} from '../hooks/useGradingSchemeCreate'
import {ApiCallStatus} from '../hooks/ApiCallStatus'
import {useGradingSchemes} from '../hooks/useGradingSchemes'
import GradingSchemeEditModal from './GradingSchemeEditModal'
import type {GradingSchemeEditableData} from './form/GradingSchemeInput'
import {useGradingSchemeUpdate} from '../hooks/useGradingSchemeUpdate'
import GradingSchemeDeleteModal from './GradingSchemeDeleteModal'
import {useGradingSchemeDelete} from '../hooks/useGradingSchemeDelete'
import GradingSchemeCreateModal from './GradingSchemeCreateModal'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {useGradingScheme} from '../hooks/useGradingScheme'

const I18n = useI18nScope('assignments.grading_type_selector')

export type GradingSchemesSelectorProps = {
  canManage: boolean
  contextType: 'Course' | 'Account'
  contextId: string
  courseDefaultSchemeId?: string
  initiallySelectedGradingSchemeId?: string
  assignmentId?: string | null
  archivedGradingSchemesEnabled: boolean
  shrinkSearchBar?: boolean
  onChange: (gradingStandardId?: string) => any
}
export const GradingSchemesSelector = ({
  initiallySelectedGradingSchemeId,
  onChange,
  canManage,
  contextType,
  contextId,
  courseDefaultSchemeId,
  archivedGradingSchemesEnabled,
  shrinkSearchBar = false,
  assignmentId = null,
}: GradingSchemesSelectorProps) => {
  if (initiallySelectedGradingSchemeId === '0' || initiallySelectedGradingSchemeId === '') {
    initiallySelectedGradingSchemeId = undefined
  }
  const {loadGradingScheme /* deleteGradingSchemeStatus */} = useGradingScheme()
  const [showViewEditGradingSchemeModal, setShowViewEditGradingSchemeModal] = useState(false)
  const [showManageGradingSchemesModal, setShowManageGradingSchemesModal] = useState(false)
  const [showViewGradingSchemeModal, setShowViewGradingSchemeModal] = useState(false)
  const [showDuplicateGradingSchemeModal, setShowDuplicateGradingSchemeModal] = useState(false)
  const [showCreateGradingSchemeModal, setShowCreateGradingSchemeModal] = useState(false)
  const [showDeleteGradingSchemeModal, setShowDeleteGradingSchemeModal] = useState(false)
  const [showEditGradingSchemeModal, setShowEditGradingSchemeModal] = useState(false)
  const [gradingSchemeSummaries, setGradingSchemeSummaries] = useState<
    GradingSchemeSummary[] | undefined
  >(undefined)
  const [selectedGradingScheme, setSelectedGradingScheme] = useState<GradingScheme | undefined>(
    undefined
  )
  const [defaultCanvasGradingScheme, setDefaultCanvasGradingScheme] = useState<
    GradingScheme | undefined
  >(undefined)
  const [selectedGradingSchemeId, setSelectedGradingSchemeId] = useState<string | undefined>(
    initiallySelectedGradingSchemeId
  )
  const {loadGradingSchemeSummaries /* loadGradingSchemesStatus */} = useGradingSchemeSummaries()
  const {loadDefaultGradingScheme /* loadGradingSchemesStatus */} = useDefaultGradingScheme()
  const {loadGradingSchemes} = useGradingSchemes()
  const {updateGradingScheme /* deleteGradingSchemeStatus */} = useGradingSchemeUpdate()
  const {createGradingScheme, createGradingSchemeStatus} = useGradingSchemeCreate()
  const {deleteGradingScheme, deleteGradingSchemeStatus} = useGradingSchemeDelete()
  useEffect(() => {
    const loadSchemes = async () => {
      try {
        const summaries = await loadGradingSchemeSummaries(
          contextType,
          contextId,
          archivedGradingSchemesEnabled ? assignmentId : null
        )
        setGradingSchemeSummaries(summaries)
        const defaultScheme = await loadDefaultGradingScheme(contextType, contextId)
        setDefaultCanvasGradingScheme(defaultScheme)
      } catch (error: any) {
        showFlashError(I18n.t('There was an error while loading grading schemes'))(error)
      }
    }
    loadSchemes()
  }, [
    loadGradingSchemeSummaries,
    loadDefaultGradingScheme,
    loadGradingSchemes,
    contextType,
    contextId,
    archivedGradingSchemesEnabled,
    initiallySelectedGradingSchemeId,
    assignmentId,
  ])

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

  function handleCreatedGradingScheme(
    gradingSchemeSummary: GradingSchemeSummary,
    gradingScheme?: GradingScheme
  ) {
    if (!gradingSchemeSummaries) return
    closeGradingSchemeViewEditModal()
    setGradingSchemeSummaries([gradingSchemeSummary, ...gradingSchemeSummaries])

    if (archivedGradingSchemesEnabled && gradingScheme) {
      setSelectedGradingScheme(gradingScheme)
    }
    handleChangeSelectedGradingSchemeId(gradingSchemeSummary.id)
  }
  function handleUpdatedGradingScheme(
    updatedGradingSchemeSummary: GradingSchemeSummary,
    updatedGradingScheme?: GradingScheme
  ) {
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
    if (archivedGradingSchemesEnabled && updatedGradingScheme) {
      setSelectedGradingScheme(updatedGradingScheme)
      setSelectedGradingSchemeId(undefined)
      setSelectedGradingSchemeId(updatedGradingScheme.id)
    }
  }
  function handleDeletedGradingScheme(gradingSchemeId: string) {
    if (!gradingSchemeSummaries) return
    setShowDeleteGradingSchemeModal(false)
    setShowEditGradingSchemeModal(false)
    setShowViewGradingSchemeModal(false)
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

  const onChangeInput = (
    _event: React.SyntheticEvent<Element, Event>,
    data: {
      value?: string | number | undefined
    }
  ) => {
    const newGradingSchemeId = String(data.value)
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
  async function openGradingSchemeViewModal() {
    setSelectedGradingScheme(undefined)
    try {
      const scheme = selectedGradingSchemeId
        ? await loadGradingScheme(
            contextType,
            contextId,
            selectedGradingSchemeId,
            archivedGradingSchemesEnabled ? assignmentId : null
          )
        : defaultCanvasGradingScheme
      setSelectedGradingScheme(scheme)
      setShowViewGradingSchemeModal(true)
    } catch (error: any) {
      showFlashError(I18n.t('There was an error while loading the grading scheme'))(error)
    }
  }
  async function openGradingSchemeDuplicateModal() {
    setSelectedGradingScheme(undefined)
    try {
      const scheme = selectedGradingSchemeId
        ? await loadGradingScheme(contextType, contextId, selectedGradingSchemeId)
        : defaultCanvasGradingScheme
      setSelectedGradingScheme(scheme)
      setShowDuplicateGradingSchemeModal(true)
    } catch (error: any) {
      showFlashError(I18n.t('There was an error while loading the grading scheme'))(error)
    }
  }
  function openGradingSchemeCreateModal() {
    setShowCreateGradingSchemeModal(true)
  }
  function openGradingSchemeDeleteModal() {
    setShowDeleteGradingSchemeModal(true)
  }
  function openGradingSchemeEditModal() {
    setShowEditGradingSchemeModal(true)
  }
  function handleGradingSchemesChanged() {
    loadGradingSchemeSummaries(
      contextType,
      contextId,
      archivedGradingSchemesEnabled ? assignmentId : null
    )
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

  const handleUpdateScheme = async (
    gradingSchemeFormInput: GradingSchemeEditableData,
    gradingSchemeId: string
  ) => {
    try {
      const updatedGradingScheme = await updateGradingScheme(contextType, contextId, {
        title: gradingSchemeFormInput.title,
        data: gradingSchemeFormInput.data,
        points_based: gradingSchemeFormInput.pointsBased,
        scaling_factor: gradingSchemeFormInput.scalingFactor,
        id: gradingSchemeId,
      })

      handleUpdatedGradingScheme(updatedGradingScheme, updatedGradingScheme)
      setShowEditGradingSchemeModal(false)
      showFlashSuccess(I18n.t('Grading scheme was successfully updated.'))()
    } catch (error) {
      showFlashError(I18n.t('There was an error while saving the grading scheme'))(error as Error)
    }
  }
  async function handleDuplicateScheme(gradingScheme: GradingScheme) {
    await handleCreateGradingScheme({
      title: `${gradingScheme.title} ${I18n.t('Copy')}`,
      data: gradingScheme.data,
      scalingFactor: gradingScheme.scaling_factor,
      pointsBased: gradingScheme.points_based,
    })
    setShowEditGradingSchemeModal(true)
  }

  async function handleCreateGradingScheme(gradingSchemeFormInput: GradingSchemeEditableData) {
    const scheme = await createGradingScheme(contextType, contextId, {
      title: gradingSchemeFormInput.title,
      data: gradingSchemeFormInput.data,
      scaling_factor: gradingSchemeFormInput.scalingFactor,
      points_based: gradingSchemeFormInput.pointsBased,
    })
    handleCreatedGradingScheme(scheme, scheme)
    setShowCreateGradingSchemeModal(false)
    setShowDuplicateGradingSchemeModal(false)
  }

  async function handleDeleteScheme(gradingSchemeId: string) {
    if (selectedGradingScheme?.id !== gradingSchemeId) {
      showFlashError(I18n.t('There was an error while removing the grading scheme'))()
    }
    try {
      const schemeToDelete = selectedGradingScheme
      if (!schemeToDelete) {
        return
      }
      await deleteGradingScheme(
        schemeToDelete.context_type,
        schemeToDelete.context_id,
        gradingSchemeId
      )
      showFlashSuccess(I18n.t('Grading scheme was successfully removed.'))()
      handleDeletedGradingScheme(gradingSchemeId)
    } catch (error) {
      showFlashError(I18n.t('There was an error while removing the grading scheme'))(error as Error)
    }
  }
  if (!gradingSchemeSummaries || !defaultCanvasGradingScheme) {
    return (
      <>
        <Spinner renderTitle="Loading" size="x-small" />
      </>
    )
  } else {
    let defaultSchemeLabel: string
    if (courseDefaultSchemeId) {
      // look for a matching grading scheme id to get the 'default' scheme title
      const matchingSummaries = gradingSchemeSummaries.filter(
        gradingSchemeSummary => gradingSchemeSummary.id === courseDefaultSchemeId
      )
      if (courseDefaultSchemeId === '0') {
        defaultSchemeLabel = I18n.t('Canvas Grading Scheme (course default)')
      } else if (matchingSummaries.length > 0) {
        defaultSchemeLabel = `${matchingSummaries[0].title} ${I18n.t('(course default)')}`
      } else {
        defaultSchemeLabel = I18n.t('Course Default Grading Scheme')
      }
    } else {
      defaultSchemeLabel = I18n.t('Default Canvas Grading Scheme')
    }
    return (
      <>
        <Flex
          justifyItems={archivedGradingSchemesEnabled ? 'start' : 'center'}
          alignItems="end"
          margin="small 0 x-small"
          padding="xxx-small 0 0"
          withVisualDebug={false}
        >
          <Flex.Item
            shouldShrink={true}
            shouldGrow={!archivedGradingSchemesEnabled || !shrinkSearchBar}
          >
            <View as="div" withVisualDebug={false}>
              <FormField
                label=""
                id={shortid()}
                data-testid="grading-schemes-selector-dropdown-form"
              >
                {archivedGradingSchemesEnabled ? (
                  <SimpleSelect
                    value={selectedGradingSchemeId ?? ''}
                    onChange={onChangeInput}
                    id={shortid()}
                    renderLabel={
                      <ScreenReaderContent>{I18n.t('Select a grading scheme')}</ScreenReaderContent>
                    }
                    data-testid="grading-schemes-selector-dropdown"
                  >
                    <SimpleSelect.Option
                      value=""
                      id="0"
                      key="0"
                      data-testid="grading-schemes-selector-default-option"
                      renderBeforeLabel={() => {
                        if (
                          selectedGradingSchemeId === '' ||
                          selectedGradingSchemeId === '0' ||
                          selectedGradingSchemeId === undefined
                        ) {
                          return <IconCheckSolid />
                        }
                      }}
                    >
                      {defaultSchemeLabel}
                    </SimpleSelect.Option>

                    <SimpleSelect.Group renderLabel={I18n.t('Course Level')}>
                      {gradingSchemeSummaries
                        .filter(gradingScheme => gradingScheme.context_type === 'Course')
                        .map(gradingScheme => (
                          <SimpleSelect.Option
                            id={gradingScheme.id}
                            value={gradingScheme.id}
                            key={gradingScheme.id}
                            renderBeforeLabel={() => {
                              if (gradingScheme.id === selectedGradingSchemeId) {
                                return <IconCheckSolid />
                              }
                            }}
                            data-testid={`grading-schemes-selector-option-${gradingScheme.id}`}
                          >
                            {gradingScheme.title}
                          </SimpleSelect.Option>
                        ))}
                    </SimpleSelect.Group>
                    <SimpleSelect.Group renderLabel={I18n.t('Account Level')}>
                      {gradingSchemeSummaries
                        ?.filter(gradingScheme => gradingScheme.context_type === 'Account')
                        .map(gradingScheme => (
                          <SimpleSelect.Option
                            id={gradingScheme.id}
                            value={gradingScheme.id}
                            key={gradingScheme.id}
                            renderBeforeLabel={() => {
                              if (gradingScheme.id === selectedGradingSchemeId) {
                                return <IconCheckSolid />
                              }
                            }}
                            data-testid={`grading-schemes-selector-option-${gradingScheme.id}`}
                          >
                            {`${gradingScheme.title} ${
                              courseDefaultSchemeId === gradingScheme.id
                                ? I18n.t('(course default)')
                                : ''
                            }`}
                          </SimpleSelect.Option>
                        ))}
                    </SimpleSelect.Group>
                  </SimpleSelect>
                ) : (
                  <select
                    style={{
                      width: '100%',
                      margin: 0,
                      padding: 0,
                    }}
                    id={shortid()}
                    value={selectedGradingSchemeId || undefined}
                    onChange={onChangeSelectedGradingScheme}
                  >
                    <option value="">{defaultSchemeLabel}</option>
                    {gradingSchemeSummaries.map(gradingSchemeSummary => (
                      <option key={gradingSchemeSummary.id} value={gradingSchemeSummary.id}>
                        {gradingSchemeSummary.title}
                      </option>
                    ))}
                  </select>
                )}
              </FormField>
            </View>
          </Flex.Item>
          {!archivedGradingSchemesEnabled && (
            <Flex.Item>
              <View as="div" margin="none none none xx-small" withVisualDebug={false}>
                <Button
                  onClick={openGradingSchemeViewEditModal}
                  data-testid="grading-schemes-selector-view-button"
                >
                  {canManage ? I18n.t('View/Edit') : I18n.t('View')}
                </Button>
              </View>
            </Flex.Item>
          )}
        </Flex>
        {archivedGradingSchemesEnabled && (
          <>
            <Flex
              justifyItems="start"
              alignItems="end"
              margin="x-small none small"
              padding="x-small none"
            >
              <Flex.Item>
                <View as="div" withVisualDebug={false}>
                  <Button
                    onClick={openGradingSchemeViewModal}
                    data-testid="grading-schemes-selector-view-button"
                  >
                    {I18n.t('View')}
                  </Button>
                </View>
              </Flex.Item>
              <Flex.Item>
                <View as="div" margin="none none none small" withVisualDebug={false}>
                  <Button
                    onClick={openGradingSchemeDuplicateModal}
                    data-testid="grading-schemes-selector-copy-button"
                  >
                    {I18n.t('Copy')}
                  </Button>
                </View>
              </Flex.Item>
              <Flex.Item>
                <View as="div" margin="none none none small" withVisualDebug={false}>
                  <Button
                    onClick={openGradingSchemeCreateModal}
                    renderIcon={IconAddLine}
                    data-testid="grading-schemes-selector-new-grading-scheme-button"
                  >
                    {I18n.t('New Grading Scheme')}
                  </Button>
                </View>
              </Flex.Item>
            </Flex>
          </>
        )}
        {canManage && true && (
          <View as="div" margin="none none small none" withVisualDebug={false}>
            <CondensedButton
              color="primary"
              onClick={openManageGradingSchemesModal}
              data-testid="manage-all-grading-schemes-button"
            >
              {I18n.t('Manage All Grading Schemes')}
            </CondensedButton>
          </View>
        )}
        {archivedGradingSchemesEnabled && (
          <>
            <GradingSchemeViewModal
              open={showViewGradingSchemeModal && selectedGradingScheme !== undefined}
              handleClose={() => setShowViewGradingSchemeModal(false)}
              openDeleteModal={openGradingSchemeDeleteModal}
              editGradingScheme={openGradingSchemeEditModal}
              canManageScheme={() => canManage}
              isCourseDefault={selectedGradingScheme?.id === courseDefaultSchemeId}
              gradingScheme={selectedGradingScheme}
            />
            <GradingSchemeEditModal
              open={showEditGradingSchemeModal}
              gradingScheme={selectedGradingScheme}
              handleCancelEdit={() => setShowEditGradingSchemeModal(false)}
              handleUpdateScheme={handleUpdateScheme}
              defaultGradingSchemeTemplate={defaultCanvasGradingScheme as GradingScheme}
              defaultPointsGradingScheme={defaultPointsGradingScheme}
              openDeleteModal={openGradingSchemeDeleteModal}
              isCourseDefault={selectedGradingScheme?.id === courseDefaultSchemeId}
            />
            <GradingSchemeCreateModal
              open={showCreateGradingSchemeModal}
              handleCreateScheme={handleCreateGradingScheme}
              archivedGradingSchemesEnabled={archivedGradingSchemesEnabled}
              defaultGradingSchemeTemplate={defaultCanvasGradingScheme as GradingScheme}
              defaultPointsGradingScheme={defaultPointsGradingScheme}
              handleCancelCreate={() => setShowCreateGradingSchemeModal(false)}
            />
            <GradingSchemeDuplicateModal
              open={showDuplicateGradingSchemeModal}
              selectedGradingScheme={selectedGradingScheme}
              handleCloseDuplicateModal={() => setShowDuplicateGradingSchemeModal(false)}
              creatingGradingScheme={createGradingSchemeStatus === ApiCallStatus.PENDING}
              handleDuplicateScheme={handleDuplicateScheme}
            />
            <GradingSchemeDeleteModal
              open={showDeleteGradingSchemeModal}
              deletingGradingScheme={deleteGradingSchemeStatus === ApiCallStatus.PENDING}
              selectedGradingScheme={selectedGradingScheme}
              handleCloseDeleteModal={() => setShowDeleteGradingSchemeModal(false)}
              handleGradingSchemeDelete={handleDeleteScheme}
            />
          </>
        )}
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
                archivedGradingSchemesEnabled={archivedGradingSchemesEnabled}
              />
            ) : courseDefaultSchemeId && courseDefaultSchemeId !== '0' ? (
              <GradingSchemeViewEditModal
                contextType={contextType}
                contextId={contextId}
                gradingSchemeId={courseDefaultSchemeId}
                onCancel={closeGradingSchemeViewEditModal}
                onUpdate={handleUpdatedGradingScheme}
                onDelete={() => handleDeletedGradingScheme(courseDefaultSchemeId)}
                archivedGradingSchemesEnabled={archivedGradingSchemesEnabled}
              />
            ) : (
              <GradingSchemeViewCopyTemplateModal
                allowDuplication={canManage}
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
            size="fullscreen"
            label={I18n.t('Manage All Grading Schemes')}
            shouldCloseOnDocumentClick={true}
          >
            <Modal.Header>
              <CloseButton
                placement="end"
                offset="small"
                onClick={closeManageGradingSchemesModal}
                screenReaderLabel={I18n.t('Close')}
                data-testid="manage-all-grading-schemes-close-button"
              />
              <Heading>{I18n.t('Manage All Grading Schemes')}</Heading>
            </Modal.Header>
            <Modal.Body>
              <>
                <GradingSchemesManagement
                  contextId={contextId}
                  contextType={contextType}
                  onGradingSchemesChanged={handleGradingSchemesChanged}
                  archivedGradingSchemesEnabled={archivedGradingSchemesEnabled}
                  showCourseSchemesOnly={true}
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
