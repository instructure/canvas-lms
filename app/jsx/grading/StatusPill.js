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

import React from 'react';
import ReactDOM from 'react-dom';
import Pill from '@instructure/ui-core/lib/components/Pill';
import I18n from 'i18n!gradebook';

function forEachNode (nodeList, fn) {
  for (let i = 0; i < nodeList.length; i += 1) {
    fn(nodeList[i]);
  }
}

export default {
  renderPills () {
    const missMountPoints = document.querySelectorAll('.submission-missing-pill');
    const lateMountPoints = document.querySelectorAll('.submission-late-pill');

    forEachNode(missMountPoints, (mountPoint) => {
      ReactDOM.render(<Pill variant="danger" text={I18n.t('missing')} />, mountPoint);
    });

    forEachNode(lateMountPoints, (mountPoint) => {
      ReactDOM.render(<Pill variant="danger" text={I18n.t('late')} />, mountPoint);
    });
  }
};
