require File.expand_path('../shared/shared_backend', __FILE__)
require File.expand_path('../shared/delayed_batch', __FILE__)
require File.expand_path('../shared/delayed_method', __FILE__)
require File.expand_path('../shared/performable_method', __FILE__)
require File.expand_path('../shared/stats', __FILE__)
require File.expand_path('../shared/worker', __FILE__)

shared_examples_for 'a delayed_jobs implementation' do
  include_examples 'a backend'
  include_examples 'Delayed::Batch'
  include_examples 'random ruby objects'
  include_examples 'Delayed::PerformableMethod'
  include_examples 'Delayed::Stats'
  include_examples 'Delayed::Worker'
end
