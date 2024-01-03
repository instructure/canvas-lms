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

/*
  TODO: Duplicated and modified within jsx/outcomes/MasteryScale for use there
        Remove when feature flag account_level_mastery_scales is enabled
*/

import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import {Billboard} from '@instructure/ui-billboard'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconPlusLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Table} from '@instructure/ui-table'
import {Spinner} from '@instructure/ui-spinner'
import ProficiencyRating from './ProficiencyRating'
import {v1 as uuid} from 'uuid'
import {memoize} from 'lodash'
import {fromJS, List} from 'immutable'
import {fetchProficiency, saveProficiency} from '../api'
import NumberHelper from '@canvas/i18n/numberHelper'
import SVGWrapper from '@canvas/svg-wrapper'

const I18n = useI18nScope('ProficiencyTable')

const ADD_DEFAULT_COLOR = 'EF4437'

function unformatColor(color) {
  if (color[0] === '#') {
    return color.substring(1)
  }
  return color
}

export default class ProficiencyTable extends React.Component {
  static propTypes = {
    accountId: PropTypes.string.isRequired,
    focusTab: PropTypes.func,
  }

  static defaultProps = {
    focusTab: null,
  }

  constructor(props) {
    super(props)
    this.state = {
      loading: true,
      masteryIndex: 1,
      rows: List([
        this.createRating('Exceeds Mastery', 4, '127A1B'),
        this.createRating('Mastery', 3, '0B874B'),
        this.createRating('Near Mastery', 2, 'FAB901'),
        this.createRating('Below Mastery', 1, 'FD5D10'),
        this.createRating('Well Below Mastery', 0, 'E0061F'),
      ]),
    }
  }

  componentDidMount() {
    this.fetchRatings()
  }

  componentDidUpdate() {
    if (this.fieldWithFocus()) {
      this.setState(oldState => {
        const rows = oldState.rows.map(row => row.delete('focusField'))
        return {rows}
      })
    }
  }

  fetchRatings = () => {
    fetchProficiency(this.props.accountId)
      .then(response => {
        if (response.status === 200) {
          this.configToState(response.data)
        } else {
          $.flashError(I18n.t('An error occurred while loading account proficiency ratings'))
          this.setState({loading: false})
        }
      })
      .catch(e => {
        // 404 status means no custom ratings, so use defaults without an alert
        if (e.response && e.response.status !== 404) {
          $.flashError(
            I18n.t('An error occurred while loading account proficiency ratings: %{m}', {
              m: e.response.statusText,
            })
          )
        }
        this.setState({billboard: true, loading: false})
      })
  }

  configToState = data => {
    const rows = List(
      data.ratings.map(rating => this.createRating(rating.description, rating.points, rating.color))
    )
    const masteryIndex = data.ratings.findIndex(rating => rating.mastery)
    this.setState({
      loading: false,
      masteryIndex,
      rows: fromJS(rows),
    })
  }

  fieldWithFocus = () => this.state.rows.some(row => row.get('focusField'))

  createRating = (description, points, color, focusField = null) =>
    fromJS({description, points, key: uuid(), color, focusField})

  addRow = () => {
    let points = 0.0
    const last = this.state.rows.last()
    if (last) {
      points = last.get('points') - 1.0
    }
    if (points < 0.0 || Number.isNaN(points)) {
      points = 0.0
    }
    const newRow = this.createRating('', points, ADD_DEFAULT_COLOR, 'mastery')
    this.setState(oldState => {
      const rows = oldState.rows.push(newRow)
      return {rows}
    })
    $.screenReaderFlashMessage(I18n.t('Added new proficiency rating'))
  }

  handleMasteryChange = memoize(index => () => {
    this.setState({masteryIndex: index})
  })

  handleDescriptionChange = memoize(index => value => {
    this.setState(oldState => {
      let rows = oldState.rows
      if (!this.invalidDescription(value)) {
        rows = rows.removeIn([index, 'descriptionError'])
      }
      rows = rows.setIn([index, 'description'], value)
      return {rows}
    })
  })

  handlePointsChange = memoize(index => value => {
    const parsed = NumberHelper.parse(value)
    this.setState(oldState => {
      let rows = oldState.rows
      if (!this.invalidPoints(parsed) && parsed >= 0) {
        rows = rows.removeIn([index, 'pointsError'])
      }
      rows = rows.setIn([index, 'points'], parsed)
      return {rows}
    })
  })

  handleColorChange = memoize(index => value => {
    this.setState(oldState => {
      const rows = oldState.rows.update(index, row => row.set('color', unformatColor(value)))
      return {rows}
    })
  })

  handleDelete = memoize(index => () => {
    const masteryIndex = this.state.masteryIndex
    const rows = this.state.rows.delete(index)
    if (masteryIndex >= index && masteryIndex > 0) {
      this.setState({masteryIndex: masteryIndex - 1})
    }
    if (index === 0) {
      this.setState({rows})
      if (this.props.focusTab) {
        setTimeout(this.props.focusTab, 700)
      }
    } else {
      this.setState({rows: rows.setIn([index - 1, 'focusField'], 'trash')})
    }
    $.screenReaderFlashMessage(I18n.t('Proficiency Rating deleted'))
  })

  isStateValid = () =>
    !this.state.rows.some(
      row =>
        this.invalidPoints(row.get('points')) ||
        row.get('points') < 0 ||
        this.invalidDescription(row.get('description'))
    )

  stateToConfig = () => ({
    ratings: this.state.rows
      .map((row, idx) => ({
        description: row.get('description'),
        points: row.get('points'),
        mastery: idx === this.state.masteryIndex,
        color: row.get('color'),
      }))
      .toJS(),
  })

  handleSubmit = () => {
    if (!this.checkForErrors()) {
      // eslint-disable-next-line promise/catch-or-return
      saveProficiency(this.props.accountId, this.stateToConfig()).then(response => {
        if (response.status === 200) {
          $.flashMessage(I18n.t('Account proficiency ratings saved'))
        } else {
          $.flashError(I18n.t('An error occurred while saving account proficiency ratings'))
        }
      })
    }
  }

  checkForErrors = () => {
    let previousPoints = null
    let firstError = true
    const rows = this.state.rows.map(row => {
      let r = row
      if (this.invalidDescription(row.get('description'))) {
        r = r.set('descriptionError', I18n.t('Missing required description'))
        if (firstError) {
          r = r.set('focusField', 'description')
          firstError = false
        }
      }
      if (this.invalidPoints(row.get('points'))) {
        previousPoints = null
        r = r.set('pointsError', I18n.t('Invalid points'))
        if (firstError) {
          r = r.set('focusField', 'points')
          firstError = false
        }
      } else if (row.get('points') < 0) {
        r = r.set('pointsError', I18n.t('Negative points'))
        if (firstError) {
          r = r.set('focusField', 'points')
          firstError = false
        }
      } else {
        const currentPoints = row.get('points')
        if (previousPoints !== null && previousPoints <= currentPoints) {
          r = r.set('pointsError', I18n.t('Points must be less than previous rating'))
          if (firstError) {
            r = r.set('focusField', 'points')
            firstError = false
          }
        }
        previousPoints = currentPoints
      }
      return r
    })
    if (!firstError) {
      this.setState({rows})
    }
    return !firstError
  }

  invalidPoints = points => Number.isNaN(points)

  invalidDescription = description => !description || description.trim().length === 0

  removeBillboard = () => {
    this.setState({billboard: false})
  }

  renderSpinner() {
    return (
      <div style={{textAlign: 'center'}}>
        <Spinner renderTitle={I18n.t('Loading')} size="large" margin="0 0 0 medium" />
      </div>
    )
  }

  renderBillboard() {
    const styles = {
      width: '10rem',
      margin: '0 auto',
    }
    const divStyle = {
      textAlign: 'center',
    }
    return (
      <div style={divStyle}>
        <Billboard
          headingAs="h2"
          headingLevel="h2"
          ref={d => {
            this.triggerRoot = d
          }}
          hero={
            <div style={styles}>
              <PresentationContent>
                <SVGWrapper url="/images/trophy.svg" />
              </PresentationContent>
            </div>
          }
          heading={I18n.t('Customize Learning Mastery Ratings')}
          message={I18n.t(
            `
            Set up how your Proficiency Ratings appear inside of Learning Mastery Gradebook.
            Adjust number of ratings, mastery level, points, and colors.
          `
          ).trim()}
        />
        <Button color="primary" onClick={this.removeBillboard}>
          {I18n.t('Get Started')}
        </Button>
      </div>
    )
  }

  renderTable() {
    const masteryIndex = this.state.masteryIndex
    return (
      <div>
        <Table caption={I18n.t('Proficiency ratings')}>
          <Table.Head>
            <Table.Row>
              <Table.ColHeader id="mastery-column" width="1%">
                {I18n.t('Mastery')}
              </Table.ColHeader>
              <Table.ColHeader id="rating-column">{I18n.t('Proficiency Rating')}</Table.ColHeader>
              <Table.ColHeader id="points-column" width="1%">
                {I18n.t('Points')}
              </Table.ColHeader>
              <Table.ColHeader id="color-column" width="1%">
                {I18n.t('Color')}
              </Table.ColHeader>
            </Table.Row>
          </Table.Head>
          <Table.Body>
            {this.state.rows.map((rating, index) => (
              <ProficiencyRating
                key={rating.get('key')}
                color={rating.get('color')}
                description={rating.get('description')}
                descriptionError={rating.get('descriptionError')}
                disableDelete={this.state.rows.size === 1}
                focusField={rating.get('focusField') || (index === 0 ? 'mastery' : null)}
                points={rating.get('points').toString()}
                pointsError={rating.get('pointsError')}
                mastery={index === masteryIndex}
                onColorChange={this.handleColorChange(index)}
                onDelete={this.handleDelete(index)}
                onDescriptionChange={this.handleDescriptionChange(index)}
                onMasteryChange={this.handleMasteryChange(index)}
                onPointsChange={this.handlePointsChange(index)}
              />
            ))}
            <Table.Row>
              <Table.Cell colSpan="4" textAlign="center">
                <IconButton
                  onClick={this.addRow}
                  renderIcon={<IconPlusLine />}
                  color="primary"
                  shape="circle"
                  screenReaderLabel={I18n.t('Add proficiency rating')}
                />
              </Table.Cell>
            </Table.Row>
          </Table.Body>
        </Table>
        <div className="save">
          <Button color="primary" onClick={this.handleSubmit}>
            {I18n.t('Save Learning Mastery')}
          </Button>
        </div>
      </div>
    )
  }

  render() {
    const {billboard, loading} = this.state
    if (loading) {
      return this.renderSpinner()
    } else if (billboard) {
      return this.renderBillboard()
    } else {
      return this.renderTable()
    }
  }
}
