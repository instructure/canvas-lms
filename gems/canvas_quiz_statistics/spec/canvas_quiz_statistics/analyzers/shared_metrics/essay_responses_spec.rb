shared_examples 'essay [:responses]' do
  it 'should count students who have written anything' do
    subject.run([{ text: 'foo' }])[:responses].should == 1
  end

  it 'should not count students who have written a blank response' do
    subject.run([{ }])[:responses].should == 0
    subject.run([{ text: nil }])[:responses].should == 0
    subject.run([{ text: '' }])[:responses].should == 0
  end
end