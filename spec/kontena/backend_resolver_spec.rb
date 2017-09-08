require_relative '../spec_helper'

describe Kontena::BackendResolver do

  before(:each) { Celluloid.boot }
  after(:each) { Celluloid.shutdown }

  let(:subject) {
    described_class.new(interval: 5, backends: ['mysql:3306'])
  }

  describe '.new' do
    it 'sets interval' do
      resolver = described_class.new(interval: 10)
      expect(resolver.interval).to eq(10)
    end

    it 'sets backends' do
      backends = ['mysql:3306']
      resolver = described_class.new(backends: backends)
      expect(resolver.backends).to eq(backends)
    end

    it 'sets dns_resolver' do
      resolver = described_class.new(interval: 10)
      expect(resolver.dns_resolver).to be_instance_of(Celluloid::IO::DNSResolver)
    end
  end

  describe '#start!' do
    it 'calls #resolve_backends' do
      expect(subject.wrapped_object).to receive(:resolve_backends)
      allow(subject.wrapped_object).to receive(:resolve_dns)
        .with('mysql').and_return(['10.81.1.5'])
      subject.async.start!
      sleep 0.01
    end
  end

  describe '#resolve_backends' do
    it 'publishes resolved ips' do
      expect(subject.wrapped_object).to receive(:publish).with('backends_resolved', {'mysql' => [{ip: '10.81.1.5', port: '3306'}]})
      allow(subject.wrapped_object).to receive(:resolve_dns)
        .with('mysql').and_return(['10.81.1.5'])
      subject.resolve_backends
    end
  end

  describe '#resolve_dns' do
    it 'calls Celluloid::IO::DnsResolver' do
      expect(subject.dns_resolver).to receive(:resolve).with('www.google.com').once
      subject.resolve_dns('www.google.com')
    end

    it 'returns array of ips' do
      ips = subject.resolve_dns('www.google.com')
      expect(ips.size).to be > 1
    end

    it 'returns passed value if dns does not resolve' do
      ips = subject.resolve_dns('10.1.1.1')
      expect(ips[0]).to eq('10.1.1.1')
    end
  end
end
