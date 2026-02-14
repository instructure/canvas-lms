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

import jobs from './jquery'

declare global {
  interface Window {
    jobs: any
    running: any
    tags: any
    Jobs: any
    Workers: any
    Tags: any
  }
}

interface JobsEnv {
  JOBS: {
    opts: any
    running_opts: any
    tags_opts: any
  }
}

// TODO: get this stuff off window, need to move the domready stuff out of
// jobs.js into here
window.jobs = new jobs.Jobs((ENV as unknown as JobsEnv).JOBS.opts).init()
window.running = new jobs.Workers((ENV as unknown as JobsEnv).JOBS.running_opts).init()
window.tags = new jobs.Tags((ENV as unknown as JobsEnv).JOBS.tags_opts).init()
