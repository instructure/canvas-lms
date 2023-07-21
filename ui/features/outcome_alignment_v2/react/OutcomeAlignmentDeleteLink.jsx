/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'

const I18n = useI18nScope('OutcomeAlignmentDeleteLink')

class OutcomeAlignmentDeleteLink extends React.Component {
  static propTypes = {
    url: PropTypes.string.isRequired,
    has_rubric_association: PropTypes.string,
  }

  static defaultProps = {
    has_rubric_association: null,
  }

  handleClick = e => {
    const $li = $(e.target).parents('li.alignment')

    e.preventDefault()
    $(e.target).confirmDelete({
      success() {
        $li.fadeOut('slow', function () {
          this.remove()
        })
      },
      url: this.props.url,
    })
  }

  hasRubricAssociation() {
    return this.props.has_rubric_association
  }

  render() {
    if (this.hasRubricAssociation()) {
      return (
        <span className="locked_alignment_link">
          <i className="icon-lock" aria-hidden="true" />
          <span className="screenreader-only">
            {' '}
            {I18n.t(`
              Can't delete alignments based on rubric associations.
              To remove these associations you need to remove the row from the asset's rubric"
            `)}{' '}
          </span>
        </span>
      )
    }
    return (
      // eslint-disable-next-line jsx-a11y/anchor-is-valid
      <a className="delete_alignment_link no-hover" href="" onClick={this.handleClick}>
        <i className="icon-end" aria-hidden="true" />
        <span className="screenreader-only">{I18n.t('Delete alignment')}</span>
      </a>
    )
  }
}

export default OutcomeAlignmentDeleteLink
