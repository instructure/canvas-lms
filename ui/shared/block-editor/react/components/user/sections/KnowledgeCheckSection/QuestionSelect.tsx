/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconButton} from '@instructure/ui-buttons'
import {IconSearchLine, IconTroubleLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {type QuestionProps} from './types'
import QuestionToggle from './QuestionToggle'

const I18n = createI18nScope('block-editor')

interface QuestionSelectProps {
  onSelect: (question: QuestionProps) => void
  questions: QuestionProps[] | null
}

const QuestionSelect: React.FC<QuestionSelectProps> = ({onSelect, questions}) => {
  const [value, setValue] = useState<string>('')
  const inputRef = useRef<HTMLInputElement | null>(null)

  const handleChange = (_e: any, newValue: string) => {
    setValue(newValue)
  }

  const renderClearButton = () => {
    return value ? (
      <IconButton
        type="button"
        size="small"
        withBackground={false}
        withBorder={false}
        screenReaderLabel={I18n.t('Clear search')}
        title={I18n.t('Clear search')}
        onClick={() => setValue('')}
      >
        <IconTroubleLine />
      </IconButton>
    ) : null
  }

  if (questions === null) {
    return (
      <View as="div">
        <Spinner renderTitle={I18n.t('Loading')} size="x-small" /> {I18n.t('Loading...')}
      </View>
    )
  }

  if (questions.length === 0) {
    return <div>{I18n.t('No questions found.')}</div>
  }

  const filteredQuestions =
    value.length > 0
      ? questions.filter(
          question =>
            question.entry.title?.toLowerCase().includes(value.toLowerCase()) ||
            question.entry.item_body?.toLowerCase().includes(value.toLowerCase()),
        )
      : questions

  return (
    <View as="div">
      <form name="searchQuestions" autoComplete="off">
        <TextInput
          renderLabel={<ScreenReaderContent>{I18n.t('Search questions')}</ScreenReaderContent>}
          placeholder={I18n.t('Search questions...')}
          value={value}
          onChange={handleChange}
          inputRef={el => (inputRef.current = el)}
          renderBeforeInput={<IconSearchLine inline={false} />}
          renderAfterInput={renderClearButton()}
          shouldNotWrap={true}
        />
      </form>

      {filteredQuestions.map(question => (
        <View as="div" margin="x-small" key={question.id}>
          {/* @ts-expect-error */}
          <QuestionToggle question={question} onSelect={onSelect} />
        </View>
      ))}
    </View>
  )
}

export default QuestionSelect
