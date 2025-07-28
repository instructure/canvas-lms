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

import React, {useEffect, useState, useRef} from 'react'
import {Link} from '@instructure/ui-link'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconSearchLine, IconTroubleLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {type GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = createI18nScope('block-editor')
declare const ENV: GlobalEnv

interface QuizSelectProps {
  onSelect: (quiz: any) => void
}

const QuizSelect: React.FC<QuizSelectProps> = ({onSelect}) => {
  const [quizzes, setQuizzes] = useState<any[]>([])
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)
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

  useEffect(() => {
    const fetchQuizzes = async () => {
      try {
        const response = await doFetchApi({
          path: `/api/quiz/v1/courses/${ENV.COURSE_ID}/quizzes/`,
        })
        const data = response.json
        if (Array.isArray(data)) {
          setQuizzes(data)
        } else {
          setError(I18n.t('Unexpected response format'))
        }
      } catch (_err) {
        setError(I18n.t('Failed to fetch quizzes'))
      } finally {
        setLoading(false)
      }
    }

    fetchQuizzes()
  }, [])

  if (loading) {
    return (
      <div>
        <Spinner renderTitle={I18n.t('Loading')} size="x-small" /> {I18n.t('Loading...')}
      </div>
    )
  }

  if (error) {
    return <div>{error}</div>
  }

  const filteredQuizzes = quizzes.filter(quiz =>
    quiz.title.toLowerCase().includes(value.toLowerCase()),
  )

  const handleQuizSelect = (quiz: any) => {
    onSelect(quiz)
  }

  return (
    <View as="div">
      <form name="searchQuizzes" autoComplete="off">
        <TextInput
          renderLabel={<ScreenReaderContent>{I18n.t('Search quizzes')}</ScreenReaderContent>}
          placeholder={I18n.t('Search...')}
          value={value}
          onChange={handleChange}
          inputRef={el => (inputRef.current = el)}
          renderBeforeInput={<IconSearchLine inline={false} />}
          renderAfterInput={renderClearButton()}
          shouldNotWrap={true}
        />
      </form>

      {filteredQuizzes.length === 0 && <div>{I18n.t('No quizzes found.')}</div>}
      {filteredQuizzes.map(quiz => (
        <View as="div" margin="x-small" key={quiz.id}>
          <Link href="#" onClick={() => handleQuizSelect(quiz)}>
            {quiz.title}
          </Link>
        </View>
      ))}
    </View>
  )
}

export default QuizSelect
