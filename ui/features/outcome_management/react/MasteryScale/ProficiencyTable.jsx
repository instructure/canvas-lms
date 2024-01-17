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
import PropTypes from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconPlusLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import ProficiencyRating from './ProficiencyRating'
import {v1 as uuid} from 'uuid'
import {memoize, isEqual} from 'lodash'
import {fromJS, List} from 'immutable'
import NumberHelper from '@canvas/i18n/numberHelper'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'
import ConfirmMasteryModal from '../ConfirmMasteryModal'

const I18n = useI18nScope('ProficiencyTable')

const ADD_DEFAULT_COLOR = 'EF4437'

function unformatColor(color) {
  if (color[0] === '#') {
    return color.substring(1)
  }
  return color
}
const createRating = (description, points, color, mastery = false, focusField = null) => ({
  description,
  points,
  key: uuid(),
  color,
  mastery,
  focusField,
})

const configToState = data => {
  const rows = List(
    data.proficiencyRatingsConnection.nodes.map(rating =>
      fromJS(createRating(rating.description, rating.points, rating.color, rating.mastery))
    )
  )
  return {
    rows,
    savedRows: rows,
    showConfirmation: false,
  }
}
class ProficiencyTable extends React.Component {
  static propTypes = {
    proficiency: PropTypes.object,
    canManage: PropTypes.bool.isRequired,
    update: PropTypes.func.isRequired,
    focusTab: PropTypes.func,
    breakpoints: breakpointsShape,
    contextType: PropTypes.string.isRequired,
    onNotifyPendingChanges: PropTypes.func,
  }

  static defaultProps = {
    proficiency: {
      proficiencyRatingsConnection: {
        nodes: [
          createRating(I18n.t('Exceeds Mastery'), 4, '127A1B'),
          createRating(I18n.t('Mastery'), 3, '0B874B', true),
          createRating(I18n.t('Near Mastery'), 2, 'FAB901'),
          createRating(I18n.t('Below Mastery'), 1, 'FD5D10'),
          createRating(I18n.t('Well Below Mastery'), 0, 'E0061F'),
        ],
      },
    },
    canManage: window.ENV?.PERMISSIONS ? ENV.PERMISSIONS.manage_proficiency_scales : true,
    focusTab: null,
    breakpoints: {},
  }

  constructor(props) {
    super(props)
    this.state = configToState(props.proficiency)
  }

  componentDidUpdate() {
    if (this.fieldWithFocus()) {
      this.setState(
        ({rows}) => ({rows: rows.map(row => row.delete('focusField'))}),
        this.notifyPendingChanges
      )
    }
  }

  notifyPendingChanges = () => {
    if (this.props.onNotifyPendingChanges) {
      this.props.onNotifyPendingChanges(this.hasPendingChanges())
    }
  }

  hasPendingChanges = () => {
    const {rows, savedRows} = this.state

    return !isEqual(rows, savedRows)
  }

  hideConfirmationModal = () => this.setState({showConfirmation: false})

  fieldWithFocus = () => this.state.rows.some(row => row.get('focusField'))

  addRow = () => {
    this.setState(
      ({rows}) => {
        let points = 0.0
        const last = rows.last()
        if (last) {
          points = last.get('points') - 1.0
        }
        if (points < 0.0 || Number.isNaN(points)) {
          points = 0.0
        }
        const newRow = fromJS(createRating('', points, ADD_DEFAULT_COLOR, false, 'mastery'))
        return {rows: rows.push(newRow)}
      },
      () => {
        this.notifyPendingChanges()
        showFlashAlert({
          message: I18n.t('Added mastery level'),
          type: 'success',
          srOnly: true,
        })
      }
    )
  }

  confirmSubmit = () => {
    if (!this.checkForErrors()) {
      this.setState({showConfirmation: true})
    }
  }

  handleSubmit = () => {
    let oldRows
    this.setState(
      ({savedRows}) => {
        oldRows = savedRows
        const sortedRows = this.sortRows()
        return {
          showConfirmation: false,
          rows: sortedRows,
          savedRows: sortedRows,
        }
      },
      () => {
        this.notifyPendingChanges()
        this.props
          .update(this.stateToConfig())
          .then(() =>
            showFlashAlert({
              message: I18n.t('Mastery scale saved'),
              type: 'success',
            })
          )
          .catch(e => {
            showFlashAlert({
              message: I18n.t('An error occurred while saving the mastery scale: %{message}', {
                message: e.message,
              }),
              type: 'error',
            })
            this.setState({savedRows: oldRows}, this.notifyPendingChanges)
          })
      }
    )
  }

  handleMasteryChange = memoize(index => () => {
    this.setState(({rows}) => {
      const masteryIndex = rows.findIndex(row => row.get('mastery'))
      const adjustedRows = rows
        .setIn([masteryIndex, 'mastery'], false)
        .setIn([index, 'mastery'], true)
      return {rows: adjustedRows}
    }, this.notifyPendingChanges)
  })

  handleDescriptionChange = memoize(index => value => {
    this.setState(({rows}) => {
      if (!this.invalidDescription(value)) {
        rows = rows.removeIn([index, 'descriptionError'])
      }
      rows = rows.setIn([index, 'description'], value)
      return {rows}
    }, this.notifyPendingChanges)
  })

  handlePointsChange = memoize(index => value => {
    this.setState(({rows}) => {
      const parsed = NumberHelper.parse(value)
      if (!this.invalidPoints(parsed) && parsed >= 0) {
        rows = rows.removeIn([index, 'pointsError'])
      }
      rows = rows.setIn([index, 'points'], parsed)
      return {rows}
    }, this.notifyPendingChanges)
  })

  handleColorChange = memoize(index => value => {
    this.setState(
      ({rows}) => ({
        rows: rows.update(index, row => row.set('color', unformatColor(value))),
      }),
      this.notifyPendingChanges
    )
  })

  handleDelete = memoize(index => () => {
    const masteryIndex = this.state.rows.findIndex(row => row.get('mastery'))
    let rows = this.state.rows.delete(index)

    if (masteryIndex === index) {
      if (masteryIndex > 0) {
        rows = rows.setIn([masteryIndex - 1, 'mastery'], true)
      } else {
        rows = rows.setIn([masteryIndex, 'mastery'], true)
      }
    }

    if (index === 0) {
      this.setState({rows}, this.notifyPendingChanges)
      if (this.props.focusTab) {
        setTimeout(this.props.focusTab, 700)
      }
    } else {
      this.setState(
        {
          rows: rows.setIn([index - 1, 'focusField'], 'trash'),
        },
        this.notifyPendingChanges
      )
    }
    showFlashAlert({
      message: I18n.t('Mastery level deleted'),
      type: 'success',
      srOnly: true,
    })
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
      .map(row => ({
        description: row.get('description'),
        points: row.get('points'),
        mastery: row.get('mastery'),
        color: row.get('color'),
      }))
      .toJS(),
  })

  sortRows = () => this.state.rows.sortBy(row => -row.get('points'))

  checkForErrors = () => {
    let hasError = false
    let changed = false
    const allPoints = this.state.rows.map(row => row.get('points'))
    const rows = this.state.rows.map((row, index) => {
      let r = row
      if (this.invalidDescription(row.get('description'))) {
        if (!hasError) {
          r = r.set('focusField', 'description')
        }
        hasError = true
        r = r.set('descriptionError', I18n.t('Missing required description'))
      } else {
        r = r.delete('descriptionError')
      }
      if (this.invalidPoints(row.get('points'))) {
        if (!hasError) {
          r = r.set('focusField', 'points')
        }
        hasError = true
        r = r.set('pointsError', I18n.t('Invalid points'))
      } else if (row.get('points') < 0) {
        if (!hasError) {
          r = r.set('focusField', 'points')
        }
        hasError = true
        r = r.set('pointsError', I18n.t('Negative points'))
      } else {
        const currentPoints = row.get('points')
        const firstIndex = allPoints.findIndex(points => points === currentPoints)
        if (index !== firstIndex) {
          if (!hasError) {
            r = r.set('focusField', 'points')
          }
          hasError = true
          r = r.set('pointsError', I18n.t('Points must be unique'))
        } else {
          r = r.delete('pointsError')
        }
      }
      changed = changed || r !== row
      return r
    })
    if (changed) {
      this.setState({rows}, this.notifyPendingChanges)
    }
    return hasError
  }

  renderBorder = () => {
    return (
      <View
        width="100%"
        textAlign="start"
        margin="0 0 small 0"
        as="div"
        borderWidth="none none small none"
      />
    )
  }

  invalidPoints = points => Number.isNaN(points)

  invalidDescription = description => !description || description.trim().length === 0

  getModalText = () => {
    const {contextType} = this.props
    if (contextType === 'Course') {
      return I18n.t(
        'This will update all rubrics aligned to outcomes within this course that have not yet been assessed.'
      )
    }
    return I18n.t(
      'This will update all account and course level rubrics that are tied to the account level mastery scale and have not yet been assessed.'
    )
  }

  render() {
    const {showConfirmation} = this.state
    const {breakpoints, canManage} = this.props
    const isMobileView = breakpoints.mobileOnly
    return (
      <>
        <Flex width="100%" padding={isMobileView ? '0 0 small 0' : '0 small small small'}>
          <Flex.Item size={isMobileView ? '25%' : '15%'} padding="0 medium 0 0">
            <div aria-hidden="true" className="header">
              {I18n.t('Mastery')}
            </div>
          </Flex.Item>
          <Flex.Item size={isMobileView ? '75%' : '40%'}>
            <div aria-hidden="true" className="header">
              {isMobileView ? I18n.t('Mastery Levels') : I18n.t('Description')}
            </div>
          </Flex.Item>
          {!isMobileView && (
            <>
              <Flex.Item size="15%">
                <div aria-hidden="true" className="header">
                  {I18n.t('Points')}
                </div>
              </Flex.Item>
              <Flex.Item padding="0 0 0 small">
                <div aria-hidden="true" className="header">
                  {I18n.t('Color')}
                </div>
              </Flex.Item>
            </>
          )}
        </Flex>
        {this.renderBorder()}
        {this.state.rows.map((rating, index) => (
          <React.Fragment key={rating.get('key')}>
            <ProficiencyRating
              color={rating.get('color')}
              description={rating.get('description')}
              descriptionError={rating.get('descriptionError')}
              disableDelete={this.state.rows.size === 1}
              focusField={rating.get('focusField') || (index === 0 ? 'mastery' : null)}
              points={rating.get('points').toString()}
              pointsError={rating.get('pointsError')}
              mastery={rating.get('mastery')}
              onColorChange={this.handleColorChange(index)}
              onDelete={this.handleDelete(index)}
              onDescriptionChange={this.handleDescriptionChange(index)}
              onMasteryChange={this.handleMasteryChange(index)}
              onPointsChange={this.handlePointsChange(index)}
              position={index + 1}
              isMobileView={isMobileView}
              canManage={canManage}
            />
            {this.renderBorder()}
          </React.Fragment>
        ))}
        {canManage && (
          <>
            <View
              width="100%"
              textAlign="start"
              padding="small small medium small"
              as="div"
              borderWidth="none none small none"
            >
              <Button onClick={this.addRow} renderIcon={<IconPlusLine />}>
                {I18n.t('Add Mastery Level')}
              </Button>
            </View>
            <div className="save">
              <Button
                color="primary"
                interaction={this.hasPendingChanges() ? 'enabled' : 'disabled'}
                onClick={this.confirmSubmit}
              >
                {I18n.t('Save Mastery Scale')}
              </Button>
            </div>
            <ConfirmMasteryModal
              isOpen={showConfirmation}
              onConfirm={this.handleSubmit}
              modalText={this.getModalText()}
              title={I18n.t('Confirm Mastery Scale')}
              onClose={this.hideConfirmationModal}
            />
          </>
        )}
      </>
    )
  }
}
export default WithBreakpoints(ProficiencyTable)
