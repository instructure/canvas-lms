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
import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconPlusLine} from '@instructure/ui-icons'
import I18n from 'i18n!ProficiencyTable'
import {View} from '@instructure/ui-view'
import ProficiencyRating from './ProficiencyRating'
import uuid from 'uuid/v1'
import _ from 'lodash'
import {fromJS, List} from 'immutable'
import NumberHelper from '../../shared/helpers/numberHelper'
import WithBreakpoints, {breakpointsShape} from '../../shared/WithBreakpoints'
import ConfirmMasteryScaleEdit from 'jsx/outcomes/ConfirmMasteryScaleEdit'

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
  focusField
})

const configToState = data => {
  const rows = List(
    data.proficiencyRatingsConnection.nodes.map(rating =>
      fromJS(createRating(rating.description, rating.points, rating.color))
    )
  )
  const masteryIndex = data.proficiencyRatingsConnection.nodes.findIndex(rating => rating.mastery)
  return {
    masteryIndex,
    rows,
    allowSave: false,
    showConfirmation: false
  }
}
class ProficiencyTable extends React.Component {
  static propTypes = {
    proficiency: PropTypes.object,
    canManage: PropTypes.bool.isRequired,
    update: PropTypes.func.isRequired,
    focusTab: PropTypes.func,
    breakpoints: breakpointsShape,
    contextType: PropTypes.string.isRequired
  }

  static defaultProps = {
    proficiency: {
      proficiencyRatingsConnection: {
        nodes: [
          createRating(I18n.t('Exceeds Mastery'), 4, '127A1B'),
          createRating(I18n.t('Mastery'), 3, '00AC18', true),
          createRating(I18n.t('Near Mastery'), 2, 'FAB901'),
          createRating(I18n.t('Below Mastery'), 1, 'FD5D10'),
          createRating(I18n.t('Well Below Mastery'), 0, 'EE0612')
        ]
      }
    },
    canManage: window.ENV?.PERMISSIONS ? ENV.PERMISSIONS.manage_proficiency_scales : true,
    focusTab: null,
    breakpoints: {}
  }

  constructor(props) {
    super(props)
    this.state = configToState(props.proficiency)
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.fieldWithFocus()) {
      // eslint-disable-next-line react/no-did-update-set-state
      this.setState(({rows}) => ({rows: rows.map(row => row.delete('focusField'))}))
    }

    const {masteryIndex, rows, allowSave} = this.state

    if (
      !allowSave &&
      !(_.isEqual(prevState.rows, rows) && prevState.masteryIndex === masteryIndex)
    ) {
      this.enableSaveButton()
    }
  }

  enableSaveButton = () => this.setState({allowSave: true})

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
        const newRow = fromJS(createRating('', points, ADD_DEFAULT_COLOR, null, 'mastery'))
        return {rows: rows.push(newRow)}
      },
      () => {
        $.screenReaderFlashMessage(I18n.t('Added new proficiency rating'))
      }
    )
  }

  confirmSubmit = () => {
    if (!this.checkForErrors()) {
      this.setState({showConfirmation: true})
    }
  }

  handleSubmit = () => {
    this.setState({allowSave: false, showConfirmation: false}, () => {
      this.props
        .update(this.stateToConfig())
        .then(() => $.flashMessage(I18n.t('Account proficiency ratings saved')))
        .catch(e => {
          $.flashError(
            I18n.t('An error occurred while saving account proficiency ratings: %{message}', {
              message: e.message
            })
          )
        })
    })
  }

  handleMasteryChange = _.memoize(index => () => {
    this.setState({masteryIndex: index})
  })

  handleDescriptionChange = _.memoize(index => value => {
    this.setState(({rows}) => {
      if (!this.invalidDescription(value)) {
        rows = rows.removeIn([index, 'descriptionError'])
      }
      rows = rows.setIn([index, 'description'], value)
      return {rows}
    })
  })

  handlePointsChange = _.memoize(index => value => {
    this.setState(({rows}) => {
      const parsed = NumberHelper.parse(value)
      if (!this.invalidPoints(parsed) && parsed >= 0) {
        rows = rows.removeIn([index, 'pointsError'])
      }
      rows = rows.setIn([index, 'points'], parsed)
      return {rows}
    })
  })

  handleColorChange = _.memoize(index => value => {
    this.setState(({rows}) => ({
      rows: rows.update(index, row => row.set('color', unformatColor(value)))
    }))
  })

  handleDelete = _.memoize(index => () => {
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
        color: row.get('color')
      }))
      .toJS()
  })

  checkForErrors = () => {
    let previousPoints = null
    let hasError = false
    let changed = false
    const rows = this.state.rows.map(row => {
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
        previousPoints = null
        r = r.set('pointsError', I18n.t('Invalid points'))
      } else if (row.get('points') < 0) {
        if (!hasError) {
          r = r.set('focusField', 'points')
        }
        hasError = true
        r = r.set('pointsError', I18n.t('Negative points'))
      } else {
        const currentPoints = row.get('points')
        if (previousPoints !== null && previousPoints <= currentPoints) {
          if (!hasError) {
            r = r.set('focusField', 'points')
          }
          hasError = true
          r = r.set('pointsError', I18n.t('Points must be less than previous rating'))
        } else {
          r = r.delete('pointsError')
        }
        previousPoints = currentPoints
      }
      changed = changed || r !== row
      return r
    })
    if (changed) {
      this.setState({rows})
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

  render() {
    const {allowSave, masteryIndex, showConfirmation} = this.state
    const {breakpoints, canManage, contextType} = this.props
    const isMobileView = breakpoints.mobileOnly
    return (
      <>
        <Flex width="100%" padding={`${isMobileView ? '0 0 small 0' : '0 small small small'}`}>
          <Flex.Item size={isMobileView ? '25%' : '15%'} padding="0 medium 0 0">
            <div aria-hidden="true" className="header">
              {I18n.t('Mastery')}
            </div>
          </Flex.Item>
          <Flex.Item size={isMobileView ? '75%' : '40%'}>
            <div aria-hidden="true" className="header">
              {isMobileView ? I18n.t('Proficiency Level') : I18n.t('Description')}
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
              mastery={index === masteryIndex}
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
                {I18n.t('Add Proficiency Level')}
              </Button>
            </View>
            <div className="save">
              <Button
                variant="primary"
                interaction={allowSave ? 'enabled' : 'disabled'}
                onClick={this.confirmSubmit}
              >
                {I18n.t('Save Mastery Scale')}
              </Button>
            </div>
            <ConfirmMasteryScaleEdit
              isOpen={showConfirmation}
              contextType={contextType}
              onConfirm={this.handleSubmit}
              onClose={this.hideConfirmationModal}
            />
          </>
        )}
      </>
    )
  }
}
export default WithBreakpoints(ProficiencyTable)
