module ApplicationHelper
  def nav_entry(body, path, options = {})
    options = {
      badge: nil,
      badge_color: nil,
      icon: nil,
      class: ''
    }.merge(options)

    unless options[:icon].nil?
      body = "#{content_tag(:i, '', class: "mdi-#{options[:icon]}")} #{body}"
    end
    unless options[:badge].nil?
      # TODO: make this prettier?
      body << " #{
        content_tag(:span, options[:badge], class: ("badge#{
          " badge-#{options[:badge_color]}" unless options[:badge_color].nil?
        }"))}"
    end

    content_tag(:li, link_to(body.html_safe, path), class: ("#{'active ' if current_page? path}#{options[:class]}"))
  end

  def list_group_item(body, path, options = {})
    options = {
      badge: nil,
      badge_color: nil,
      class: ''
    }.merge(options)

    unless options[:badge].nil? or options[:badge] == 0
      # TODO: make this prettier?
      body << " #{
        content_tag(:span, options[:badge], class: ("badge#{
          " badge-#{options[:badge_color]}" unless options[:badge_color].nil?
        }"))}"
    end

    content_tag(:a, body.html_safe, href: path, class: ("list-group-item #{'active ' if current_page? path}#{options[:class]}"))
  end
  
  ##
  # 
  def bootstrap_color c
    case c
    when "error", "alert"
      "danger"
    when "notice"
      "info"
    else
      c
    end
  end

  def inbox_count
    return 0 unless user_signed_in?
    count = Inbox.select("COUNT(id) AS count")
                 .where(new: true)
                 .where(user_id: current_user.id)
                 .group(:user_id)
                 .order(:count)
                 .first
    return nil if count.nil?
    return nil unless count.count > 0
    count.count
  end

  def notification_count
    return 0 unless user_signed_in?
    count = Notification.for(current_user).where(new: true)
    return nil if count.nil?
    return nil unless count.count > 0
    count.count
  end

  def privileged?(user)
    ((!current_user.nil?) && ((current_user == user) || current_user.mod?)) ? true : false
  end

  # @deprecated Use {User#profile_picture.url} instead.
  def gravatar_url(user)
    return user.profile_picture.url :medium
    # return '/cage.png'
    #return '//www.gravatar.com/avatar' if user.nil?
    #return "//www.gravatar.com/avatar/#{Digest::MD5.hexdigest(user)}" if user.is_a? String
    #"//www.gravatar.com/avatar/#{Digest::MD5.hexdigest(user.email)}"
  end

  def ios_web_app?
    user_agent = request.env['HTTP_USER_AGENT'] || 'Mozilla/5.0'
    # normal MobileSafari.app UA: Mozilla/5.0 (iPhone; CPU iPhone OS 8_1_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B435 Safari/600.1.4
    # webapp UA: Mozilla/5.0 (iPhone; CPU iPhone OS 8_1_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Mobile/12B435
    return true if user_agent.match /^Mozilla\/\d+\.\d+ \(i(?:Phone|Pad|Pod); CPU(?:.*) like Mac OS X\)(?:.*) Mobile(?:\S*)$/
    false
  end
end
