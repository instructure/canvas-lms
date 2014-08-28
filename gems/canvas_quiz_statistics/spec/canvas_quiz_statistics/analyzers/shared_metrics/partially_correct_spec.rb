shared_examples '[:partially_correct]' do
  it 'should count all partially correct responses' do
    stats = subject.run([
      { correct: "true" },
      { correct: "partial" }
    ])

    stats[:partially_correct].should == 1
  end
end