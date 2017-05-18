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
import I18n from 'i18n!react_files'
import FilesUsage from 'compiled/react_files/components/FilesUsage'
import friendlyBytes from 'compiled/util/friendlyBytes'

  FilesUsage.render = function () {
    if (this.state) {
      const percentUsed = Math.round(this.state.quota_used / this.state.quota * 100);
      const label = I18n.t('%{percentUsed} of %{bytesAvailable} used', {
        percentUsed: I18n.n(percentUsed, { percentage: true }),
        bytesAvailable: friendlyBytes(this.state.quota)
      });
      const srLabel = I18n.t('Files Quota: %{percentUsed} of %{bytesAvailable} used', {
        percentUsed: I18n.n(percentUsed, { percentage: true }),
        bytesAvailable: friendlyBytes(this.state.quota)
      });
      return (
        <div className='grid-row ef-quota-usage'>
          <div className='col-xs-5'>
            <div ref='container' className='progress-bar__bar-container' aria-hidden={true}>
              <div
                ref='bar'
                className='progress-bar__bar'
                style={{
                  width: Math.min(percentUsed, 100) + '%'
                }}
              />
            </div>
          </div>
          <div className='col-xs-7' style={{paddingLeft: '0px'}} aria-hidden={true}>
            {label}
          </div>
          <div className='screenreader-only'>{srLabel}</div>
        </div>
      );
    } else {
      return <div />;
    }
  };

export default React.createClass(FilesUsage)
