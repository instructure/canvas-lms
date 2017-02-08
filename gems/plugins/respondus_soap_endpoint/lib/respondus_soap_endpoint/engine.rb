module RespondusSoapEndpoint
  class Railtie < ::Rails::Engine
    initializer "respondus_soap_endpoint.canvas_plugin" do |app|
      require 'respondus_soap_endpoint/plugin_validator'
      Canvas::Plugin.register :respondus_soap_endpoint, nil, {
        name: ->{ t :name, 'Respondus SOAP Endpoint' },
        author: 'instructure',
        author_website: 'http://www.instructure.com',
        description: ->{ t :description, 'SOAP Endpoint for Respondus QTI uploads' },
        version: RespondusSoapEndpoint::VERSION,
        settings_partial: 'respondus_soap_endpoint/plugin_settings',
        settings: {
          enabled: false,
          worker: 'QtiWorker',
        },
        validator: 'RespondusSoapEndpointPluginValidator',
      }
    end

    initializer "respondus_soap_endpoint.middleware" do |app|
      app.middleware.use RespondusSoapEndpoint::Middleware
    end
  end
end
