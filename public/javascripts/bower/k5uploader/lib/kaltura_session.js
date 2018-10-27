import defaults from "./defaults";

function KalturaSession (){
  this.ks = '';
  this.subp_id = '';
  this.partner_id = '';
  this.uid = '';
  this.serverTime = 0;
}

KalturaSession.prototype.setSession = function(obj) {
  if (obj) {
    defaults('ks', this, obj);
    defaults('subp_id', this, obj);
    defaults('partner_id', this, obj);
    defaults('uid', this, obj);
    defaults('serverTime', this, obj);
    defaults('ui_conf_id', this, obj);
  }
};

KalturaSession.prototype.getSession = function() {
  return {
    ks: this.ks,
    subp_id: this.subp_id,
    partner_id: this.partner_id,
    uid: this.uid,
    serverTime: this.serverTime,
    ui_conf_id: this.ui_conf_id
  }
};

KalturaSession.prototype.asEntryParams = function() {
  return this.getSession();
};

export default KalturaSession;
