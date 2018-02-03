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
import KeyboardShortcutModal from '../shared/KeyboardShortcutModal'
import I18n from 'i18n!react_files'

  var SHORTCUTS = [
    { keycode: 'j', description: I18n.t('Next Message') },
    { keycode: 'k', description: I18n.t('Previous Message') },
    { keycode: 'e', description: I18n.t('Edit Current Message') },
    { keycode: 'd', description: I18n.t('Delete Current Message') },
    { keycode: 'r', description: I18n.t('Reply to Current Message') },
    { keycode: 'n', description: I18n.t('Reply to Topic') }
  ];

  var DiscussionTopicKeyboardShortcutModal = React.createClass({
    render() {
      return <KeyboardShortcutModal {...this.props} shortcuts={SHORTCUTS} />;
    }
  });

export default DiscussionTopicKeyboardShortcutModal
