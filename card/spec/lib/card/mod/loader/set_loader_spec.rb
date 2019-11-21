# -*- encoding : utf-8 -*-

RSpec.describe Card::Mod::Loader::SetLoader do
  let(:mod_dirs) do
    path = File.expand_path "../../../../support/test_mods", __dir__
    Card::Mod::Dirs.new path
  end

  it "initializes the load strategy" do
    expect(Card::Mod::LoadStrategy::Eval).to receive(:new).with(mod_dirs, instance_of(described_class))
    described_class.new(:eval, mod_dirs)
  end

  it "load mods" do
    described_class.new(:eval, mod_dirs).load
    expect(Card::Set).to be_const_defined("All::TestSet")
    expect(Card.take.test_method).to eq "method works"
  end
end
