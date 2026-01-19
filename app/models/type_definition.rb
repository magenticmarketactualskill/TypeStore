# frozen_string_literal: true

class TypeDefinition < ApplicationRecord
  include Taggable
  include Versionable

  CATEGORIES = %w[primitive composite enum union alias].freeze

  # Associations
  belongs_to :namespace
  belongs_to :current_version, class_name: 'TypeVersion', optional: true
  has_many :versions, class_name: 'TypeVersion', dependent: :destroy
  has_many :source_references, as: :source, class_name: 'SchemaReference', dependent: :destroy
  has_many :target_references, as: :target, class_name: 'SchemaReference', dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :namespace_id }
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  # Callbacks
  before_validation :generate_slug, on: :create

  # Scopes
  scope :active, -> { where(deprecated: false) }
  scope :deprecated, -> { where(deprecated: true) }
  scope :by_category, ->(cat) { where(category: cat) }

  # Returns the full reference string: @namespace/types/slug
  def ref
    "#{namespace.display_slug}/types/#{slug}"
  end

  # Returns reference with version: @namespace/types/slug@1.0.0
  def ref_with_version(version = nil)
    version ||= current_version&.version
    version ? "#{ref}@#{version}" : ref
  end

  # Deprecate with message
  def deprecate!(message = nil)
    update!(deprecated: true, deprecation_message: message)
  end

  # Get version by semver string
  def version(semver)
    versions.find_by(version: semver)
  end

  # Get latest version
  def latest_version
    current_version || versions.order(version_major: :desc, version_minor: :desc, version_patch: :desc).first
  end

  private

  def generate_slug
    return if slug.present?

    self.slug = name.to_s.parameterize
  end
end
