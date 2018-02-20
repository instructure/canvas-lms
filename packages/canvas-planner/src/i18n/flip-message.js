/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import parse from 'format-message-parse';
import print from 'format-message-print';
import { reverse } from 'esrever';

const PREFIX_EMOJI = [
  '(╯°□°）╯︵',
  '(ﾉಥ益ಥ）ﾉ',
  '(ノಠ益ಠ)ノ彡',
  '(J °O°)J ',
  '(ノ ゜Д゜)ノ ︵',
  '(╯\'□\')╯︵',
  'ʕノ•ᴥ•ʔノ',
  '┗[© ♒ ©]┛ ︵',
];

const POSTFIX_EMOJI = [
  '︵ヽ(`Д´)ﾉ',
  ' /(.□. \\）',
  '︵ ~ (._.)',
  ' ( \\o°o)\\',
  ' ლ(⌒-⌒ლ)',
];

const INVERTED = {
  'a': '\u0250',
  'b': 'q',
  'c': '\u0254',
  'd': 'p',
  'e': '\u01DD',
  'f': '\u025F',
  'g': '\u0183',
  'h': '\u0265',
  'i': '\u1D09',
  'j': '\u027E',
  'k': '\u029E',
  'm': '\u026F',
  'n': 'u',
  'r': '\u0279',
  't': '\u0287',
  'v': '\u028C',
  'w': '\u028D',
  'y': '\u028E',
  'A': '\u2200',
  'C': '\u0186',
  'E': '\u018E',
  'F': '\u2132',
  'G': '\u05E4',
  'H': 'H',
  'I': 'I',
  'J': '\u017F',
  'L': '\u02E5',
  'M': 'W',
  'N': 'N',
  'P': '\u0500',
  'T': '\u2534',
  'U': '\u2229',
  'V': '\u039B',
  'Y': '\u2144',
  '1': '\u0196',
  '2': '\u1105',
  '3': '\u0190',
  '4': '\u3123',
  '5': '\u03DB',
  '6': '9',
  '7': '\u3125',
  '8': '8',
  '9': '6',
  '0': '0',
  '.': '\u02D9',
  ',': '\'',
  '"': ',,',
  '`': ',',
  '?': '\u00BF',
  '!': '\u00A1',
  '[': ']',
  '(': ')',
  '{': '}',
  '<': '>',
  '&': '\u214B',
  '_': '\u203E',
  '\u2234': '\u2235',
  '\u2045': '\u2046',
};
Object.keys(INVERTED).forEach((key) => { INVERTED[INVERTED[key]] = key; });

export default function flip (pattern) {
  let elements = parse(pattern)
    .map(flipElement)
    .reverse();
  let index = String(pattern).length % (
    (PREFIX_EMOJI.length + POSTFIX_EMOJI.length)
  );
  if (index < PREFIX_EMOJI.length) {
    elements.unshift(PREFIX_EMOJI[index]);
  } else {
    index -= PREFIX_EMOJI.length;
    elements.push(POSTFIX_EMOJI[index]);
  }
  return print(elements);
}

export function flipAll (strings) {
  if (Object.keys(strings).length === 1) {
    strings = strings[Object.keys(strings)[0]];
  }
  return Object.keys(strings).reduce((flipped, id) => {
    flipped[id] = { message: flip(strings[id].message || strings[id]) };
    return flipped;
  }, {});
}

function flipElement (element) {
  if (typeof element === 'string') return flipText(element);
  const type = element[1];
  if (type === 'plural' || type === 'selectordinal') {
    element = element.slice();
    element[3] = flipOptions(element[3]);
  } else if (type === 'select') {
    element = element.slice();
    element[2] = flipOptions(element[2]);
  }
  return element;
}

function flipOptions (options) {
  let flipped = {};
  Object.keys(options).forEach((key) => {
    flipped[key] = options[key]
      .map(flipElement)
      .reverse();
  });
  return flipped;
}

function flipText (text) {
  return reverse(text)
    .split('')
    .map((c) => INVERTED[c] || c)
    .join('');
}
