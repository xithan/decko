RSpec.describe Card::Command::SeedCommand do
  it "seeds database", as_bot: true do
    create_card "new card", content: "some content"
    binding.pry
    described_class.perform
    expect_card("new card").to be_unknown
  end
end
