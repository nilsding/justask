class Question < ActiveRecord::Base
  belongs_to :user
  has_many :answers, dependent: :destroy
  has_many :inboxes, dependent: :destroy

  validates :content, length: { maximum: 255 }

  before_destroy do
    user.decrement! :asked_count unless self.author_is_anonymous
  end

  def can_be_removed?
    return false if self.answers.count > 0
    return false if Inbox.where(question: self).count > 1
    true
  end

  # @return 'spoiler' or nil
  def nsfw_spoiler(current_user = nil)
    return nil unless self.nsfw
    unless current_user.nil?
      return nil if current_user.show_nsfw
    end
    'spoiler'
  end
end
