require "bosh-bootstrap/network"

describe Bosh::Bootstrap::Network do
  include Bosh::Bootstrap::Cli::Helpers::Settings

  let(:aws_cyoi_provider_client) { instance_double("Cyoi::Providers::Clients::AwsProviderClient") }

  it "uses NetworkProvider if available" do
    network = Bosh::Bootstrap::Network.new("aws", aws_cyoi_provider_client)
    expect(aws_cyoi_provider_client).to receive(:create_security_group).exactly(3).times
    network.deploy
  end

  it "does nothing if no NetworkProvider for the infrastructure" do
    network = Bosh::Bootstrap::Network.new("vsphere", nil)
    network.deploy
  end
end
