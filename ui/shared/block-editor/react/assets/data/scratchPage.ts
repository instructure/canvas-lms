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

export const scratchPage = `{
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
      "pEdeFvz6_0"
    ],
    "linkedNodes": {}
  },
  "pEdeFvz6_0": {
    "type": {
      "resolvedName": "ColumnsSection"
    },
    "isCanvas": false,
    "props": {
      "columns": 1
    },
    "displayName": "Blank Section",
    "custom": {
      "isSection": true
    },
    "parent": "ROOT",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {
      "columns-pEdeFvz6_0__inner": "ax57suVCfC"
    }
  },
  "ax57suVCfC": {
    "type": {
      "resolvedName": "ColumnsSectionInner"
    },
    "isCanvas": true,
    "props": {},
    "displayName": "Columns",
    "custom": {
      "noToolbar": true
    },
    "parent": "pEdeFvz6_0",
    "hidden": false,
    "nodes": [
      "wasLLTTys-"
    ],
    "linkedNodes": {}
  },
  "wasLLTTys-": {
    "type": {
      "resolvedName": "GroupBlock"
    },
    "isCanvas": true,
    "props": {
      "alignment": "start",
      "layout": "column",
      "resizable": false,
      "isColumn": true,
      "id": "columns-pEdeFvz6_0-1"
    },
    "displayName": "Group",
    "custom": {
      "isResizable": false
    },
    "parent": "ax57suVCfC",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {
      "group-wasLLTTys-_inner": "le254LKmwg"
    }
  },
  "le254LKmwg": {
    "type": {
      "resolvedName": "NoSections"
    },
    "isCanvas": true,
    "props": {
      "className": "",
      "placeholderText": "Drop a block to add it here"
    },
    "displayName": "NoSections",
    "custom": {
      "noToolbar": true
    },
    "parent": "wasLLTTys-",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {}
  }
}`
