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
import {GradingScheme, GradingSchemeTemplate} from '@canvas/grading_scheme/gradingSchemeApiModel'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {
  GradingSchemeEditableData,
  GradingSchemeInput,
  GradingSchemeInputHandle,
} from './form/GradingSchemeInput'

const I18n = useI18nScope('GradingSchemeViewModal')

type Props = {
  open: boolean
  handleCreateScheme: (gradingSchemeFormInput: GradingSchemeEditableData) => Promise<void>
  defaultGradingSchemeTemplate: GradingScheme
  defaultPointsGradingScheme: GradingSchemeTemplate
  pointsBasedGradingSchemesEnabled: boolean
  archivedGradingSchemesEnabled: boolean
  handleCancelCreate: () => void
}
const GradingSchemeCreateModal = ({
  open,
  handleCreateScheme,
  pointsBasedGradingSchemesEnabled,
  archivedGradingSchemesEnabled,
  defaultGradingSchemeTemplate,
  defaultPointsGradingScheme,
  handleCancelCreate,
}: Props) => {
  const gradingSchemeCreateRef = useRef<GradingSchemeInputHandle>(null)
  if (!defaultGradingSchemeTemplate) {
    return <></>
  }

  return (
    <Modal
      as="form"
      open={open}
      onDismiss={handleCancelCreate}
      label={I18n.t('New Grading Scheme')}
      size="small"
    >
      <Modal.Header>
        <CloseButton
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="small"
          onClick={handleCancelCreate}
        />
        <Heading>{I18n.t('New Grading Scheme')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <GradingSchemeInput
          schemeInputType="percentage"
          initialFormDataByInputType={{
            percentage: {
              data: defaultGradingSchemeTemplate.data,
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
          ref={gradingSchemeCreateRef}
          pointsBasedGradingSchemesFeatureEnabled={pointsBasedGradingSchemesEnabled}
          archivedGradingSchemesEnabled={archivedGradingSchemesEnabled}
          onSave={handleCreateScheme}
        />
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end">
          <Flex.Item>
            <Button onClick={handleCancelCreate} margin="0 x-small">
              {I18n.t('Cancel')}
            </Button>
            <Button onClick={() => gradingSchemeCreateRef.current?.savePressed()} color="primary">
              {I18n.t('Save')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default GradingSchemeCreateModal
