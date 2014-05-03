shared_examples_for 'it provides variable mapping' do |key, method_name|
  it "maps #{key} to ##{method_name}" do
    object = described_class.new

    expect(object).to respond_to(method_name)
    expect(object).to receive(method_name)
    object.variable_substitution_mapping(key)
  end
end