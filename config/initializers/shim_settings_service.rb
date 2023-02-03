SettingsService::AuthToken.authenticator = ::AccessToken

if ENV['RAILS_ENV'] == 'development'
  SettingsService.update_settings(id: 1, value: 'true', setting: 'disable_pipeline', object: 'school')
end
