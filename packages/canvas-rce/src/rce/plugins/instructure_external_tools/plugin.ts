/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import dispatchInitEvent from './dispatchInitEvent'
import {IconLtiLine} from '@instructure/ui-icons/es/svg'
import clickCallback from './clickCallback'
import tinymce from 'tinymce'
import {TsMigrationAny} from '../../../types/ts-migration'

// Register plugin
tinymce.PluginManager.add('instructure_external_tools', function (ed, url) {
  document.addEventListener('tinyRCE/onExternalTools', (event: TsMigrationAny) => {
    clickCallback(ed, event.detail.ltiButtons)
  })
  ed.ui.registry.addIcon('lti', IconLtiLine.src)
  dispatchInitEvent(ed, document, url)
})
