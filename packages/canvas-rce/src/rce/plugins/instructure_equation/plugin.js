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

import htmlEscape from 'escape-html'
import formatMessage from '../../../format-message'
import clickCallback from './clickCallback'
import {IconEquationLine} from '@instructure/ui-icons/es/svg'

tinymce.create('tinymce.plugins.InstructureEquation', {
  init(ed) {
    ed.ui.registry.addIcon('equation', IconEquationLine.src)

    ed.addCommand('instructureEquation', clickCallback.bind(this, ed, document))

    ed.ui.registry.addToggleButton('instructure_equation', {
      tooltip: htmlEscape(
        formatMessage({
          default: 'Insert Math Equation',
          description: 'Title for RCE button to insert a math equation'
        })
      ),
      onAction: () => ed.execCommand('instructureEquation'),
      icon: 'equation',
      onSetup(buttonApi) {
        const toggleActive = eventApi => {
          buttonApi.setActive(
            eventApi.element.nodeName.toLowerCase() === 'IMG' &&
              eventApi.element.className === 'equation_image'
          )
        }
        ed.on('NodeChange', toggleActive)
        return () => ed.off('NodeChange', toggleActive)
      }
    })
  }
})

// Register plugin
tinymce.PluginManager.add('instructure_equation', tinymce.plugins.InstructureEquation)
