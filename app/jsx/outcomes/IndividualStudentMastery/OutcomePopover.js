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
import _ from 'lodash'
import I18n from 'i18n!outcomes'
import View from '@instructure/ui-layout/lib/components/View'
import Flex, { FlexItem } from '@instructure/ui-layout/lib/components/Flex'
import Text from '@instructure/ui-elements/lib/components/Text'
import Link from '@instructure/ui-elements/lib/components/Link'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import CalculationMethodContent from 'compiled/models/grade_summary/CalculationMethodContent'
import Popover, {PopoverTrigger, PopoverContent} from '@instructure/ui-overlays/lib/components/Popover'
import IconInfo from '@instructure/ui-icons/lib/Line/IconInfo'
import DatetimeDisplay from '../../shared/DatetimeDisplay'
import * as shapes from './shapes'

export default class OutcomePopover extends React.Component {
  static propTypes = {
    outcome: shapes.outcomeShape.isRequired,
    outcomeProficiency: shapes.outcomeProficiencyShape
  }

  static defaultProps = {
    outcomeProficiency: null
  }

  constructor () {
    super()
    this.state = { moreInformation: false }
  }

  getSelectedRating () {
    const { outcomeProficiency } = this.props
    const { points_possible, mastery_points, score } = this.props.outcome
    const hasScore = score >= 0
    if (outcomeProficiency && hasScore) {
      const totalPoints = points_possible || mastery_points
      const percentage = totalPoints ? (score / totalPoints) : score
      const maxRating = outcomeProficiency.ratings[0].points
      const scaledScore = maxRating * percentage
      return _.find(outcomeProficiency.ratings, (r) => (scaledScore >= r.points)) || _.last(outcomeProficiency.ratings)
    } else if (hasScore) {
      return _.find(this.defaultProficiency(mastery_points).ratings, (r) => (score >= r.points))
    }
    return null
  }

  defaultProficiency = _.memoize((mastery_points) => (
    {
      ratings: [
        {points: mastery_points * 1.5, color: '127A1B', description: I18n.t('Exceeds Mastery')},
        {points: mastery_points, color: '00AC18', description: I18n.t('Meets Mastery')},
        {points: mastery_points/2, color: 'FAB901', description: I18n.t('Near Mastery')},
        {points: 0, color: 'EE0612', description: I18n.t('Well Below Mastery')}
      ]
    }
  ))

  latestTime () {
    const { outcome } = this.props
    if (outcome.results.length > 0) {
      return _.sortBy(outcome.results, (r) => (r.submitted_or_assessed_at))[0].submitted_or_assessed_at
    }
    return null
  }

  expandDetails = () => { this.setState({ moreInformation: !this.state.moreInformation }) }

  renderPopoverContent () {
    const selectedRating = this.getSelectedRating()
    const latestTime = this.latestTime()
    const popoverContent = new CalculationMethodContent(this.props.outcome).present()
    const {
      method,
      exampleText,
      exampleScores,
      exampleResult
    } = popoverContent
    return (
      <View as='div' padding='small' maxWidth='30rem'>
        <Text size='small'>
          <Flex
            alignItems='stretch'
            direction='row'
            justifyItems='space-between'
          >
            <FlexItem grow shrink>
              <div>{I18n.t('Last Assessment: ')}
                { latestTime ?
                  <DatetimeDisplay datetime={latestTime} format='%b %d, %l:%M %p' /> :
                  I18n.t('No submissions')
                }
              </div>
            </FlexItem>
            <FlexItem grow shrink align='stretch'>
              <Text size='small' weight='bold'>
                <div>
                  {selectedRating &&
                  <div style={{color: `#${selectedRating.color}`, textAlign: 'end'}}>
                    {selectedRating.description}
                  </div>}
                </div>
              </Text>
            </FlexItem>
          </Flex>
          <hr role='presentation'/>
          <div>
            <Text size='small' weight='bold'>{I18n.t('Calculation Method')}</Text>
            <div>{method}</div>
            <div style={{padding: '0.5rem 0 0 0'}}><Text size='small' weight="bold">{I18n.t('Example')}</Text></div>
            <div>{exampleText}</div>
            <div>{I18n.t('1- Item Scores: %{exampleScores}', { exampleScores })}</div>
            <div>{I18n.t('2- Final Score: %{exampleResult}', { exampleResult })}</div>
          </div>
        </Text>
      </View>
    )
  }

  render () {
    const popoverContent = this.renderPopoverContent()
    return (
      <span>
        <Popover
          placement="bottom"
        >
          <PopoverTrigger>
            <Link onClick={() => this.expandDetails()}>
              <span style={{color: 'black'}}><IconInfo /></span>
              <span>
              {!this.state.moreInformation ?
                <ScreenReaderContent>{I18n.t('Click to expand outcome details')}</ScreenReaderContent> :
                <ScreenReaderContent>{I18n.t('Click to collapse outcome details')}</ScreenReaderContent>
              }
              </span>
            </Link>
          </PopoverTrigger>
          <PopoverContent>
            {popoverContent}
          </PopoverContent>
        </Popover>
        <FlexItem>
          {this.state.moreInformation &&
            <ScreenReaderContent>{popoverContent}</ScreenReaderContent>
          }
        </FlexItem>
      </span>
    )
  }
}
