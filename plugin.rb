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
#		puts topic.category_id # the topic category id.
		#		puts Category.find_by_name("Hidden Categories").id # the target category to limit things
		topics_posted = 0
		if Category.find_by_name("Hidden Categories").id == topic.category_id# and !user.staff?
			dupe_post = false
			user.topics.each do |usertopic|
#				puts usertopic.category_id
				if usertopic.category_id == topic.category_id and !usertopic.closed?
					#					dupe_post = true
					topics_posted += 1
					if topics_posted > 1
						dupe_post = true
#						puts "Duplicate post!"
					end
				end
			end
			if dupe_post
#				puts "User already posted here before!"
				topic.update_status("closed", true, Discourse.system_user)
				topic.update_status("visible", false, Discourse.system_user)
				Topic.find_by_id(topic.id).posts.last.update(raw: "You already have a topic in this category. You are only allowed to create one. Please stick to your existing one and edit that one instead.")
			end
		end
		puts "User: " + user.username + " has posted: " + topics_posted.to_s + " topics in this category."
#		puts "Is user staff?"
#		puts user.staff?
		
	end
end