Package.describe({
	name: 'zhenya:slider',
	version: '0.0.1',
	// Brief, one-line summary of the package.
	summary: 'Slide smoothly',
	// URL to the Git repository containing the source code for this package.
	git: '',
	// By default, Meteor will default to using README.md for documentation.
	// To avoid submitting documentation, set this field to null.
	documentation: 'README.md'
});

Package.onUse(function(api) {
	api.versionsFrom('1.0.3.2');
	api.use([
		'coffeescript',
		'less',
		'templating',
		'underscore']);

	api.addFiles([

		'utils.import.less',
		'slider.less',
		'slider.coffee',

		'meteor/template.html',
		'meteor/template.coffee'
		
		], 'client');


});

Package.onTest(function(api) {
	api.use('tinytest');
	api.use('zhenya:slider');
});
