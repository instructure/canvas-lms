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

import I18n from 'i18n!gradebook';
import React from 'react';
import ReactDOM from 'react-dom';
import CustomColumnHeader from './CustomColumnHeader'

function getProps (column, gradebook, options) {
  const customColumn = gradebook.getCustomColumn(column.customColumnId);

  return {
    ref: options.ref,
    title: customColumn.teacher_notes ? I18n.t('Notes') : customColumn.title
  };
}

export default class CustomColumnHeaderRenderer {
  constructor (gradebook) {
    this.gradebook = gradebook;
  }

  render (column, $container, _gridSupport, options) {
    const props = getProps(column, this.gradebook, options);
    ReactDOM.render(<CustomColumnHeader {...props} />, $container);
  }

  destroy (_column, $container, _gridSupport) {
    ReactDOM.unmountComponentAtNode($container);
  }
}
