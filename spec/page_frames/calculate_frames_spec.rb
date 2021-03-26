# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PageFrames::CalculateFrames do
  subject(:frames) { described_class.new('Subject').call(object) }

  let(:object) { Subject.new }

  let(:frame) do
    {
      id: 'id',
      name: 'name',
      special_pdns: ['lorem'],
      biometric_pdns: ['lorem'],
      others_pdns: ['lorem'],
      public_pdns: ['lorem']
    }
  end

  it 'Фрейм вычисляется корректно' do
    serializer_options = { 'fields' => %w[id name special_pdns biometric_pdns others_pdns public_pdns], 'root' => 'object' }
    mock = class_double(ActiveModelSerializers::SerializableResource).as_stubbed_const(transfer_nested_constants: true)
    allow(mock).to receive(:new).and_return({ object: frame })
    expect(mock).to receive(:new).with(object, serializer_options)
    expect(frames).to eq({ 'subject' => { errors: [], md5: 'ab4c6ada6f0d05ea22d2f7973d3cb8b7', valid: true } })
  end
end

class Subject
  def self.after_save(*_args); end

  def self.after_destroy(*_args); end
  include PageFrames::Pageable
end
