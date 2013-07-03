module.exports = function(grunt) {

  var path = require('path');

  grunt.registerMultiTask('handlebars', 'Compile Handlebars files', function() {
    var dest = this.file.dest;
    grunt.file.expandFiles(this.file.src).forEach(function(filepath) {
      grunt.helper('handlebars', filepath, dest);
    });

    if (grunt.task.current.errorCount) {
      return false;
    }
  });

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  grunt.registerHelper('handlebars', function(src, destPath) {
    var handlebars = require('handlebars'),
        js = '';

    var dest = path.join(destPath,
                         path.basename(src, '.handlebars') + '.js');

    try {
      js += '(function() {';
      js += 'var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};';
      js += 'templates[\'' + path.basename(src, '.handlebars') + '\'] = template(' + handlebars.precompile(grunt.file.read(src)) + ');\n';
      js += '})();';
      grunt.log.writeln( "File '" + dest + "' created." );
      grunt.file.write(dest, js);
    } catch (e) {
      grunt.log.error("Unable to compile your handlebars", e);
    }
  });

  // Project configuration.
  grunt.initConfig({
    pkg         : '<json:package.json>',
    coffee      : {
      dist        : {
        src         : ['<config:concat.coffee.dest>'],
        dest        : '<%= pkg.assets.tmp.js %>'
      }
    },
    handlebars  : {
      dist        : {
        src         : ['<%= pkg.assets.templates %>/**/*.handlebars'],
        dest        : '<%= pkg.assets.tmp.templates %>'
      }
    },
    concat      : {
      less        : {
        src         : [
          '<%= pkg.assets.less %>/lib/prefixer.less',
          '<%= pkg.assets.less %>/content.less'
        ],
        dest        : '<%= pkg.assets.tmp.less %>/less.less'
      },
      coffee      : {
        src         : ['<%= pkg.assets.coffee %>/main.coffee'],
        dest        : '<%= pkg.assets.tmp.coffee %>/main.coffee'
      },
      templates   : {
        src         : ['<%= pkg.assets.tmp.templates %>/**/*.js'],
        dest        : '<%= pkg.assets.tmp.js %>/templates.js',
        separator   : ';'
      },
      app         : {
        src         : [
          '<%= pkg.assets.js %>/vendor/jquery-1.7.2.js',
          '<%= pkg.assets.js %>/vendor/jquery.imagesloaded.js',
          '<%= pkg.assets.js %>/vendor/jquery.fancybox.js',
          '<%= pkg.assets.tmp.js %>/main.js'
        ],
        dest        : '<%= pkg.assets.js %>/main.pkg.js',
        separator   : ';'
      },
      css         : {
        src         : [
          '<%= pkg.assets.css %>/lib/libraries.css',
          '<%= pkg.assets.css %>/lib/media.css',
          '<%= pkg.assets.css %>/lib/space.css',
          '<%= pkg.assets.css %>/lib/grids.css',
          '<%= pkg.assets.css %>/lib/skeleton.css',
          '<%= pkg.assets.css %>/lib/buttons.css',
          '<%= pkg.assets.css %>/lib/jquery.fancybox.css',
          '<%= pkg.assets.tmp.css %>/less.css'
        ],
        dest        : '<%= pkg.assets.css %>/all.css'
      }
    },
    less          : {
      dist          : {
        src           : ['<config:concat.less.dest>'],
        dest          : '<%= pkg.assets.tmp.css %>/less.css'
      }
    },
    min           : {
      dist          : {
        src           : ['<config:concat.app.dest>'],
        dest          : '<%= pkg.assets.js %>/main.pkg.min.js'
      }
    },
    cssmin        : {
      dist          : {
        src           : ['<config:concat.css.dest>'],
        dest          : '<%= pkg.assets.css %>/all.min.css'
      }
    },
    watch         : {
      files         : [
        '<config:concat.coffee.src>',
        '<config:handlebars.dist.src>',
        '<config:concat.css.src>',
        '<config:concat.less.src>'
      ],
      tasks         : 'default'
    },
    uglify: {}
  });

  // Plugins
  grunt.loadNpmTasks('grunt-less');
  grunt.loadNpmTasks('grunt-css');
  grunt.loadNpmTasks('grunt-coffee');
  // Default task.
  grunt.registerTask('default', 'handlebars concat:templates concat:coffee coffee concat:app concat:less less concat:css');
  grunt.registerTask('production', 'default min cssmin');

};
