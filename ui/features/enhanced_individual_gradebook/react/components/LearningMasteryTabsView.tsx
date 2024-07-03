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
import {useScope as useI18nScope} from '@canvas/i18n'
import outcomeGrid from '@canvas/outcome-gradebook-grid'
import {useQuery as useCanvasQuery} from '@canvas/query'
import {Tabs} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-view'
import {useQuery} from 'react-apollo'
import {useSearchParams} from 'react-router-dom'
import type {AssignmentGroupCriteriaMap} from '@canvas/grading/grading.d'
import {GRADEBOOK_QUERY} from '../../queries/Queries'
import type {
  CustomColumn,
  CustomOptions,
  GradebookOptions,
  GradebookQueryResponse,
  Outcome,
  SectionConnection,
  SortableStudent,
} from '../../types'
import {
  gradebookOptionsSetup,
  mapAssignmentGroupQueryResults,
  mapAssignmentSubmissions,
  mapEnrollmentsToSortableStudents,
} from '../../utils/gradebookUtils'
import {useCurrentStudentInfo} from '../hooks/useCurrentStudentInfo'
import {useCustomColumns} from '../hooks/useCustomColumns'
import ContentSelection from './ContentSelectionLearningMastery'
import EnhancedIndividualGradebook from './EnhancedIndividualGradebook'
import GlobalSettings from './GlobalSettingsLearningMastery'
import OutcomeInformation from './OutcomeInformation'
import OutcomeReult from './OutcomeResult'
import fetchOutcomeResult from './OutcomeResult/OutcomeResultQuery'
import StudentInformation from './StudentInformation'

const I18n = useI18nScope('enhanced_individual_gradebook')

const STUDENT_SEARCH_PARAM = 'student'
const OUTCOME_SEARCH_PARAM = 'outcome'
const TABS = {
  assignments: 'assignments',
  learningMastery: 'learning-mastery',
}

export type OutcomeScore = {
  average: number
  max: number
  min: number
  cnt: number
}

export type ParsedOutcomeRollup = {
  outcome_id: string
  user_id: string
  score: number
}

export default function LearningMasteryTabsView() {
  const [sections, setSections] = useState<SectionConnection[]>([])
  const [students, setStudents] = useState<SortableStudent[]>()
  const [outcomes, setOutcomes] = useState<Outcome[]>()
  const [parsedOutcomeRollups, setParsedOutcomeRollups] = useState<ParsedOutcomeRollup[]>()
  const [selectedOutcomeRollup, setSelectedOutcomeRollup] = useState<ParsedOutcomeRollup>()
  const [outcomeScore, setOutcomeScore] = useState<OutcomeScore>()
  const courseId = ENV.GRADEBOOK_OPTIONS?.context_id || ''
  const [selectedTab, setSelectedTab] = useState<string | undefined>(TABS.assignments)

  const [searchParams, setSearchParams] = useSearchParams()
  const studentIdQueryParam = searchParams.get(STUDENT_SEARCH_PARAM)
  const [selectedStudentId, setSelectedStudentId] = useState<string | null | undefined>(
    studentIdQueryParam
  )
  const {currentStudent, studentSubmissions} = useCurrentStudentInfo(courseId, selectedStudentId)

  const [assignmentGroupMap, setAssignmentGroupMap] = useState<AssignmentGroupCriteriaMap>({})

  const outcomeIdQueryParam = searchParams.get(OUTCOME_SEARCH_PARAM)
  const [selectedOutcomeId, setSelectedOutcomeId] = useState<string | null | undefined>(
    outcomeIdQueryParam
  )

  const selectedOutcome = outcomes?.find(outcome => outcome.id === selectedOutcomeId)

  const [gradebookOptions, setGradebookOptions] = useState<GradebookOptions>(
    gradebookOptionsSetup(ENV)
  )

  const {data, error} = useQuery<GradebookQueryResponse>(GRADEBOOK_QUERY, {
    variables: {courseId},
    fetchPolicy: 'no-cache',
    skip: !courseId,
  })

  const {data: outcomeRollupsData, isLoading} = useCanvasQuery({
    queryKey: [`fetch-outcome-result-${courseId}`],
    queryFn: async () => fetchOutcomeResult(),
    enabled: !!courseId,
  })

  const {customColumnsUrl} = gradebookOptions

  const {customColumns} = useCustomColumns(customColumnsUrl)
  const studentNotesColumnId = customColumns?.find(
    (column: CustomColumn) => column.teacher_notes
  )?.id

  const [currentStudentHiddenName, setCurrentStudentHiddenName] = useState<string>('')

  useEffect(() => {
    if (outcomeRollupsData && outcomeRollupsData.length > 0) {
      const outcomeRollups = outcomeRollupsData
        .map(row => {
          if (!row.scores) return []

          return row.scores.map(score => ({
            user_id: row.links.user,
            outcome_id: score.links.outcome_id,
            score: parseInt(score.score, 10),
          }))
        })
        .flat()

      setParsedOutcomeRollups(outcomeRollups)
    }
  }, [outcomeRollupsData])

  useEffect(() => {
    if (!selectedStudentId || !selectedOutcomeId || !parsedOutcomeRollups) {
      setOutcomeScore(undefined)
      setSelectedOutcomeRollup(undefined)
      return
    }

    const outcomeRollupScores = parsedOutcomeRollups.filter(
      outcomeRollup => outcomeRollup.outcome_id === selectedOutcomeId
    )

    const scores = outcomeRollupScores
      .map(outcomeRollup => outcomeRollup.score)
      .filter(score => typeof score === 'number')

    if (scores.length > 0) {
      const outcomeScoreMap = {
        average: outcomeGrid.Math.mean(scores),
        max: outcomeGrid.Math.max(scores),
        min: outcomeGrid.Math.min(scores),
        cnt: outcomeGrid.Math.cnt(scores),
      }
      setOutcomeScore(outcomeScoreMap)
    } else {
      setOutcomeScore(undefined)
    }

    const selectedParsedOutcomeRollup = parsedOutcomeRollups.find(
      outcomeRollup => outcomeRollup.user_id === selectedStudentId
    )

    if (selectedParsedOutcomeRollup) {
      setSelectedOutcomeRollup(selectedParsedOutcomeRollup)
    } else {
      setSelectedOutcomeRollup(undefined)
    }
  }, [selectedStudentId, selectedOutcomeId, parsedOutcomeRollups])

  useEffect(() => {
    if (!currentStudent || !students) {
      return
    }
    const hiddenName = students?.find(s => s.id === currentStudent.id)?.hiddenName
    setCurrentStudentHiddenName(hiddenName ?? I18n.t('Student'))
  }, [currentStudent, students])

  useEffect(() => {
    if (error) {
      // TODO: handle error
    }

    if (data?.course) {
      const {
        assignmentGroupsConnection,
        enrollmentsConnection,
        sectionsConnection,
        submissionsConnection,
        rootOutcomeGroup,
      } = data.course

      const {assignmentGradingPeriodMap} = mapAssignmentSubmissions(submissionsConnection.nodes)

      const {mappedAssignmentGroupMap} = mapAssignmentGroupQueryResults(
        assignmentGroupsConnection.nodes,
        assignmentGradingPeriodMap
      )

      setAssignmentGroupMap(mappedAssignmentGroupMap)
      setSections(sectionsConnection.nodes)
      setOutcomes(rootOutcomeGroup.outcomes.nodes)

      const sortableStudents = mapEnrollmentsToSortableStudents(enrollmentsConnection.nodes)
      const sortedStudents = sortableStudents.sort((a, b) => {
        return a.sortableName.localeCompare(b.sortableName)
      })
      sortedStudents.forEach(
        (student, index) => (student.hiddenName = I18n.t('Student %{id}', {id: index + 1}))
      )
      setStudents(sortedStudents)
    }
  }, [data, error])

  const invalidAssignmentGroups = Object.keys(assignmentGroupMap).reduce((invalidKeys, groupId) => {
    const {invalid, name, gradingPeriodsIds} = assignmentGroupMap[groupId]
    const {selectedGradingPeriodId} = gradebookOptions
    if (
      invalid ||
      (selectedGradingPeriodId && !gradingPeriodsIds?.includes(selectedGradingPeriodId))
    ) {
      invalidKeys[groupId] = name
    }

    return invalidKeys
  }, {} as Record<string, string>)

  const handleStudentChange = (studentId?: string) => {
    setSelectedStudentId(studentId)
    if (studentId) {
      searchParams.set(STUDENT_SEARCH_PARAM, studentId)
    } else {
      searchParams.delete(STUDENT_SEARCH_PARAM)
    }
    setSearchParams(searchParams)
  }

  const handleOutcomeChange = (outcomeId?: string) => {
    setSelectedOutcomeId(outcomeId)
    if (outcomeId) {
      searchParams.set(OUTCOME_SEARCH_PARAM, outcomeId)
    } else {
      searchParams.delete(OUTCOME_SEARCH_PARAM)
    }
    setSearchParams(searchParams)
  }

  return (
    <>
      <Tabs
        data-testid="learning-mastery-tabs"
        margin="large auto"
        padding="medium"
        onRequestTabChange={(_e: any, {id}: {id?: string}) => setSelectedTab(id)}
      >
        <Tabs.Panel
          id={TABS.assignments}
          renderTitle={I18n.t('Assignments')}
          isSelected={selectedTab === TABS.assignments}
          padding="none"
        >
          <View as="div" margin="medium 0" data-testid="assignment-data">
            <EnhancedIndividualGradebook />
          </View>
        </Tabs.Panel>
        <Tabs.Panel
          id={TABS.learningMastery}
          renderTitle={I18n.t('Learning Mastery')}
          isSelected={selectedTab === TABS.learningMastery}
          padding="none"
        >
          <View as="div" margin="medium 0" data-testid="learning-mastery-data">
            <GlobalSettings
              sections={sections}
              gradebookOptions={gradebookOptions}
              onSectionChange={sectionId => {
                const newGradebookOptions = {...gradebookOptions, selectedSection: sectionId}
                setGradebookOptions(newGradebookOptions)
              }}
              handleCheckboxChange={(key: keyof CustomOptions, value: boolean) => {
                setGradebookOptions(prevGradebookOptions => {
                  const newCustomOptions = {...prevGradebookOptions.customOptions, [key]: value}
                  return {...prevGradebookOptions, customOptions: newCustomOptions}
                })
              }}
            />

            <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

            <ContentSelection
              outcomes={outcomes}
              students={students}
              selectedStudentId={selectedStudentId}
              selectedOutcomeId={selectedOutcomeId}
              gradebookOptions={gradebookOptions}
              onStudentChange={handleStudentChange}
              onOutcomeChange={handleOutcomeChange}
            />

            <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

            <OutcomeReult
              outcomeScore={outcomeScore}
              outcome={selectedOutcome}
              selectedStudentId={selectedStudentId}
              selectedOutcomeRollup={selectedOutcomeRollup}
              isLoading={isLoading}
            />

            <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

            <StudentInformation
              assignmentGroupMap={assignmentGroupMap}
              gradebookOptions={gradebookOptions}
              invalidAssignmentGroups={invalidAssignmentGroups}
              student={currentStudent}
              studentNotesColumnId={studentNotesColumnId}
              currentStudentHiddenName={currentStudentHiddenName}
              submissions={studentSubmissions}
            />

            <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

            <OutcomeInformation outcome={selectedOutcome} outcomeScore={outcomeScore} />

            <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />
          </View>
        </Tabs.Panel>
      </Tabs>
    </>
  )
}
