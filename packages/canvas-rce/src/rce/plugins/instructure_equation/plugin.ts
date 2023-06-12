// @ts-nocheck
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

import formatMessage from '../../../format-message'
import clickCallback from './clickCallback'
import {IconEquationLine} from '@instructure/ui-icons/es/svg'
import tinymce from 'tinymce'

function isEquationImage(node: Element) {
  return (
    (node.tagName === 'IMG' && node.classList.contains('equation_image')) ||
    node.classList.contains('math_equation_latex')
  )
}

// Register plugin
tinymce.PluginManager.add('instructure_equation', function (ed) {
  ed.ui.registry.addIcon('equation', IconEquationLine.src)

  ed.addCommand('instructureEquation', () => clickCallback(ed, document))

  ed.ui.registry.addMenuItem('instructure_equation', {
    text: formatMessage('Equation'),
    icon: 'equation',
    onAction: () => ed.execCommand('instructureEquation'),
  })

  ed.ui.registry.addToggleButton('instructure_equation', {
    tooltip: formatMessage({
      default: 'Insert Math Equation',
      description: 'Title for RCE button to insert a math equation',
    }),
    onAction: () => ed.execCommand('instructureEquation'),
    icon: 'equation',
    onSetup(buttonApi) {
      const toggleActive = eventApi => {
        buttonApi.setActive(isEquationImage(eventApi.element))
      }
      ed.on('NodeChange', toggleActive)
      return () => ed.off('NodeChange', toggleActive)
    },
  })

  ed.ui.registry.addButton('instructure-equation-options', {
    onAction(/* buttonApi */) {
      ed.execCommand('instructureEquation')
    },

    text: formatMessage('Edit Equation'),
  })

  ed.ui.registry.addContextToolbar('instructure-equation-toolbar', {
    items: 'instructure-equation-options',
    position: 'node',
    predicate: isEquationImage,
    scope: 'node',
  })
})
