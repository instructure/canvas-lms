shared_examples_for 'Id Answer Serializers' do
  it '[auto] should reject an unknown answer ID' do
    input = 12321
    input = format(input) if respond_to?(:format)

    rc = subject.serialize(input)
    expect(rc.error).not_to be_nil
    expect(rc.error).to match(/unknown answer/i)
  end

  it '[auto] should accept a string answer ID' do
    input = '12321'
    input = format(input) if respond_to?(:format)

    rc = subject.serialize(input)
    expect(rc.error).not_to be_nil
    expect(rc.error).to match(/unknown answer/i)
  end

  it '[auto] should reject a bad answer ID' do
    [ nil, [], {} ].each do |bad_input|
      bad_input = format(bad_input) if respond_to?(:format)

      rc = subject.serialize(bad_input)
      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/must be of type integer/i)
    end
  end
end
