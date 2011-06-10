plugin = Canvas::Plugin.register('registration_form_recaptcha', 'registration_form', {
  :name => lambda{ t :name, "Registration form ReCAPTCHA" },
  :description => lambda{ t :description, "CAPTCHA plugin for the registration form" },
  :website => 'http://www.instructure.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'users/recaptcha_settings',
  :settings => {
    :registration_partial => 'users/registration_form_recaptcha'
  }
})
