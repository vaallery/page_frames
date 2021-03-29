# frozen_string_literal: true

require 'digest/md5'
require 'active_support/concern'

# Модуль для подключения к моделям, которые участвуют в формировании фреймов страниц

module PageFrames
  module Pageable
    extend ActiveSupport::Concern

    included do
      attr_accessor :skip_publish

      # before_save :update_pages_frame!, unless: :skip_publish
      after_save :update_frame, :recalculate_associations, :update_pages, unless: :skip_publish
      after_destroy :remove_frame, :recalculate_associations, :update_pages, unless: :skip_publish

      def model
        self.class.name
      end

      def update_frame
        calculator = PageFrames::CalculateFrames.new(model)
        frames = [{
          pageable_type: model,
          pageable_id: id,
          pages: calculator.call(self),
          organization_id: organization_id
        }]
        PageFrames::RpcClient.fetch.mass_update(frames)
      end

      def remove_frame
        PageFrames::RpcClient.fetch.mass_remove(model, [id])
      end

      # Пересчитать связанные ассоциации, только для связей belongs_to, если будут связи has_many, то надо будет допилить
      def recalculate_associations
        return unless (associations = PageFrames::ModelPagesConfig.config_for_model(model)[:cascade])

        associations.each do |ref|
          next unless (object = send(ref))
          next if destroyed_by_association&.active_record == object.class

          object.update_frame
          object.recalculate_associations
          object.update_pages
        end
      end

      def update_pages
        return if ModelPagesConfig.page_fields_for_model(model).blank?

        PageFrames::RpcClient.fetch.update_pages(model, organization_id)
      end
    end
  end
end
