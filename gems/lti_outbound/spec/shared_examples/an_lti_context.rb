shared_examples_for 'an LTI context' do
  it_behaves_like 'it has a proc attribute setter and getter for', :name
  it_behaves_like 'it has a proc attribute setter and getter for', :consumer_instance
  it_behaves_like 'it has a proc attribute setter and getter for', :opaque_identifier
  it_behaves_like 'it has a proc attribute setter and getter for', :id
  it_behaves_like 'it has a proc attribute setter and getter for', :sis_source_id
end