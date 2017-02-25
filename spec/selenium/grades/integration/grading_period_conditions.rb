shared_context 'all grading periods' do
  before(:each) do
    @grading_period_index = 0
  end
end

shared_context 'grading period one' do
  before(:each) do
    @grading_period_index = 1
  end
end

shared_context 'grading period two' do
  before(:each) do
    @grading_period_index = 2
  end
end

shared_context 'no grading periods' do
  before(:each) do
    @grading_period_index = nil
  end
end
