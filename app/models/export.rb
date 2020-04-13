class Export < ApplicationRecord
  validates :filename, presence: true, uniqueness: { case_sensitive: false }
  validates :path, presence: true, uniqueness: { case_sensitive: false }

  scope :last_ten, -> { order(created_at: :desc).limit(10) }
end
