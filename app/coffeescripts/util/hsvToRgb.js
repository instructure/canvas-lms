//
// Copyright (C) 2012 - present Instructure, Inc.
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

// copy/pasted from:
// http://matthaynes.net/blog/2008/08/07/javascript-colour-functions/

// /**
// * Converts HSV to RGB value.
// *
// * @param {Integer} h Hue as a value between 0 - 360 degrees
// * @param {Integer} s Saturation as a value between 0 - 100 %
// * @param {Integer} v Value as a value between 0 - 100 %
// * @returns {Array} The RGB values  EG: [r,g,b], [255,255,255]
// */
export default function hsvToRgb(h, s, v) {
  s = s / 100
  v = v / 100
  const hi = Math.floor((h / 60) % 6)
  const f = h / 60 - hi
  const p = v * (1 - s)
  const q = v * (1 - f * s)
  const t = v * (1 - (1 - f) * s)
  let rgb = []

  switch (hi) {
    case 0:
      rgb = [v, t, p]
      break
    case 1:
      rgb = [q, v, p]
      break
    case 2:
      rgb = [p, v, t]
      break
    case 3:
      rgb = [p, q, v]
      break
    case 4:
      rgb = [t, p, v]
      break
    case 5:
      rgb = [v, p, q]
      break
  }

  const r = Math.min(255, Math.round(rgb[0] * 256))
  const g = Math.min(255, Math.round(rgb[1] * 256))
  const b = Math.min(255, Math.round(rgb[2] * 256))

  return [r, g, b]
}
