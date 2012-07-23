require File.expand_path('../shared_backend_spec', __FILE__)
require File.expand_path('../delayed_batch_spec', __FILE__)
require File.expand_path('../delayed_method_spec', __FILE__)
require File.expand_path('../performable_method_spec', __FILE__)
require File.expand_path('../stats_spec', __FILE__)
require File.expand_path('../worker_spec', __FILE__)

shared_examples_for 'a delayed_jobs implementation' do
  it_should_behave_like 'a backend'
  it_should_behave_like 'Delayed::Batch'
  it_should_behave_like 'random ruby objects'
  it_should_behave_like 'Delayed::PerformableMethod'
  it_should_behave_like 'Delayed::Stats'
  it_should_behave_like 'Delayed::Worker'
end
