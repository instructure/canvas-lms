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

export const blank_page = `{
  "ROOT": {
    "type": {
      "resolvedName": "PageBlock"
    },
    "isCanvas": true,
    "props": {},
    "displayName": "Page",
    "custom": {},
    "hidden": false,
    "nodes": [],
    "linkedNodes": {}
  }
}`

export const blank_section_with_text = `{
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
      "_H17VRi7hL"
    ],
    "linkedNodes": {}
  },
  "_H17VRi7hL": {
    "type": {
      "resolvedName": "BlankSection"
    },
    "isCanvas": false,
    "props": {},
    "displayName": "Blank Section",
    "custom": {
      "isSection": true
    },
    "parent": "ROOT",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {
      "blank-section_nosection1": "eXJDI6Ex1I"
    }
  },
  "eXJDI6Ex1I": {
    "type": {
      "resolvedName": "NoSections"
    },
    "isCanvas": true,
    "props": {
      "className": "blank-section__inner"
    },
    "displayName": "NoSections",
    "custom": {
      "noToolbar": true
    },
    "parent": "_H17VRi7hL",
    "hidden": false,
    "nodes": [
      "a7y-qnd2V8"
    ],
    "linkedNodes": {}
  },
  "a7y-qnd2V8": {
    "type": {
      "resolvedName": "TextBlock"
    },
    "isCanvas": false,
    "props": {
      "fontSize": "12pt",
      "textAlign": "initial",
      "color": "var(--ic-brand-font-color-dark)",
      "text": "this is text."
    },
    "displayName": "Text",
    "custom": {},
    "parent": "eXJDI6Ex1I",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {}
  }
}`

export const blank_section_with_button_and_heading = `{
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
      "_H17VRi7hL"
    ],
    "linkedNodes": {}
  },
  "_H17VRi7hL": {
    "type": {
      "resolvedName": "BlankSection"
    },
    "isCanvas": false,
    "props": {},
    "displayName": "Blank Section",
    "custom": {
      "isSection": true
    },
    "parent": "ROOT",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {
      "blank-section_nosection1": "eXJDI6Ex1I"
    }
  },
  "eXJDI6Ex1I": {
    "type": {
      "resolvedName": "NoSections"
    },
    "isCanvas": true,
    "props": {
      "className": "blank-section__inner"
    },
    "displayName": "NoSections",
    "custom": {
      "noToolbar": true
    },
    "parent": "_H17VRi7hL",
    "hidden": false,
    "nodes": [
      "TMfTkPb0pu",
      "MY71Zd6Z3S"
    ],
    "linkedNodes": {}
  },
  "TMfTkPb0pu": {
    "type": {
      "resolvedName": "ButtonBlock"
    },
    "isCanvas": false,
    "props": {
      "text": "Click me",
      "href": "",
      "size": "medium",
      "variant": "filled",
      "color": "primary"
    },
    "displayName": "Button",
    "custom": {},
    "parent": "eXJDI6Ex1I",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {}
  },
  "MY71Zd6Z3S": {
    "type": {
      "resolvedName": "HeadingBlock"
    },
    "isCanvas": false,
    "props": {
      "text": "a heading",
      "level": "h2"
    },
    "displayName": "Heading",
    "custom": {},
    "parent": "eXJDI6Ex1I",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {}
  }
}`
