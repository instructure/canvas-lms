module OCADU
  
  def self.initialize
    self.register_connect_plugin
    true
  end
  
  def self.register_connect_plugin
    require_dependency 'plugins/validators/adobe_connect_validator'
    Canvas::Plugin.register('adobe_connect', :web_conferencing, 
      {
        :name => lambda{ t :name, "Adobe Connect" },
        :description => lambda{ t :description, "Adobe Connect web conferencing support" },
        :website => 'http://www.adobe.com/products/adobeconnect.html',
        :author => 'OCAD University',
        :author_website => 'http://www.ocadu.ca',
        :version => '0.1',
        :validator => 'AdobeConnectValidator', 
        :settings_partial => 'plugins/connect_settings',
        :settings => {:timezone => 'Eastern Time (US & Canada)'},
        :encrypted_settings => [:password],
      }
    )
  end
end
