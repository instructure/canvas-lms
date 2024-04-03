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
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {Spinner} from '@instructure/ui-spinner'

import {useGradingSchemeCreate} from '../hooks/useGradingSchemeCreate'
import {useDefaultGradingScheme} from '../hooks/useDefaultGradingScheme'
import {
  GradingSchemeInput,
  type GradingSchemeEditableData,
  type GradingSchemeInputHandle,
} from './form/GradingSchemeInput'
import type {GradingScheme, GradingSchemeSummary} from '../../gradingSchemeApiModel'
import {GradingSchemeTemplateView} from './view/GradingSchemeTemplateView'
import {defaultPointsGradingScheme} from '../../defaultPointsGradingScheme'

const I18n = useI18nScope('GradingSchemeManagement')

export interface ComponentProps {
  contextType: 'Account' | 'Course'
  contextId: string
  allowDuplication: boolean
  onCreate?: (gradingSchemeSummary: GradingSchemeSummary) => any
  onCancel: () => any
}

export const GradingSchemeViewCopyTemplateModal = ({
  contextType,
  contextId,
  onCreate,
  onCancel,
  allowDuplication,
}: ComponentProps) => {
  const {createGradingScheme /* deleteGradingSchemeStatus */} = useGradingSchemeCreate()
  const {loadDefaultGradingScheme /* deleteGradingSchemeStatus */} = useDefaultGradingScheme()
  const [defaultCanvasGradingSchemeTemplate, setDefaultCanvasGradingSchemeTemplate] = useState<
    GradingScheme | undefined
  >(undefined)
  const [copying, setCopying] = useState<boolean>(false)
  const toggleCopying = () => {
    setCopying(!copying)
  }
  const gradingSchemeCreateRef = useRef<GradingSchemeInputHandle>(null)

  useEffect(() => {
    loadDefaultGradingScheme(contextType, contextId)
      .then(defaultCanvasTemplate => {
        setDefaultCanvasGradingSchemeTemplate(defaultCanvasTemplate)
      })
      .catch(error => {
        showFlashError(
          I18n.t('There was an error while loading the default canvas grading scheme')
        )(error)
      })
    return () => {
      // this is called when the component unmounts
    }
  }, [contextType, contextId, loadDefaultGradingScheme])
  const handleCreateScheme = async (gradingSchemeFormInput: GradingSchemeEditableData) => {
    if (!defaultCanvasGradingSchemeTemplate) return
    // TODO: if (!saving) {

    try {
      const createdGradingScheme = await createGradingScheme(contextType, contextId, {
        ...gradingSchemeFormInput,
        points_based: gradingSchemeFormInput.pointsBased,
        scaling_factor: gradingSchemeFormInput.scalingFactor,
      })

      setCopying(false)
      showFlashSuccess(I18n.t('Grading scheme was successfully created.'))()
      if (onCreate) {
        // if parent supplied a callback method, inform parent that grading scheme was created
        onCreate({
          title: createdGradingScheme.title,
          id: createdGradingScheme.id,
          context_type: createdGradingScheme.context_type,
        })
      }
    } catch (error) {
      showFlashError(I18n.t('There was an error while creating the grading scheme'))(error as Error)
    }
  }

  const cancelPressed = () => {
    if (onCancel) {
      onCancel()
    }
  }

  return (
    <>
      <Modal
        open={true}
        size="medium"
        label={
          allowDuplication ? I18n.t('View/Copy Grading Scheme') : I18n.t('View Grading Scheme')
        }
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
            {allowDuplication ? I18n.t('View/Copy Grading Scheme') : I18n.t('View Grading Scheme')}
          </Heading>
        </Modal.Header>
        <Modal.Body>
          {defaultCanvasGradingSchemeTemplate ? (
            <>
              {copying ? (
                <GradingSchemeInput
                  ref={gradingSchemeCreateRef}
                  schemeInputType="percentage"
                  initialFormDataByInputType={{
                    percentage: {
                      data: defaultCanvasGradingSchemeTemplate.data,
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
                  onSave={modifiedGradingScheme => handleCreateScheme(modifiedGradingScheme)}
                />
              ) : (
                <GradingSchemeTemplateView
                  allowDuplicate={allowDuplication}
                  onDuplicationRequested={toggleCopying}
                  key="1"
                  gradingSchemeTemplate={defaultCanvasGradingSchemeTemplate}
                />
              )}
            </>
          ) : (
            <>
              <Spinner renderTitle="Loading" size="x-small" />
            </>
          )}
        </Modal.Body>
        <Modal.Footer>
          {copying ? (
            <>
              <Button onClick={toggleCopying} margin="0 x-small 0 0">
                {I18n.t('Cancel')}
              </Button>
              <Button
                onClick={() => gradingSchemeCreateRef.current?.savePressed()}
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
    </>
  )
}
