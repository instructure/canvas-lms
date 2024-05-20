/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'

const I18n = useI18nScope('RubricAddCriterionPopover')

class RubricAddCriterionPopover extends React.Component {
  static propTypes = {
    rubric: PropTypes.instanceOf($).isRequired,
    duplicateFunction: PropTypes.func.isRequired,
  }

  render() {
    const {rubric, duplicateFunction} = this.props
    const rubric_data = rubric
      .find('.criterion:not(.blank)')
      .map(function (i) {
        const $criterion = $(this)
        const vals = $criterion.getTemplateData({textValues: ['description']})
        return {index: i, description: vals.description}
      })
      .toArray()

    return (
      <span>
        <Menu
          placement="bottom"
          trigger={
            // eslint-disable-next-line jsx-a11y/anchor-is-valid
            <a className="icon-plus" href="#">
              {I18n.t('Criterion')}
            </a>
          }
        >
          <Menu.Item
            id="add_criterion_button"
            onClick={() => $('#add_criterion_link').trigger('click')}
          >
            <Text size="small" weight="bold">
              {I18n.t('New Criterion')}
            </Text>
          </Menu.Item>
          <Menu.Separator />
          <Menu.Group id="criterion_duplicate_menu" label={I18n.t('Duplicate')}>
            {rubric_data.map(item => (
              <Menu.Item onClick={() => duplicateFunction(rubric, item.index)} key={item.index}>
                <div className="ellipsis popover_menu_width">{item.description}</div>
              </Menu.Item>
            ))}
          </Menu.Group>
        </Menu>
        {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
        <a
          href="#"
          id="add_learning_outcome_link"
          className="icon-search find_outcome_link outcome"
          role="button"
        >
          {I18n.t('Find Outcome')}
        </a>
        {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
        <a
          href="#"
          id="add_criterion_link"
          className="hidden icon-plus add_criterion_link"
          role="button"
        >
          {I18n.t('New Criterion')}
        </a>
      </span>
    )
  }
}

export default RubricAddCriterionPopover
