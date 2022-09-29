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

/* eslint-disable no-console */

let filename

export function logCurrentContext(currentContext, options = {}) {
  let messages = []
  if (options.message) {
    messages = Array.isArray(options.message) ? options.message : [options.message]
  }

  const logMessage = [...messages, 'Related spec context(s):']
  const entries = currentContext.stack.map((entry, index) => {
    let contextName = `${entry.type}: "${entry.description}"`
    if (index === currentContext.stack.length - 1 && entry.phase) {
      contextName = `${contextName} – ${entry.phase}`
    }
    return index === 0 ? `  ${contextName}` : `  ↳ ${contextName}`
  })

  console[options.logType || 'error'](logMessage.concat(entries).join('\n'))
  if (options.sourceStack) {
    console.log(options.sourceStack)
  }
}

export function logError(error, options = {}) {
  console.error(error)

  // TEMP
  if (error.filename) {
    console.log(error.filename)
    console.log(error.colno, error.lineno)
  }

  if (options.currentContext) {
    logCurrentContext(options.currentContext, {...options, logType: 'error'})
  } else if (options.message) {
    console.error(options.message)
  }
}

export function logHere(options = {}) {
  try {
    throw new Error('message')
  } catch (error) {
    logError(error, options)
  }
}

export function getStack(message) {
  try {
    throw new Error(message)
  } catch (error) {
    return extractStack(error.stack, false)
  }
}

export function logTrackers(trackers, optionFn) {
  const behaviorMap = {}
  trackers.forEach(tracker => {
    behaviorMap[tracker.type] = behaviorMap[tracker.type] || []
    behaviorMap[tracker.type].push(tracker)
  })

  Object.keys(behaviorMap).forEach(trackerType => {
    const typeTrackers = behaviorMap[trackerType]
    logCurrentContext(typeTrackers[0].currentContext, {
      ...optionFn(trackerType, typeTrackers),
      sourceStack: typeTrackers[0].sourceStack,
    })
  })
}

export function extractStack(fullStack, skipError = true) {
  if (fullStack) {
    let stack = []
    const stackLines = fullStack.split('\n')

    if (!(skipError && /^error/i.test(stackLines[0]))) {
      stack.push(stackLines.shift())
    }

    if (filename) {
      const filenameLineIndex = stackLines.findIndex(line => line.indexOf(filename !== -1))
      if (filenameLineIndex !== -1) {
        stackLines.splice(0, filenameLineIndex + 2)
      }
    }
    stack = stack.concat(stackLines)

    if (stack.length) {
      return stack.join('\n')
    }
  }

  return null
}

// Obtain filename to improve stacktrace culling.
try {
  throw new Error('obtain filename')
} catch (error) {
  if (error.stack) {
    filename = extractStack(error.stack)
      .replace(/(:\d+)+\)?/, '')
      .replace(/.+\//, '')
  } else {
    filename = ''
  }
}
/* eslint-enable no-console */
