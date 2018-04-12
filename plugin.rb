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
			target_category = SiteSetting.discourse_topic_limit_category_name
			if target_category and target_category != "" and target_category != "none"
				close_message = SiteSetting.discourse_topic_limit_message
				if !close_message or close_message == ""
					close_message = "You already have a topic in this category. Please stick to the one and edit it if you need to change the information in that topic. Do **not** create a new topic."
				end
				if Category.find_by_name(target_category.to_s)
					if Category.find_by_name(target_category.to_s).id == topic.category_id# and !user.staff?
						dupe_post = false
						user.topics.each do |usertopic|
							if usertopic.category_id == topic.category_id and !usertopic.closed?
								topics_posted += 1
								if topics_posted > 1
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