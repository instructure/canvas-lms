/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import I18n from 'i18n!external_tools'
import React from 'react'

export default React.createClass({
    displayName: 'Header',

    render() {

      const paragraph = I18n.t(
        '*See some LTI tools* that work great with Canvas.',
        { wrappers: [
          '<a href="https://www.eduappcenter.com/">$1</a>',
        ]}
      );

      return (
        <div className="Header">
          <h2 className="page-header" ref="pageHeader">
            <span className="externalApps_label_text">{I18n.t('External Apps')}</span>
            <div className="externalApps_buttons_container">
              {this.props.children}
            </div>
          </h2>

          <div>
            <p>{I18n.t('Apps are an easy way to add new features to Canvas. They can be added to individual courses, or to all courses in an account. Once configured, you can link to them through course modules and create assignments for assessment tools.')}</p>
            <p dangerouslySetInnerHTML={{ __html: paragraph }}></p>
          </div>
        </div>
      )
    }
  });
