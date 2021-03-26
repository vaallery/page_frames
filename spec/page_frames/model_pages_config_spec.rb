# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PageFrames::ModelPagesConfig do
  before do
    PageFrames.configure do |c|
      c.model_pages = YAML.load_file(File.join(__dir__, 'fixtures/pages.yml')).with_indifferent_access
    end
  end

  it { expect(described_class.model_pages_config).to be_a(Hash) }
  it { expect(described_class.config_for_model('Subject')).to be_a(Hash) }
  it { expect(described_class.page_fields_for_model('Subject').keys[0]).to eq('subject') }
  it { expect(described_class.base_models_for(128)).to eq(['InformationSystem']) }
  it { expect(described_class.models_by_dependency_for_pages(128)).to eq(%w[DataModel::OutsideOrganization InformationSystem]) }
end
