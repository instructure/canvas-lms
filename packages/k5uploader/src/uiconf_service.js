import urlParams from "./url_params";
import signatureBuilder from "./signature_builder";
import XmlParser from "./xml_parser";
import UiConfig from "./ui_config";
import uiConfigFromNode from "./ui_config_from_node";
import mBus from "./message_bus";
import k5Options from "./k5_options";

function UiconfService (){
  this.xmlParser = new XmlParser();
}

UiconfService.prototype.load = function(sessionSettings) {
  var data = sessionSettings.getSession();
  data.kalsig = signatureBuilder(data);
  this.xhr = new XMLHttpRequest();
  this.xhr.open('GET', k5Options.uiconfUrl + urlParams(data));
  this.xhr.addEventListener('load', this.onXhrLoad.bind(this));
  this.xhr.send(data);
};

UiconfService.prototype.createUiConfig = function(xml) {
  this.config = uiConfigFromNode(xml);
};

UiconfService.prototype.onXhrLoad = function(event) {
  this.xmlParser.parseXML(this.xhr.response);
  var conf = this.xmlParser.find('result').find('ui_conf').find('confFile').first().text()
  if(conf) {
    this.xmlParser = new XmlParser();
    this.xmlParser.parseXML(conf);
    this.config = uiConfigFromNode(this.xmlParser);
    mBus.dispatchEvent('UiConf.complete', this.config, this);
  } else {
    mBus.dispatchEvent('UiConf.error', this.xhr.response, this);
  }
};

export default UiconfService;
