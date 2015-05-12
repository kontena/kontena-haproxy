require_relative '../spec_helper'

describe Kontena::HaproxySpawner do

  before(:each) { Celluloid.boot }
  after(:each) { Celluloid.shutdown }
  let(:subject) { described_class.new.wrapped_object }

  describe '#update_haproxy' do
    it 'calls #start_haproxy if current_pid is nil' do
      expect(subject).to receive(:start_haproxy)
      subject.update_haproxy
    end

    it 'calls #reload_haproxy if current_pid exists' do
      allow(subject).to receive(:current_pid).and_return(123)
      expect(subject).to receive(:reload_haproxy)
      subject.update_haproxy
    end
  end
end
