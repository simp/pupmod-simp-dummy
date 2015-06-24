require 'spec_helper'

describe 'dummy' do

  simp_os_facts = {
    'CentOS' => {
       '6' => {
       'x86_64' => {
          :grub_version              => '0.97',
          :uid_min                   => '500',
        },
       },
       '7' => {
       'x86_64' => {
          :grub_version              => '2.02~beta2',
          :uid_min                   => '500',
        },
       },
    },
    'RedHat' => {
       '6' => {
       'x86_64' => {
          :grub_version              => '0.97',
          :uid_min                   => '500',
        },
       },
       '7' => {
       'x86_64' => {
          :grub_version              => '2.02~beta2',
          :uid_min                   => '500',
        },
       },
    },
  }


  shared_examples_for "a structured module" do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('dummy') }
    it { is_expected.to contain_class('dummy') }
    it { is_expected.to contain_class('dummy::params') }
    it { is_expected.to contain_class('dummy::install').that_comes_before('dummy::config') }
    it { is_expected.to contain_class('dummy::config') }
    it { is_expected.to contain_class('dummy::service').that_subscribes_to('dummy::config') }

    it { is_expected.to contain_service('dummy') }
    it { is_expected.to contain_package('dummy').with_ensure('present') }
### FIXME    it { should contain_package('dummy').that_comes_before('Service[dummy]') }
  end


  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          # FIXME: create simp-rspec-puppet-facts (SIMP-207)
          facts[:lsbmajdistrelease] = facts[:operatingsystemmajrelease]
          # FIXME: one
          simp_facts = simp_os_facts.fetch( facts.fetch(:operatingsystem) ).fetch( facts.fetch(:operatingsystemmajrelease) ).fetch( facts.fetch(:architecture) )

             # require 'pp'
             # puts "------------- FACTS"
             # pp simp_facts
          facts
        end

        context "dummy class without any parameters" do
          let(:params) {{ }}
          it_behaves_like "a structured module"
          it { is_expected.to contain_class('dummy').with_client_nets( ['127.0.0.1/32']) }
        end

        context "dummy class with firewall enabled" do
          let(:params) {{
            :client_nets     => ['10.0.2.0/24'],
            :tcp_listen_port => '1234',
            :enable_firewall => true,
          }}
          ###it_behaves_like "a structured module"
          it { is_expected.to contain_class('dummy::firewall') }

          it { is_expected.to contain_class('dummy::firewall').that_comes_before('dummy::service') }
          it { is_expected.to create_iptables__add_tcp_stateful_listen('allow_dummy_tcp_connections').with_dports('1234') }
        end

        context "dummy class with selinux enabled" do
          let(:params) {{
            :enable_selinux => true,
          }}
          ###it_behaves_like "a structured module"
          it { is_expected.to contain_class('dummy::selinux') }
          it { is_expected.to contain_class('dummy::selinux').that_comes_before('dummy::service') }
          it { is_expected.to create_notify('FIXME: selinux') }
        end

        context "dummy class with auditing enabled" do
          let(:params) {{
            :enable_auditing => true,
          }}
          ###it_behaves_like "a structured module"
          it { is_expected.to contain_class('dummy::auditing') }
          it { is_expected.to contain_class('dummy::auditing').that_comes_before('dummy::service') }
          it { is_expected.to create_notify('FIXME: auditing') }
        end

        context "dummy class with logging enabled" do
          let(:params) {{
            :enable_logging => true,
          }}
          ###it_behaves_like "a structured module"
          it { is_expected.to contain_class('dummy::logging') }
          it { is_expected.to contain_class('dummy::logging').that_comes_before('dummy::service') }
          it { is_expected.to create_notify('FIXME: logging') }
        end
      end
    end
  end

  context 'unsupported operating system' do
    describe 'dummy class without any parameters on Solaris/Nexenta' do
      let(:facts) {{
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta',
      }}

      it { expect { is_expected.to contain_package('dummy') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
