group :i18n_tools do
  gem 'i18n_extraction', :path => 'gems/i18n_extraction', :require => false

end

group :i18n_tools, :rake_tasks do
  gem 'i18n_tasks', :path => 'gems/i18n_tasks'
  gem 'handlebars_tasks', :path => 'gems/handlebars_tasks'
end

