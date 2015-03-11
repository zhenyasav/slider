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

		map: (o, f) -> f? v, k for k,v of o

		isObject: (o) -> "[object Object]" is Object.prototype.toString.call o

		isArray: (o) -> "[object Array]" is Object.prototype.toString.call o

		isMobile: 'ontouchstart' of window

		delay: (d, f) -> setTimeout f, d

		addClass: (e, c) -> e?.classList?.add c

		removeClass: (e, c) -> e?.classList?.remove c

		offset: (e) ->
			return if e not instanceof Element
			offset = 
				x: e.offsetLeft
				y: e.offsetTop

			parent = e.offsetParent

			while parent?
				offset.x += parent.offsetLeft
				offset.y += parent.offsetTop
				parent = parent.offsetParent

			offset


		transform: (el, x, y) ->
			style = el?.style
			{x, y} = x if x instanceof Vector

			style.transform = style.WebkitTransform = style.msTransform = "translate3d(#{x.toFixed 3}px, #{y.toFixed 3}px, 0)"

		clamp: (v, min, max) -> 
			v = min if min? and v < min
			v = max if max? and v > max
			v

		roundTo: (n, d) -> d * Math.round n / d

		sign: (n) ->
			return 0 if typeof n isnt 'number' or isNaN(n) or not isFinite(n)
			if n >= 0 then 1 else -1

		fixFPError: (n) ->
			str = String n
			if /\..*00000\d$/i.test str
				Number str.substring 0, str.length-1
			else if /\..*99999\d$/i.test str
				r = Number str[str.length-1]
				p = str.indexOf '.'
				p = p - str.length + 1
				n + (_.sign n) * (10-r) * 10**p
			else
				n

		formatObject: (v, indent=0) ->
			_.map v, (val, key) ->
				val = "\"#{val}\"" if typeof val is 'string'
				val = "\n" + _.formatObject val, indent+1 if '[object Object]' is Object.prototype.toString.call val
				"#{if indent then ('  ' for t in [0..indent]).join('') else ''}#{key}: #{val}"
			.join '\n'

		formatNumber: (n, options) ->

			defaults = 
				inf: "&#8734;"
				nan: "?"
				decimalPlaces: 2
				separator: ''

			options = _.extend {}, defaults, options ? {}

			return n if typeof n isnt 'number' 
			return "?" if isNaN n
			return "&#8734;" if not isFinite n

			order = if n isnt 0 then Math.floor Math.log10 Math.abs n else 0

			
			unit = (order, suffix) -> 
				(x) ->
					number = _.sign(x) * Math.round(Math.abs(x) / 10**(order - options.decimalPlaces)) / 10**(options.decimalPlaces)
					number + options.separator + suffix

			macro = [
				unit 0, ''
				unit 3, 'k'
				unit 6, 'M'
				unit 9, 'G'
				unit 12, 'T'
				unit 15, 'P'
				unit 18, 'E'
				unit 21, 'Z'
				unit 24, 'Y'
			]

			micro = [
				unit 0, ''
				unit -3, 'm'
				unit -6, 'μ'
				unit -9, 'n'
				unit -12, 'p'
				unit -15, 'f'
				unit -18, 'a'
				unit -21, 'z'
				unit -24, 'y'
			]
			
			order = _.sign(order) * Math.floor Math.abs(order)/3
			if order >= 0
				order = _.clamp order, 0, macro.length-1
				"" + macro[order] n
			else
				order = _.clamp order, -micro.length+1, 0
				"" + micro[-order] n


		log: (e) -> 
			console.log e
			e

		tag: (name) ->
			(args...) ->
				attr = {}
				last = args[args.length - 1]
				if last instanceof Element or _.isArray last
					content = args.splice(args.length - 1, 1)?[0]
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
	_.pre = _.tag 'pre'

	[_.startEvent, _.moveEvent, _.endEvent] = if _.isMobile
		['touchstart', 'touchmove', 'touchend'] 
	else 
		['mousedown', 'mousemove', 'mouseup']


	Vector = class @Vector

		constructor: (x, y) ->
			if x instanceof Event
				if _.isMobile
					touches = if x.type is 'touchend' then x.changedTouches else x.touches
				@x = if _.isMobile then (touches)[0].pageX else x.pageX
				@y = if _.isMobile then (touches)[0].pageY else x.pageY
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

	@polling: 
		timeout: null
		
		interval: 1931
		
		start: -> 
			if not @timeout?
				@timeout = setInterval ->
					Slider.instances.map (slider) -> 
						if slider.options.poll and not slider.transitioning and not slider.dragging
							slider.position slider.position()
				, @interval
		
		stop: -> clearInterval(@timeout) if @timeout?


	@defaults:
		min: 0
		max: 1
		initial: 0
		step: 0.1
		warnings: true
		orientation: 'horizontal'
		transitionDuration: 350
		poll: false

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

		for component, ctor of Slider.components
			@[component] = new ctor @, @options[component]

		@value @options.initial

		Slider.polling.start() if @options.poll

	value: (v, options={}) ->
		@position v, _.extend options, normalized: false

	position: (p, options) ->
		if _.isObject p 
			options = p
			p = undefined

		defaults = 
			normalized: true
			transition: @options.transitionDuration
			step: if options?.normalized is false then @options.step else @options.step / (@options.max - @options.min)

		options = _.extend {}, defaults, options


		pos = if p is undefined
			@normalizedPosition
		else
			if options.normalized then p else (p - @options.min) / (@options.max - @options.min)
	
		
		if options.step 
			step = if not options.normalized
				options.step / (@options.max - @options.min)
			else 
				options.step
		else
			step = 1 / @knob.range()

		pos = _.fixFPError _.roundTo pos, step


		val = if options.normalized
			(x) -> x 
		else
			(x) => @options.min + x * (@options.max - @options.min) 

		return _.fixFPError val pos if p is undefined

 
		if not (val(0) <= p <= val(1))
			@warn if options.normalized
				Slider.errors.positionInvalid
			else
				Slider.errors.valueInvalid
			return

		@normalizedPosition = pos

		if options.transition
			_.addClass @element, 'transition'
			@transitioning = true

		@[comp]?.position? @normalizedPosition, options for comp, ctr of Slider.components

		if options.transition
			_.delay options.transition, => 
				_.delay 17, =>
					_.removeClass @element, 'transition'
					@transitioning = false
		pos



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

						trackOffset = _.offset @element

						dest = switch @slider.options.orientation
							when 'horizontal' then pos.x - trackOffset.x
							when 'vertical' then pos.y - trackOffset.y

						@slider.position _.clamp (dest - @slider.knob.size() / 2) / @slider.knob.range(), 0, 1



	Knob = class @Knob

		@defaults:
			interactive: true

		size: -> switch @slider.options.orientation 
			when 'horizontal' then @element.offsetWidth + 2 * @element.offsetLeft
			when 'vertical' then @element.offsetHeight + 2 * @element.offsetTop

		range: -> @slider.track.size() - @size()

		position: (p, options) ->
			@offset.set switch @slider.options.orientation
				when 'horizontal'
					x: @range() * p 
					y: 0
				when 'vertical'
					x: 0
					y: @range() * p

			_.transform @element, @offset


		constructor: (@slider, options) ->
			@options = _.extend {}, Knob.defaults ? {}, options ? {}

			@slider.element.appendChild @element = _.div class:'knob'

			@offset = new Vector 0, 0

			if @options.interactive

				start = null
				startOffset = null

				@element.addEventListener _.startEvent, (e) => 
					start = new Vector e
					startOffset = @offset.clone()
					_.removeClass @slider.element, 'transition'
					_.addClass @slider.element, 'dragging'
					@slider.dragging = true

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

						, 
							transition: false
							step: false

				window.addEventListener _.endEvent, (e) =>
					if start?
						start = null
						_.removeClass @slider.element, 'dragging'
						@slider.dragging = false
						if @slider.options.step?
							@slider.position @slider.position()



	Label = class @Label extends Knob

		@defaults: 
			location: 'knob'
			precision: 1
			popup: true
			format: (v, options) -> _.formatNumber v, decimalPlaces: options.precision

		position: (p, o) ->
			super p, o

			formatted = @options.format? @slider.value(), @options

			@value.innerText = 
			@hiddenValue.innerText = 
			@hiddenKnobValue.innerText = formatted

		constructor: (@slider, options) ->
			super @slider, _.extend {}, Label.defaults, options ? {}, interactive: false

			_.addClass @element, 'label'

			_.addClass @element, 'popup' if @options.popup

			@element.appendChild @popup = _.div class: 'popup', [
				@value = _.div class: 'value'
				_.div class: 'arrow'
			]

			@element.appendChild @hiddenValue = _.div class: 'hidden value'

			if @options.location is 'knob'
				@slider.knob.element.appendChild @hiddenKnobValue = _.div class: 'hidden value'


	Debug = class @Debug

		position: (p, options) ->
			@element.innerText = _.formatObject
				position: p
				value: @slider.value()

		constructor: (@slider, options) ->
			@slider.element.appendChild @element = _.pre class:'debug'

	@components:
		track: @Track
		knob: @Knob
		label: @Label
		#debug: @Debug


