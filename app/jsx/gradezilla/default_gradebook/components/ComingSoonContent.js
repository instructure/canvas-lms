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
import SVGWrapper from 'jsx/shared/SVGWrapper';
import Typography from 'instructure-ui/lib/components/Typography';
import I18n from 'i18n!gradebook';

export default function ContentComingSoon () {
  return (
    <div className="ComingSoonContent__Container">
      <div className="ComingSoonContent__Body">
        <SVGWrapper url="/images/gift_closed.svg" />
        <Typography size="xx-large" weight="light">{I18n.t('New goodies coming soon!')}</Typography>
        <br />
        <Typography weight="bold">{I18n.t('Check back in a little while.')}</Typography>
      </div>
    </div>
  );
}
