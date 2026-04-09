//
// Copyright (C) 2026 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import React from 'react'
import {render} from '@canvas/react/index'
import {Tooltip} from '@instructure/ui-tooltip'
import {Portal} from '@instructure/ui-portal'

export default function vddTooltip() {
  const tooltipMount = document.getElementById('vdd_tooltip_mount')
  if (tooltipMount) {
    const allTooltips = document.getElementsByClassName('vdd_tooltip_link')
    const toolTipElements = Array.from(allTooltips).map((tip, index) => {
      try {
        if (tip.closest('.user_content')) return null

        const selector = (tip as HTMLElement).dataset.tooltipSelector
        const el = selector && document.querySelector(selector)
        if (!el) return null

        const tooltipElement = tip.innerHTML
        tip.innerHTML = ''
        return (
          <Portal key={`vdd_tooltip_${index}`} mountNode={tip} open={true}>
            <Tooltip
              renderTip={
                <span
                  data-testid={`vdd_contents_${index}`}
                  dangerouslySetInnerHTML={{__html: el?.innerHTML}}
                />
              }
            >
              <span
                data-testid={`vdd_tooltip_${index}`}
                dangerouslySetInnerHTML={{__html: tooltipElement}}
              />
            </Tooltip>
          </Portal>
        )
      } catch {
        return null
      }
    })

    render(<>{toolTipElements}</>, tooltipMount)
  }
}
