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


	DiscourseEvent.on(:topic_created) do |topic, rawPost, user|
		puts "Topic: "
		puts topic
		puts "topic.category_id: "
		puts topic.category_id
#		puts rawPost
#		puts rawPost["category"]
		puts "Category and category.id for the 'Hidden Categories' category:"
		puts Category.find_by_name("Hidden Categories")
		puts Category.find_by_name("Hidden Categories").id
#		if Category.find_by_name("Hidden Categories").id == post.category
#			dupe_post = false
#			user.topics.each do |usertopic|
#				puts usertopic.category_id
#				if usertopic.category_id == post.category and !usertopic.closed?
#					dupe_post = true
#					puts "Duplicate post!"
#				end
#			end
#			if dupe_post
#				puts "User already posted here before!"
#			else
#				puts "User has not posted here before!"
#			end
#		end
		
		puts "Is user staff?"
		puts user.staff?
		
	end
end