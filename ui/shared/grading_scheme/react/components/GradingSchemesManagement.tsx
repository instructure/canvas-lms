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

import React, {useEffect, useRef, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'

import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Transition} from '@instructure/ui-motion'
import {Spinner} from '@instructure/ui-spinner'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconAddLine, IconInfoLine, IconSearchLine} from '@instructure/ui-icons'

import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {GradingSchemeView} from './view/GradingSchemeView'
import {GradingSchemeTemplateView} from './view/GradingSchemeTemplateView'
import {useGradingSchemes} from '../hooks/useGradingSchemes'
import {useDefaultGradingScheme} from '../hooks/useDefaultGradingScheme'
import {useGradingSchemeCreate} from '../hooks/useGradingSchemeCreate'
import {useGradingSchemeDelete} from '../hooks/useGradingSchemeDelete'
import {useGradingSchemeUpdate} from '../hooks/useGradingSchemeUpdate'
import type {
  GradingScheme,
  GradingSchemeCardData,
  GradingSchemeTemplate,
} from '../../gradingSchemeApiModel'

import {
  type GradingSchemeEditableData,
  GradingSchemeInput,
  type GradingSchemeInputHandle,
} from './form/GradingSchemeInput'
import {defaultPointsGradingScheme} from '../../defaultPointsGradingScheme'
import {canManageAccountGradingSchemes} from '../helpers/gradingSchemePermissions'
import {GradingSchemeTable} from './GradingSchemeTable'
import GradingSchemeViewModal from './GradingSchemeViewModal'
import GradingSchemeEditModal from './GradingSchemeEditModal'
import {TextInput} from '@instructure/ui-text-input'
import GradingSchemeCreateModal from './GradingSchemeCreateModal'
import {Heading} from '@instructure/ui-heading'
import GradingSchemeUsedLocationsModal from './GradingSchemeUsedLocationsModal'
import GradingSchemeDuplicateModal from './GradingSchemeDuplicateModal'
import GradingSchemeDeleteModal from './GradingSchemeDeleteModal'
import {useGradingSchemeArchive} from '../hooks/useGradingSchemeArchive'
import {useGradingSchemeUnarchive} from '../hooks/useGradingSchemeUnarchive'
import {Tooltip} from '@instructure/ui-tooltip'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('GradingSchemeManagement')

interface GradingSchemeTemplateCardData {
  creating: boolean
  gradingSchemeTemplate: GradingSchemeTemplate
}

export interface GradingSchemesManagementProps {
  contextId: string
  contextType: 'Account' | 'Course'
  onGradingSchemesChanged?: () => any
  archivedGradingSchemesEnabled: boolean
  showCourseSchemesOnly?: boolean
}

export const GradingSchemesManagement = ({
  contextType,
  contextId,
  onGradingSchemesChanged,
  archivedGradingSchemesEnabled,
  showCourseSchemesOnly = false,
}: GradingSchemesManagementProps) => {
  const {createGradingScheme /* createGradingSchemeStatus */} = useGradingSchemeCreate()
  const {deleteGradingScheme /* deleteGradingSchemeStatus */} = useGradingSchemeDelete()
  const {updateGradingScheme /* deleteGradingSchemeStatus */} = useGradingSchemeUpdate()
  const {archiveGradingScheme} = useGradingSchemeArchive()
  const {unarchiveGradingScheme} = useGradingSchemeUnarchive()

  const [gradingSchemeCards, setGradingSchemeCards] = useState<GradingSchemeCardData[] | undefined>(
    undefined
  )

  const [gradingSchemeSearch, setGradingSchemeSearch] = useState<string>('')

  const [gradingSchemeCreating, setGradingSchemeCreating] = useState<
    GradingSchemeTemplateCardData | undefined
  >(undefined)

  const [viewingUsedLocations, setViewingUsedLocations] = useState<boolean>(false)
  const [editing, setEditing] = useState<boolean>(false)
  const [duplicateSchemeModalOpen, setDuplicateSchemeModalOpen] = useState<boolean>(false)
  const [deleteModalOpen, setDeleteModalOpen] = useState<boolean>(false)
  const [creatingGradingScheme, setCreatingGradingScheme] = useState<boolean>(false)
  const [deletingGradingScheme, setDeletingGradingScheme] = useState<boolean>(false)
  const [selectedGradingScheme, setSelectedGradingScheme] = useState<GradingScheme | undefined>(
    undefined
  )
  const {loadGradingSchemes} = useGradingSchemes()
  const {loadDefaultGradingScheme} = useDefaultGradingScheme()
  const [defaultGradingScheme, setDefaultGradingScheme] = useState<GradingScheme | undefined>(
    undefined
  )

  const gradingSchemeCreateRef = useRef<GradingSchemeInputHandle>(null)
  const gradingSchemeUpdateRef = useRef<GradingSchemeInputHandle>(null)
  useEffect(() => {
    loadGradingSchemes(contextType, contextId, archivedGradingSchemesEnabled)
      .then(gradingSchemes => {
        setGradingSchemeCards(
          gradingSchemes
            .filter(scheme => !showCourseSchemesOnly || scheme.context_type === 'Course')
            .map(scheme => {
              return {
                gradingScheme: scheme,
                editing: false,
                creating: false,
              } as GradingSchemeCardData
            })
        )
      })
      .catch(error => {
        showFlashError(I18n.t('There was an error while loading grading schemes'))(error)
      })
    loadDefaultGradingScheme(contextType, contextId)
      .then(loadedDefaultGradingScheme => {
        setDefaultGradingScheme(loadedDefaultGradingScheme)
      })
      .catch(error => {
        showFlashError(I18n.t('There was an error while loading the default grading scheme'))(error)
      })
  }, [
    loadGradingSchemes,
    loadDefaultGradingScheme,
    contextType,
    contextId,
    archivedGradingSchemesEnabled,
    showCourseSchemesOnly,
  ])

  const handleGradingSchemeDelete = async (gradingSchemeId: string) => {
    if (!gradingSchemeCards) {
      return
    }

    setDeletingGradingScheme(true)
    if (
      !archivedGradingSchemesEnabled &&
      // eslint-disable-next-line no-alert
      !window.confirm(
        I18n.t('confirm.delete', 'Are you sure you want to delete this grading scheme?')
      )
    ) {
      return
    }

    const gradingSchemeToDelete = gradingSchemeCards.filter(
      gradingSchemeCard => gradingSchemeId === gradingSchemeCard.gradingScheme.id
    )[0].gradingScheme

    try {
      await deleteGradingScheme(
        gradingSchemeToDelete.context_type,
        gradingSchemeToDelete.context_id,
        gradingSchemeId
      )
      showFlashSuccess(I18n.t('Grading scheme was successfully removed.'))()
      if (onGradingSchemesChanged) {
        // if parent supplied a callback method, inform parent that grading standards changed (one was removed)
        onGradingSchemesChanged()
      }
      setGradingSchemeCards(
        gradingSchemeCards.filter(
          gradingSchemeCard => gradingSchemeId !== gradingSchemeCard.gradingScheme.id
        )
      )
      setSelectedGradingScheme(undefined)
      setDeleteModalOpen(false)
      setEditing(false)
    } catch (error) {
      showFlashError(I18n.t('There was an error while removing the grading scheme'))(error as Error)
    }
    setDeletingGradingScheme(false)
  }
  const handleDuplicateScheme = async (gradingScheme: GradingScheme) => {
    setCreatingGradingScheme(true)
    await handleCreateScheme(
      {
        title: `${gradingScheme.title} ${I18n.t('Copy')}`,
        data: gradingScheme.data,
        scalingFactor: gradingScheme.scaling_factor,
        pointsBased: gradingScheme.points_based,
      },
      gradingScheme.context_type,
      gradingScheme.context_id
    )
    setCreatingGradingScheme(false)
    handleCloseDuplicateModal()
  }

  const handleCreateScheme = async (
    gradingSchemeFormInput: GradingSchemeEditableData,
    schemeContextType = contextType,
    schemeContextId = contextId
  ) => {
    if (!gradingSchemeCards) {
      return
    }
    // TODO: if (!saving) {
    try {
      const gradingScheme = await createGradingScheme(schemeContextType, schemeContextId, {
        ...gradingSchemeFormInput,
        points_based: gradingSchemeFormInput.pointsBased,
        scaling_factor: gradingSchemeFormInput.scalingFactor,
      })
      setGradingSchemeCreating(undefined)
      const updatedGradingSchemeCards = [{gradingScheme, editing: false}, ...gradingSchemeCards]
      setGradingSchemeCards(updatedGradingSchemeCards)
      showFlashSuccess(I18n.t('Grading scheme was successfully saved.'))()
      if (onGradingSchemesChanged) {
        // if parent supplied a callback method, inform parent that grading standards changed (one was added)
        onGradingSchemesChanged()
      }
    } catch (error) {
      showFlashError(I18n.t('There was an error while creating the grading scheme'))(error as Error)
    }
  }

  const handleUpdateScheme = async (
    gradingSchemeFormInput: GradingSchemeEditableData,
    gradingSchemeId: string
  ) => {
    if (!gradingSchemeCards) {
      return
    }
    // TODO: if (!saving) {

    try {
      const updatedGradingScheme = await updateGradingScheme(contextType, contextId, {
        title: gradingSchemeFormInput.title,
        data: gradingSchemeFormInput.data,
        points_based: gradingSchemeFormInput.pointsBased,
        scaling_factor: gradingSchemeFormInput.scalingFactor,
        id: gradingSchemeId,
      })

      const updatedGradingSchemeCards = gradingSchemeCards.map(gradingSchemeCard => {
        if (gradingSchemeCard.gradingScheme.id === gradingSchemeId) {
          gradingSchemeCard.gradingScheme = updatedGradingScheme
          gradingSchemeCard.editing = false
        }
        return gradingSchemeCard
      })
      setGradingSchemeCards(updatedGradingSchemeCards)
      setSelectedGradingScheme(undefined)
      setEditing(false)
      showFlashSuccess(I18n.t('Grading scheme was successfully saved.'))()
      if (onGradingSchemesChanged) {
        // if parent supplied a callback method, inform parent that grading standards changed (one was updated)
        onGradingSchemesChanged()
      }
    } catch (error) {
      showFlashError(I18n.t('There was an error while saving the grading scheme'))(error as Error)
    }
  }

  const handleArchiveScheme = async (gradingScheme: GradingScheme) => {
    if (!gradingSchemeCards) {
      return
    }
    setSelectedGradingScheme(undefined)
    try {
      await archiveGradingScheme(
        gradingScheme.context_type,
        gradingScheme.context_id,
        gradingScheme.id
      )
      showFlashSuccess(I18n.t('Grading scheme was successfully archived.'))()
      if (onGradingSchemesChanged) {
        // if parent supplied a callback method, inform parent that grading standards changed (one was archived)
        onGradingSchemesChanged()
      }
      const updatedGradingSchemeCards = gradingSchemeCards.map(gradingSchemeCard => {
        if (gradingSchemeCard.gradingScheme.id === gradingScheme.id) {
          gradingSchemeCard.gradingScheme.workflow_state = 'archived'
        }
        return gradingSchemeCard
      })
      setGradingSchemeCards(updatedGradingSchemeCards)
    } catch (error) {
      showFlashError(I18n.t('There was an error while archiving the grading scheme'))(
        error as Error
      )
    }
  }

  const handleUnarchiveScheme = async (gradingScheme: GradingScheme) => {
    if (!gradingSchemeCards) {
      return
    }
    setSelectedGradingScheme(undefined)
    try {
      await unarchiveGradingScheme(
        gradingScheme.context_type,
        gradingScheme.context_id,
        gradingScheme.id
      )
      showFlashSuccess(I18n.t('Grading scheme was successfully unarchived.'))()
      if (onGradingSchemesChanged) {
        // if parent supplied a callback method, inform parent that grading standards changed (one was unarchived)
        onGradingSchemesChanged()
      }
      const updatedGradingSchemeCards = gradingSchemeCards.map(gradingSchemeCard => {
        if (gradingSchemeCard.gradingScheme.id === gradingScheme.id) {
          gradingSchemeCard.gradingScheme.workflow_state = 'active'
        }
        return gradingSchemeCard
      })
      setGradingSchemeCards(updatedGradingSchemeCards)
    } catch (error) {
      showFlashError(I18n.t('There was an error while unarchiving the grading scheme'))(
        error as Error
      )
    }
  }

  const addNewGradingScheme = () => {
    if (!gradingSchemeCards || !defaultGradingScheme) return
    const newStandard: GradingSchemeTemplateCardData = {
      creating: true,
      gradingSchemeTemplate: defaultGradingScheme,
    }
    setGradingSchemeCreating(newStandard)
  }

  function editGradingScheme(gradingSchemeId: string) {
    if (!gradingSchemeCards) {
      throw new Error('grading scheme cards cannot be edited until after they are loaded')
    }
    if (editing) return
    setSelectedGradingScheme(undefined)
    setGradingSchemeCards(
      gradingSchemeCards.map(gradingSchemeCard => {
        if (gradingSchemeCard.gradingScheme.id === gradingSchemeId) {
          setSelectedGradingScheme(gradingSchemeCard.gradingScheme)
          setEditing(true)
          gradingSchemeCard.editing = true
        }
        return gradingSchemeCard
      })
    )
  }

  function viewUsedLocations(gradingScheme: GradingScheme) {
    setSelectedGradingScheme(gradingScheme)
    setEditing(false)
    setViewingUsedLocations(true)
  }

  function handleCancelViewUsedLocations() {
    setViewingUsedLocations(false)
    setSelectedGradingScheme(undefined)
  }

  function openDuplicateModal(gradingScheme: GradingScheme) {
    setDuplicateSchemeModalOpen(true)
    setSelectedGradingScheme(gradingScheme)
  }

  function handleCloseDuplicateModal() {
    setDuplicateSchemeModalOpen(false)
    setSelectedGradingScheme(undefined)
  }

  function openDeleteModal(gradingScheme: GradingScheme) {
    setEditing(false)
    setDeleteModalOpen(true)
    setSelectedGradingScheme(gradingScheme)
  }

  function handleCloseDeleteModal() {
    setDeleteModalOpen(false)
    setSelectedGradingScheme(undefined)
  }

  function openGradingScheme(gradingScheme: GradingScheme) {
    setSelectedGradingScheme(gradingScheme)
    setEditing(false)
  }

  function handleCancelEdit(gradingSchemeId: string) {
    if (!gradingSchemeCards) {
      throw new Error('grading scheme cards cannot be edited until after they are loaded')
    }
    setEditing(false)
    setSelectedGradingScheme(undefined)
    setGradingSchemeCards(
      gradingSchemeCards.map(gradingSchemeCard => {
        if (gradingSchemeCard.gradingScheme.id === gradingSchemeId) {
          gradingSchemeCard.editing = false
        }
        return gradingSchemeCard
      })
    )
  }

  function handleCancelCreate() {
    setGradingSchemeCreating(undefined)
  }

  function canManageScheme(gradingScheme: GradingScheme) {
    if (editing) {
      return false
    }
    if (gradingSchemeCreating) {
      return false
    }
    if (!gradingScheme.permissions.manage) {
      return false
    }
    if (!canManageAccountGradingSchemes(contextType, gradingScheme.context_type)) {
      return false
    }
    return !gradingScheme.assessed_assignment
  }
  return (
    <>
      <View>
        <Flex justifyItems="end">
          {archivedGradingSchemesEnabled && (
            <Flex.Item margin="medium small 0 0" shouldShrink={true}>
              <TextInput
                type="search"
                placeholder={I18n.t('Search...')}
                value={gradingSchemeSearch}
                onChange={e => setGradingSchemeSearch(e.target.value)}
                renderBeforeInput={() => <IconSearchLine inline={false} />}
                width="22.5rem"
                renderLabel={<ScreenReaderContent>{I18n.t('Search')}</ScreenReaderContent>}
                data-testid="grading-scheme-search"
              />
            </Flex.Item>
          )}
          <Flex.Item margin="medium 0 0 0">
            <Button
              color="primary"
              onClick={addNewGradingScheme}
              disabled={!!(gradingSchemeCreating || editing)}
              renderIcon={IconAddLine}
            >
              {I18n.t('New Grading Scheme')}
            </Button>
          </Flex.Item>
        </Flex>
      </View>
      {!gradingSchemeCards || !defaultGradingScheme ? (
        <Spinner renderTitle="Loading" size="small" margin="0 0 0 medium" />
      ) : (
        <>
          {!archivedGradingSchemesEnabled && gradingSchemeCreating ? (
            <>
              <Transition transitionOnMount={true} unmountOnExit={true} in={true} type="fade">
                <View
                  as="div"
                  display="block"
                  padding="small"
                  margin="medium none medium none"
                  borderWidth="small"
                  borderRadius="medium"
                  withVisualDebug={false}
                  key="grading-scheme-create"
                >
                  <GradingSchemeInput
                    ref={gradingSchemeCreateRef}
                    schemeInputType="percentage"
                    initialFormDataByInputType={{
                      percentage: {
                        data: defaultGradingScheme.data,
                        title: '',
                        scalingFactor: 1.0,
                        pointsBased: false,
                      },
                      points: {
                        data: defaultPointsGradingScheme.data,
                        title: '',
                        scalingFactor: defaultPointsGradingScheme.scaling_factor,
                        pointsBased: true,
                      },
                    }}
                    onSave={handleCreateScheme}
                  />
                  <hr />
                  <Flex justifyItems="end">
                    <Flex.Item>
                      <Button onClick={handleCancelCreate} margin="0 x-small 0 0">
                        {I18n.t('Cancel')}
                      </Button>
                      <Button
                        onClick={() => gradingSchemeCreateRef.current?.savePressed()}
                        color="primary"
                      >
                        {I18n.t('Save')}
                      </Button>
                    </Flex.Item>
                  </Flex>
                </View>
              </Transition>
            </>
          ) : (
            <></>
          )}
          {archivedGradingSchemesEnabled && defaultGradingScheme ? (
            <>
              <Heading
                level="h2"
                margin="medium 0"
                themeOverride={{h2FontWeight: 700, lineHeight: 1.05}}
              >
                {I18n.t('Canvas Default')}
              </Heading>
              <GradingSchemeTable
                gradingSchemeCards={[{editing: false, gradingScheme: defaultGradingScheme}]}
                caption={I18n.t('Canvas Default Grading Scheme')}
                editGradingScheme={editGradingScheme}
                openGradingScheme={openGradingScheme}
                viewUsedLocations={viewUsedLocations}
                openDuplicateModal={openDuplicateModal}
                openDeleteModal={openDeleteModal}
                archiveOrUnarchiveScheme={handleArchiveScheme}
                defaultScheme={true}
                showUsedLocations={false}
              />
              <Heading
                level="h2"
                margin="large 0 medium"
                themeOverride={{h2FontWeight: 700, lineHeight: 1.05}}
              >
                {I18n.t('Your Grading Schemes')}
              </Heading>
              <GradingSchemeTable
                gradingSchemeCards={gradingSchemeCards?.filter(
                  card =>
                    card.gradingScheme.workflow_state === 'active' &&
                    card.gradingScheme.title
                      .toLowerCase()
                      .includes(gradingSchemeSearch.toLowerCase())
                )}
                caption={I18n.t('Active Grading Schemes')}
                editGradingScheme={editGradingScheme}
                viewUsedLocations={viewUsedLocations}
                openGradingScheme={openGradingScheme}
                openDuplicateModal={openDuplicateModal}
                openDeleteModal={openDeleteModal}
                archiveOrUnarchiveScheme={handleArchiveScheme}
                showUsedLocations={!showCourseSchemesOnly}
              />

              <Heading
                level="h2"
                margin="large 0 medium"
                themeOverride={{h2FontWeight: 700, lineHeight: 1.05}}
              >
                {I18n.t('Archived')}
                <Tooltip
                  renderTip={I18n.t(
                    'Archived grading schemes in use can still be used, but cannot be added to new courses or assignments.'
                  )}
                >
                  <IconButton
                    renderIcon={IconInfoLine}
                    withBackground={false}
                    withBorder={false}
                    screenReaderLabel="Toggle tooltip"
                  />
                </Tooltip>
              </Heading>
              <GradingSchemeTable
                gradingSchemeCards={gradingSchemeCards?.filter(
                  card =>
                    card.gradingScheme.workflow_state === 'archived' &&
                    card.gradingScheme.title
                      .toLowerCase()
                      .includes(gradingSchemeSearch.toLowerCase())
                )}
                caption={I18n.t('Archived Grading Schemes')}
                editGradingScheme={editGradingScheme}
                viewUsedLocations={viewUsedLocations}
                openGradingScheme={openGradingScheme}
                openDuplicateModal={openDuplicateModal}
                openDeleteModal={openDeleteModal}
                archiveOrUnarchiveScheme={handleUnarchiveScheme}
                archivedSchemes={true}
                showUsedLocations={!showCourseSchemesOnly}
              />
              <GradingSchemeViewModal
                open={
                  selectedGradingScheme !== undefined &&
                  !editing &&
                  !viewingUsedLocations &&
                  !duplicateSchemeModalOpen &&
                  !deleteModalOpen
                }
                gradingScheme={selectedGradingScheme}
                viewingFromAccountManagementPage={true}
                handleClose={() => setSelectedGradingScheme(undefined)}
                openDeleteModal={openDeleteModal}
                editGradingScheme={editGradingScheme}
                canManageScheme={canManageScheme}
              />
              <GradingSchemeEditModal
                open={selectedGradingScheme !== undefined && editing && !viewingUsedLocations}
                gradingScheme={selectedGradingScheme}
                handleCancelEdit={handleCancelEdit}
                handleUpdateScheme={handleUpdateScheme}
                defaultGradingSchemeTemplate={defaultGradingScheme}
                defaultPointsGradingScheme={defaultPointsGradingScheme}
                openDeleteModal={openDeleteModal}
                viewingFromAccountManagementPage={true}
              />
              <GradingSchemeCreateModal
                open={!!gradingSchemeCreating}
                handleCreateScheme={handleCreateScheme}
                archivedGradingSchemesEnabled={archivedGradingSchemesEnabled}
                defaultGradingSchemeTemplate={defaultGradingScheme}
                defaultPointsGradingScheme={defaultPointsGradingScheme}
                handleCancelCreate={handleCancelCreate}
              />
              <GradingSchemeUsedLocationsModal
                open={selectedGradingScheme !== undefined && !editing && viewingUsedLocations}
                handleClose={handleCancelViewUsedLocations}
                gradingScheme={selectedGradingScheme}
              />
              <GradingSchemeDuplicateModal
                open={
                  selectedGradingScheme !== undefined &&
                  !editing &&
                  !viewingUsedLocations &&
                  duplicateSchemeModalOpen
                }
                selectedGradingScheme={selectedGradingScheme}
                handleCloseDuplicateModal={handleCloseDuplicateModal}
                handleDuplicateScheme={handleDuplicateScheme}
                creatingGradingScheme={creatingGradingScheme}
              />
              <GradingSchemeDeleteModal
                open={selectedGradingScheme !== undefined && !editing && deleteModalOpen}
                selectedGradingScheme={selectedGradingScheme}
                handleCloseDeleteModal={handleCloseDeleteModal}
                handleGradingSchemeDelete={handleGradingSchemeDelete}
                deletingGradingScheme={deletingGradingScheme}
              />
            </>
          ) : (
            gradingSchemeCards.map(gradingSchemeCard => (
              <View
                display="block"
                padding="small"
                margin="medium none medium none"
                borderWidth="small"
                borderRadius="medium"
                key={gradingSchemeCard.gradingScheme.id}
              >
                {gradingSchemeCard.editing ? (
                  <Transition transitionOnMount={true} unmountOnExit={true} in={true} type="fade">
                    <>
                      <GradingSchemeInput
                        schemeInputType={
                          gradingSchemeCard.gradingScheme.points_based ? 'points' : 'percentage'
                        }
                        initialFormDataByInputType={{
                          percentage: {
                            data: gradingSchemeCard.gradingScheme.points_based
                              ? defaultGradingScheme.data
                              : gradingSchemeCard.gradingScheme.data,
                            title: gradingSchemeCard.gradingScheme.title,
                            pointsBased: false,
                            scalingFactor: 1.0,
                          },
                          points: {
                            data: gradingSchemeCard.gradingScheme.points_based
                              ? gradingSchemeCard.gradingScheme.data
                              : defaultPointsGradingScheme.data,
                            title: gradingSchemeCard.gradingScheme.title,
                            pointsBased: true,
                            scalingFactor: gradingSchemeCard.gradingScheme.points_based
                              ? gradingSchemeCard.gradingScheme.scaling_factor
                              : defaultPointsGradingScheme.scaling_factor,
                          },
                        }}
                        ref={gradingSchemeUpdateRef}
                        onSave={modifiedGradingScheme =>
                          handleUpdateScheme(
                            modifiedGradingScheme,
                            gradingSchemeCard.gradingScheme.id
                          )
                        }
                      />
                      <hr />
                      <Flex justifyItems="end">
                        <Flex.Item>
                          <Button
                            onClick={() => handleCancelEdit(gradingSchemeCard.gradingScheme.id)}
                            margin="0 x-small 0 0"
                          >
                            {I18n.t('Cancel')}
                          </Button>
                          <Button
                            onClick={() => gradingSchemeUpdateRef.current?.savePressed()}
                            color="primary"
                          >
                            {I18n.t('Save')}
                          </Button>
                        </Flex.Item>
                      </Flex>
                    </>
                  </Transition>
                ) : (
                  <Transition transitionOnMount={true} unmountOnExit={true} in={true} type="fade">
                    <View display="block">
                      <GradingSchemeView
                        gradingScheme={gradingSchemeCard.gradingScheme}
                        archivedGradingSchemesEnabled={archivedGradingSchemesEnabled}
                        disableDelete={!canManageScheme(gradingSchemeCard.gradingScheme)}
                        disableEdit={!canManageScheme(gradingSchemeCard.gradingScheme)}
                        onDeleteRequested={() =>
                          handleGradingSchemeDelete(gradingSchemeCard.gradingScheme.id)
                        }
                        onEditRequested={() =>
                          editGradingScheme(gradingSchemeCard.gradingScheme.id)
                        }
                      />
                    </View>
                  </Transition>
                )}
              </View>
            ))
          )}
          {!archivedGradingSchemesEnabled && (
            <View
              display="block"
              padding="small"
              margin="medium none"
              borderWidth="small"
              borderRadius="small"
            >
              <View display="block">
                <GradingSchemeTemplateView
                  allowDuplicate={false}
                  onDuplicationRequested={addNewGradingScheme}
                  gradingSchemeTemplate={defaultGradingScheme}
                />
              </View>
            </View>
          )}
        </>
      )}
    </>
  )
}
