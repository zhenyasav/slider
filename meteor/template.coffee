Template.slider.rendered = ->

	knownKeys = _.keys Slider.defaults
	dataKeys = _.keys @data ? {}

	eligible = _.intersection knownKeys, dataKeys

	new Slider @firstNode, if eligible.length then @data else {}