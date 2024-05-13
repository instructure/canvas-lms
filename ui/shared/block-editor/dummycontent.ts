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

export default `{
  "ROOT": {
    "type": {
      "resolvedName": "PageBlock"
    },
    "isCanvas": true,
    "props": {},
    "displayName": "Page",
    "custom": {},
    "hidden": false,
    "nodes": [
      "yBssUvai3s"
    ],
    "linkedNodes": {}
  },
  "yBssUvai3s": {
    "type": {
      "resolvedName": "ColumnsSection"
    },
    "isCanvas": false,
    "props": {
      "columns": 2,
      "variant": "fixed"
    },
    "displayName": "Columns",
    "custom": {
      "isSection": true
    },
    "parent": "ROOT",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {
      "columns-section-0": "hgLNCRY3_D",
      "columns-section-1": "C2Q5tlqCkS"
    }
  },
  "hgLNCRY3_D": {
    "type": {
      "resolvedName": "NoSections"
    },
    "isCanvas": true,
    "props": {
      "columns": 2,
      "variant": "fixed"
    },
    "displayName": "Column",
    "custom": {},
    "parent": "yBssUvai3s",
    "hidden": false,
    "nodes": [
      "niKqfYtnMe"
    ],
    "linkedNodes": {}
  },
  "C2Q5tlqCkS": {
    "type": {
      "resolvedName": "NoSections"
    },
    "isCanvas": true,
    "props": {
      "columns": 2,
      "variant": "fixed"
    },
    "displayName": "Column",
    "custom": {},
    "parent": "yBssUvai3s",
    "hidden": false,
    "nodes": [
      "dcXVbJh-cR"
    ],
    "linkedNodes": {}
  },
  "niKqfYtnMe": {
    "type": {
      "resolvedName": "TextBlock"
    },
    "isCanvas": false,
    "props": {
      "text": "para 1"
    },
    "displayName": "Text",
    "custom": {},
    "parent": "hgLNCRY3_D",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {}
  },
  "dcXVbJh-cR": {
    "type": {
      "resolvedName": "TextBlock"
    },
    "isCanvas": false,
    "props": {
      "text": "para 2"
    },
    "displayName": "Text",
    "custom": {},
    "parent": "C2Q5tlqCkS",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {}
  }
}`
