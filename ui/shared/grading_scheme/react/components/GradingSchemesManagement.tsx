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
import {Button} from '@instructure/ui-buttons'
// @ts-expect-error -- TODO: remove once we're on InstUI 8
import {IconPlusLine} from '@instructure/ui-icons'

import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {GradingSchemeView} from './view/GradingSchemeView'
import {GradingSchemeTemplateView} from './view/GradingSchemeTemplateView'
import {useGradingSchemes} from '../hooks/useGradingSchemes'
import {useDefaultGradingScheme} from '../hooks/useDefaultGradingScheme'
import {useGradingSchemeCreate} from '../hooks/useGradingSchemeCreate'
import {useGradingSchemeDelete} from '../hooks/useGradingSchemeDelete'
import {useGradingSchemeUpdate} from '../hooks/useGradingSchemeUpdate'
import {GradingScheme, GradingSchemeTemplate} from '../../gradingSchemeApiModel'

import {
  GradingSchemeFormInput,
  GradingSchemeInput,
  GradingSchemeInputHandle,
} from './form/GradingSchemeInput'

// Doing this to avoid TS2339 errors -- TODO: remove once we're on InstUI 8
const {Item} = Flex as any

const I18n = useI18nScope('GradingSchemeManagement')

interface GradingSchemeCardData {
  editing: boolean
  gradingScheme: GradingScheme
}

interface GradingSchemeTemplateCardData {
  creating: boolean
  gradingSchemeTemplate: GradingSchemeTemplate
}

interface ComponentProps {
  contextId: string
  contextType: 'Account' | 'Course'
  onGradingSchemesChanged?: () => any
}

export const GradingSchemesManagement = ({
  contextType,
  contextId,
  onGradingSchemesChanged,
}: ComponentProps) => {
  const {createGradingScheme /* createGradingSchemeStatus */} = useGradingSchemeCreate()
  const {deleteGradingScheme /* deleteGradingSchemeStatus */} = useGradingSchemeDelete()
  const {updateGradingScheme /* deleteGradingSchemeStatus */} = useGradingSchemeUpdate()

  const [gradingSchemeCards, setGradingSchemeCards] = useState<GradingSchemeCardData[] | undefined>(
    undefined
  )

  const [gradingSchemeCreating, setGradingSchemeCreating] = useState<
    GradingSchemeTemplateCardData | undefined
  >(undefined)

  const [editing, setEditing] = useState<boolean>(false)

  const {loadGradingSchemes} = useGradingSchemes()
  const {loadDefaultGradingScheme} = useDefaultGradingScheme()
  const [defaultGradingSchemeTemplate, setDefaultGradingSchemeTemplate] = useState<
    GradingSchemeTemplate | undefined
  >(undefined)

  const gradingSchemeCreateRef = useRef<GradingSchemeInputHandle>(null)
  const gradingSchemeUpdateRef = useRef<GradingSchemeInputHandle>(null)
  useEffect(() => {
    loadGradingSchemes(contextType, contextId)
      .then(gradingSchemes => {
        setGradingSchemeCards(
          gradingSchemes.map(scheme => {
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
      .then(defaultGradingScheme => {
        setDefaultGradingSchemeTemplate(defaultGradingScheme)
      })
      .catch(error => {
        showFlashError(I18n.t('There was an error while loading the default grading scheme'))(error)
      })
  }, [loadGradingSchemes, loadDefaultGradingScheme, contextType, contextId])

  const handleGradingSchemeDelete = async (gradingSchemeId: string) => {
    if (!gradingSchemeCards) return

    // TODO: is there a good inst ui component for confirmation dialog?
    if (
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
    } catch (error) {
      showFlashError(I18n.t('There was an error while removing the grading scheme'))(error as Error)
    }
  }

  const handleCreateScheme = async (gradingSchemeFormInput: GradingSchemeFormInput) => {
    if (!gradingSchemeCards) {
      return
    }
    // TODO: if (!saving) {
    try {
      const gradingScheme = await createGradingScheme(
        contextType,
        contextId,
        gradingSchemeFormInput
      )
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
    gradingSchemeFormInput: GradingSchemeFormInput,
    gradingSchemeId: string
  ) => {
    if (!gradingSchemeCards) {
      return
    }
    // TODO: if (!saving) {

    try {
      const updatedGradingScheme = await updateGradingScheme(contextType, contextId, {
        ...gradingSchemeFormInput,
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

  const addNewGradingScheme = () => {
    if (!gradingSchemeCards || !defaultGradingSchemeTemplate) return
    const newStandard: GradingSchemeTemplateCardData = {
      creating: true,
      gradingSchemeTemplate: defaultGradingSchemeTemplate,
    }
    setGradingSchemeCreating(newStandard)
  }

  function editGradingScheme(gradingSchemeId: string) {
    if (!gradingSchemeCards) {
      throw new Error('grading scheme cards cannot be edited until after they are loaded')
    }
    if (editing) return
    setEditing(true)
    setGradingSchemeCards(
      gradingSchemeCards.map(gradingSchemeCard => {
        if (gradingSchemeCard.gradingScheme.id === gradingSchemeId) {
          gradingSchemeCard.editing = true
        }
        return gradingSchemeCard
      })
    )
  }

  function handleCancelEdit(gradingSchemeId: string) {
    if (!gradingSchemeCards) {
      throw new Error('grading scheme cards cannot be edited until after they are loaded')
    }
    setEditing(false)
    setGradingSchemeCards(
      gradingSchemeCards.map(gradingSchemeCard => {
        if (gradingSchemeCard.gradingScheme.id === gradingSchemeId) {
          gradingSchemeCard.editing = false
        }
        return gradingSchemeCard
      })
    )
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
    return !gradingScheme.assessed_assignment
  }

  return (
    <>
      <View>
        <Flex justifyItems="end">
          <Item>
            <Button
              color="secondary"
              onClick={addNewGradingScheme}
              disabled={!!(gradingSchemeCreating || editing)}
            >
              <IconPlusLine />
              {I18n.t('Add grading scheme')}
            </Button>
          </Item>
        </Flex>
      </View>
      {!gradingSchemeCards || !defaultGradingSchemeTemplate ? (
        <Spinner renderTitle="Loading" size="small" margin="0 0 0 medium" />
      ) : gradingSchemeCards.length === 0 ? (
        <h3>{I18n.t('No grading schemes to display')}</h3>
      ) : (
        <>
          {gradingSchemeCreating ? (
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
                    initialFormData={{
                      data: defaultGradingSchemeTemplate.data,
                      title: '',
                    }}
                    onSave={handleCreateScheme}
                  />
                  <hr />
                  <Flex justifyItems="end">
                    <Item>
                      <Button
                        onClick={() => setGradingSchemeCreating(undefined)}
                        margin="0 x-small 0 0"
                      >
                        {I18n.t('Cancel')}
                      </Button>
                      <Button
                        onClick={() => gradingSchemeCreateRef.current?.savePressed()}
                        color="primary"
                      >
                        {I18n.t('Save')}
                      </Button>
                    </Item>
                  </Flex>
                </View>
              </Transition>
            </>
          ) : (
            <></>
          )}
          {gradingSchemeCards.map(gradingSchemeCard => (
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
                      ref={gradingSchemeUpdateRef}
                      initialFormData={{
                        data: gradingSchemeCard.gradingScheme.data,
                        title: gradingSchemeCard.gradingScheme.title,
                      }}
                      onSave={modifiedGradingScheme =>
                        handleUpdateScheme(
                          modifiedGradingScheme,
                          gradingSchemeCard.gradingScheme.id
                        )
                      }
                    />
                    <hr />
                    <Flex justifyItems="end">
                      <Item>
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
                      </Item>
                    </Flex>
                  </>
                </Transition>
              ) : (
                <Transition transitionOnMount={true} unmountOnExit={true} in={true} type="fade">
                  <View display="block">
                    <GradingSchemeView
                      gradingScheme={gradingSchemeCard.gradingScheme}
                      disableDelete={!canManageScheme(gradingSchemeCard.gradingScheme)}
                      disableEdit={!canManageScheme(gradingSchemeCard.gradingScheme)}
                      onDeleteRequested={() =>
                        handleGradingSchemeDelete(gradingSchemeCard.gradingScheme.id)
                      }
                      onEditRequested={() => editGradingScheme(gradingSchemeCard.gradingScheme.id)}
                    />
                  </View>
                </Transition>
              )}
            </View>
          ))}
          <View
            display="block"
            padding="small"
            margin="0 0 small"
            borderWidth="small"
            borderRadius="small"
          >
            <View display="block">
              <GradingSchemeTemplateView
                allowDuplicate={false}
                onDuplicationRequested={addNewGradingScheme}
                gradingSchemeTemplate={defaultGradingSchemeTemplate}
              />
            </View>
          </View>
        </>
      )}
    </>
  )
}
