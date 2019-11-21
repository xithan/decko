describe Card::Mod::Dirs do
  it "loads mods from Modfile" do
    path = File.expand_path __dir__
    tg = described_class.new path
    expect(tg.mods).to eq %w[mod1 mod2]
  end
end
