/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

module.exports = [
  {
    rule: 'Let the initializer do what it needs to',
    source: 'ui/index.ts',
    target: '**',
    specifier: 'any',
  },

  {
    rule: 'Let boot code do what it needs to',
    source: 'ui/boot/**',
    target: '**',
    specifier: 'any',
  },

  {
    rule: 'Allow extensions to dynamically import from gems/plugins',
    source: 'ui/shared/bundles/**',
    target: '**',
    specifier: 'any',
  },

  {
    rule: 'Allow engine entrypoints to source everything there',
    source: 'ui/engine/{index.ts,capabilities/index.ts}',
    target: 'ui/engine/**',
    specifier: 'relative',
  },

  {
    rule: 'Allow capabilities to depend on each other',
    source: 'ui/engine/capabilities/*/**',
    target: 'ui/engine/capabilities/*/**',
    specifier: 'relative',
  },

  {
    source: 'ui/features/*/index.js',
    target: 'ui/engine/**',
    specifier: 'bare',
  },

  {
    rule: 'Let everyone consume legacy public/javascripts/',
    source: '**',
    target: 'public/javascripts/**',
    specifier: 'bare',
  },

  {
    rule: 'Let calendar monkey patch moment/timezone',
    source: 'ui/features/calendar/ext/**',
    target: 'ui/ext/custom_{moment,timezone}_locales/**',
    specifier: 'relative',
  },

  {
    rule: `
      Modules of the same package (packages/*) should import each other
      using relative specifiers.
    `,
    source: 'packages/*/**',
    target: 'packages/*/**',
    boundary: 0,
    specifier: 'relative',
  },

  {
    rule: `
      Package modules (packages/*/**) may only be accessed through
      their package.
    `,
    source: '**',
    target: 'packages/**',
    specifier: 'package',
  },

  {
    rule: `
      Modules of the same Canvas package (ui/shared/*) should import each
      other using relative specifiers.
    `,
    source: 'ui/shared/*/**',
    target: 'ui/shared/*/**',
    boundary: 0,
    specifier: 'relative',
  },

  {
    rule: `
      Canvas package modules (ui/shared/*/**) may only be accessed
      through their package.
    `,
    source: '{gems/plugins,public/javascripts,ui}/**',
    target: 'ui/shared/**',
    specifier: 'package',
  },

  {
    rule: `
      Modules of the same feature (ui/features/*) should import each
      other using relative specifiers.
    `,
    source: 'ui/features/*/**',
    target: 'ui/features/*/**',
    boundary: 0,
    specifier: 'relative',
  },

  {
    rule: `
      Modules of the same plugin should import each other using relative
      specifiers.
    `,
    source: 'gems/plugins/*/**',
    target: 'gems/plugins/*/**',
    boundary: 0,
    specifier: 'relative',
  },
]
