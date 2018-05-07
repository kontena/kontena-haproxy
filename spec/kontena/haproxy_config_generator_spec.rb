require_relative '../spec_helper'

describe Kontena::HaproxyConfigGenerator do

  before(:each) { Celluloid.boot }
  after(:each) { Celluloid.shutdown }

  let(:subject) do
    described_class.new(
      frontend_port: '80',
      maxconn: '4096',
      mode: 'http',
      balance: 'roundrobin',
      polling_interval: 5,
      virtual_hosts: 'ghost=blog.kontena.io,jenkins=ci.kontena.io',
      option: %w{ redispatch forwardfor},
      server_option: '',
      timeout: ['connect 5000', 'client 50000', 'server 50000']
    ).wrapped_object
  end

  let(:backends) do
    {
      'ghost' => [{ip: '10.81.1.12', port: '2368'}, {ip: '10.81.2.12', port: '2368'}],
      'jenkins' => [{ip: '10.81.1.14', port: '8080'}]
    }
  end

  describe '#create_default_config' do
    it 'sets global scope to config' do
      expect(subject.config['global']).to be_instance_of(Array)
    end

    it 'sets global.maxconn from parameters' do
      expect(subject.config['global']).to include("maxconn 4096")
    end

    it 'sets global.pidfile' do
      expect(subject.config['global']).to include("pidfile /var/run/haproxy.pid")
    end

    it 'sets defaults scope to config' do
      expect(subject.config['defaults']).to be_instance_of(Array)
    end

    it 'sets defaults mode to config' do
      expect(subject.config['defaults']).to include('mode http')
    end

    it 'sets additional options to defaults scope' do
      expect(subject.config['defaults']).to include('option redispatch')
      expect(subject.config['defaults']).to include('option forwardfor')
    end

    it 'sets timeout to defaults scope' do
      expect(subject.config['defaults']).to include('timeout connect 5000')
      expect(subject.config['defaults']).to include('timeout client 50000')
      expect(subject.config['defaults']).to include('timeout server 50000')
    end
  end

  describe '#update_config' do
    it 'calls #create_frontend' do
      expect(subject).to receive(:create_frontend).once
      subject.update_config('topic', backends)
    end

    it 'calls #create_backend' do
      expect(subject).to receive(:create_backend).once.with(backends)
      subject.update_config('topic', backends)
    end
  end

  describe '#create_frontend' do

    context 'with virtual hosts' do
      before(:each) { subject.create_frontend }
      let(:frontend_config) { subject.config['frontend default_frontend'] }

      it 'sets default frontend to config' do
        expect(frontend_config).to be_instance_of(Array)
      end

      it 'sets frontend bind' do
        expect(frontend_config).to include('bind 0.0.0.0:80')
      end

      it 'adds virtualhost frontend configs' do
        expect(frontend_config).to include('acl host_ghost hdr(host) -i blog.kontena.io')
        expect(frontend_config).to include('use_backend ghost_cluster if host_ghost')

        expect(frontend_config).to include('acl host_jenkins hdr(host) -i ci.kontena.io')
        expect(frontend_config).to include('use_backend jenkins_cluster if host_jenkins')
      end
    end

    context 'without virtual hosts' do
      let(:subject) do
        described_class.new(
          frontend_port: '80',
          maxconn: '4096',
          mode: 'http',
          balance: 'roundrobin',
          polling_interval: 5,
          virtual_hosts: '',
          option: %w{ redispatch forwardfor},
          timeout: ['connect 5000', 'client 50000', 'server 50000']
        ).wrapped_object
      end

      before(:each) { subject.create_frontend }
      let(:frontend_config) { subject.config['frontend default_frontend'] }

      it 'sets default_backend if virtualhosts is empty' do
        expect(frontend_config).to include('default_backend default_backend')
      end
    end
  end

  describe '#create_backend' do
    it 'calls #create_default_backend if there are no virtual hosts' do
      subject.options[:virtual_hosts] = ''
      expect(subject).to receive(:create_default_backend).once.with(backends)
      subject.create_backend(backends)
    end

    it 'calls #create_virtual_host_backends if there are virtual hosts' do
      expect(subject).to receive(:create_virtual_host_backends).once.with(backends)
      subject.create_backend(backends)
    end
  end

  describe '#create_default_backend' do
    before(:each) { subject.create_default_backend(backends) }
    let(:backend_config) { subject.config['backend default_backend'] }

    it 'sets default backend to config' do
      expect(backend_config).to be_instance_of(Array)
    end

    it 'sets backend balance' do
      expect(backend_config).to include('balance roundrobin')
    end

    it 'sets backend servers' do
      expect(backend_config).to include('server ghost-1 10.81.1.12:2368')
      expect(backend_config).to include('server ghost-2 10.81.2.12:2368')
      expect(backend_config).to include('server jenkins-1 10.81.1.14:8080')
    end
  end

  describe '#create_virtual_host_backends' do
    before(:each) { subject.create_virtual_host_backends(backends) }

    it 'sets backend config for each virtual host' do
      expect(subject.config['backend ghost_cluster']).to be_instance_of(Array)
      expect(subject.config['backend jenkins_cluster']).to be_instance_of(Array)
    end

    it 'sets backend balance for virtual host' do
      expect(subject.config['backend ghost_cluster']).to include('balance roundrobin')
    end

    it 'sets backend servers for virtual host' do
      expect(subject.config['backend ghost_cluster']).to include('server ghost-1 10.81.1.12:2368')
      expect(subject.config['backend ghost_cluster']).to include('server ghost-2 10.81.2.12:2368')
      expect(subject.config['backend ghost_cluster']).not_to include('server jenkins-1 10.81.1.14:8080')
    end
  end

  describe '#create_vhosts' do
    it 'parses virtual_hosts to vhosts hash' do
      subject.create_vhosts
      expect(subject.vhosts).to eq({
        'ghost' => 'blog.kontena.io',
        'jenkins' => 'ci.kontena.io'
      })
    end
  end
end
