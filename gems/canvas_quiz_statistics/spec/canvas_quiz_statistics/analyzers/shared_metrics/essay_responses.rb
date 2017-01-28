shared_examples 'essay [:responses]' do
  it 'should count students who have written anything' do
    expect(subject.run([{ text: 'foo' }])[:responses]).to eq(1)
  end

  it 'should not count students who have written a blank response' do
    expect(subject.run([{ }])[:responses]).to eq(0)
    expect(subject.run([{ text: nil }])[:responses]).to eq(0)
    expect(subject.run([{ text: '' }])[:responses]).to eq(0)
  end
end