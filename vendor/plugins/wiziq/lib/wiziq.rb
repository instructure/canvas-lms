module Wiziq
  def self.register_plugin
    Canvas::Plugin.register('wiziq', :web_conferencing, {
      :name => lambda{ t :name, "Wiziq" },
      :description => lambda{ t :description, "Wiziq virtual classroom" },
      :website => 'http://wiziq.com',
      :author => 'Instructure',
      :author_website => 'http://www.instructure.com/',
      :version => '1.0.0',
      :settings_partial => 'plugins/wiziq_settings',
      :settings => {:api_url => 'http://class.api.wiziq.com/'}
    })
  end
end
