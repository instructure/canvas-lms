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

function XmlParser() {}

XmlParser.prototype.parseXML = function(xml) {
  this.$xml = $(xml)
  this.determineError()
  return this.$xml
}

XmlParser.prototype.determineError = function() {
  this.isError = !!this.find('error').children().length
}

XmlParser.prototype.find = function(nodeName) {
  return this.$xml.find(nodeName)
}

XmlParser.prototype.findRecursive = function(nodes) {
  var nodes = nodes.split(':')
  let currentNode = this.$xml
  let found
  for (let i = 0, l = nodes.length; i < l; i++) {
    found = currentNode.find(nodes[i])[0]
    if (!found) {
      currentNode = undefined
      break
    } else {
      currentNode = $(found)
    }
  }
  return currentNode
}

XmlParser.prototype.nodeText = function(name, node, asNumber) {
  let res
  if (node.find(name).text() != '') {
    res = node.find(name).text()
    if (asNumber === true) {
      res = parseFloat(res)
    }
  }
  return res
}

export default XmlParser
