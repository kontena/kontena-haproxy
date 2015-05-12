require_relative '../spec_helper'

describe Kontena::HaproxyConfigWriter do

  CONFIG_PATH = './tmp/haproxy.cfg'

  before(:each) { Celluloid.boot }
  after(:each) {
    Celluloid.shutdown
    File.unlink(CONFIG_PATH) if File.exists?(CONFIG_PATH)
  }

  let(:subject) { described_class.new(CONFIG_PATH).wrapped_object }

  describe '#update_config' do
    it 'writes config file when it has changes' do
      subject.update_config('topic', 'update!')
      expect(File.exists?(subject.config_file)).to eq(true)
    end

    it 'sends notification when config is changed' do
      expect(subject).to receive(:publish).with('haproxy:config_updated').once
      subject.update_config('topic', 'update!')
    end

    it 'does not write config if it has no changes' do
      subject.update_config('topic', '')
      expect(File.exists?(subject.config_file)).to eq(false)
    end

    it 'does not send notification if config has no changes' do
      expect(subject).not_to receive(:publish).with('haproxy:config_updated')
      subject.update_config('topic', '')
    end
  end

  describe '#write_config' do
    it 'writes given config to a file' do
      subject.write_config('foo bar')
      expect(File.exists?(subject.config_file)).to eq(true)
    end
  end
end
