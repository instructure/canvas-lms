/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useQuery} from '@tanstack/react-query'
import {useEffect} from 'react'
import {getGradingRubricContexts} from '../../queries'
import {Heading} from '@instructure/ui-heading'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {View} from '@instructure/ui-view'
import {LoadingIndicator} from '@instructure/platform-loading-indicator'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import {GradingRubricContext} from '../../types/rubricAssignment'

const I18n = createI18nScope('enhanced-rubrics-assignment-search')

type RubricContextSelectProps = {
  courseId: string
  selectedContext?: string
  handleChangeContext: (context: string, rubricsCount: number) => void
  setSelectedContext: (context: string) => void
  setSelectedRubricCount: (count: number) => void
}
export const RubricContextSelect = ({
  courseId,
  selectedContext,
  handleChangeContext,
  setSelectedContext,
  setSelectedRubricCount,
}: RubricContextSelectProps) => {
  const {
    data: rubricContexts = [],
    isLoading,
    isSuccess,
  } = useQuery({
    queryKey: ['fetchGradingRubricContexts', courseId],
    queryFn: getGradingRubricContexts,
  })

  useEffect(() => {
    if (rubricContexts.length > 0) {
      const matchingCourseContext = rubricContexts.find(
        x => x.context_code === `course_${courseId}`,
      )

      if (matchingCourseContext) {
        setSelectedContext(matchingCourseContext.context_code)
        setSelectedRubricCount(matchingCourseContext.rubrics || 0)
      } else {
        setSelectedContext(rubricContexts[0]?.context_code)
        setSelectedRubricCount(rubricContexts[0]?.rubrics || 0)
      }
    }
  }, [rubricContexts, courseId, setSelectedContext, setSelectedRubricCount])

  const contextPrefix = (contextCode: string) => {
    if (contextCode.startsWith('account_')) {
      return I18n.t('Account')
    } else if (contextCode.startsWith('course_')) {
      return I18n.t('Course')
    }

    return ''
  }

  const getContextName = (context: GradingRubricContext) => {
    return `${context.name} (${contextPrefix(context.context_code)})`
  }

  if (isSuccess && rubricContexts.length === 0) {
    return (
      <View as="div">
        <Heading level="h3">{I18n.t('No Rubrics Found')}</Heading>
      </View>
    )
  }

  if (isLoading) {
    return <LoadingIndicator />
  }

  return (
    <SimpleSelect
      renderLabel={<ScreenReaderContent>{I18n.t('select account or course')}</ScreenReaderContent>}
      value={selectedContext}
      onChange={(_, {value}) => {
        const selected = rubricContexts.find(context => context.context_code === value)
        handleChangeContext(value as string, selected?.rubrics || 0)
      }}
      data-testid="rubric-context-select"
    >
      {rubricContexts.map(context => (
        <SimpleSelect.Option
          key={context.context_code}
          id={`opt-${context.context_code}`}
          value={context.context_code}
        >
          {getContextName(context)}
        </SimpleSelect.Option>
      ))}
    </SimpleSelect>
  )
}
