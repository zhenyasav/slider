class @Slider

	_ = @_ =
		extend: (args...) ->
			return if not args.length
			return args[0] if args.length is 1
			first = args.splice(0, 1)?[0]
			for o, i in args
				for k, v of o
					first[k] = v
			first

		isObject: (o) -> "[object Object]" is Object.prototype.toString.call o

		isArray: (o) -> "[object Array]" is Object.prototype.toString.call o

		isMobile: 'ontouchstart' of window

		delay: (d, f) -> setTimeout f, d

		addClass: (e, c) -> e?.classList?.add c

		removeClass: (e, c) -> e?.classList?.remove c

		transform: (el, xform) ->
			style = el?.style
			style.transform = style.WebkitTransform = style.msTransform = xform

		clamp: (v, min, max) -> 
			v = min if min? and v < min
			v = max if max? and v > max
			v

		log: (e) -> 
			console.log e
			e

		tag: (name) ->
			(args...) ->
				attr = {}
				last = args[args.length - 1]
				if last instanceof Element or _.isArray last
					content = args.splice args.length - 1, 1
				for arg in args
					for key, val of arg 
						attr[key] = val
				el = document.createElement name
				for a, val of attr
					el.setAttribute a, val
				if not _.isArray content
					content = [content]
				content.map (c) -> el.appendChild c if c instanceof Element
				el


	_.div = _.tag 'div'

	[_.startEvent, _.moveEvent, _.endEvent] = if _.isMobile
		['touchstart', 'touchmove', 'touchend'] 
	else 
		['mousedown', 'mousemove', 'mouseup']


	Vector = class @Vector

		constructor: (x, y) ->
			if x instanceof Event
				if _.isMobile
					touches = if x.type is 'touchend' then x.changedTouches else x.touches
				@x = if _.isMobile then (touches)[0].clientX else x.clientX
				@y = if _.isMobile then (touches)[0].clientY else x.clientY
			else
				@set {x, y}

		set: (v) -> 
			@x = v.x if v?.x?
			@y = v.y if v?.y?

		clone: -> new Vector @x, @y

		subtract: (v) -> new Vector @x - v.x, @y - v.y
		
		add: (v) -> new Vector @x + v.x, @y + v.y
		
		magnitude: -> Math.sqrt @x**2 + @y**2
		
		clamp: (r) ->
			@x = _.clamp @x, r?.x?[0], r?.x?[1]
			@y = _.clamp @y, r?.y?[0], r?.y?[1]


	@errors:
		selectorEmpty: 'slider element selector must return at least one element'
		elementInvalid: 'slider first argument must be a selector or an element'
		valueInvalid: 'slider value must be between options.min and options.max'
		positionInvalid: 'slider position must be between 0 and 1'

	@defaults:
		warnings: true
		orientation: 'horizontal'
		transitionDuration: 350
		min: 0
		max: 1

	@instances: []

	warn: -> console?.warn?.apply console, arguments if @options.warnings

	constructor: (element, options) ->
		@options = _.extend {}, Slider.defaults, options ? {}

		if typeof element is 'string'
			r = document.querySelectorAll element
			throw Slider.errors.selectorEmpty if not r.length
			@element = r[0]
		else if element instanceof Element
			@element = element
		else
			throw Slider.errors.elementInvalid

		Slider.instances?.push? @

		_.addClass @element, 'slider'
		_.addClass @element, @options.orientation

		@relativePosition = 0
	
		for component, ctor of Slider.components
			@[component] = new ctor @, @options[component]

	value: (v, options) ->
		return @relativePosition * (@options.max - @options.min) + @options.min if not arguments?.length

		if not (@options.min <= v <= @options.max)
			@warn Slider.errors.valueInvalid
			return

		@relativePosition = v / (@options.max - @options.min)

		@[comp]?.position? @relativePosition, options for comp, ctr of Slider.components

	position: (p, options) ->
		return @relativePosition if not arguments?.length

		if not (0 <= p <= 1)
			@warn Slider.errors.positionInvalid
			return

		@relativePosition = p

		@[comp]?.position? @relativePosition, options for comp, ctr of Slider.components



	Track = class @Track

		size: -> switch @slider.options.orientation
			when 'horizontal' then @element.offsetWidth
			when 'vertical' then @element.offsetHeight

		constructor: (@slider, options) ->
			@options = _.extend {}, Track.defaults ? {}, options ? {}

			@slider.element.appendChild @element = _.div class:'track'

			start = null

			@element.addEventListener _.startEvent, (e) =>
				start = new Vector e

			@element.addEventListener _.endEvent, (e) =>
				if start?
					pos = new Vector e
					delta = pos.subtract(start).magnitude()
					start = null
					if delta < 5

						offset = switch @slider.options.orientation
							when 'horizontal' then e.offsetX
							when 'vertical' then e.offsetY

						@slider.position _.clamp (offset - @slider.knob.size() / 2) / @slider.knob.range(), 0, 1



	Knob = class @Knob

		size: -> switch @slider.options.orientation 
			when 'horizontal' then @element.offsetWidth + 2 * @element.offsetLeft
			when 'vertical' then @element.offsetHeight + 2 * @element.offsetTop

		range: -> @slider.track.size() - @size()

		position: (p, options) ->
			defaults = 
				transition: true
			options = _.extend {}, defaults, options

			_.addClass @slider.element, 'transition' if options.transition

			@offset.set switch @slider.options.orientation
				when 'horizontal'
					x: @range() * p 
					y: 0
				when 'vertical'
					x: 0
					y: @range() * p

			_.transform @element, "translate3d(#{@offset.x.toFixed 3}px, #{@offset.y.toFixed 3}px, 0)"

			if options.transition
				_.delay @slider.options.transitionDuration, => 
					_.removeClass @slider.element, 'transition'

		constructor: (@slider, options) ->
			@options = _.extend {}, Knob.defaults ? {}, options ? {}

			@slider.element.appendChild @element = _.div class:'knob'

			@offset = new Vector 0, 0

			start = null
			startOffset = null

			@element.addEventListener _.startEvent, (e) => 
				start = new Vector e
				startOffset = @offset.clone()
				_.removeClass @element, 'transition'

			window.addEventListener _.moveEvent, (e) =>
				if start?
					e.preventDefault()
					pos = new Vector e
					offset = pos.subtract start
					offset = offset.add startOffset

					@slider.position switch @slider.options.orientation
						when 'horizontal'
							_.clamp offset.x / @range(), 0, 1
						when 'vertical'
							_.clamp offset.y / @range(), 0, 1

					, transition: false

			window.addEventListener _.endEvent, (e) =>
				start = null



	Label = class @Label extends Knob

		@defaults: 
			location: 'knob'
			precision: 1

		format: (v) -> 
			if Math.abs(v) <= 1
				v.toFixed @options.precision
			else
				v

		position: (p, o) ->
			super p, o
			@element.innerText = @format @slider.value()

		constructor: (@slider, options) ->
			@options = _.extend {}, Label.defaults, options ? {}

			@slider.element.appendChild @element = _.div class: "label #{@options.location}"

			@offset = new Vector 0, 0

			@element.innerText = @format @slider.value()



	@components:
		track: @Track
		knob: @Knob
		label: @Label


