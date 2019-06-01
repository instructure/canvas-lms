import $ from "jquery";

function XmlParser (){}

XmlParser.prototype.parseXML = function(xml) {
  this.$xml = $(xml);
  this.determineError();
  return this.$xml;
};

XmlParser.prototype.determineError = function() {
  this.isError = !!(this.find('error').children().length);
};

XmlParser.prototype.find = function(nodeName) {
  return this.$xml.find(nodeName);
};

XmlParser.prototype.findRecursive = function(nodes) {
  var nodes = nodes.split(':');
  var currentNode = this.$xml;
  var found;
  for(var i=0, l=nodes.length; i<l; i++) {
    found = currentNode.find(nodes[i])[0];
    if (!found) {
      currentNode = undefined;
      break;
    } else {
      currentNode = $(found);
    }
  }
  return currentNode;
};

XmlParser.prototype.nodeText = function(name, node, asNumber) {
  var res = undefined;
  if (node.find(name).text() != '') {
    res = node.find(name).text();
    if (asNumber === true) {
      res = parseFloat(res);
    }
  }
  return res;
};

export default XmlParser;
