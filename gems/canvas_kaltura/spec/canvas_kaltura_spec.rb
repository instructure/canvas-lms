require 'spec_helper'

describe CanvasKaltura do
  context ".timeout_protector" do
    it "call block if not set" do
      CanvasKaltura.timeout_protector_proc = nil
      expect(CanvasKaltura.with_timeout_protector { 2 }).to be 2
    end

    it "call timeout protector if set" do
      CanvasKaltura.timeout_protector_proc = lambda { |options, &block| 27 }
      expect(CanvasKaltura.with_timeout_protector).to be 27
    end
  end
end
