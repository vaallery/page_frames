# frozen_string_literal: true

require 'active_support/core_ext/enumerable'

# Функциональный модуль для работы с файлом конфигурации страниц.

module PageFrames
  module ModelPagesConfig
    module_function

    # Каждый документ состоит из набора страниц и если нужно обновить статус для конкретного документа, нужно получить список стриниц.
    # На входе массив идентификаторов страниц, на выходе - список моделей, отсортированных в том порядке в котором их нужно пересчитывать
    def models_by_dependency_for_pages(*page_ids)
      page_ids.flatten!
      models = base_models_for(*page_ids)
      models_by_dependency_for_models(models)
    end

    # Исходим из предположения что каждая страница зависит лишь от одной модели верхнего уровня.
    def base_models_for(*page_ids)
      page_ids.flatten!
      model_pages_config.select { |_m, p| (p[:page_fields].values.pluck(:page_ids).flatten.uniq & page_ids).any? }.keys
    end

    # Файл с конфигурацией располагается в config/pages.yml и подгружается в config/initializers/pages.rb
    def model_pages_config
      PageFrames.config.model_pages
    end

    def config_for_model(model)
      model_pages_config[model]
    end

    # Список страниц для модели
    def page_fields_for_model(model)
      model_pages_config[model][:page_fields]
    end

    # private

    def models_by_dependency_for_model(model)
      return [] unless model_pages_config[model]

      models = (model_pages_config[model][:page_fields].values.pluck(:aggregates) +
        model_pages_config[model.to_sym][:page_fields].values.pluck(:subscriptions)).flatten.compact.pluck(:model).compact.uniq
      models_by_dependency_for_models(models)
    end

    def models_by_dependency_for_models(models)
      dependencies = []
      models.each do |s_model|
        dependencies = arrange_dependencies(dependencies, models_by_dependency_for_model(s_model))
        dependencies = arrange_dependencies(dependencies, [s_model])
      end
      dependencies
    end

    # Метод правильно выстраивает зависти (все зависимые элементы выбранного элемента находятся слева от него)
    # rubocop:disable Naming/MethodParameterName
    def arrange_dependencies(a = [], b = [])
      (a & b) + (a - b) + (b - a)
    end
    # rubocop:enable Naming/MethodParameterName
  end
end
