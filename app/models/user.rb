class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :async, :registerable,
         :recoverable, :rememberable, :trackable,
         :validatable, :authentication_keys => [:login]

#   attr_accessor :login

  has_many :questions, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :inboxes, dependent: :destroy
  has_many :active_relationships, class_name: 'Relationship',
                                  foreign_key: 'source_id',
                                  dependent: :destroy
  has_many :passive_relationships, class_name: 'Relationship',
                                   foreign_key: 'target_id',
                                   dependent: :destroy
  has_many :friends,   through: :active_relationships, source: :target
  has_many :followers, through: :passive_relationships, source: :source
  has_many :smiles, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_many :moderation_comments, dependent: :destroy
  has_many :moderation_votes, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :group_memberships, class_name: "GroupMember", foreign_key: 'user_id', dependent: :destroy

  SCREEN_NAME_REGEX = /\A[a-zA-Z0-9_]{1,16}\z/
  WEBSITE_REGEX = /https?:\/\/([A-Za-z.\-]+)\/?(?:.*)/i

  before_validation do
    screen_name.strip!
  end

  validates :screen_name, presence: true, format: { with: SCREEN_NAME_REGEX }, uniqueness: { case_sensitive: false }, screen_name: true

  validates :display_name, length: { maximum: 50 }
  validates :bio, length: { maximum: 200 }

  # validates :website, format: { with: WEBSITE_REGEX }

  has_attached_file :profile_picture, styles: { large: "500x500#", medium: "256x256#", small: "80x80#" },
                    default_url: "/images/:style/no_avatar.png", use_timestamp: false,
                    processors: [:cropper]
  validates_attachment_content_type :profile_picture, :content_type => /\Aimage\/.*\Z/
  process_in_background :profile_picture

  before_save do
    self.display_name = 'WRYYYYYYYY' if display_name == 'Dio Brando'
    self.website = if website.match %r{\Ahttps?://}
                     website
                   else
                     "http://#{website}"
                   end unless website.blank?
  end

  def login=(login)
    @login = login
  end

  def login
    @login || self.screen_name || self.email
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup.to_h
    if login = conditions.delete(:login)
      where(conditions).where(["lower(screen_name) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

  # @return [Array] the users' timeline
  def timeline
    Answer.where("user_id in (?) OR user_id = ?", friend_ids, id).order(:created_at).reverse_order
  end

  # follows an user.
  def follow(target_user)
    active_relationships.create(target: target_user)
  end

  # unfollows an user
  def unfollow(target_user)
    active_relationships.find_by(target: target_user).destroy
  end

  # @return [Boolean] true if +self+ is following +target_user+
  def following?(target_user)
    friends.include? target_user
  end

  # @param group [Group]
  # @return [Boolean] true if +self+ is a member of +group+
  def member_of?(group)
    group_memberships.pluck(:group_id).include? group.id
  end

  # answers a question
  # @param question [Question] the question to answer
  # @param content [String] the answer content
  def answer(question, content)
    Answer.create!(content: content,
                   user: self,
                   question: question)
  end

  # has the user answered +question+ yet?
  # @param question [Question]
  def answered?(question)
    question.answers.pluck(:user_id).include? self.id
  end

  # smiles an answer
  # @param answer [Answer] the answer to smile
  def smile(answer)
    Smile.create!(user: self, answer: answer)
  end

  # unsmile an answer
  # @param answer [Answer] the answer to unsmile
  def unsmile(answer)
    Smile.find_by(user: self, answer: answer).destroy
  end

  def smiled?(answer)
    answer.smiles.pluck(:user_id).include? self.id
  end

  def display_website
    website.match(/https?:\/\/([A-Za-z.\-0-9]+)\/?(?:.*)/i)[1]
  rescue NoMethodError
    website
  end

  def comment(answer, content)
    Comment.create!(user: self, answer: answer, content: content)
  end

  # @return [Boolean] is the user a moderator?
  def mod?
    self.moderator? || self.admin?
  end

  # region stuff used for reporting/moderation
  def report(object)
    Report.create(type: "Reports::#{object.class}", target_id: object.id, user_id: self.id)
  end

  # @param upvote [Boolean]
  def report_vote(report, upvote = false)
    return unless mod?
    ModerationVote.create!(user: self, report: report, upvote: upvote)
  end

  def report_unvote(report)
    return unless mod?
    ModerationVote.find_by(user: self, report: report).destroy
  end

  def report_voted?(report)
    return false unless mod?
    report.moderation_votes.each { |s| return true if s.user_id == self.id }
    false
  end

  # @param upvote [Boolean]
  def report_x_voted?(report, upvote)
    return false unless mod?
    report.moderation_votes.where(upvote: upvote).each { |s| return true if s.user_id == self.id }
    false
  end

  def report_comment(report, content)
    ModerationComment.create!(user: self, report: report, content: content)
  end
  # endregion

  def cropping?
    !crop_x.blank? && !crop_y.blank? && !crop_w.blank? && !crop_h.blank?
  end
end
