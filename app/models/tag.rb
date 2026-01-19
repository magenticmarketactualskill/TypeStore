# frozen_string_literal: true

class Tag < ApplicationRecord
  # Associations
  has_many :taggings, dependent: :destroy
  has_many :type_definitions, through: :taggings, source: :taggable, source_type: 'TypeDefinition'
  has_many :data_shapes, through: :taggings, source: :taggable, source_type: 'DataShape'
  has_many :api_specs, through: :taggings, source: :taggable, source_type: 'ApiSpec'

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_slug, on: :create

  # Scopes
  scope :by_category, ->(cat) { where(category: cat) }
  scope :popular, -> { left_joins(:taggings).group(:id).order('COUNT(taggings.id) DESC') }

  def usage_count
    taggings.count
  end

  private

  def generate_slug
    return if slug.present?

    self.slug = name.to_s.parameterize
  end
end
