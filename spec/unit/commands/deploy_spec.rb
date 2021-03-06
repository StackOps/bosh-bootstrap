# Copyright (c) 2012-2013 Stark & Wayne, LLC

require "bosh-bootstrap/cli/commands/deploy"
require "cyoi/providers/clients/aws_provider_client"
require "cyoi/providers/clients/openstack_provider_client"
describe Bosh::Bootstrap::Cli::Commands::Deploy do
  include StdoutCapture
  include Bosh::Bootstrap::Cli::Helpers

  let(:settings_dir) { File.expand_path("~/.microbosh") }

  before do
    FileUtils.mkdir_p(@stemcells_dir = File.join(Dir.mktmpdir, "stemcells"))
    FileUtils.mkdir_p(@cache_dir = File.join(Dir.mktmpdir, "cache"))
  end

  let(:cmd) { Bosh::Bootstrap::Cli::Commands::Deploy.new }

  # * select_provider
  # * select_or_provision_public_networking # public_ip or ip/network/gateway
  # * select_public_image_or_download_stemcell # download if stemcell
  # * create_microbosh_manifest
  # * microbosh_deploy
  describe "aws" do
    before do
      setting "provider.name", "aws"
      setting "key_pair.name", "test-bosh"
      setting "key_pair.private_key", "PRIVATE"
    end

    it "deploy creates provisions IP address micro_bosh.yml, discovers/downloads stemcell/AMI, runs 'bosh micro deploy'" do
      # select_provider
      cli_provider = instance_double("Cyoi::Cli::Provider")
      expect(cli_provider).to receive(:execute!)
      expect(Cyoi::Cli::Provider).to receive(:new).with([settings_dir]).and_return(cli_provider)

      cyoi_provider_client = instance_double("Cyoi::Providers::Clients::AwsProviderClient")
      expect(cyoi_provider_client).to receive(:create_security_group).exactly(3).times
      expect(Cyoi::Providers).to receive(:provider_client).with("name" => "aws").and_return(cyoi_provider_client)

      # select_or_provision_public_networking
      address = instance_double("Cyoi::Cli::Address")
      expect(address).to receive(:execute!)
      expect(Cyoi::Cli::Address).to receive(:new).with([settings_dir]).and_return(address)

      # microbosh_provider & select_public_image_or_download_stemcell
      microbosh_provider = instance_double("Bosh::Bootstrap::MicroboshProviders::AWS")
      expect(microbosh_provider).to receive(:stemcell).exactly(1).times.and_return("")
      expect(microbosh_provider).to receive(:stemcell).exactly(1).times.and_return("ami-123456")
      expect(cmd).to receive(:microbosh_provider).and_return(microbosh_provider).exactly(3).times

      # setup_keypair
      key_pair = instance_double(Cyoi::Cli::KeyPair)
      expect(key_pair).to receive(:execute!)
      expect(Cyoi::Cli::KeyPair).to receive(:new).with(["test-bosh", settings_dir]).and_return(key_pair)

      keypair = instance_double(Bosh::Bootstrap::KeyPair)
      expect(keypair).to receive(:execute!)
      expect(keypair).to receive(:path).and_return(home_file(".microbosh/ssh/test-bosh"))
      expect(Bosh::Bootstrap::KeyPair).to receive(:new).with(settings_dir, "test-bosh", "PRIVATE").and_return(keypair)

      # perform_microbosh_deploy
      microbosh = instance_double(Bosh::Bootstrap::Microbosh)
      expect(microbosh).to receive(:deploy)
      expect(Bosh::Bootstrap::Microbosh).to receive(:new).with(settings_dir, microbosh_provider).and_return(microbosh)

      capture_stdout { cmd.perform }
    end

  end

  describe "openstack" do
    it "deploy creates provisions IP address micro_bosh.yml, discovers/downloads stemcell, runs 'bosh micro deploy'" do
      setting "provider.name", "openstack"
      setting "key_pair.name", "test-bosh"
      setting "key_pair.private_key", "PRIVATE"

      # select_provider
      cli_provider = instance_double("Cyoi::Cli::Provider")
      expect(cli_provider).to receive(:execute!)
      expect(Cyoi::Cli::Provider).to receive(:new).with([settings_dir]).and_return(cli_provider)

      cyoi_provider_client = instance_double("Cyoi::Providers::Clients::OpenStackProviderClient")
      expect(cyoi_provider_client).to receive(:create_security_group).exactly(3).times
      expect(Cyoi::Providers).to receive(:provider_client).with("name" => "openstack").and_return(cyoi_provider_client)

      # select_or_provision_public_networking
      address = instance_double("Cyoi::Cli::Address")
      expect(address).to receive(:execute!)
      expect(Cyoi::Cli::Address).to receive(:new).with([settings_dir]).and_return(address)

      # microbosh_provider & select_public_image_or_download_stemcell
      microbosh_provider = instance_double("Bosh::Bootstrap::MicroboshProviders::OpenStack")
      expect(microbosh_provider).to receive(:stemcell).exactly(1).times.and_return("")
      expect(microbosh_provider).to receive(:stemcell).exactly(1).times.and_return("openstack.tgz")
      expect(cmd).to receive(:microbosh_provider).and_return(microbosh_provider).exactly(3).times

      # setup_keypair
      key_pair = instance_double(Cyoi::Cli::KeyPair)
      expect(key_pair).to receive(:execute!)
      expect(Cyoi::Cli::KeyPair).to receive(:new).with(["test-bosh", settings_dir]).and_return(key_pair)

      keypair = instance_double(Bosh::Bootstrap::KeyPair)
      expect(keypair).to receive(:execute!)
      expect(keypair).to receive(:path).and_return(home_file(".microbosh/ssh/test-bosh"))
      expect(Bosh::Bootstrap::KeyPair).to receive(:new).with(settings_dir, "test-bosh", "PRIVATE").and_return(keypair)

      # perform_microbosh_deploy
      microbosh = instance_double(Bosh::Bootstrap::Microbosh)
      expect(microbosh).to receive(:deploy)
      expect(Bosh::Bootstrap::Microbosh).to receive(:new).with(settings_dir, microbosh_provider).and_return(microbosh)

      capture_stdout { cmd.perform }
    end
  end
end
