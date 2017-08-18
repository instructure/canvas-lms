/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import I18n from 'i18n!custom_help_link'
import CustomHelpLinkPropTypes from './CustomHelpLinkPropTypes'
  const CustomHelpLinkHiddenInputs = React.createClass({
    propTypes: {
      link: CustomHelpLinkPropTypes.link.isRequired
    },
    render () {
      const {
        text,
        url,
        subtext,
        available_to,
        type,
        index,
        state,
        id
      } = this.props.link
      const namePrefix = `account[custom_help_links][${index}]`
      return (
        <span>
          <input type="hidden" name={`${namePrefix}[id]`} value={id} />
          <input type="hidden" name={`${namePrefix}[text]`} value={text} />
          <input type="hidden" name={`${namePrefix}[subtext]`} value={subtext} />
          <input type="hidden" name={`${namePrefix}[url]`} value={url} />
          <input type="hidden" name={`${namePrefix}[type]`} value={type} />
          <input type="hidden" name={`${namePrefix}[state]`} value={state} />
          {
            available_to && available_to.map(value =>
              <input type="hidden" key={value} name={`${namePrefix}[available_to][]`} value={value} />
            )
          }
        </span>
      )
    }
  });

export default CustomHelpLinkHiddenInputs
