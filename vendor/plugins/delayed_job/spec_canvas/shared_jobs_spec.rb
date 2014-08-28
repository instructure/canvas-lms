require File.expand_path('../shared_backend_spec', __FILE__)
require File.expand_path('../delayed_batch_spec', __FILE__)
require File.expand_path('../delayed_method_spec', __FILE__)
require File.expand_path('../performable_method_spec', __FILE__)
require File.expand_path('../stats_spec', __FILE__)
require File.expand_path('../worker_spec', __FILE__)

shared_examples_for 'a delayed_jobs implementation' do
  include_examples 'a backend'
  include_examples 'Delayed::Batch'
  include_examples 'random ruby objects'
  include_examples 'Delayed::PerformableMethod'
  include_examples 'Delayed::Stats'
  include_examples 'Delayed::Worker'
end
