Rails.configuration.to_prepare do
  require_dependency 'respondus_soap_endpoint_plugin_validator'
  plugin = Canvas::Plugin.register :respondus_soap_endpoint, nil, {
          :name => lambda{ t :name, 'Respondus SOAP Endpoint' },
          :author => 'instructure',
          :author_website => 'http://www.instructure.com',
          :description => lambda{ t :description, 'SOAP Endpoint for Respondus QTI uploads' },
          :version => '1.0.0',
          :settings_partial => 'plugins/respondus_soap_endpoint_settings',
          :settings => {
            :enabled => false,
            :worker => 'QtiWorker'
          },
          :validator => 'RespondusSoapEndpointPluginValidator'
  }
end

class RespondusRailtie < Rails::Railtie
  config.app_middleware.insert_before 'ActionDispatch::ParamsParser', 'RespondusAPIMiddleware'
end
