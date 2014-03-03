
shared_examples_for 'it has an attribute setter and getter for' do |attribute|
  it "the attribute '#{attribute}'" do
    obj = described_class.new
    expect(obj.send(attribute)).to eq nil
    obj.send("#{attribute}=", 10)
    expect(obj.send(attribute)).to eq 10
  end
end
