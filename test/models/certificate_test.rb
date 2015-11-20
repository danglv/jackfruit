require "test_helper"

describe Certificate do
  let(:certificate) { Certificate.new }

  it "must be valid" do
    value(certificate).must_be :valid?
  end
end
