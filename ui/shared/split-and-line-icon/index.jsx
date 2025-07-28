/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {SVGIcon} from '@instructure/ui-svg-images'

const splitView =
  '<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">\n' +
  '<mask id="mask0_653_26399" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="18" height="18">\n' +
  '<path fill-rule="evenodd" clip-rule="evenodd" d="M17.5 7.43094e-07C17.7761 7.55164e-07 18 0.223858 18 0.500001V17.5C18 17.7761 17.7761 18 17.5 18H10.5C10.2239 18 10 17.7761 10 17.5L10 0.500001C10 0.223858 10.2239 4.03187e-07 10.5 4.15258e-07L17.5 7.43094e-07ZM16.6 1C16.8209 1 17 1.17909 17 1.4V16.6C17 16.8209 16.8209 17 16.6 17H11.4C11.1791 17 11 16.8209 11 16.6L11 1.4C11 1.17909 11.1791 1 11.4 1L16.6 1Z" fill="#273540"/>\n' +
  '<path fill-rule="evenodd" clip-rule="evenodd" d="M7.5 6.25858e-07C7.77614 6.37929e-07 8 0.223858 8 0.500001L8 17.5C8 17.7761 7.77614 18 7.5 18H0.5C0.223858 18 -1.20706e-08 17.7761 0 17.5L7.43094e-07 0.5C7.55164e-07 0.223858 0.223859 -1.20706e-08 0.500001 0L7.5 6.25858e-07ZM6.6 1C6.82091 1 7 1.17909 7 1.4L7 16.6C7 16.8209 6.82091 17 6.6 17H1.4C1.17909 17 1 16.8209 1 16.6L1 1.4C1 1.17909 1.17909 1 1.4 1L6.6 1Z" fill="#273540"/>\n' +
  '</mask>\n' +
  '<g mask="url(#mask0_653_26399)">\n' +
  '<rect width="18" height="18" fill="#273540"/>\n' +
  '</g>\n' +
  '</svg>'

const lineView =
  '<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">\n' +
  '<mask id="mask0_653_31518" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="18" height="18">\n' +
  '<path fill-rule="evenodd" clip-rule="evenodd" d="M0 13.83C0 13.5539 0.223858 13.33 0.5 13.33H17.5C17.7761 13.33 18 13.5539 18 13.83V17.5C18 17.7761 17.7761 18 17.5 18H0.5C0.223858 18 0 17.7761 0 17.5V13.83ZM1 14.73C1 14.5091 1.17909 14.33 1.4 14.33H16.6C16.8209 14.33 17 14.5091 17 14.73V16.6C17 16.8209 16.8209 17 16.6 17H1.4C1.17909 17 1 16.8209 1 16.6V14.73Z" fill="#273540"/>\n' +
  '<path fill-rule="evenodd" clip-rule="evenodd" d="M0 7.17C0 6.89386 0.223858 6.67 0.5 6.67H17.5C17.7761 6.67 18 6.89386 18 7.17V10.83C18 11.1061 17.7761 11.33 17.5 11.33H0.5C0.223858 11.33 0 11.1061 0 10.83V7.17ZM1 8.17C1 7.94909 1.17909 7.67 1.4 7.67H16.6C16.8209 7.67 17 7.94909 17 8.17V9.93C17 10.1509 16.8209 10.33 16.6 10.33H1.4C1.17909 10.33 1 10.1509 1 9.93V8.17Z" fill="#273540"/>\n' +
  '<path fill-rule="evenodd" clip-rule="evenodd" d="M0 0.5C0 0.223858 0.223858 0 0.5 0H17.5C17.7761 0 18 0.223858 18 0.5V4.17C18 4.44614 17.7761 4.67 17.5 4.67H0.5C0.223858 4.67 0 4.44614 0 4.17V0.5ZM1 1.4C1 1.17909 1.17909 1 1.4 1H16.6C16.8209 1 17 1.17909 17 1.4V3.27C17 3.49091 16.8209 3.67 16.6 3.67H1.4C1.17909 3.67 1 3.49091 1 3.27V1.4Z" fill="#273540"/>\n' +
  '</mask>\n' +
  '<g mask="url(#mask0_653_31518)">\n' +
  '<rect width="18" height="18" fill="#273540"/>\n' +
  '</g>\n' +
  '</svg>'

export const SplitViewIcon = () => <SVGIcon src={splitView} title="splitview" color="inherit" />
export const LineViewIcon = () => <SVGIcon src={lineView} title="lineview" color="inherit" />
