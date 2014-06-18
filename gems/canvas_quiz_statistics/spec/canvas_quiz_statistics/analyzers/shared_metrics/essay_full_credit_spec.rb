shared_examples 'essay [:full_credit]' do
  let :question_data do
    { points_possible: 3 }
  end

  it 'should count all students who received full credit' do
    output = subject.run([
      { points: 3 }, { points: 2 }, { points: 3 }
    ])

    output[:full_credit].should == 2
  end

  it 'should count students who received more than full credit' do
    output = subject.run([
      { points: 3 }, { points: 2 }, { points: 5 }
    ])

    output[:full_credit].should == 2
  end

  it 'should be 0 otherwise' do
    output = subject.run([
      { points: 1 }
    ])

    output[:full_credit].should == 0
  end

  it 'should count those who exceed the maximum points possible' do
    output = subject.run([{ points: 5 }])
    output[:full_credit].should == 1
  end
end