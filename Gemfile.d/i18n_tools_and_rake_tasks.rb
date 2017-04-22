group :i18n_tools do
  gem 'i18n_extraction', path: 'gems/i18n_extraction', require: false

end

group :i18n_tools, :development do
  gem 'i18n_tasks', path: 'gems/i18n_tasks'
end

