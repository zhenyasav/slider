module.exports = (grunt) ->

	grunt.initConfig
		pkg: grunt.file.readJSON 'package.json'

		coffee:
			compile:
				src: 'src/slider.coffee'
				dest: 'slider.js'

		less:
			compile:
				src: 'src/slider.less'
				dest: 'slider.css'
			
			minify:
				options:
					compress: true
				src: 'src/slider.less'
				dest: 'slider.min.css'

		uglify:
			build:
				options: 
					banner: "// <%= pkg.name %>\n// <%= pkg.author %>\n// <%= pkg.repository.url %>\n\n"
				src: 'slider.js'
				dest: 'slider.min.js'


	grunt.loadNpmTasks 'grunt-contrib-coffee'
	grunt.loadNpmTasks 'grunt-contrib-less'
	grunt.loadNpmTasks 'grunt-contrib-uglify'

	grunt.registerTask 'default', ['coffee', 'less', 'uglify']