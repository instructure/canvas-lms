/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {Alert} from '@instructure/ui-alerts'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {useState} from 'react'

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import LoadingIndicator from '@canvas/loading-indicator'

const I18n = useI18nScope('discussion_topics_post')

export const REPORT_TYPES = [
  {value: 'inappropriate', getLabel: () => I18n.t('Inappropriate')},
  {value: 'offensive', getLabel: () => I18n.t('Offensive, abusive')},
  {value: 'other', getLabel: () => I18n.t('Other')},
]

export const ReportReply = props => {
  const [selectedReportType, setSelectedReportType] = useState('')

  const onClose = () => {
    setSelectedReportType('')
    props.onCloseReportModal()
  }

  return (
    <Modal
      open={props.showReportModal}
      onDismiss={onClose}
      size="medium"
      label={I18n.t('Report Reply')}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Report Reply')}</Heading>
      </Modal.Header>
      <Modal.Body>
        {props.errorSubmitting && (
          <Alert margin="small" variant="error" timeout={2500}>
            {I18n.t('We experienced an issue. This reply was not reported.')}
          </Alert>
        )}
        {props.isLoading ? (
          <LoadingIndicator />
        ) : (
          <>
            <View as="div" margin="0 0 medium 0">
              <Text>
                {I18n.t(
                  'Reported replies will be sent to your teacher for review. You will not be able to undo this action.'
                )}
              </Text>
            </View>
            <RadioInputGroup
              name={I18n.t('Report Reply Options')}
              onChange={event => {
                setSelectedReportType(event.target.value)
              }}
              description={I18n.t('Please select a reason for reporting this reply')}
            >
              {REPORT_TYPES.map(reportType => (
                <RadioInput
                  key={reportType.value}
                  value={reportType.value}
                  label={reportType.getLabel()}
                />
              ))}
            </RadioInputGroup>
          </>
        )}
      </Modal.Body>
      <Modal.Footer>
        <span className="discussions-report-cancel">
          <Button
            data-testid="report-reply-cancel-modal-button"
            onClick={onClose}
            margin="0 x-small 0 0"
            interaction={!props.isLoading ? 'enabled' : 'disabled'}
          >
            {I18n.t('Cancel')}
          </Button>
        </span>
        <span className="discussions-report-submit">
          <Button
            data-testid="report-reply-submit-button"
            color="danger"
            onClick={() => props.onSubmit(selectedReportType)}
            interaction={selectedReportType && !props.isLoading ? 'enabled' : 'disabled'}
          >
            {I18n.t('Submit')}
          </Button>
        </span>
      </Modal.Footer>
    </Modal>
  )
}

ReportReply.propTypes = {
  onCloseReportModal: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  showReportModal: PropTypes.bool,
  isLoading: PropTypes.bool,
  errorSubmitting: PropTypes.bool,
}

ReportReply.defaultProps = {
  showReportModal: false,
  isLoading: false,
  errorSubmitting: false,
}
