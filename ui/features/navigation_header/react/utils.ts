/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

type CommonProperties = {
  href: string | null | undefined
  isActive: boolean
  label: string
}

type SvgTool = CommonProperties & {svgPath: string}
type ImgTool = CommonProperties & {imgSrc: string}

export type ExternalTool = SvgTool | ImgTool

export function getExternalTools(): ExternalTool[] {
  return Array.from(document.querySelectorAll('.globalNavExternalTool')).map(el => {
    const svg = el.querySelector('svg')
    return {
      href: el.querySelector('a')?.getAttribute('href'),
      isActive: el.classList.contains('ic-app-header__menu-list-item--active'),
      label: (el.querySelector('.menu-item__text') as HTMLDivElement)?.innerText || '',
      ...(svg
        ? {svgPath: svg.innerHTML}
        : {imgSrc: (el.querySelector('img') as HTMLImageElement)?.getAttribute('src') || ''}),
    }
  })
}
