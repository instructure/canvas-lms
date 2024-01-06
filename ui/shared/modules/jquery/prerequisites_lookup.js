/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import htmlEscape from '@instructure/html-escape'
import Spinner from 'spin.js'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_misc_helpers'

const I18n = useI18nScope('prerequisites_lookup')

let lookupStarted = false

INST.lookupPrerequisites = function () {
  if (lookupStarted) {
    return
  }

  const $link = $('#module_prerequisites_lookup_link')
  if ($link.length == 0) {
    return
  }
  lookupStarted = true

  const url = $link.attr('x-canvaslms-trusted-url')

  const spinner = new Spinner({radius: 5})
  spinner.spin()
  $(spinner.el).css({opacity: 0.5, top: '25px', left: '200px'}).appendTo('.spinner')

  $.ajaxJSON(
    url,
    'GET',
    {},
    function (data) {
      spinner.stop()
      if (data.locked === false) {
        return
      }
      const $ul = $('<ul/>')
      $ul.attr('id', 'module_prerequisites_list')
      for (const idx in data.modules) {
        const module = data.modules[idx]
        const $li = $('<li/>')
        const $i = $('<i/>')
        $li.addClass('module')
        $li.click(function () {
          $(this).find('ul').toggle()
        })
        $li.toggleClass('locked', !!module.locked)
        if (module.locked) {
          $i.addClass('icon-lock')
        }
        $li.append($i)
        const $h3 = $('<h3/>')
        $h3.text(module.name)
        $li.append($h3)
        if (module.prerequisites && module.prerequisites.length > 0) {
          const $pres = $('<ul/>')
          for (const jdx in module.prerequisites) {
            const pre = module.prerequisites[jdx]
            const $pre = $('<li/>')
            $pre.addClass('requirement')
            $pre.toggleClass('locked_requirement', !pre.available)
            const $a = $('<a/>')
            $a.attr('href', pre.url)
            $a.text(pre.title)
            $a.toggleClass('icon-lock', !pre.available)
            $pre.append($a)
            const desc = pre.requirement_description
            if (desc) {
              const $div = $('<div/>')
              $div.addClass('description')
              $div.text(desc)
              $pre.append($div)
            }
            $pres.append($pre)
          }
          $li.append($pres)
        }
        $ul.append($li)
      }
      $link.after($ul)
      const header = I18n.t('headers.completion_prerequisites', 'Completion Prerequisites')
      const sentence = I18n.beforeLabel(
        I18n.t(
          'labels.requirements_must_be_completed',
          'The following requirements need to be completed before this page will be unlocked'
        )
      )
      $link.after(
        "<br/><h2 style='margin-top: 15px;'>" + htmlEscape(header) + '</h2>' + htmlEscape(sentence)
      )
      $link.prev('a').hide()
    },
    _data => {
      spinner.stop()
      $('.module_prerequisites_fallback').show()
    }
  )
}
$(document).ready(INST.lookupPrerequisites)
