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
// @ts-expect-error -- TODO: remove once we're on InstUI 8
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'

import {GradingSchemeView} from './view/GradingSchemeView'
import {useGradingSchemeUpdate} from '../hooks/useGradingSchemeUpdate'
import {useGradingSchemeDelete} from '../hooks/useGradingSchemeDelete'
import {useGradingScheme} from '../hooks/useGradingScheme'
import {
  GradingSchemeInput,
  GradingSchemeFormInput,
  GradingSchemeInputHandle,
} from './form/GradingSchemeInput'
import {GradingScheme, GradingSchemeSummary} from '../../gradingSchemeApiModel'

const I18n = useI18nScope('GradingSchemeManagement')

export interface ComponentProps {
  contextType: 'Account' | 'Course'
  contextId: string
  gradingSchemeId: string
  onUpdate?: (gradingSchemeSummary: GradingSchemeSummary) => any
  onCancel: () => any
  onDelete?: () => any
}

export const GradingSchemeViewEditModal: React.FC<ComponentProps> = ({
  contextType,
  contextId,
  gradingSchemeId,
  onUpdate,
  onCancel,
  onDelete,
}) => {
  const {updateGradingScheme /* deleteGradingSchemeStatus */} = useGradingSchemeUpdate()
  const {deleteGradingScheme /* deleteGradingSchemeStatus */} = useGradingSchemeDelete()
  const {loadGradingScheme /* deleteGradingSchemeStatus */} = useGradingScheme()
  const [gradingScheme, setGradingScheme] = useState<GradingScheme | undefined>(undefined)
  const [editing, setEditing] = useState<boolean>(false)
  const toggleEditing = () => {
    setEditing(!editing)
  }
  const gradingSchemeUpdateRef = useRef<GradingSchemeInputHandle>(null)

  useEffect(() => {
    loadGradingScheme(contextType, contextId, gradingSchemeId)
      .then(loadedGradingScheme => {
        setGradingScheme(loadedGradingScheme)
      })
      .catch(error => {
        showFlashError(I18n.t('There was an error while loading grading schemes'))(error)
      })
    return () => {
      // this is called when the component unmounts
    }
  }, [contextType, contextId, loadGradingScheme, gradingSchemeId])
  const handleUpdateScheme = async (gradingSchemeFormInput: GradingSchemeFormInput) => {
    if (!gradingScheme) return
    // TODO: if (!saving) {

    try {
      const updatedGradingScheme = await updateGradingScheme(
        gradingScheme.context_type,
        gradingScheme.context_id,
        {
          ...gradingSchemeFormInput,
          id: gradingScheme.id,
        }
      )

      setEditing(false)
      showFlashSuccess(I18n.t('Grading scheme was successfully saved.'))()
      setGradingScheme(updatedGradingScheme)
      if (onUpdate) {
        // if parent supplied a callback method, inform parent that grading standard was updated
        onUpdate({title: updatedGradingScheme.title, id: updatedGradingScheme.id})
      }
    } catch (error) {
      showFlashError(I18n.t('There was an error while updating the grading scheme'))(error as Error)
    }
  }

  const handleGradingSchemeDelete = async () => {
    if (!gradingScheme) return

    // TODO: is there a good inst ui component for confirmation dialog?
    if (
      // eslint-disable-next-line no-alert
      !window.confirm(
        I18n.t('confirm.delete', 'Are you sure you want to delete this grading scheme?')
      )
    ) {
      return
    }
    try {
      await deleteGradingScheme(
        gradingScheme.context_type,
        gradingScheme.context_id,
        gradingScheme.id
      )
      showFlashSuccess(I18n.t('Grading scheme was successfully removed.'))()
      if (onDelete) {
        // if parent supplied a callback method, inform parent that grading scheme was deleted
        onDelete()
      }
    } catch (error) {
      showFlashError(I18n.t('There was an error while removing the grading scheme'))(error as Error)
    }
  }

  const cancelPressed = () => {
    if (onCancel) {
      onCancel()
    }
  }

  function canManageScheme(scheme: GradingScheme | undefined) {
    if (!scheme) return false
    if (!scheme.permissions.manage) {
      return false
    }
    return !scheme.assessed_assignment
  }

  const canManage = canManageScheme(gradingScheme)

  return (
    <>
      {gradingScheme ? (
        <Modal
          open={true}
          size="medium"
          label={canManage ? I18n.t('View/Edit Grading Scheme') : I18n.t('View Grading Scheme')}
          shouldCloseOnDocumentClick={true}
        >
          <Modal.Header>
            <CloseButton
              placement="end"
              offset="small"
              onClick={cancelPressed}
              screenReaderLabel={I18n.t('Close')}
            />
            <Heading>
              {canManage ? I18n.t('View/Edit Grading Scheme') : I18n.t('View Grading Scheme')}
            </Heading>
          </Modal.Header>
          <Modal.Body>
            <>
              {editing ? (
                <GradingSchemeInput
                  ref={gradingSchemeUpdateRef}
                  initialFormData={{
                    data: gradingScheme.data,
                    title: gradingScheme.title,
                  }}
                  onSave={modifiedGradingScheme => handleUpdateScheme(modifiedGradingScheme)}
                />
              ) : (
                <GradingSchemeView
                  disableEdit={!canManageScheme(gradingScheme)}
                  disableDelete={!canManageScheme(gradingScheme)}
                  onEditRequested={toggleEditing}
                  onDeleteRequested={handleGradingSchemeDelete}
                  key="1"
                  gradingScheme={gradingScheme}
                />
              )}
            </>
          </Modal.Body>
          <Modal.Footer>
            {editing ? (
              <>
                <Button onClick={toggleEditing} margin="0 x-small 0 0">
                  {I18n.t('Cancel')}
                </Button>
                <Button
                  onClick={() => gradingSchemeUpdateRef.current?.savePressed()}
                  color="primary"
                  type="submit"
                >
                  {I18n.t('Save')}
                </Button>
              </>
            ) : (
              <Button onClick={cancelPressed} margin="0 x-small 0 0">
                {I18n.t('Close')}
              </Button>
            )}
          </Modal.Footer>
        </Modal>
      ) : (
        <></>
      )}
    </>
  )
}
