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
import React, {useRef} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import type {GradingScheme, GradingSchemeTemplate} from '../../gradingSchemeApiModel'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {
  type GradingSchemeEditableData,
  GradingSchemeInput,
  type GradingSchemeInputHandle,
} from './form/GradingSchemeInput'

const I18n = useI18nScope('GradingSchemeViewModal')

type Props = {
  open: boolean
  gradingScheme?: GradingScheme
  handleCancelEdit: (gradingSchemeId: string) => void
  handleGradingSchemeDelete: (gradingSchemeId: string) => void
  handleUpdateScheme: (
    gradingSchemeFormInput: GradingSchemeEditableData,
    gradingSchemeId: string
  ) => void
  defaultGradingSchemeTemplate: GradingScheme
  defaultPointsGradingScheme: GradingSchemeTemplate
  archivedGradingSchemesEnabled: boolean
}
const GradingSchemeEditModal = ({
  open,
  gradingScheme,
  handleCancelEdit,
  handleGradingSchemeDelete,
  handleUpdateScheme,
  archivedGradingSchemesEnabled,
  defaultGradingSchemeTemplate,
  defaultPointsGradingScheme,
}: Props) => {
  const gradingSchemeUpdateRef = useRef<GradingSchemeInputHandle>(null)
  if (!gradingScheme) {
    return <></>
  }

  return (
    <Modal
      as="form"
      open={open}
      onDismiss={() => handleCancelEdit(gradingScheme.id)}
      label={I18n.t('Edit Grading Scheme')}
      size="small"
    >
      <Modal.Header>
        <CloseButton
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="small"
          onClick={() => handleCancelEdit(gradingScheme.id)}
        />
        <Heading>{gradingScheme.title}</Heading>
      </Modal.Header>
      <Modal.Body>
        <GradingSchemeInput
          schemeInputType={gradingScheme.points_based ? 'points' : 'percentage'}
          initialFormDataByInputType={{
            percentage: {
              data: gradingScheme.points_based
                ? defaultGradingSchemeTemplate.data
                : gradingScheme.data,
              title: gradingScheme.title,
              pointsBased: false,
              scalingFactor: 1.0,
            },
            points: {
              data: gradingScheme.points_based
                ? gradingScheme.data
                : defaultPointsGradingScheme.data,
              title: gradingScheme.title,
              pointsBased: true,
              scalingFactor: gradingScheme.points_based
                ? gradingScheme.scaling_factor
                : defaultPointsGradingScheme.scaling_factor,
            },
          }}
          ref={gradingSchemeUpdateRef}
          archivedGradingSchemesEnabled={archivedGradingSchemesEnabled}
          onSave={modifiedGradingScheme =>
            handleUpdateScheme(modifiedGradingScheme, gradingScheme.id)
          }
        />
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end">
          <Flex.Item>
            <Button onClick={() => handleGradingSchemeDelete(gradingScheme.id)}>
              {I18n.t('Delete')}
            </Button>
            <Button onClick={() => handleCancelEdit(gradingScheme.id)} margin="0 x-small 0 x-small">
              {I18n.t('Cancel')}
            </Button>
            <Button onClick={() => gradingSchemeUpdateRef.current?.savePressed()} color="primary">
              {I18n.t('Save')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default GradingSchemeEditModal
