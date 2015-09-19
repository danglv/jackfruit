require 'test_helper'

# Unit tests for module Sale
module Sale
  describe 'Campaign' do
    let(:sale_campaign) { Sale::Campaign.new }
    let(:campaign) { Sale::Campaign.where(title: 'Test Sale Campaign 1').first }

    it 'must be valid' do
      value(sale_campaign).must_be :valid?
    end

    it 'must have in_progress scope' do
      value(Sale::Campaign.in_progress.all.to_a[0].title).must_equal campaign.title
    end

    it 'must have at least a course package' do
      packages = campaign.packages
      value(packages.count).must_be :>=, 1
    end
  end

  describe 'Package' do
    let(:sale_package) { Sale::Package.new }

    it 'must be valid' do
      value(sale_package).must_be :valid?
    end
  end

  describe 'Course' do
    let(:sale_course) { Sale::Course.new }

    it 'must be valid' do
      value(sale_course).must_be :valid?
    end
  end
end
