# Slider
Mobile-first HTML5 slider component. Demo at http://slider.zhenya.co

## Vanilla API
Include:
- `slider.js` or `slider.min.js`
- `slider.css` or `slider.min.css`

To instantiate a slider, pass a root element and an optional config object to the constructor. If a selector is passed in that matches more than one element, the first element will be used.
``` js
var myslider = new Slider("#slider", {
	min: 0,
	max: 1
});
```

## Meteor API
Use the template helper `{{>slider}}` to instantiate a slider. The data context of the slider will be assumed to be the options object if and only if there are some keys on that object that are also present on `Slider.defaults`. In other words, if the data context looks like a slider options object, it will be used. 

This makes it easy to pass options to the slider directly from the template:
```
{{>slider min=0 max=100 step=1 value=foobar}}
```
In the example above, if there is a key on the data context called `foobar` that returns a numeric value, it will reactively control the value of the slider.

### Default options:
``` coffee
Slider.defaults = 
	min: 0	# minimum value
	max: 1 	# maximum value
	value: 0 	# initial value
	step: 0.1 	# minimum step size
	warnings: true	# log warnings to the console
	orientation: 'horizontal'	# can be 'vertical' or 'horizontal'
	transitionDuration: 350		# animation duration, must be same as in CSS
	poll: false		# automatically refresh all sliders periodically
	formElement: null	# connect slider value to a form element via a selector
	knob:
		dragEvents: true	# fire drag events
	label:
		location: 'knob'	# location of label
		precision: 1 	# how many decimal places
		popup: true		# does label pop up when dragged
		format: (v, options) -> Slider._.formatNumber v, decimalPlaces: options.precision
		# how to format the numeric value to a string
```

### Custom Components
The slider instantiates child components based on the configuration in `Slider.components`. The core pieces of slider: the knob, track, and label are also components.
``` coffee
	Slider.components =
		track: -> Track
		knob: -> Knob
		label: -> Label
		fill: (o) -> Fill if o.fill?
		debug: (o) -> Debug if o.debug
```

Each value in this object is a function that takes an options object and is expected to return a compnent constructor. If one is returned, the component is instantiated and assigned under the same key to the slider instance. For example:
``` js
var slider = new Slider('#slider');
slider.track // is the slider's track instance
```
The signature of a component constructor is `(slider, options)` where the options is borrowed from the main slider's options object under the key name of the component. This means you can pass options to components by using the same key as in the component definition.

To disable the knob popup for example:
``` coffee
slider = new Slider '#slider',
	min: 0
	max: 1
	knob:
		popup: false
```

Adding your own component is easy:
``` coffee
class Widget

	constructor: (@slider, options) ->

Slider.components.widget = (o) -> Widget

myWidgetSlider = new Slider '#slider',
	min: 0
	max: 10
	widget:
		widgetOption: true

myWidgetSlider.widget # will return the widget component instance
```
or in JavaScript:
``` js
function Widget(slider, options) {
	// construct away	
}

Slider.components.widget = function(o) { return Widget; };

myWidgetSlider = new Slider(#slider, {
	min: 0,
	max: 1,
	widget: {
		widgetOption: true
	}
});
```
