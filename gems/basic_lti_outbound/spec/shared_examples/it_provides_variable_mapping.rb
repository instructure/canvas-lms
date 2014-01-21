shared_examples_for "it provides variable mapping" do |key, method_name|
  it "maps #{key} to ##{method_name}" do
    object = described_class.new
    #object.send(:"#{method_name}=", 99)
    #object.variable_substitution_mapping(key).should == 99
    #expect(object.has_variable_mapping?(key)).to eq(true)
    expect(object).to receive(method_name)
    object.variable_substitution_mapping(key)
  end
end