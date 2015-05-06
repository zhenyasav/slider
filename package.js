Package.describe({
	name: 'zhenya:slider',
	version: '0.0.4',
	summary: 'Mobile-first, smooth slider component',
	git: 'https://github.com/zhenyasav/slider',
	documentation: 'README.md'
});

Package.onUse(function(api) {

	api.versionsFrom('1.0');
	
	api.use([
		'coffeescript',
		'less',
		'templating',
		'underscore']);

	api.addFiles([

		'src/utils.import.less',
		'src/slider.less',
		'src/slider.coffee',

		'meteor/template.html',
		'meteor/template.coffee'
		
		], 'client');
});

Package.onTest(function(api) {
	api.use('tinytest');
	api.use('zhenya:slider');
});
