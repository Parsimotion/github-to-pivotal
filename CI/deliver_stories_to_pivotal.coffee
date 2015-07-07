tracker = require('pivotaltracker')
_ = require("lodash")
exec = require('child_process').exec;

TRACKER_TOKEN = process.env.npm_config_trackerToken
TRACKER_PROJECT_ID =process.env.npm_config_trackerProjectId
ENVIRONMENT = process.env.npm_config_enviroment

client = new tracker.Client(TRACKER_TOKEN);
client.use_ssl = true

client.project(TRACKER_PROJECT_ID).stories.all {with_state: "finished"}, (error, stories) ->

	exec 'git tag | grep staging | tail -n1', (error, staging_deploy_tag, stderr) =>	
		_.forEach stories, (story) =>
			console.log "Searching for #{story.id} in local git repo."
			exec "git log --grep #{story.id}", (error, search_result, stderr) =>
				process.stdout.write search_result
				if search_result.length > 0
					console.log "Found #{story.id}, marking as delivered to #{ENVIRONMENT}."
					obj = {labels: story.labels}
					obj.labels.push { name: "#{ENVIRONMENT}" }
					if "#{ENVIRONMENT}" == "Development"
						obj.current_state = "delivered"
					client.project(TRACKER_PROJECT_ID).story(story.id).update obj, ->
				else
					console.log "Could not find #{story.id} in git repo."
