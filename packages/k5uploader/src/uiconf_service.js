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

import urlParams from './url_params'
import signatureBuilder from './signature_builder'
import XmlParser from './xml_parser'
import UiConfig from './ui_config'
import uiConfigFromNode from './ui_config_from_node'
import mBus from './message_bus'
import k5Options from './k5_options'

function UiconfService() {
  this.xmlParser = new XmlParser()
}

UiconfService.prototype.load = function(sessionSettings) {
  const data = sessionSettings.getSession()
  data.kalsig = signatureBuilder(data)
  this.xhr = new XMLHttpRequest()
  this.xhr.open('GET', k5Options.uiconfUrl + urlParams(data))
  this.xhr.addEventListener('load', this.onXhrLoad.bind(this))
  this.xhr.send(data)
}

UiconfService.prototype.createUiConfig = function(xml) {
  this.config = uiConfigFromNode(xml)
}

UiconfService.prototype.onXhrLoad = function(event) {
  this.xmlParser.parseXML(this.xhr.response)
  const conf = this.xmlParser
    .find('result')
    .find('ui_conf')
    .find('confFile')
    .first()
    .text()
  if (conf) {
    this.xmlParser = new XmlParser()
    this.xmlParser.parseXML(conf)
    this.config = uiConfigFromNode(this.xmlParser)
    mBus.dispatchEvent('UiConf.complete', this.config, this)
  } else {
    mBus.dispatchEvent('UiConf.error', this.xhr.response, this)
  }
}

export default UiconfService
