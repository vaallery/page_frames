# frozen_string_literal: true

RSpec.describe PageFrames do
  it "has a version number" do
    expect(PageFrames::VERSION).not_to be nil
  end

  it "config present" do
    expect(PageFrames.config.model_pages).not_to be_nil
    expect(PageFrames.config.validators).not_to be_nil
  end
end
