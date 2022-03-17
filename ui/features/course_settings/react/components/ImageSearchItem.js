/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('image_search')

class ImageSearchItem extends React.Component {
  static propTypes = {
    description: PropTypes.string,
    src: PropTypes.string,
    confirmationId: PropTypes.string,
    selectImage: PropTypes.func,
    userUrl: PropTypes.string,
    userName: PropTypes.string
  }

  handleClick = () => {
    this.props.selectImage(this.props.src, this.props.confirmationId)
  }

  render() {
    return (
      <div className="ImageSearch__wrapper">
        <button className="ImageSearch__item" type="button" onClick={this.handleClick}>
          <img className="ImageSearch__img" alt={this.props.description} src={this.props.src} />
        </button>
        <div className="ImageSearch__attribution">
          <a href={this.props.userUrl} target="_blank" rel="noopener noreferrer">
            <ScreenReaderContent>
              {I18n.t('Artist info for %{userName} for %{description}', {
                userName: this.props.userName,
                description: this.props.description
              })}
            </ScreenReaderContent>
            <PresentationContent>{this.props.userName}</PresentationContent>
          </a>
        </div>
      </div>
    )
  }
}

export default ImageSearchItem
