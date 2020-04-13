// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require uikit.min
//= require jquery
//= require_tree .
var Crawler = {
  notify: function(msg, type){
    UIkit.notification({
      message: msg,
      status: type,
      timeout: 2000,
      pos: 'top-center'
    });
  }
}
$(document).on('turbolinks:load', function(){
  jQuery(document).on("ajax:beforeSend", '.js-spinner-form', function () {
    $(".js-spinner").removeClass("uk-hidden");
  });
  jQuery(document).on("ajax:complete", '.js-spinner-form', function () {
    $(".js-spinner").addClass("uk-hidden");
  });
})
