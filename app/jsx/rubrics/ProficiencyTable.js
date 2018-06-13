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
import Button from '@instructure/ui-buttons/lib/components/Button'
import IconPlus from 'instructure-icons/lib/Line/IconPlusLine'
import I18n from 'i18n!rubrics'
import Table from '@instructure/ui-elements/lib/components/Table'
import ProficiencyRating from 'jsx/rubrics/ProficiencyRating'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import uuid from 'uuid/v1'
import _ from 'underscore'
import { fromJS, List } from 'immutable'
import NumberHelper from '../shared/helpers/numberHelper'

const ADD_DEFAULT_COLOR = '#EF4437'

export default class ProficiencyTable extends React.Component {
  constructor (props) {
    super(props)
    this.state = {
      masteryIndex: 1,
      rows: List([
        this.createRating('Exceeds Mastery', 5, '#6A843F'),
        this.createRating('Mastery', 4, '#8AAC53'),
        this.createRating('Near Mastery', 3, '#E0D773'),
        this.createRating('Well Below Mastery', 2, '#DF5B59')
      ])
    }
  }

  componentDidUpdate() {
    if (this.fieldWithFocus()) {
      this.setState({rows: this.state.rows.map(row => row.delete('focusField'))})
    }
  }

  fieldWithFocus = () => this.state.rows.some(row => row.get('focusField'))

  createRating = (description, points, color) => fromJS({description,
                                                         points,
                                                         key: uuid(),
                                                         color
                                                        })

  addRow = () => {
    let points = 0.0
    const last = this.state.rows.last()
    if (last) {
      points = last.get('points') - 1.0
    }
    if (points < 0.0 || Number.isNaN(points)) {
      points = 0.0
    }
    const newRow = this.createRating('', points, ADD_DEFAULT_COLOR)
    this.setState({rows: this.state.rows.push(newRow)})
  }

  handleMasteryChange = _.memoize((index) => () => {
    this.setState({ masteryIndex: index })
  })

  handleDescriptionChange = _.memoize((index) => (value) => {
    let rows = this.state.rows
    if (!this.invalidDescription(value)) {
      rows = rows.removeIn([index, 'descriptionError'])
    }
    rows = rows.setIn([index, 'description'], value)
    this.setState({rows})
  })

  handlePointsChange = _.memoize((index) => (value) => {
    const parsed = NumberHelper.parse(value)
    let rows = this.state.rows
    if (!this.invalidPoints(parsed)) {
      rows = rows.removeIn([index, 'pointsError'])
    }
    rows = rows.setIn([index, 'points'], parsed)
    this.setState({rows})
  })

  handleColorChange = _.memoize((index) => (value) => {
    const rows = this.state.rows.update(index, row => row.set('color', value))
    this.setState({rows})
  })

  handleDelete = _.memoize((index) => () => {
    const masteryIndex = this.state.masteryIndex
    const rows = this.state.rows.delete(index)
    if (masteryIndex >= index && masteryIndex > 0) {
      this.setState({ masteryIndex: masteryIndex - 1 })
    }
    this.setState({rows})
  })

  isStateValid = () => !this.state.rows.some(row =>
    this.invalidPoints(row.get('points')) || this.invalidDescription(row.get('description')))

  handleSubmit = () => {
    if (!this.isStateValid()) {
      this.checkForErrors()
    }
  }

  checkForErrors = () => {
    let firstError = true
    const rows = this.state.rows.map((row) => {
      let r = row
      if (this.invalidDescription(row.get('description'))) {
        r = r.set('descriptionError', I18n.t('Missing required description'))
        if (firstError) {
          r = r.set('focusField', 'description')
          firstError = false
        }
      }
      if (this.invalidPoints(row.get('points'))) {
        r = r.set('pointsError', I18n.t('Invalid points'))
        if (firstError) {
          r = r.set('focusField', 'points')
          firstError = false
        }
      }
      return r
    })
    this.setState({ rows })
  }

  invalidPoints = (points) => Number.isNaN(points)

  invalidDescription = (description) => !description || description.trim().length === 0

  render() {
    const masteryIndex = this.state.masteryIndex
    return (
      <div>
        <Table caption={<ScreenReaderContent>{I18n.t('Proficiency ratings')}</ScreenReaderContent>}>
          <thead>
            <tr>
              <th className="masteryCol" scope="col">{I18n.t('Mastery')}</th>
              <th scope="col">{I18n.t('Proficiency Rating')}</th>
              <th className="pointsCol" scope="col">{I18n.t('Points')}</th>
              <th className="colorCol" scope="col">{I18n.t('Color')}</th>
            </tr>
          </thead>
          <tbody>
            { this.state.rows.map(
                (rating, index) => <ProficiencyRating
                  key={rating.get('key')}
                  color={rating.get('color')}
                  description={rating.get('description')}
                  descriptionError={rating.get('descriptionError')}
                  focusField={rating.get('focusField')}
                  points={rating.get('points').toString()}
                  pointsError={rating.get('pointsError')}
                  mastery={index === masteryIndex}
                  onColorChange={this.handleColorChange(index)}
                  onDelete={this.handleDelete(index)}
                  onDescriptionChange={this.handleDescriptionChange(index)}
                  onMasteryChange={this.handleMasteryChange(index)}
                  onPointsChange={this.handlePointsChange(index)} />
              )
            }
            <tr>
              <td colSpan="4" style={{textAlign: 'center'}}>
                <Button variant="circle-primary" onClick={this.addRow}>
                  <IconPlus title={I18n.t('Add proficiency rating')}/>
                </Button>
              </td>
            </tr>
          </tbody>
        </Table>
        <div className="save">
          <Button variant="primary" onClick={this.handleSubmit}>
            {I18n.t('Save Learning Mastery')}
          </Button>
        </div>
      </div>
    )
  }
}
