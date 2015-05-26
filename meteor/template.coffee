Template.slider.rendered = ->

	knownKeys = _.keys Slider.defaults
	dataKeys = _.keys @data ? {}

	eligible = _.intersection knownKeys, dataKeys

	@slider = new Slider @firstNode, if eligible.length then @data else {}

	@autorun =>
		data = Template.currentData()
		n = Number data?.value
		if n? and isFinite(n) and not isNaN(n)
			setValue = =>
				@slider.value n,
					changeEvent: false
					transitionEvent: false
			setValue()