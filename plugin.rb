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
		topics_posted = 0
		puts topic.category_id # the topic category id.
		puts Category.find_by_name("Hidden Categories").id # the target category to limit things
		if Category.find_by_name("Hidden Categories").id == topic.category_id
			dupe_post = false
			user.topics.each do |usertopic|
#				puts usertopic.category_id
				if usertopic.category_id == topic.category_id and !usertopic.closed?
					#					dupe_post = true
					topics_posted = topics_posted + 1
					if topics_posted > 1
						dupe_posts = true
						puts "Duplicate post!"
					end
				end
			end
			if dupe_post
				puts "User already posted here before!"
			else
				puts "User has not posted here before!"
			end
		else
			puts "Topic is not in the target category."
		end
		puts "User: " + user.username + " has posted: " + topics_posted + " topics in this category."
		puts "Is user staff?"
		puts user.staff?
		
	end
end