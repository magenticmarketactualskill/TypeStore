class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Generate UUID for string primary keys (SQLite compatibility)
  before_create :generate_uuid_id

  private

  def generate_uuid_id
    self.id ||= SecureRandom.uuid if self.class.columns_hash['id']&.type == :string
  end
end
