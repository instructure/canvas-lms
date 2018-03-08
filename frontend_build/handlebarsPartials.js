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

// We specify partials with an arrow and expect to simply find them
// because out old build would register them manually in a rewrite.
// We should be able to find them by referencing them relative to the jst directory

function addPartialLeader(fullName) {
  const refPieces = fullName.split('/')
  refPieces[refPieces.length - 1] = `_${refPieces[refPieces.length - 1]}`
  return refPieces.join('/')
}

module.exports = function(input) {
  this.cacheable()
  const partialsRegexp = /\{\{>(.+)( |})/g
  // search for all things that look like partial references {{>partial}},
  // replace them with {{> $jst/_partial}}
  let newInput = input.replace(partialsRegexp, partialInvocation => {
    const fixedInvocation = partialInvocation.replace(/([^\{\}> ]+) ?/, partialName => {
      // replace the name of the partial with a reference webpack can resolve
      const newPartialName = addPartialLeader(`$jst/${partialName}.handlebars`)
      return newPartialName
    })
    return fixedInvocation
  })

  // search for all sub-partial references like {{>[assignments/partial],
  // replace them with {{> $jst/assignments/_partial}}
  const subPartialsRegexp = /\{\{> ?\[.+?\]/g
  newInput = newInput.replace(subPartialsRegexp, partialInvocation => {
    const absoluteReferencedPartial = partialInvocation.replace('[', ' $jst/').replace(']', '')
    const fixedInvocation = addPartialLeader(absoluteReferencedPartial)
    return fixedInvocation
  })

  return newInput
}
