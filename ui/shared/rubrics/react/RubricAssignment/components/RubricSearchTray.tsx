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

import React, {useEffect, useState} from 'react'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import LoadingIndicator from '@canvas/loading-indicator'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TextInput} from '@instructure/ui-text-input'
import {IconAddLine, IconArrowOpenEndLine, IconSearchLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {getGradingRubricContexts, getGradingRubricsForContext} from '../queries'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {RadioInput} from '@instructure/ui-radio-input'
import type {GradingRubricContext} from '../types/rubricAssignment'
import type {Rubric, RubricAssociation} from '../../types/rubric'
import {possibleString} from '../../Points'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useQuery} from '@tanstack/react-query'

const I18n = createI18nScope('enhanced-rubrics-assignment-search')

type RubricSearchTrayProps = {
  courseId: string
  isOpen: boolean
  onPreview: (rubric: Rubric) => void
  onDismiss: () => void
  onAddRubric: (rubricId: string, updatedAssociation: RubricAssociation) => void
}
export const RubricSearchTray = ({
  courseId,
  isOpen,
  onPreview,
  onDismiss,
  onAddRubric,
}: RubricSearchTrayProps) => {
  const [search, setSearch] = useState<string>('')
  const [selectedContext, setSelectedContext] = useState<string>()
  const [selectedAssociation, setSelectedAssociation] = useState<RubricAssociation>()
  const [selectedRubricId, setSelectedRubricId] = useState<string>()

  useEffect(() => {
    if (isOpen) {
      setSearch('')
      setSelectedAssociation(undefined)
      setSelectedRubricId(undefined)
    }
  }, [isOpen])

  const handleChangeContext = (contextCode: string) => {
    setSelectedContext(contextCode)
    setSelectedAssociation(undefined)
    setSelectedRubricId(undefined)
  }

  return (
    <Tray
      label={I18n.t('Rubric Search Tray')}
      open={isOpen}
      onDismiss={onDismiss}
      size="small"
      placement="end"
      shouldCloseOnDocumentClick={true}
    >
      <View as="div" padding="medium" data-testid="rubric-search-tray">
        <Flex>
          <Flex.Item shouldGrow={true} shouldShrink={true}>
            <Heading level="h3">{I18n.t('Find Rubric')}</Heading>
          </Flex.Item>
          <Flex.Item>
            <CloseButton
              placement="end"
              offset="small"
              screenReaderLabel={I18n.t('Close')}
              onClick={onDismiss}
            />
          </Flex.Item>
        </Flex>
      </View>

      <View as="div" margin="x-small 0 0" padding="0 small">
        <TextInput
          autoComplete="off"
          renderLabel={<ScreenReaderContent>{I18n.t('search rubrics input')}</ScreenReaderContent>}
          placeholder={I18n.t('Search rubrics')}
          value={search}
          onChange={e => setSearch(e.target.value)}
          renderAfterInput={() => <IconSearchLine inline={false} />}
        />
      </View>

      {isOpen && (
        <View as="div" margin="medium 0 0" padding="0 small">
          <RubricContextSelect
            courseId={courseId}
            selectedContext={selectedContext}
            handleChangeContext={handleChangeContext}
            setSelectedContext={setSelectedContext}
          />

          <View
            as="div"
            margin="small 0 0"
            height="100vh"
            maxHeight="calc(100vh - 272px)"
            padding="small 0"
            overflowY="auto"
          >
            {selectedContext ? (
              <RubricsForContext
                courseId={courseId}
                selectedAssociation={selectedAssociation}
                selectedContext={selectedContext}
                search={search}
                onPreview={onPreview}
                onSelect={(rubricAssociation, rubricId) => {
                  setSelectedAssociation(rubricAssociation)
                  setSelectedRubricId(rubricId)
                }}
              />
            ) : (
              <LoadingIndicator />
            )}
          </View>
        </View>
      )}

      <View as="footer" margin="small 0 0" height="62px">
        <View as="hr" margin="0" />
        <RubricSearchFooter
          disabled={!selectedRubricId}
          onSubmit={() => {
            if (!selectedRubricId || !selectedAssociation) return

            onAddRubric(selectedRubricId, selectedAssociation)
          }}
          onCancel={onDismiss}
        />
      </View>
    </Tray>
  )
}

type RubricContextSelectProps = {
  courseId: string
  selectedContext?: string
  handleChangeContext: (context: string) => void
  setSelectedContext: (context: string) => void
}
const RubricContextSelect = ({
  courseId,
  selectedContext,
  handleChangeContext,
  setSelectedContext,
}: RubricContextSelectProps) => {
  const {data: rubricContexts = [], isLoading} = useQuery({
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
      } else {
        setSelectedContext(rubricContexts[0]?.context_code)
      }
    }
  }, [rubricContexts, courseId, setSelectedContext])

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

  if (isLoading && !rubricContexts) {
    return <LoadingIndicator />
  }

  return (
    <SimpleSelect
      renderLabel={<ScreenReaderContent>{I18n.t('select account or course')}</ScreenReaderContent>}
      value={selectedContext}
      onChange={(_, {value}) => handleChangeContext(value as string)}
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

type RubricsForContextProps = {
  courseId: string
  selectedAssociation?: RubricAssociation
  selectedContext: string
  search: string
  onPreview: (rubric: Rubric) => void
  onSelect: (rubricAssociation: RubricAssociation, rubricId: string) => void
}
const RubricsForContext = ({
  courseId,
  selectedAssociation,
  selectedContext,
  search,
  onPreview,
  onSelect,
}: RubricsForContextProps) => {
  const {data: rubricsForContext = [], isLoading: isRubricsLoading} = useQuery({
    queryKey: ['fetchGradingRubricsForContext', courseId, selectedContext],
    queryFn: getGradingRubricsForContext,
  })

  if (isRubricsLoading) {
    return <LoadingIndicator />
  }

  const filteredContextRubrics = rubricsForContext?.filter(({rubric}) =>
    rubric.title.toLowerCase().includes(search.toLowerCase()),
  )

  return (
    <>
      {filteredContextRubrics?.map(({rubricAssociation, rubric}) => (
        <RubricSearchRow
          key={rubricAssociation.id}
          rubric={rubric}
          checked={selectedAssociation?.id === rubricAssociation.id}
          onPreview={onPreview}
          onSelect={() => {
            onSelect(rubricAssociation, rubric.id)
          }}
        />
      ))}
    </>
  )
}

type RubricSearchRowProps = {
  checked: boolean
  rubric: Rubric
  onPreview: (rubric: Rubric) => void
  onSelect: () => void
}
const RubricSearchRow = ({checked, rubric, onPreview, onSelect}: RubricSearchRowProps) => {
  return (
    <View as="div" margin="medium 0 0">
      <Flex>
        <Flex.Item align="start" margin="xxx-small 0 0">
          <RadioInput
            label={
              <ScreenReaderContent>
                {I18n.t('select %{title}', {title: rubric.title})}
              </ScreenReaderContent>
            }
            onChange={onSelect}
            checked={checked}
          />
        </Flex.Item>
        <Flex.Item shouldGrow={true} align="start" margin="0 0 0 xx-small">
          <View as="div">
            <Text data-testid="rubric-search-row-title">{rubric.title}</Text>
          </View>
          <View as="div">
            <Text size="small" data-testid="rubric-search-row-data">
              {possibleString(rubric.pointsPossible)} | {rubric.criteriaCount} {I18n.t('criterion')}
            </Text>
          </View>
        </Flex.Item>
        <Flex.Item align="start">
          <IconArrowOpenEndLine
            data-testid="rubric-preview-btn"
            onClick={() => onPreview(rubric)}
            style={{cursor: 'pointer'}}
          />
        </Flex.Item>
      </Flex>
      <View as="hr" margin="medium 0 0" />
    </View>
  )
}

type RubricSearchFooterProps = {
  disabled: boolean
  onSubmit: () => void
  onCancel: () => void
}
const RubricSearchFooter = ({disabled, onSubmit, onCancel}: RubricSearchFooterProps) => {
  return (
    <View
      as="div"
      data-testid="rubric-assessment-footer"
      overflowX="hidden"
      overflowY="hidden"
      background="secondary"
      padding="0 small"
    >
      <Flex justifyItems="end" margin="small 0">
        <Flex.Item margin="0 small 0 0">
          <Button
            color="secondary"
            onClick={() => onCancel()}
            data-testid="cancel-rubric-search-button"
          >
            {I18n.t('Cancel')}
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button
            color="primary"
            // @ts-expect-error
            renderIcon={IconAddLine}
            onClick={() => onSubmit()}
            data-testid="save-rubric-assessment-button"
            disabled={disabled}
          >
            {I18n.t('Add')}
          </Button>
        </Flex.Item>
      </Flex>
    </View>
  )
}
