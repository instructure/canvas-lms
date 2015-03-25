require 'spec_helper'


def create_subject(payload={}, statsd=nil)
  args = ['name', 1000, 1001, 1234, payload]
  args << statsd if statsd
  CanvasStatsd::RequestStat.new(*args)
end


describe CanvasStatsd::RequestStat do

  describe '#db_runtime' do
    it 'should return the payload db_runtime' do
      rs = create_subject({db_runtime: 11.11})
      expect(rs.db_runtime).to eq 11.11
    end

    it 'should return nil when payload db_runtime key doesnt exists' do
      rs = create_subject
      expect(rs.db_runtime).to eq nil
    end
  end

  describe '#view_runtime' do
    it 'should return the payload view_runtime' do
      rs = create_subject(view_runtime: 11.11)
      expect(rs.view_runtime).to eq 11.11
    end

    it 'should return nil when payload view_runtime key doesnt exists' do
      rs = create_subject
      expect(rs.view_runtime).to eq nil
    end
  end

  describe '#controller' do
    it "should return params['controller']" do
      rs = create_subject({params: {'controller' => 'foo'}})
      expect(rs.controller).to eq 'foo'
    end

    it 'should return nil if no params are available' do
      rs = create_subject
      expect(rs.controller).to eq nil
    end

    it 'should return nil if no controller is available on params' do
      rs = create_subject({params: {}})
      expect(rs.controller).to eq nil
    end
  end

  describe '#action' do
    it "should return params['action']" do
      rs = create_subject({params: {'action' => 'index'}})
      expect(rs.action).to eq 'index'
    end

    it 'should return nil if no params are available' do
      rs = create_subject
      expect(rs.action).to eq nil
    end

    it 'should return nil if no action is available on params' do
      rs = create_subject({params: {}})
      expect(rs.action).to eq nil
    end
  end

  describe '#ms' do
    it 'correctly calcuates milliseconds from start, finish' do
      rs = create_subject({params: {}})
      # start and finish are in seconds
      expect(rs.ms).to eq 1000
    end

    it 'defaults to zero if either start or finish are nil' do
      rs = CanvasStatsd::RequestStat.new('name', nil, 1001, 1111, {params: {}})
      expect(rs.ms).to eq 0
      rs = CanvasStatsd::RequestStat.new('name', 1, nil, 1111, {params: {}})
      expect(rs.ms).to eq 0
    end
  end

  describe '#report' do
    it 'doesnt send stats when no controller or action' do
      statsd = double
      rs = create_subject({params: {}}, statsd)
      expect(statsd).to_not receive(:timing).with('request.foo.index', 1000)
      rs.report
    end

    it 'sends total timing when controller && action are present, doesnt send db, or view if they are not' do
      statsd = double
      payload = {
        params: {
          'controller' => 'foo',
          'action'     => 'index'
        }
      }
      rs = create_subject(payload, statsd)
      expect(statsd).to receive(:timing).with('request.foo.index.total', 1000)
      rs.report
    end

    it 'sends view_runtime and db_runtime when present' do
      statsd = double
      payload = {
        view_runtime: 70.1,
        db_runtime: 100.2,
        params: {
          'controller' => 'foo',
          'action'     => 'index'
        }
      }
      rs = create_subject(payload, statsd)
      allow(statsd).to receive(:timing).with('request.foo.index.total', 1000)
      expect(statsd).to receive(:timing).with('request.foo.index.view', 70.1)
      expect(statsd).to receive(:timing).with('request.foo.index.db', 100.2)
      rs.report
    end
  end

end
