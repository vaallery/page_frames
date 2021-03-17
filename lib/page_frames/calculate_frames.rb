require_relative 'model_pages_config'

module PageFrames
  class CalculateFrames
    class Error < StandardError; end

    def initialize(model)
      @model = model.is_a?(Class) ? model.name : model
    end

    def call(object)
      pages = page_fields.map do |page, page_attrs|
        [page.to_s, serialize_and_validate_page(object, page_attrs)]
      end
      Hash[pages]
    end

    private

    def page_fields
      @page_fields ||= pages_config[:page_fields]
    end

    def pages_config
      @pages_config ||= ModelPagesConfig.config_for_model(@model)
    end

    def aggregates
      @aggregates ||= pages_config[:aggregates] || []
    end

    def subscriptions
      @subscriptions ||= pages_config[:subscriptions] || []
    end

    def serialize_and_validate_page(object, page_attrs)
      serializer_options = page_attrs[:serializer_options]
      serializer_options.tap { |o| o[:serializer] = o[:serializer].constantize if o[:serializer].is_a?(String) }
      validator = page_attrs[:validator]
      subscriptions = page_attrs[:subscriptions]
      aggregates = page_attrs[:aggregates]

      serializer_options.merge!(root: "object", for_md5: true)
      page_data = ActiveModelSerializers::SerializableResource.new(object, serializer_options).as_json[:object].compact

      page_data.merge!(aggregated_data(aggregates, object))
      page_data.merge!(subscribed_data(subscriptions, object))
      errors = JSON::Validator.fully_validate(validation_schema(validator), page_data)
      {
        md5: Digest::MD5.hexdigest(page_data.to_json),
        errors: errors,
        valid: errors.blank?
      }
    end

    def validation_schema(validator)
      validator.is_a?(Hash) ? validator : { '$ref': "#/components/schemas/#{validator}" }.merge(PageFrames.config.validators)
    end

    def aggregated_data(aggregates, object)
      return {} unless aggregates

      aggregates.each_with_object({}) do |aggregate_params, data|
        association_name = aggregate_params[:association]
        page_alias = aggregate_params[:page_alias]
        pageable_type = aggregate_params[:model]
        unless page_alias && association_name && pageable_type
          raise Error, "В конфигурации модели #{@model} некорректно указаны настройки aggregates, должны присутствовать ключи: model, association, page_alias"
        end
        pageable_ids = object.send(association_name).ids
        info = PageFrames::RpcClient.fetch.aggregated_md5(page_alias, pageable_type, pageable_ids)
        data["#{association_name}_md5".to_sym] = info
      end
    end

    def subscribed_data(subscriptions, object)
      return {} unless subscriptions

      subscriptions.each_with_object({}) do |subscription_params, data|
        pageable_type = subscription_params[:model]
        association_name = subscription_params[:ref_id_name]
        page_alias = subscription_params[:page_alias]
        unless page_alias && association_name && pageable_type
          raise Error, "В конфигурации модели #{@model} некорректно указаны настройки subscriptions, должны присутствовать ключи: model, ref_id_name, page_alias"
        end
        if (model_id = object.send(association_name))
          pageable_ids = [model_id]
          info = FramesService::RpcClient.fetch.aggregated_md5(page_alias, pageable_type, pageable_ids)
        else
          info = { md5: "", valid: false }
        end
        data["#{association_name}_md5"] = info
      end
    end

    # Метод пробегает по всем объектам и формирует обобщенные значения (MD5 и valid) для всех страниц, которые зависят от Модели
    def aggregated_md5_for(relation)

      total_pages = relation.each_with_object({}) do |item, h|
        item.pages_frame&.pages&.each do |page, params|
          if h[page]
            h[page]["md5"] << params["md5"]
            h[page]["valid"] &= params["valid"]
          else
            h[page] = { "md5" => params["md5"], "valid" => params["valid"] }
          end
        end
      end
      # В p["md5"] сейчас лежит конкатенированая строка со всеми md5 всех объектов, заменяем ее на вычесленную md5
      total_pages.transform_values! { |page| page.tap { |p| p["md5"] = Digest::MD5.hexdigest(p["md5"]) } }
      total_pages.with_indifferent_access
    end
  end
end

