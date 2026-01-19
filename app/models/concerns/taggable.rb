# frozen_string_literal: true

module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings
  end

  def tag_names
    tags.pluck(:name)
  end

  def tag_names=(names)
    self.tags = names.map do |name|
      Tag.find_or_create_by!(name: name) do |tag|
        tag.slug = name.parameterize
      end
    end
  end

  def add_tag(name)
    tag = Tag.find_or_create_by!(name: name) do |t|
      t.slug = name.parameterize
    end
    tags << tag unless tags.include?(tag)
  end

  def remove_tag(name)
    tag = Tag.find_by(name: name)
    tags.delete(tag) if tag
  end

  def tagged_with?(name)
    tags.exists?(name: name)
  end

  class_methods do
    def tagged_with(tag_name)
      joins(:tags).where(tags: { name: tag_name })
    end

    def tagged_with_any(tag_names)
      joins(:tags).where(tags: { name: tag_names }).distinct
    end

    def tagged_with_all(tag_names)
      tag_names.reduce(all) do |scope, name|
        scope.tagged_with(name)
      end
    end
  end
end
