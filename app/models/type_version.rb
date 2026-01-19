# frozen_string_literal: true

class TypeVersion < ApplicationRecord
  include SemanticVersioning

  # Associations
  belongs_to :type_definition
  belongs_to :published_by, class_name: 'User', optional: true

  # Validations
  validates :version, presence: true, uniqueness: { scope: :type_definition_id }
  validates :version_major, :version_minor, :version_patch, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :content, presence: true
  validates :content_hash, presence: true

  # Callbacks
  before_validation :parse_version, if: -> { version.present? && version_major.nil? }
  before_validation :compute_content_hash, if: -> { content.present? && content_hash.blank? }

  # Scopes
  scope :published, -> { where.not(published_at: nil) }
  scope :draft, -> { where(published_at: nil) }
  scope :ordered, -> { order(version_major: :desc, version_minor: :desc, version_patch: :desc) }

  # Delegate namespace access
  delegate :namespace, to: :type_definition

  # Returns the full reference string
  def ref
    "#{type_definition.ref}@#{version}"
  end

  # Check if published
  def published?
    published_at.present?
  end

  # Publish the version
  def publish!(user)
    update!(published_at: Time.current, published_by: user)
    type_definition.update!(current_version: self)
  end

  private

  def compute_content_hash
    self.content_hash = Digest::SHA256.hexdigest(content.to_json)
  end
end
