Rails.configuration.to_prepare do
  require 'saml2'
  require 'onelogin/saml'

  block = -> do
    Onelogin::Saml.config[:max_message_size] =
      SAML2.config[:max_message_size] =
        Setting.get('saml_max_message_size', 1.megabyte).to_i
  end
  block.call
  Canvas::Reloader.on_reload(&block)
end
