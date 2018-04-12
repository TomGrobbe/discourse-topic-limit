# name: discourse-topic-limit
# about: Limits topics per user in a specific category.
# version: 0.0.1
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
			target_category = SiteSetting.discourse_topic_limit_category_name
			if target_category and target_category != "" and target_category != "none"
				close_message = SiteSetting.discourse_topic_limit_message
				if !close_message or close_message == ""
					close_message = "You already have a topic in the #server-development:server-bazaar section. Please include all advertisements, developer requests, information, etc. in ONE topic. You are able to edit previous posts to include new or modified information by clicking the pencil icon. If you would like to return your post to the top of the list, you can reply to the original topic to bump it. Please do not create any additional topics."
				end
				if Category.find_by_name(target_category.to_s)
					ignore_staff = SiteSetting.discourse_topic_limit_excempt_staff
					if (ignore_staff == true and !user.staff?) or (!ignore_staff)
						if Category.find_by_name(target_category.to_s).id == topic.category_id
							dupe_post = false
							user.topics.each do |usertopic|
								if usertopic.category_id == topic.category_id and !usertopic.closed?
									topics_posted += 1
									if topics_posted > max_posts_allowed
										dupe_post = true
									end
								end
							end
							if dupe_post
								topic.update_status("closed", true, Discourse.system_user)
								topic.update_status("visible", false, Discourse.system_user)
								Topic.find_by_id(topic.id).posts.last.update(raw: close_message.to_s)
							end
						end
					end
				end
			end
		end
		
	end
end