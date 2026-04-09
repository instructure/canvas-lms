/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useState} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Text} from '@instructure/ui-text'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import {RegradeOption} from './QuizRegradeModal.utils'

const I18n = createI18nScope('quizzes_regrade_modal')

export interface QuizRegradeModalProps {
  open: boolean
  regradeDisabled: boolean
  regradeOption?: RegradeOption
  multipleAnswer: boolean
  onUpdate: (selectedOption: RegradeOption) => void
  onDismiss: () => void
}

export default function QuizRegradeModal({
  open,
  regradeDisabled,
  regradeOption,
  multipleAnswer,
  onUpdate,
  onDismiss,
}: QuizRegradeModalProps) {
  const [selectedOption, setSelectedOption] = useState<RegradeOption | undefined>(regradeOption)

  const handleUpdate = () => {
    if (!selectedOption) return

    onUpdate(selectedOption)
  }

  const updateDisabled = regradeDisabled || !selectedOption

  return (
    <Modal open={open} onDismiss={onDismiss} size="medium" label={I18n.t('Regrade options modal')}>
      <Modal.Header>
        <CloseButton placement="end" onClick={onDismiss} screenReaderLabel={I18n.t('Close')} />
        <Heading>{I18n.t('Regrade Options')}</Heading>
      </Modal.Header>

      <Modal.Body>
        <Alert
          variant="warning"
          margin="0 0 medium 0"
          transition="none"
          data-testid="regrade-warning"
        >
          {I18n.t(
            "Choose a regrade option for students who have already taken the quiz. Canvas will regrade all your submissions after you save the quiz (students' scores MAY be affected).",
          )}
        </Alert>

        {regradeDisabled ? (
          <Text>
            {I18n.t(
              'Regrading is not allowed on this question because either an answer was removed or the question type was changed after a student completed a submission.',
            )}
          </Text>
        ) : (
          <RadioInputGroup
            name="regrade_option"
            description={<ScreenReaderContent>{I18n.t('Regrade options')}</ScreenReaderContent>}
            value={selectedOption}
            onChange={(_event, value) => setSelectedOption(value as RegradeOption)}
          >
            {!multipleAnswer && (
              <RadioInput
                value={RegradeOption.CurrentAndPreviousCorrect}
                label={I18n.t(
                  'Award points for both corrected and previously correct answers (no scores will be reduced)',
                )}
              />
            )}
            <RadioInput
              value={RegradeOption.CurrentCorrectOnly}
              label={I18n.t(
                "Only award points for the correct answer (some students' scores may be reduced)",
              )}
            />
            <RadioInput
              value={RegradeOption.FullCredit}
              label={I18n.t('Give everyone full credit for this question')}
            />
            <RadioInput
              value={RegradeOption.NoRegrade}
              label={I18n.t('Update question without regrading')}
            />
          </RadioInputGroup>
        )}
      </Modal.Body>

      <Modal.Footer>
        <Flex gap="buttons">
          <Button onClick={onDismiss}>{I18n.t('Cancel')}</Button>
          <Button
            type="button"
            color="primary"
            onClick={handleUpdate}
            interaction={updateDisabled ? 'disabled' : 'enabled'}
            data-testid="update-button"
          >
            {I18n.t('Update')}
          </Button>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
