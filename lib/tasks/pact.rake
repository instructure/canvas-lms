begin
  require 'pact/tasks'
rescue LoadError # the pact gem is in the 'test' group so it isn't bundled on production
end

