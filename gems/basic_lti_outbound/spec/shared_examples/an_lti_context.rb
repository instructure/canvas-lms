shared_examples_for "an LTI context" do
  it_behaves_like "it has an attribute setter and getter for", :root_account
  it_behaves_like "it has an attribute setter and getter for", :opaque_identifier
  it_behaves_like "it has an attribute setter and getter for", :id
  it_behaves_like "it has an attribute setter and getter for", :sis_source_id

  it_behaves_like "it provides variable mapping", ".id", :id
  it_behaves_like "it provides variable mapping", ".sisSourceId", :sis_source_id
end