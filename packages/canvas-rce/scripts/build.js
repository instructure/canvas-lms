#!/usr/bin/env node

/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

// Generates all the pre-translated code in lib/translated/{locale}.

const shell = require('shelljs')

shell.set('-e')

// We make this directory if it doesn't exist so that the following delete command works outside of docker.  This
// directory is automatically created via a volume mount when using docker, so the -p flag prevents the mkdir command
// from failing
shell.exec('mkdir -p lib')
shell.exec('mkdir -p es')

// We can't delete this directory when inside docker because it is used as a volume mount point, so instead we
// delete everything in it.
shell.exec('rm -rf lib/*')
shell.exec('rm -rf es/*')
shell.exec('scripts/installTranslations.js')

shell.echo('Building')
shell.exec("npx babel --out-dir es src --ignore '**/__tests__' --extensions '.ts,.tsx,.js,.jsx'")
