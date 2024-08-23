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

import {LtiScopes, ZLtiScope} from '../LtiScope'
import {i18nLtiScope} from '../i18nLtiScope'
import YAML from 'yaml'
// eslint-disable-next-line import/no-nodejs-modules
import fs from 'fs'
// eslint-disable-next-line import/no-nodejs-modules
import path from 'path'

describe('LtiScopes', () => {
  // YAML file used also in Ruby specs to keep ruby scopes/descriptions in sync
  const scopesYaml = '../../../../../spec/fixtures/lti/lti_scopes.yml'

  it('should contain all the scopes described in lti_scopes.yml', () => {
    const yamlContents = fs.readFileSync(path.resolve(__dirname, scopesYaml), 'utf8')

    type ScopeDefn = {scope: string; description: string}

    const expected = YAML.parse(yamlContents).map(({scope, description}: ScopeDefn) => ({
      scope,
      description,
    }))

    const actual = Object.values(LtiScopes).map(scope => ({
      scope,
      description: i18nLtiScope(scope),
    }))

    const sortfn = (a: ScopeDefn, b: ScopeDefn) => a.scope.localeCompare(b.scope)
    expect(actual.sort(sortfn)).toEqual(expected.sort(sortfn))
  })
})

describe('ZLtiScope', () => {
  it('should contain all LtiScopes', () => {
    const zScopes = Object.keys(ZLtiScope.enum)
    const ltiScopesScopes = Object.values(LtiScopes)
    expect(zScopes.sort()).toEqual(ltiScopesScopes.sort())
  })
})
