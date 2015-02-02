require 'elasticsearch/model'

class Answer < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  belongs_to :user
  belongs_to :question
  has_many :comments, dependent: :destroy
  has_many :smiles, dependent: :destroy

  after_create do
    Inbox.where(user: self.user, question: self.question).destroy_all

    Notification.notify self.question.user, self unless self.question.author_is_anonymous
    self.user.increment! :answered_count
    self.question.increment! :answer_count
  end

  before_destroy do
    # mark a report as deleted if it exists
    rep = Report.where(target_id: self.id).first
    unless rep.nil?
      rep.deleted = true
      rep.save
    end

    self.user.decrement! :answered_count
    self.question.decrement! :answer_count
    self.smiles.each do |smile|
      Notification.denotify self.user, smile
    end
    self.comments.each do |comment|
      comment.user.decrement! :commented_count
      Notification.denotify self.user, comment
    end
    Notification.denotify self.question.user, self
  end

  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :content, analyzer: 'english'
    end
  end

  def self.search(query)
    __elasticsearch__.search(
      {
        query: {
          multi_match: {
            query: query,
            fields: ['content^10', 'text']
          }
        },
        highlight: {
          pre_tags: ['<strong>'],
          post_tags: ['</strong>'],
          fields: {
            title: {},
            text: {}
          }
        }
      }
    )
  end

  def notification_type(*_args)
    Notifications::QuestionAnswered
  end
end
Answer.import