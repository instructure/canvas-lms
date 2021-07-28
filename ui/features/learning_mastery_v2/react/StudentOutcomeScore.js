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
import React from 'react'
import PropTypes from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import SVGWrapper from '@canvas/svg-wrapper'
import {svgUrl} from './icons'
import {outcomeShape, outcomeRollupShape} from './shapes'
import I18n from 'i18n!learning_mastery_gradebook'

const StudentOutcomeScore = ({outcome, rollup}) => (
  <Flex width="100%" height="100%" alignItems="center" justifyItems="center">
    <div style={{display: 'flex', transform: 'scale(2.1)'}}>
      <SVGWrapper
        fillColor={rollup?.rating?.color}
        url={svgUrl(rollup?.rating?.points, outcome.mastery_points)}
      />
      <ScreenReaderContent>
        {rollup?.rating?.description || I18n.t('Unassessed')}
      </ScreenReaderContent>
    </div>
  </Flex>
)

StudentOutcomeScore.propTypes = {
  outcome: PropTypes.shape(outcomeShape).isRequired,
  rollup: PropTypes.shape(outcomeRollupShape)
}

export default StudentOutcomeScore
