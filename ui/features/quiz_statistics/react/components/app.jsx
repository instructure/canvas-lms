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

import {extend} from 'lodash'
import CalculatedRenderer from './questions/calculated'
import EssayRenderer from './questions/essay'
import FileUploadRenderer from './questions/file_upload'
import FillInMultipleBlanksRenderer from './questions/fill_in_multiple_blanks'
import {useScope as useI18nScope} from '@canvas/i18n'
import MultipleChoiceRenderer from './questions/multiple_choice'
import QuestionRenderer from './question'
import React from 'react'
import Report from './summary/report'
import ScreenReaderContent from '@canvas/quiz-legacy-client-apps/react/components/screen_reader_content'
import ShortAnswerRenderer from './questions/short_answer'
import Summary from './summary/index'

const I18n = useI18nScope('quiz_statistics')

const Renderers = {
  multiple_choice_question: MultipleChoiceRenderer,
  true_false_question: MultipleChoiceRenderer,
  short_answer_question: ShortAnswerRenderer,
  multiple_answers_question: ShortAnswerRenderer,
  numerical_question: ShortAnswerRenderer,
  fill_in_multiple_blanks_question: FillInMultipleBlanksRenderer,
  multiple_dropdowns_question: FillInMultipleBlanksRenderer,
  matching_question: FillInMultipleBlanksRenderer,
  essay_question: EssayRenderer,
  calculated_question: CalculatedRenderer,
  file_upload_question: FileUploadRenderer,
}

class Statistics extends React.Component {
  static defaultProps = {
    quizStatistics: {
      submissionStatistics: {},
      questionStatistics: [],
    },
  }

  render() {
    const quizStatistics = this.props.quizStatistics
    const submissionStatistics = quizStatistics.submissionStatistics
    if (!this.props.canBeLoaded) {
      return (
        <div id="canvas-quiz-statistics" className="canvas-quiz-statistics-noload">
          <div id="sad-panda">
            <img
              src="/images/sadpanda.svg"
              alt={I18n.t('sad-panda-alttext', 'Sad things in panda land.')}
            />
            <p>
              {I18n.t(
                'quiz-stats-noshow-warning',
                "Even awesomeness has limits. We can't render statistics for this quiz, but you can download the reports."
              )}
            </p>
            <div className="links">{this.renderQuizReports(this.props.quizReports)}</div>
          </div>
        </div>
      )
    } else {
      return (
        <div id="canvas-quiz-statistics">
          <ScreenReaderContent tagName="h1">
            {I18n.t('title', 'Quiz Statistics')}
          </ScreenReaderContent>

          <section>
            <Summary
              pointsPossible={quizStatistics.pointsPossible}
              scoreAverage={submissionStatistics.scoreAverage}
              scoreHigh={submissionStatistics.scoreHigh}
              scoreLow={submissionStatistics.scoreLow}
              scoreStdev={submissionStatistics.scoreStdev}
              durationAverage={submissionStatistics.durationAverage}
              quizReports={this.props.quizReports}
              scores={submissionStatistics.scores}
              loading={this.props.isLoadingStatistics}
            />
          </section>

          <section id="question-statistics-section">
            <header className="padded">
              <h2 className="section-title inline">
                {I18n.t('question_breakdown', 'Question Breakdown')}
              </h2>
            </header>

            {this.renderQuestions()}
          </section>
        </div>
      )
    }
  }

  renderQuestions() {
    const isLoadingStatistics = this.props.isLoadingStatistics
    const questionStatistics = this.props.quizStatistics.questionStatistics
    const participantCount = this.props.quizStatistics.submissionStatistics.uniqueCount

    if (isLoadingStatistics) {
      return (
        <p>
          {I18n.t(
            'loading_questions',
            'Question statistics are being loaded. Please wait a while.'
          )}
        </p>
      )
    } else if (questionStatistics.length === 0) {
      return (
        <p>{I18n.t('empty_question_breakdown', 'There are no question statistics available.')}</p>
      )
    } else {
      return <div>{questionStatistics.map(this.renderQuestion.bind(this, participantCount))}</div>
    }
  }

  renderQuizReports() {
    const quizReports = this.props.quizReports
    if (typeof quizReports !== 'undefined' && quizReports !== null && quizReports.length) {
      return quizReports.map(this.renderReport.bind(this))
    }
  }

  renderReport(reportProps) {
    return <Report key={'report-' + reportProps.id} {...reportProps} />
  }

  renderQuestion(participantCount, question) {
    const Renderer = Renderers[question.questionType] || QuestionRenderer
    const stats = this.props.quizStatistics
    const questionProps = extend({}, question, {
      key: 'question-' + question.id,
      participantCount: question.participantCount,
      speedGraderUrl: stats.speedGraderUrl,
      quizSubmissionsZipUrl: stats.quizSubmissionsZipUrl,
    })

    return <Renderer {...questionProps} />
  }
}

export default Statistics
