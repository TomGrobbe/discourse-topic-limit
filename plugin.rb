# name: discourse-topic-limit
# about: Limits topics per user in a specific category.
# version: 1.2.3
# authors: Tom Grobbe
# url: https://github.com/TomGrobbe/discourse-topic-limit

enabled_site_setting :discourse_topic_limit_enabled

require_dependency 'post_creator'
require_dependency 'topic_creator'


after_initialize do

    module ::TopicLimit; end

    module ::TopicLimit::WebHookTopicViewSerializerExtensions
        def include_post_stream?
            true
        end
    end

    module ::TopicLimit::PostCreatorExtensions
        def initialize(user, opts)
            super
        end
    end

    class ::PostCreator
        prepend ::TopicLimit::PostCreatorExtensions
    end

    class ::WebHookTopicViewSerializer
        prepend ::TopicLimit::WebHookTopicViewSerializerExtensions
    end

    DiscourseEvent.on(:topic_created) do |topic, post, user|
        if enabled_site_setting 
            topics_posted = 0
            max_posts_allowed = SiteSetting.discourse_topic_limit_max_posts
            if !max_posts_allowed
                max_posts_allowed = 1
            end
            target_categories = SiteSetting.discourse_topic_limit_categories_names.split("|")
            
            if target_categories and target_categories != "" and target_categories != "none"
                close_message = SiteSetting.discourse_topic_limit_message
                if !close_message or close_message == ""
                    close_message = "You already have one or more active topic(s) in this category. You can only have {max} active topic(s) in this category.<br><br>Please edit your existing topic instead.<br><br>Please do **not** create a new topic."
                end
                close_message = close_message.gsub '{max}', max_posts_allowed.to_s
                
                target_categories.each do |target_category|
                    ignore_staff = SiteSetting.discourse_topic_limit_excempt_staff
                    if (ignore_staff == true and !user.staff?) or (!ignore_staff)
                        if target_category.to_s == topic.category_id.to_s
                            user.topics.each do |usertopic|
                                if usertopic.category_id == topic.category_id and !usertopic.closed?
                                    topics_posted += 1
                                end
                            end
                            if topics_posted > max_posts_allowed
                                topic.update_status("visible", false, Discourse.system_user)
                                topic.update_status("closed", true, Discourse.system_user, message: close_message.to_s)
                                if SiteSetting.discourse_topic_limit_send_warning
                                    warning_message = SiteSetting.discourse_topic_limit_warning_message
                                    if !warning_message or warning_message == ""
                                        warning_message = "Hello @{user},<br>This is an automated warning to let you know that you have reached the topic limit of {max} topics in the '{category}' category. Your most recent topic in that category has been automatically closed and unlisted for this reason.<br><br>Please note that if you (attempt to) evade this topic limit policy **in any way**, you are very likely to end up being (temporarily) suspended from the forums."
                                    end
                                    warning_message = warning_message.gsub '{user}', user.username.to_s
                                    warning_message = warning_message.gsub '{max}', max_posts_allowed.to_s
                                    warning_message = warning_message.gsub '{category}', target_category.name.to_s
                                    if SiteSetting.discourse_topic_limit_use_official_warning
                                        PostCreator.create!(Discourse.system_user, title: "Topic limit reached", raw: close_message.to_s, target_usernames: user.username.to_s, archetype: Archetype.private_message, subtype: TopicSubtype.moderator_warning)
                                    else
                                        PostCreator.create!(Discourse.system_user, title: "Topic limit reached", raw: close_message.to_s, target_usernames: user.username.to_s, archetype: Archetype.private_message)
                                    end
                                end
                                if SiteSetting.discourse_topic_limit_auto_delete_topic
                                    number_of_hours = SiteSetting.discourse_topic_limit_auto_delete_time
                                    if !number_of_hours
                                        number_of_hours = 24
                                    end
                                    topic.topic_timers=[TopicTimer.create(execute_at: DateTime.now + number_of_hours.hours, status_type: 4, user_id: Discourse.system_user.id, topic_id: topic.id, based_on_last_post: false, created_at: DateTime.now, updated_at: DateTime.now, public_type: true)]
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end