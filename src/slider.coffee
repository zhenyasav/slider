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

		map: (o, f) -> 
			if _.isArray o
				f? v, k for v, k in o
			else
				f? v, k for k, v of o

		find: (o, f) ->
			if _.isArray o
				for v, k in o
					if f? v, k
						return v
			else
				for k, v of o
					if f? v, k
						return v

		isObject: (o) -> "[object Object]" is Object.prototype.toString.call o

		isArray: (o) -> "[object Array]" is Object.prototype.toString.call o

		isMobile: 'ontouchstart' of window

		delay: (d, f) -> setTimeout f, d

		throttle: (d, fun, ctx) ->
			tmout = null
			-> 
				if tmout
					clearTimeout tmout
				args = (k for k in arguments)
				tmout = setTimeout -> 
					fun?.apply? (ctx ? @), args
				, d

		addClass: (e, c) -> e?.classList?.add c

		removeClass: (e, c) -> e?.classList?.remove c

		toggleClass: (e, c, t) -> e?.classList?[if t then 'add' else 'remove']? c

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

		event: (name, data) ->
			evt = document.createEvent 'Event'
			evt.initEvent name, true, true
			_.extend evt, data ? {}

		listenOnce: (element, name, listener) ->
			harness = (e) -> 
				element.removeEventListener name, harness
				listener? e
			element.addEventListener name, harness


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

		subtract: (v) -> new Vector @x - v?.x ? 0, @y - v?.y ? 0
		
		add: (v) -> new Vector @x + v?.x ? 0, @y + v?.y ? 0
		
		magnitude: -> Math.sqrt @x**2 + @y**2
		
		clamp: (r) ->
			@x = _.clamp @x, r?.x?[0], r?.x?[1]
			@y = _.clamp @y, r?.y?[0], r?.y?[1]


	@errors:
		selectorEmpty: 'slider element selector must return at least one element'
		elementInvalid: 'first argument must be a selector or an element'
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
		value: 0
		step: 0.1
		warnings: true
		orientation: 'horizontal'
		transitionDuration: 350
		poll: false
		formElement: null

	@instances: []

	@getInstance: (element) ->
		return null if element not instanceof Element
		_.find Slider.instances, (i) -> i.element is element

	warn: -> 
		console?.warn?.apply console, arguments if @options.warnings

	constructor: (element, options) ->
		@options = _.extend {}, Slider.defaults, options ? {}

		if typeof element is 'string'
			@element = document.querySelector element
			throw Slider.errors.selectorEmpty if not @element
		else if element instanceof Element
			@element = element
		else
			throw Slider.errors.elementInvalid

		Slider.instances?.push? @

		@onFormElementChange = (e) =>
			val = e?.target?.value
			if val?
				val = Number val
				if isFinite(val) and not isNaN(val)
					ok = @value val, updateFormElement: false
					if not ok?
						e?.target?.value = @value()
				else
					@warn Slider.errors.valueInvalid + " : " + val
					e?.target?.value = @value()

		@bindFormElement @options.formElement if @options.formElement

		_.addClass @element, 'slider'
		_.addClass @element, @options.orientation

		for component, generator of Slider.components
			if ctor = generator @options
				@[component] = new ctor @, @options[component]

		@value @options.value, 
			changeEvent: false
			transitionEvent: false

		Slider.polling.start() if @options.poll

		window.addEventListener 'resize', _.throttle 600, =>
			@refresh()

	refresh: (o) ->
		refresh = =>
			@position @position(), _.extend 
				changeEvent: false
				transitionEvent: false
			, o

		if @transitioning
			_.listenOnce @element, 'transition', refresh
		else
			refresh()

	bindFormElement: (element, options) ->
		defaults = 
			unbindOldElement: true

		options = _.extend {}, defaults, options

		if typeof element is 'string'
			element = document.querySelector element
			throw Slider.errors.selectorEmpty if not element
		else if element not instanceof Element
			throw Slider.errors.elementInvalid

		if options.unbindOldElement and @formElement and @onFormElementChange
			@formElement.removeEventListener 'change', @onFormElementChange

		element.addEventListener 'change', @onFormElementChange

		@formElement = element

	value: (v, options={}) ->
		@position v, _.extend options, normalized: false

	position: (p, options) ->
		if _.isObject p 
			options = p
			p = undefined

		defaults = 
			normalized: true
			transition: @options.transitionDuration
			changeEvent: true
			transitionEvent: true
			step: if options?.normalized is false then @options.step else @options.step / (@options.max - @options.min)
			updateFormElement: true

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
				Slider.errors.positionInvalid + " : " + p
			else
				Slider.errors.valueInvalid + " : " + p
			return

		@normalizedPosition = pos

		if options.transition
			_.addClass @element, 'transition'
			@transitioning = true

		@[comp]?.position? @normalizedPosition, options for comp, ctr of Slider.components

		@formElement?.value = @value() if options.updateFormElement

		if options.changeEvent
			@element.dispatchEvent _.event 'change', value: @value()

		if options.transition
			_.delay options.transition, => 
				_.delay 17, =>
					_.removeClass @element, 'transition'
					@transitioning = false
					@element.dispatchEvent _.event 'transition', value: @value() if options.transitionEvent
		pos


	Component = class @Component

	Track = class @Track extends Component

		@defaults:
			dragEvents: true

		size: -> switch @slider.options.orientation
			when 'horizontal' then @element.offsetWidth
			when 'vertical' then @element.offsetHeight

		constructor: (@slider, options) ->
			@options = _.extend {}, Track.defaults ? {}, options ? {}

			@slider.element.appendChild @element = _.div class:'track'

			start = null
			knobStartOffset = null

			pixelPos = (pxOffset, options) => 
				p = switch @slider.options.orientation
					when 'horizontal' then pxOffset.x
					when 'vertical' then pxOffset.y
				p = _.clamp (p - @slider.knob.size() / 2) / @slider.knob.range(), 0, 1
				@slider.position p, options


			toggleClass = _.throttle 100, (cls, condition=true) => 
				_.toggleClass @slider.element, cls, condition


			@element.addEventListener _.startEvent, (e) =>
				start = new Vector e
				trackOffset = _.offset @element
				pixelPos start.subtract(trackOffset), 
					transition: false
					step: false
					changeEvent: false
				knobStartOffset = @slider.knob.offset.clone()
				_.removeClass @slider.element, 'transition'
				toggleClass 'dragging', true
				@slider.dragging = true

			window.addEventListener _.endEvent, (e) =>
				if start? 
					toggleClass 'dragging', false
					@slider.dragging = false
					@slider.refresh
						changeEvent: true
						transitionEvent: true

					start = null

			window.addEventListener _.moveEvent, (e) =>
				if start

					orientOffset = switch @slider.options.orientation
						when 'horizontal' then x: @slider.knob.size() / 2
						when 'vertical' then y: @slider.knob.size() / 2

					pixelPos knobStartOffset.add(new Vector(e).subtract start).add(orientOffset), 
						transition: false
						step: false
						changeEvent: false

					if @options.dragEvents
						@slider.element.dispatchEvent _.event 'drag',
							position: @slider.position()
							value: @slider.value()



	Knob = class @Knob extends Component

		@defaults:
			dragEvents: true

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

			@


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
			super @slider, _.extend {}, Label.defaults, options ? {}

			_.addClass @element, 'label'

			_.addClass @element, 'popup' if @options.popup

			@element.appendChild @popup = _.div class: 'popup', [
				@value = _.div class: 'value'
				_.div class: 'arrow'
			]

			@element.appendChild @hiddenValue = _.div class: 'hidden value'

			if @options.location is 'knob'
				@slider.knob.element.appendChild @hiddenKnobValue = _.div class: 'hidden value'



	Fill = class @Fill extends Component

		@defaults: null

		position: (p, options) ->
			if @options is 'upper'
				p = 1 - p

			styleProp = if @slider.options.orientation is 'horizontal' then 'width' else 'height'
			
			@element.style[styleProp] = p * @slider.knob.range() + @slider.knob.size() / 2 + 'px'

		constructor: (@slider, options) ->
			@options = options ? Fill.defaults

			_.addClass @slider.element, "fill-" + @options

			@slider.track.element.appendChild @element = _.div class: 'fill'


	Debug = class @Debug extends Component

		position: (p, options) ->
			@element.innerText = _.formatObject
				position: p
				value: @slider.value()

		constructor: (@slider, options) ->
			@slider.element.appendChild @element = _.pre class:'debug'


	@components:
		track: -> Track
		knob: -> Knob
		label: -> Label
		fill: (o) -> Fill if o.fill?
		debug: (o) -> Debug if o.debug


