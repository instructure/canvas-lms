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

import React, {useCallback, useEffect, useState} from 'react'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('content_migrations_redesign')

type QuestionBank = {
  // eslint-disable-next-line react/no-unused-prop-types
  assessment_question_bank: {
    id: number
    title: string
  }
}

export type QuestionBankSettings = {
  question_bank_id?: string | number
  question_bank_name?: string
}

type QuestionBankSelectorProps = {
  onChange: (settings: QuestionBankSettings | null) => void
  questionBankError: boolean
  disable?: boolean
  notCompatible?: boolean
  questionBankSettings?: QuestionBankSettings | null
}

const QuestionBankSelector = ({
  onChange,
  questionBankError,
  disable = false,
  notCompatible = false,
  questionBankSettings,
}: QuestionBankSelectorProps) => {
  const [showQuestionInput, setShowQuestionInput] = useState<boolean>(false)
  const questionBanks = ENV.QUESTION_BANKS || []

  const handleChange = useCallback(
    (_, {value}) => {
      setShowQuestionInput(value === 'new_question_bank')
      if (!value) {
        onChange(null)
      } else {
        onChange({...questionBankSettings, question_bank_id: value})
      }
    },
    [onChange, questionBankSettings]
  )

  useEffect(() => {
    if (notCompatible) {
      setShowQuestionInput(false)
      onChange(null)
    }
  }, [notCompatible, onChange])

  return (
    <>
      <View as="div" margin="medium 0" maxWidth="22.5rem">
        <SimpleSelect
          data-testid="questionBankSelect"
          renderLabel={I18n.t('Default Question bank')}
          assistiveText={I18n.t('Select a question bank')}
          onChange={handleChange}
          disabled={disable}
          value={questionBankSettings?.question_bank_id || ''}
        >
          <SimpleSelect.Option id="selectQuestion" value="">
            {I18n.t('Select question bank')}
          </SimpleSelect.Option>
          <SimpleSelect.Option id="createQuestion" value="new_question_bank">
            {I18n.t('Create new question bank...')}
          </SimpleSelect.Option>
          {questionBanks.map(({assessment_question_bank: {id, title}}: QuestionBank) => (
            <SimpleSelect.Option key={id} id={id.toString()} value={id}>
              {title}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>
        {!!notCompatible && (
          <Text lineHeight="double">
            {I18n.t('This option is not compatible with New Quizzes')}
          </Text>
        )}
      </View>
      {showQuestionInput && (
        <View as="div" maxWidth="22.5rem">
          <TextInput
            disabled={disable}
            messages={
              questionBankError
                ? [
                    {
                      text: (
                        <Text color="danger">
                          {I18n.t('You must enter a name for the new question bank')}
                        </Text>
                      ),
                      type: 'error',
                    },
                  ]
                : []
            }
            renderLabel={<></>}
            placeholder={I18n.t('New question bank')}
            onChange={(_, value) => onChange({...questionBankSettings, question_bank_name: value})}
          />
        </View>
      )}
    </>
  )
}

export default QuestionBankSelector
