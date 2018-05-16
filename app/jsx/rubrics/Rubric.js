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
import PropTypes from 'prop-types'
import Table from '@instructure/ui-elements/lib/components/Table'
import I18n from 'i18n!edit_rubric'

import Criterion from './Criterion'

import { rubricShape, rubricAssessmentShape, rubricAssociationShape } from './types'

const Rubric = ({ rubric, rubricAssessment, rubricAssociation }) => {
  const byCriteria = _.keyBy(rubricAssessment.data, (ra) => ra.criterion_id)
  const criteria = rubric.criteria.map((criterion) => {
    const assessment = byCriteria[criterion.id]
    return (
      <Criterion
        key={criterion.id}
        assessment={assessment}
        criterion={criterion}
        freeForm={rubric.free_form_criterion_comments}
        />
    )
  })

  // XXX - when assessing, the prior code includes "out of %{possible}". We
  // aren't handling assessing yet, but will need to include this Very Soon.
  const total = I18n.t('Total Points: %{total}', {
    total: I18n.toNumber(rubricAssessment.score, { precision: 1 })
  })

  return (
    <div className="react-rubric">
      <Table caption={rubric.title}>
        <thead>
          <tr>
            <th scope="col">{I18n.t('Criteria')}</th>
            <th scope="col">{I18n.t('Ratings')}</th>
            <th scope="col">{I18n.t('Pts')}</th>
          </tr>
        </thead>
        <tbody className="criterions">
          {criteria}
          <tr>
            <td colSpan="3" className="total-points">
              {rubricAssociation.hide_score_total === true ? null : total}
            </td>
          </tr>
        </tbody>
      </Table>
    </div>
  )
}
Rubric.propTypes = {
  rubric: PropTypes.shape(rubricShape).isRequired,
  rubricAssessment: PropTypes.shape(rubricAssessmentShape).isRequired,
  rubricAssociation: PropTypes.shape(rubricAssociationShape)
}
Rubric.defaultProps = {
  rubricAssociation: {}
}

export default Rubric
