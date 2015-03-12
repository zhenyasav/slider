# Slider

HTML5 slider component

http://slider.zhenya.co

## API

To instantiate a slider, pass a root element and an optional options object to the constructor:

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