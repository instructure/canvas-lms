shared_examples_for 'Id Answer Serializers' do
  it '[auto] should reject an unknown answer ID' do
    input = 12321
    input = format(input) if respond_to?(:format)

    rc = subject.serialize(input)
    rc.error.should_not be_nil
    rc.error.should match(/unknown answer/i)
  end

  it '[auto] should accept a string answer ID' do
    input = '12321'
    input = format(input) if respond_to?(:format)

    rc = subject.serialize(input)
    rc.error.should_not be_nil
    rc.error.should match(/unknown answer/i)
  end

  it '[auto] should reject a bad answer ID' do
    [ nil, [], {} ].each do |bad_input|
      bad_input = format(bad_input) if respond_to?(:format)

      rc = subject.serialize(bad_input)
      rc.error.should_not be_nil
      rc.error.should match(/must be of type integer/i)
    end
  end
end
