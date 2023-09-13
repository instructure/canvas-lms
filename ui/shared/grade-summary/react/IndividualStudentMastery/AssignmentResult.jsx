/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import _ from 'lodash'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconAssignmentLine, IconQuizLine, IconHighlighterLine} from '@instructure/ui-icons'
import * as shapes from './shapes'
import Ratings from '@canvas/rubrics/react/Ratings'

import {Link} from '@instructure/ui-link'

const I18n = useI18nScope('IndividiualStudentMasteryAssignmentResult')

const scoreFromPercent = (percent, outcome) => {
  if (outcome.points_possible > 0) {
    return +(percent * outcome.points_possible).toFixed(2)
  } else {
    return +(percent * outcome.mastery_points).toFixed(2)
  }
}

const scaleScore = (score, possible, outcome) => {
  if (!possible) return score
  if (outcome.points_possible > 0) {
    return +((score / possible) * outcome.points_possible).toFixed(2)
  } else {
    return +((score / possible) * outcome.mastery_points).toFixed(2)
  }
}

const renderLinkedResult = (name, url, isQuiz) => (
  <Link
    href={url}
    isWithinText={false}
    themeOverride={{mediumPaddingHorizontal: '0', mediumHeight: 'normal', fontWeight: '700'}}
    renderIcon={isQuiz ? IconQuizLine : IconAssignmentLine}
  >
    {name}
  </Link>
)

const renderUnlinkedResult = name => (
  <Flex alignItems="center">
    <Flex.Item>
      <Text size="medium">
        <IconHighlighterLine />
      </Text>
    </Flex.Item>
    <Flex.Item padding="0 x-small">
      <Text weight="bold">{name}</Text>
    </Flex.Item>
  </Flex>
)

const AssignmentResult = ({outcome, result, outcomeProficiency}) => {
  const {ratings} = outcome
  const {html_url: url, name, submission_types: types} = result.assignment
  const isQuiz = types && types.indexOf('online_quiz') >= 0
  const score = result.percent
    ? scoreFromPercent(result.percent, outcome)
    : scaleScore(result.score, result.points_possible, outcome)
  return (
    <Flex padding="small" direction="column" alignItems="stretch">
      <Flex.Item>
        {url.length > 0 ? renderLinkedResult(name, url, isQuiz) : renderUnlinkedResult(name)}
      </Flex.Item>
      <Flex.Item padding="x-small 0">
        <View padding="x-small 0 0 0">
          <Text size="small" fontStyle="italic" weight="bold">
            {result.hide_points ? I18n.t('Your score') : I18n.t('Your score: %{score}', {score})}
          </Text>
        </View>
      </Flex.Item>
      <Flex.Item borderWidth="small">
        <div className="react-rubric">
          <div className="ratings">
            <Ratings
              tiers={ratings}
              points={score}
              hidePoints={result.hide_points}
              useRange={false}
              customRatings={_.get(outcomeProficiency, 'ratings')}
              defaultMasteryThreshold={outcome.mastery_points}
              pointsPossible={outcome.points_possible}
              assessing={false}
              isSummary={false}
            />
          </div>
        </div>
      </Flex.Item>
    </Flex>
  )
}

AssignmentResult.propTypes = {
  result: shapes.outcomeResultShape.isRequired,
  outcome: shapes.outcomeShape.isRequired,
  outcomeProficiency: shapes.outcomeProficiencyShape,
}

AssignmentResult.defaultProps = {
  outcomeProficiency: null,
}

export default AssignmentResult
