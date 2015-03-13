# Slider

Mobile-first HTML5 slider component

Demo at http://slider.zhenya.co

## Include

- `slider.js` or `slider.min.js`
- `slider.css` or `slider.min.css`

## API

To instantiate a slider, pass a root element and an optional config object to the constructor:

``` js
var myslider = new Slider("#slider", {
	min: 0,
	max: 1
});
```

If a selector is passed in that matches more than one element, the first element will be used.

### Default options:
``` coffee
Slider.defaults = 
	min: 0
	max: 1
	initial: 0
	step: 0.1
	warnings: true
	orientation: 'horizontal'
	transitionDuration: 350
	poll: false
	formElement: null
```

### Components

The slider instantiates child components based on the configuration in `Slider.components`.

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