Template.slider.rendered = ->

	knownKeys = _.union _.keys(Slider.defaults), _.keys(Slider.components)
	dataKeys = _.keys @data ? {}

	eligible = _.intersection knownKeys, dataKeys

	@slider = new Slider @firstNode, if eligible.length then @data else {}

	@autorun =>
		data = Template.currentData()
		n = Number data?.value
		if n? and isFinite(n) and not isNaN(n)
			@slider.value n