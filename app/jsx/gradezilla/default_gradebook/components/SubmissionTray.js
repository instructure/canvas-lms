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
import { bool, func } from 'prop-types';
import ComingSoonContent from 'jsx/gradezilla/default_gradebook/components/ComingSoonContent';
import Tray from 'instructure-ui/lib/components/Tray';
import I18n from 'i18n!gradebook';

export default function SubmissionTray (props) {
  return (
    <Tray
      label={I18n.t('Submission tray')}
      isDismissable
      closeButtonLabel={I18n.t('Close submission tray')}
      isOpen={props.isOpen}
      trapFocus
      placement="end"
      onRequestClose={props.onRequestClose}
      onClose={props.onClose}
    >
      <div className="SubmissionTray__Container">
        {props.showContentComingSoon && <ComingSoonContent />}
      </div>
    </Tray>
  );
}

SubmissionTray.propTypes = {
  onRequestClose: func.isRequired,
  onClose: func.isRequired,
  showContentComingSoon: bool.isRequired,
  isOpen: bool.isRequired
};
