tracker = require('pivotaltracker')
_ = require("lodash")
exec = require('child_process').exec;

# TRACKER_TOKEN = process.argv[0]
# TRACKER_PROJECT_ID = process.argv[1]
# ENVIRONMENT = process.argv[2]

TRACKER_TOKEN = "368271fdb6f98f3a67301591b9df3785"
TRACKER_PROJECT_ID = "799115"
ENVIRONMENT = "Development"

client = new tracker.Client(TRACKER_TOKEN);
client.use_ssl = true
stories = null

client.project(TRACKER_PROJECT_ID).stories.all (error, projectStories) ->
	console.log '------------------------------------------------------------------------'
	stories = _.filter projectStories , (it) => it.state == "finished" and _.contains ['bug', 'feature'], it.story_type

exec 'git tag | grep staging | tail -n1', (error, stdout, stderr) =>
  staging_deploy_tag = stdout

_.forEach stories, (story) =>
	console.log "Searching for #{story.id} in local git repo."

	exec 'git log --grep #{story.id} #{staging_deploy_tag}', (error, stdout, stderr) =>
  		search_result = stdout

	if search_result.length > 0
		console.log "Found #{story.id}, marking as delivered to #{ENVIRONMENT}."		
		story.labels = if story.labels then story.labels + "," else ""
		story.labels += "#{ENVIRONMENT}"
		if "#{ENVIRONMENT}" == "Development"
			story.notes.create(text: "Marked as delivered by deploy script.")
			story.update({current_state: "delivered"})
		else
			story.update()

	else
		console.log "Could not find #{story.id} in git repo."
