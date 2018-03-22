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

import axios from 'axios'

function delayAsPromise(interval) {
  return new Promise((resolve) => {
    setTimeout(resolve, interval);
  });
}

// takes a object description of a Canvas Progress object (per the API docs)
// and polls every `interval` until the progress completes or fails. returns a
// Promise that resolves when the progress completes and that rejects when it
// fails.
export default function resolveProgress(progress, options={}) {
  const ajaxLib = options.ajaxLib || axios;

  const { url, workflow_state, results, message } = progress;
  if (workflow_state === 'queued' || workflow_state === 'running') {
    // poll again after a delay. default to once a second if not specified, and
    // wait at least 100ms between polls even if asked for less.
    let { interval } = options;
    if (!interval) { interval = 1000; }
    if (interval < 100) { interval = 100; }
    return delayAsPromise(interval)
      .then(() => ajaxLib.get(url))
      .then((response) => {
        const newProgress = response.data;
        return resolveProgress(newProgress, options)
      });
  } else if (workflow_state === 'completed') {
    // done
    return Promise.resolve(results);
  } else {
    // failed
    return Promise.reject(message);
  }
}
