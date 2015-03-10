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
				r = Number str.substring str.length-1, 1
				p = str.indexOf '.'
				p = p - str.length
				n + (10-r) * 10**p
			else
				n

		format: (n, options) ->

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

			
			units = (order, suffix) -> 
				(x) ->
					number = _.sign(x) * Math.round(Math.abs(x) / 10**(order - options.decimalPlaces)) / 10**(options.decimalPlaces)
					number + options.separator + suffix

			macro = [
				units 0, ''
				units 3, 'k'
				units 6, 'M'
				units 9, 'G'
				units 12, 'T'
				units 15, 'P'
				units 18, 'E'
				units 21, 'Z'
				units 24, 'Y'
			]

			micro = [
				units 0, ''
				units -3, 'm'
				units -6, 'μ'
				units -9, 'n'
				units -12, 'p'
				units -15, 'f'
				units -18, 'a'
				units -21, 'z'
				units -24, 'y'
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

	@defaults:
		min: 0
		max: 1
		initial: 0
		step: 0.01
		warnings: true
		orientation: 'horizontal'
		transitionDuration: 350

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

	value: (v, options={}) ->
		@position v, _.extend options, normalized: false

	position: (p, options) ->
		if _.isObject p 
			options = p

		defaults = 
			normalized: true
			transition: @options.transitionDuration

		options = _.extend {}, defaults, options

		if p isnt undefined and @options.step?
			step = if options.normalized then @options.step / (@options.max - @options.min) else @options.step
			p = _.fixFPError _.roundTo p, step

		val = if options.normalized
			(x) -> x 
		else
			(x) => @options.min + x * (@options.max - @options.min) 

		return val @normalizedPosition if p is undefined or _.isObject p
 
		if not (val(0) <= p <= val(1))
			@warn if options.normalized then Slider.errors.positionInvalid else Slider.errors.valueInvalid
			return

		@normalizedPosition = if options.normalized then p else (p - @options.min) / (@options.max - @options.min)

		_.addClass @element, 'transition' if options.transition

		@[comp]?.position? @normalizedPosition, options for comp, ctr of Slider.components

		if options.transition
			_.delay options.transition, => 
				_.removeClass @element, 'transition'



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
					_.removeClass @slider.element, 'dragging'



	Label = class @Label extends Knob

		@defaults: 
			location: 'knob'
			precision: 1
			popup: true

		format: (v) -> _.format v, decimalPlaces: @options.precision

		position: (p, o) ->
			super p, o

			@value.innerText = @format @slider.value()

		constructor: (@slider, options) ->
			super @slider, _.extend {}, Label.defaults, options ? {}, interactive: false

			_.addClass @element, 'label'

			_.addClass @element, 'popup' if @options.popup

			@element.appendChild @popup = _.div class: 'popup', [
				@value = _.div class: 'value'
				_.div class: 'arrow'
			]


	@components:
		track: @Track
		knob: @Knob
		label: @Label


