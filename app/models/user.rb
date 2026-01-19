# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships
  has_many :owned_namespaces, as: :owner, class_name: 'Namespace', dependent: :restrict_with_error
  has_many :published_type_versions, class_name: 'TypeVersion', foreign_key: :published_by_id
  has_many :published_shape_versions, class_name: 'ShapeVersion', foreign_key: :published_by_id
  has_many :published_api_spec_versions, class_name: 'ApiSpecVersion', foreign_key: :published_by_id
  has_many :audit_logs, dependent: :nullify
  has_many :webhook_subscriptions, dependent: :destroy
  has_many :access_grants, as: :grantee, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: { in: %w[user admin system] }

  # Callbacks
  before_validation :set_default_role, on: :create

  # API Key management
  def generate_api_key!
    raw_key = SecureRandom.hex(32)
    update!(api_key_digest: Digest::SHA256.hexdigest(raw_key))
    raw_key
  end

  def self.find_by_api_key(raw_key)
    return nil if raw_key.blank?

    digest = Digest::SHA256.hexdigest(raw_key)
    find_by(api_key_digest: digest)
  end

  def revoke_api_key!
    update!(api_key_digest: nil)
  end

  def admin?
    role == 'admin'
  end

  private

  def set_default_role
    self.role ||= 'user'
  end
end
