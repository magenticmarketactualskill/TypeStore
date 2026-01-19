# frozen_string_literal: true

class ApiSpec < ApplicationRecord
  include Taggable
  include Versionable

  SPEC_TYPES = %w[openapi json_rpc json_rpc_ld graphql grpc asyncapi].freeze

  # Associations
  belongs_to :namespace
  belongs_to :current_version, class_name: 'ApiSpecVersion', optional: true
  has_many :versions, class_name: 'ApiSpecVersion', dependent: :destroy
  has_many :source_references, as: :source, class_name: 'SchemaReference', dependent: :destroy
  has_many :target_references, as: :target, class_name: 'SchemaReference', dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :namespace_id }
  validates :spec_type, presence: true, inclusion: { in: SPEC_TYPES }

  # Callbacks
  before_validation :generate_slug, on: :create

  # Scopes
  scope :active, -> { where(deprecated: false) }
  scope :deprecated, -> { where(deprecated: true) }
  scope :by_type, ->(type) { where(spec_type: type) }
  scope :openapi_specs, -> { by_type('openapi') }
  scope :json_rpc_specs, -> { by_type('json_rpc') }
  scope :graphql_specs, -> { by_type('graphql') }

  # Returns the full reference string: @namespace/apis/slug
  def ref
    "#{namespace.display_slug}/apis/#{slug}"
  end

  # Returns reference with version: @namespace/apis/slug@1.0.0
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

  # Check spec type
  def openapi?
    spec_type == 'openapi'
  end

  def json_rpc?
    spec_type == 'json_rpc' || spec_type == 'json_rpc_ld'
  end

  def graphql?
    spec_type == 'graphql'
  end

  private

  def generate_slug
    return if slug.present?

    self.slug = name.to_s.parameterize
  end
end
