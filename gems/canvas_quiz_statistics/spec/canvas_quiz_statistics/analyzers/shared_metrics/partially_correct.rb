shared_examples '[:partially_correct]' do
  it 'should count all partially correct responses' do
    stats = subject.run([
      { correct: "true" },
      { correct: "partial" }
    ])

    expect(stats[:partially_correct]).to eq(1)
  end
end