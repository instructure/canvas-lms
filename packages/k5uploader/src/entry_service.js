import signatureBuilder from "./signature_builder";
import urlParams from "./url_params";
import mBus from "./message_bus";
import XmlParser from "./xml_parser";
import objectMerge from "./object_merge";
import k5Options from "./k5_options";

function EntryService (){
  this.xmlParser = new XmlParser();
}

EntryService.prototype.addEntry = function(allParams) {
  this.formData = objectMerge(allParams);
  this.createEntryRequest();
};

EntryService.prototype.createEntryRequest = function() {
  var data = this.formData;
  data.kalsig = signatureBuilder(data);

  this.xhr = new XMLHttpRequest();
  this.xhr.open('GET', k5Options.entryUrl + urlParams(data));
  this.xhr.requestType = 'xml';
  this.xhr.onload = this.onEntryRequestLoaded.bind(this);
  this.xhr.send(data);
};

EntryService.prototype.onEntryRequestLoaded = function(e) {
  this.xmlParser.parseXML(this.xhr.response);
  var ent = this.xmlParser.findRecursive('result:entries:entry1_');
  if (ent) {
    var ent = {
      id: ent.find('id').text(),
      type: ent.find('type').text(),
      title: ent.find('name').text(),
      context_code: ent.find('partnerData').text(),
      mediaType: ent.find('mediatype').text(),
      entryId: ent.find('id').text(),
      userTitle: undefined
    };
    mBus.dispatchEvent('Entry.success', ent, this);
  } else {
    mBus.dispatchEvent('Entry.fail', this.xhr.response, this);
  }
};

export default EntryService;
